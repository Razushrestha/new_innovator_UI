import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/api_response.dart';
import 'models/search_models.dart';
import 'profile_page.dart';
import 'services/search_api.dart';
import 'theme/brand_colors.dart';
import 'widgets/liquid_pressable.dart';
import 'widgets/wave_fill_painter.dart';

const _ink = BrandColors.ink;
const _muted = BrandColors.muted;

/// In-shell search wired to http://36.253.137.34:8015
///
/// Idle: suggested users + recent history.
/// Typing: combined search (people, posts, hashtags) with debounce.
class SearchSection extends StatefulWidget {
  const SearchSection({super.key, this.contentPadding = EdgeInsets.zero});

  final EdgeInsets contentPadding;

  @override
  State<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<SearchSection>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _searchApi = SearchApi();

  String _query = '';
  bool _loading = false;
  bool _bootLoading = true;
  String? _error;

  CombinedSearchResult _results = const CombinedSearchResult();
  List<SearchUserHit> _suggested = const [];
  List<SearchHistoryItem> _history = const [];

  Timer? _debounce;

  late final AnimationController _stretch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _loadIdle();
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    _stretch.dispose();
    _wave.dispose();
    super.dispose();
  }

  Future<void> _loadIdle() async {
    setState(() {
      _bootLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _searchApi.suggestedUsers(),
        _searchApi.history(),
      ]);
      if (!mounted) return;
      setState(() {
        _suggested = results[0] as List<SearchUserHit>;
        _history = results[1] as List<SearchHistoryItem>;
        _bootLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _bootLoading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bootLoading = false;
        _error = 'Could not load search';
      });
    }
  }

  void _onQueryChanged(String value) {
    final trimmed = value.trim();
    setState(() => _query = trimmed);
    _debounce?.cancel();
    if (trimmed.isEmpty) {
      setState(() {
        _results = const CombinedSearchResult();
        _loading = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 220), () {
      _runSearch(trimmed);
    });
  }

  Future<void> _runSearch(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final combined = await _searchApi.search(q: q, type: 'all');
      // Fill empty sections in parallel instead of chaining round trips.
      var users = combined.users;
      var posts = combined.posts;
      var hashtags = combined.hashtags;
      final fill = <Future<void>>[];
      if (users.isEmpty) {
        fill.add(() async {
          try {
            users = await _searchApi.searchUsers(q);
          } catch (_) {}
        }());
      }
      if (posts.isEmpty) {
        fill.add(() async {
          try {
            posts = await _searchApi.searchPosts(q);
          } catch (_) {}
        }());
      }
      if (hashtags.isEmpty) {
        fill.add(() async {
          try {
            hashtags = await _searchApi.searchHashtags(q);
          } catch (_) {}
        }());
      }
      if (fill.isNotEmpty) await Future.wait(fill);
      if (!mounted || _query != q) return;
      setState(() {
        _results = CombinedSearchResult(
          users: users,
          posts: posts,
          hashtags: hashtags,
          totalUsers: combined.totalUsers > 0
              ? combined.totalUsers
              : users.length,
          totalPosts: combined.totalPosts > 0
              ? combined.totalPosts
              : posts.length,
        );
        _loading = false;
      });
      // Refresh history after a search is recorded server-side.
      unawaited(_refreshHistoryQuiet());
    } on ApiException catch (e) {
      if (!mounted || _query != q) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted || _query != q) return;
      setState(() {
        _loading = false;
        _error = 'Search failed';
      });
    }
  }

  Future<void> _refreshHistoryQuiet() async {
    try {
      final history = await _searchApi.history();
      if (mounted) setState(() => _history = history);
    } catch (_) {}
  }

  void _useTerm(String term) {
    HapticFeedback.selectionClick();
    _controller.text = term;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    _focus.requestFocus();
    _onQueryChanged(term);
  }

  void _clear() {
    HapticFeedback.selectionClick();
    _debounce?.cancel();
    _controller.clear();
    _focus.requestFocus();
    setState(() {
      _query = '';
      _results = const CombinedSearchResult();
      _loading = false;
      _error = null;
    });
  }

  Future<void> _clearHistory() async {
    HapticFeedback.mediumImpact();
    try {
      await _searchApi.clearHistory();
      if (mounted) setState(() => _history = const []);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(behavior: SnackBarBehavior.floating, content: Text(e.message)),
        );
      }
    }
  }

  void _openUser(SearchUserHit user) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AuthorProfilePage(
          name: user.displayName,
          authUserId: user.id,
          username: user.username,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.contentPadding;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        20,
        padding.top + 10,
        20,
        padding.bottom + 6,
      ),
      children: [
        _buildBar(),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .04),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _buildBody(),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_query.isEmpty) {
      if (_bootLoading) {
        return const Padding(
          key: ValueKey('boot'),
          padding: EdgeInsets.only(top: 40),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
        );
      }
      if (_error != null && _suggested.isEmpty && _history.isEmpty) {
        return _ErrorBlock(
          key: const ValueKey('idle-error'),
          message: _error!,
          onRetry: _loadIdle,
        );
      }
      return _IdlePanel(
        key: const ValueKey('idle'),
        suggested: _suggested,
        history: _history,
        wave: _wave,
        onUser: _openUser,
        onHistory: _useTerm,
        onClearHistory: _history.isEmpty ? null : _clearHistory,
      );
    }

    if (_loading && _results.totalCount == 0) {
      return const Padding(
        key: ValueKey('loading'),
        padding: EdgeInsets.only(top: 40),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }

    if (_error != null && _results.totalCount == 0) {
      return _ErrorBlock(
        key: const ValueKey('search-error'),
        message: _error!,
        onRetry: () => _runSearch(_query),
      );
    }

    if (_results.totalCount == 0) {
      return _NoResults(key: const ValueKey('empty'), query: _query, wave: _wave);
    }

    return _ResultsPanel(
      key: ValueKey('results-$_query'),
      query: _query,
      results: _results,
      loading: _loading,
      onUser: _openUser,
      onHashtag: _useTerm,
    );
  }

  Widget _buildBar() {
    return LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: Listenable.merge([_stretch, _wave, _focus]),
        builder: (context, _) {
          final t = Curves.easeOutBack.transform(_stretch.value);
          final width = lerpDouble(
            56,
            constraints.maxWidth,
            t.clamp(0, 1.2),
          )!.clamp(56.0, constraints.maxWidth);
          final open = ((_stretch.value - .55) / .35).clamp(0.0, 1.0);
          final focused = _focus.hasFocus;
          final phase = _wave.value * 2 * pi;

          return Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  width: width,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: focused ? .72 : .58),
                        Colors.white.withValues(alpha: focused ? .42 : .30),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: focused ? 1 : .85),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _ink.withValues(alpha: focused ? .14 : .08),
                        blurRadius: focused ? 26 : 16,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: WaveFillPainter(
                          phase: phase,
                          fill: focused ? .22 : .12,
                          color: _ink.withValues(alpha: .05),
                          amplitude: 3,
                          frequency: 1.6,
                        ),
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 54,
                            child: Icon(
                              Icons.search_rounded,
                              size: 23,
                              color: _ink,
                            ),
                          ),
                          Expanded(
                            child: Opacity(
                              opacity: open,
                              child: TextField(
                                controller: _controller,
                                focusNode: _focus,
                                onChanged: _onQueryChanged,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (v) {
                                  _debounce?.cancel();
                                  final q = v.trim();
                                  if (q.isNotEmpty) _runSearch(q);
                                },
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: _ink,
                                ),
                                cursorColor: _ink,
                                decoration: const InputDecoration(
                                  isCollapsed: true,
                                  border: InputBorder.none,
                                  hintText: 'Search people, posts, hashtags…',
                                  hintStyle: TextStyle(
                                    fontSize: 14.5,
                                    color: _muted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          AnimatedScale(
                            scale: _query.isEmpty ? 0 : 1,
                            duration: const Duration(milliseconds: 380),
                            curve: Curves.easeOutBack,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: LiquidPressable(
                                onTap: _clear,
                                borderRadius: BorderRadius.circular(14),
                                rippleColor: Colors.white,
                                intensity: 1.1,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        const Color(0xFF2A2F3E)
                                            .withValues(alpha: .95),
                                        const Color(0xFF15181F)
                                            .withValues(alpha: .9),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: .35),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------------ idle

class _IdlePanel extends StatelessWidget {
  const _IdlePanel({
    super.key,
    required this.suggested,
    required this.history,
    required this.wave,
    required this.onUser,
    required this.onHistory,
    this.onClearHistory,
  });

  final List<SearchUserHit> suggested;
  final List<SearchHistoryItem> history;
  final AnimationController wave;
  final ValueChanged<SearchUserHit> onUser;
  final ValueChanged<String> onHistory;
  final VoidCallback? onClearHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (history.isNotEmpty) ...[
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recent',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    letterSpacing: -.2,
                  ),
                ),
              ),
              if (onClearHistory != null)
                TextButton(
                  onPressed: onClearHistory,
                  style: TextButton.styleFrom(
                    foregroundColor: _muted,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Clear', style: TextStyle(fontSize: 12.5)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in history.take(8))
                _Chip(
                  label: item.query,
                  icon: Icons.history_rounded,
                  onTap: () => onHistory(item.query),
                ),
            ],
          ),
          const SizedBox(height: 22),
        ],
        AnimatedBuilder(
          animation: wave,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, sin(wave.value * 2 * pi) * 2.2),
            child: child,
          ),
          child: const Text(
            'Suggested for you',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: _ink,
              letterSpacing: -.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (suggested.isEmpty)
          const Text(
            'No suggestions yet — follow people to improve this list.',
            style: TextStyle(fontSize: 12.5, color: _muted),
          )
        else
          for (var i = 0; i < suggested.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _UserTile(
              user: suggested[i],
              query: '',
              subtitleOverride: suggested[i].reason ??
                  (suggested[i].bio?.trim().isNotEmpty == true
                      ? suggested[i].bio
                      : null),
              onTap: () => onUser(suggested[i]),
            ),
          ],
      ],
    );
  }
}

// --------------------------------------------------------------- results

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({
    super.key,
    required this.query,
    required this.results,
    required this.loading,
    required this.onUser,
    required this.onHashtag,
  });

  final String query;
  final CombinedSearchResult results;
  final bool loading;
  final ValueChanged<SearchUserHit> onUser;
  final ValueChanged<String> onHashtag;

  @override
  Widget build(BuildContext context) {
    final count = results.totalCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$count result${count == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _muted,
                    letterSpacing: .2,
                  ),
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        if (results.users.isNotEmpty) ...[
          const _SectionLabel('People'),
          const SizedBox(height: 8),
          for (final user in results.users) ...[
            _UserTile(user: user, query: query, onTap: () => onUser(user)),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
        ],
        if (results.hashtags.isNotEmpty) ...[
          const _SectionLabel('Hashtags'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in results.hashtags)
                _Chip(
                  label: tag.startsWith('#') ? tag : '#$tag',
                  icon: Icons.tag_rounded,
                  onTap: () => onHashtag(tag.replaceFirst('#', '')),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (results.posts.isNotEmpty) ...[
          const _SectionLabel('Posts'),
          const SizedBox(height: 8),
          for (final post in results.posts) ...[
            _PostTile(post: post, query: query, onAuthor: () {
              if (post.authorId.isEmpty) return;
              onUser(
                SearchUserHit(
                  id: post.authorId,
                  username: post.username,
                  avatar: post.avatar,
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _muted,
          letterSpacing: .3,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      rippleColor: _ink,
      intensity: .6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: .5),
          border: Border.all(color: Colors.white.withValues(alpha: .9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _ink.withValues(alpha: .55)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _ink.withValues(alpha: .75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.query,
    required this.onTap,
    this.subtitleOverride,
  });

  final SearchUserHit user;
  final String query;
  final VoidCallback onTap;
  final String? subtitleOverride;

  @override
  Widget build(BuildContext context) {
    final subtitle = subtitleOverride?.trim().isNotEmpty == true
        ? subtitleOverride!.trim()
        : [
            if (user.username != null && user.username!.isNotEmpty)
              '@${user.username}',
            if (user.bio != null && user.bio!.trim().isNotEmpty) user.bio!.trim(),
          ].join(' · ');

    return _GlassTile(
      onTap: onTap,
      leading: _Avatar(name: user.displayName, url: user.avatar),
      title: _highlight(user.displayName, query),
      subtitle: subtitle.isEmpty ? 'Innovator' : subtitle,
      trailing: user.isFollowing
          ? Text(
              'Following',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _ink.withValues(alpha: .45),
              ),
            )
          : null,
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({
    required this.post,
    required this.query,
    required this.onAuthor,
  });

  final SearchPostHit post;
  final String query;
  final VoidCallback onAuthor;

  @override
  Widget build(BuildContext context) {
    final content = (post.content ?? '').trim();
    final meta = [
      if (post.username != null && post.username!.isNotEmpty)
        '@${post.username}',
      '${post.reactionsCount} reactions',
      '${post.commentsCount} comments',
    ].join(' · ');

    return _GlassTile(
      onTap: onAuthor,
      leading: _Avatar(name: post.username ?? 'P', url: post.avatar),
      title: _highlight(
        content.isEmpty ? '(No caption)' : content,
        query,
        maxLines: 2,
      ),
      subtitle: meta,
    );
  }
}

class _GlassTile extends StatelessWidget {
  const _GlassTile({
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final VoidCallback onTap;
  final Widget leading;
  final InlineSpan title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      rippleColor: _ink,
      intensity: .6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: .62),
                  Colors.white.withValues(alpha: .36),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: .92)),
            ),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: _ink.withValues(alpha: .48),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.url});

  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final letter = name.isEmpty ? '?' : name[0].toUpperCase();
    final trimmed = url?.trim();
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF38BDF8)],
        ),
        border: Border.all(color: Colors.white, width: 1.4),
      ),
      clipBehavior: Clip.antiAlias,
      child: trimmed != null && trimmed.isNotEmpty
          ? Image.network(
              trimmed,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  letter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
    );
  }
}

TextSpan _highlight(String text, String query, {int maxLines = 1}) {
  const base = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color(0xB31B1E28),
  );
  const match = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: _ink,
  );
  final lowerTitle = text.toLowerCase();
  final lowerQuery = query.toLowerCase();
  final start = lowerTitle.indexOf(lowerQuery);
  if (lowerQuery.isEmpty || start < 0) {
    return TextSpan(text: text, style: base);
  }
  final end = start + lowerQuery.length;
  return TextSpan(
    children: [
      TextSpan(text: text.substring(0, start), style: base),
      TextSpan(text: text.substring(start, end), style: match),
      TextSpan(text: text.substring(end), style: base),
    ],
  );
}

class _NoResults extends StatelessWidget {
  const _NoResults({super.key, required this.query, required this.wave});

  final String query;
  final AnimationController wave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: wave,
            builder: (context, _) => Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .55),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .95),
                  width: 1.4,
                ),
              ),
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: WaveFillPainter(
                        phase: wave.value * 2 * pi,
                        fill: .16,
                        color: _ink.withValues(alpha: .1),
                        amplitude: 3,
                        frequency: 1.5,
                      ),
                    ),
                    const Center(
                      child: Icon(
                        Icons.search_off_rounded,
                        size: 28,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No matches for “$query”',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Try a person, post keyword, or hashtag.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: _muted),
          ),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
