import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/api_response.dart';
import '../models/feed_models.dart';
import '../profile_page.dart';
import '../config/api_config.dart';
import '../services/auth_session.dart';
import '../services/feed_api.dart';
import '../services/memory_cache.dart';
import '../services/post_view_recorder.dart';
import '../services/profile_api.dart';
import '../theme/brand_colors.dart';
import 'fast_glass.dart';
import 'liquid_pressable.dart';

const _ink = BrandColors.ink;
const _likeRed = Color(0xFFE0245E);
const _repostGreen = Color(0xFF17A275);

/// Feed media frame — Instagram-style clamps:
/// landscape up to ~1.91:1, portrait down to 4:5.
const _mediaMinRatio = 4 / 5;
const _mediaMaxRatio = 1.91;

/// News feed backed by http://36.253.137.34:8012 (`/api/feed`).
class NewsFeedSection extends StatefulWidget {
  const NewsFeedSection({
    super.key,
    this.controller,
    this.padding = EdgeInsets.zero,
  });

  final ScrollController? controller;
  final EdgeInsets padding;

  @override
  State<NewsFeedSection> createState() => _NewsFeedSectionState();
}

class _NewsFeedSectionState extends State<NewsFeedSection> {
  final _feedApi = FeedApi();
  final _posts = <FeedPostDto>[];
  var _page = 1;
  var _loading = true;
  var _loadingMore = false;
  var _hasMore = true;
  String? _error;
  ScrollController? _ownedController;

  ScrollController get _scroll =>
      widget.controller ?? (_ownedController ??= ScrollController());

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _ownedController?.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    final pos = _scroll.position;
    if (pos.pixels > pos.maxScrollExtent - 480) {
      _loadMore();
    }
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      final cached = MemoryCache.get<List<FeedPostDto>>('feed.page1');
      setState(() {
        _error = null;
        _page = 1;
        _hasMore = true;
        if (cached != null && cached.isNotEmpty && _posts.isEmpty) {
          _posts.addAll(cached);
          _loading = false;
        } else {
          _loading = _posts.isEmpty;
        }
      });
    }
    try {
      final page = await _feedApi.getFeed(
        page: _page,
        pageSize: ApiConfig.feedPageSize,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _posts
            ..clear()
            ..addAll(page.results);
          MemoryCache.set(
            'feed.page1',
            List<FeedPostDto>.from(page.results),
            ttl: const Duration(minutes: 2),
          );
        } else {
          _posts.addAll(page.results);
        }
        _hasMore = page.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (_posts.isEmpty) _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (_posts.isEmpty) _error = 'Could not load feed';
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;
    setState(() {
      _loadingMore = true;
      _page += 1;
    });
    await _load(reset: false);
  }

  void _replacePost(FeedPostDto updated) {
    final i = _posts.indexWhere((p) => p.id == updated.id);
    if (i < 0) return;
    setState(() => _posts[i] = updated);
  }

  void _removePost(String id) {
    setState(() => _posts.removeWhere((p) => p.id == id));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
    }
    if (_error != null && _posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              TextButton(
                onPressed: () => _load(reset: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final cacheExtent = MediaQuery.sizeOf(context).height * 1.5;
    final itemCount = _posts.length + (_loadingMore ? 1 : 0);

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        controller: _scroll,
        padding: widget.padding,
        itemCount: itemCount == 0 ? 1 : itemCount,
        cacheExtent: cacheExtent,
        physics: const ClampingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        addSemanticIndexes: false,
        itemBuilder: (context, index) {
          if (_posts.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: Text('No posts yet — be the first.')),
            );
          }
          if (index >= _posts.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            );
          }
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == _posts.length - 1 && !_loadingMore ? 0 : 12,
            ),
            child: _FeedCard(
              post: _posts[index],
              onChanged: _replacePost,
              onDeleted: _removePost,
            ),
          );
        },
      ),
    );
  }
}

class _FeedCard extends StatefulWidget {
  const _FeedCard({
    required this.post,
    required this.onChanged,
    required this.onDeleted,
  });

  final FeedPostDto post;
  final ValueChanged<FeedPostDto> onChanged;
  final ValueChanged<String> onDeleted;

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> {
  final _feedApi = FeedApi();
  final _profileApi = ProfileApi();
  bool _busy = false;

  FeedPostDto get post => widget.post;

  @override
  void initState() {
    super.initState();
    PostViewRecorder.schedule(post.id);
  }

  Future<void> _openPostMenu(BuildContext buttonContext) async {
    HapticFeedback.selectionClick();
    final box = buttonContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    final anchor = origin & box.size;

    final action = await Navigator.of(context).push<_FeedMenuAction>(
      _FeedMenuRoute(anchorRect: anchor),
    );
    if (!mounted || action == null) return;

    switch (action) {
      case _FeedMenuAction.repost:
        await _repost();
      case _FeedMenuAction.copy:
        await Clipboard.setData(
          ClipboardData(text: post.content ?? ''),
        );
        HapticFeedback.selectionClick();
        _toast('Copied');
      case _FeedMenuAction.block:
        HapticFeedback.mediumImpact();
        try {
          await _profileApi.block(post.userId);
          _toast('Blocked ${post.displayAuthor}');
        } on ApiException catch (e) {
          _toast(e.message);
        }
      case _FeedMenuAction.delete:
        await _deleteOwnPost();
    }
  }

  Future<void> _repost() async {
    HapticFeedback.lightImpact();
    try {
      await _feedApi.createPost(
        content: 'Reposted',
        sharedPostId: post.id,
      );
      widget.onChanged(
        post.copyWith(shareCount: post.shareCount + 1),
      );
      _toast('Reposted');
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  void _toast(String label) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        backgroundColor: _ink.withValues(alpha: .92),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        duration: const Duration(milliseconds: 1600),
      ),
    );
  }

  void _openAuthorProfile() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: AuthorProfilePage(
            name: post.displayAuthor,
            authUserId: post.userId,
            username: post.username,
          ),
        ),
      ),
    );
  }

  void _openAvatarFullscreen() {
    HapticFeedback.selectionClick();
    final letter = post.displayAuthor.isEmpty
        ? '?'
        : post.displayAuthor[0].toUpperCase();
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: .82),
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, animation, __) => _AvatarLightbox(
          letter: letter,
          name: post.displayAuthor,
          imageUrl: post.avatar,
          heroTag: 'feed-avatar-${post.id}',
          animation: animation,
        ),
      ),
    );
  }

  Future<void> _toggleLike() async {
    if (_busy) return;
    HapticFeedback.lightImpact();
    final previous = post;
    final wasLiked = previous.likedByMe;
    widget.onChanged(
      previous.copyWith(
        reactionsCount: wasLiked
            ? (previous.reactionsCount > 0 ? previous.reactionsCount - 1 : 0)
            : previous.reactionsCount + 1,
        currentUserReaction: wasLiked ? null : 'like',
        clearReaction: wasLiked,
      ),
    );
    setState(() => _busy = true);
    try {
      await _feedApi.react(postId: previous.id, type: 'like');
    } on ApiException catch (e) {
      widget.onChanged(previous);
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_busy || post.userId.isEmpty) return;
    final me = AuthSession.instance.userId;
    if (me != null && me == post.userId) return;
    HapticFeedback.selectionClick();
    final next = !post.isFollowed;
    widget.onChanged(post.copyWith(isFollowed: next));
    setState(() => _busy = true);
    try {
      final result = await _profileApi.toggleFollow(post.userId);
      widget.onChanged(post.copyWith(isFollowed: result.isFollowing));
    } on ApiException catch (e) {
      widget.onChanged(post.copyWith(isFollowed: !next));
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openComments() async {
    HapticFeedback.selectionClick();
    final added = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(postId: post.id),
    );
    if (added != null && added > 0) {
      widget.onChanged(
        post.copyWith(commentsCount: post.commentsCount + added),
      );
    }
  }

  Future<void> _deleteOwnPost() async {
    final me = AuthSession.instance.userId;
    if (me == null || me != post.userId) return;
    try {
      await _feedApi.deletePost(post.id);
      widget.onDeleted(post.id);
      _toast('Post deleted');
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = post.media.isNotEmpty ? post.media.first : null;
    final isOwn = AuthSession.instance.userId == post.userId;
    final profession = post.categories.isNotEmpty
        ? post.categories.first.name
        : (post.isReel ? 'Reel' : 'Innovator');

    return FastGlass(
      borderRadius: BorderRadius.circular(26),
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FastTap(
                onTap: _openAvatarFullscreen,
                borderRadius: BorderRadius.circular(999),
                child: Hero(
                  tag: 'feed-avatar-${post.id}',
                  child: _Avatar(
                    letter: post.displayAuthor.isEmpty
                        ? '?'
                        : post.displayAuthor[0],
                    imageUrl: post.avatar,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: FastTap(
                            onTap: _openAuthorProfile,
                            borderRadius: BorderRadius.circular(6),
                            child: Text(
                              post.displayAuthor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _ink,
                                letterSpacing: -.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const _NameBadge(),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$profession · ${formatFeedTime(post.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _ink.withValues(alpha: .45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isOwn)
                _FollowButton(
                  following: post.isFollowed,
                  onTap: _toggleFollow,
                ),
              const SizedBox(width: 2),
              Builder(
                builder: (buttonContext) => FastTap(
                  onTap: () => _openPostMenu(buttonContext),
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.more_horiz_rounded,
                      size: 20,
                      color: _ink.withValues(alpha: .4),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if ((post.content ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _ExpandableStatus(text: post.content!.trim()),
          ],
          if (post.sharedPost != null) ...[
            const SizedBox(height: 10),
            _SharedPostPreview(post: post.sharedPost!),
          ],
          if (media != null && media.file.isNotEmpty) ...[
            const SizedBox(height: 12),
            _MediaSection(
              isVideo: media.isVideo,
              label: media.isVideo ? 'Video' : 'Photo',
              imageUrl: media.thumbnail?.isNotEmpty == true
                  ? media.thumbnail!
                  : media.file,
            ),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ActionButton(
                icon: post.likedByMe
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: '${post.reactionsCount}',
                active: post.likedByMe,
                activeColor: _likeRed,
                onTap: _toggleLike,
              ),
              _ActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: '${post.commentsCount}',
                onTap: _openComments,
              ),
              _ActionButton(
                icon: Icons.repeat_rounded,
                label: '${post.shareCount}',
                activeColor: _repostGreen,
                onTap: _repost,
              ),
              _ActionButton(
                icon: Icons.ios_share_rounded,
                label: 'Share',
                onTap: () {
                  HapticFeedback.selectionClick();
                  Clipboard.setData(
                    ClipboardData(text: post.content ?? post.id),
                  );
                  _toast('Link copied');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SharedPostPreview extends StatelessWidget {
  const _SharedPostPreview({required this.post});
  final FeedPostDto post;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ink.withValues(alpha: .1)),
        color: Colors.white.withValues(alpha: .35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '@${post.displayAuthor}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: _ink,
            ),
          ),
          if ((post.content ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              post.content!.trim(),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: _ink.withValues(alpha: .7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.letter, this.imageUrl});

  final String letter;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BrandColors.secondarySurface, Color(0xFF8A93A8)],
        ),
      ),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: .95),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    letter.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  letter.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Immersive avatar preview — tap anywhere to dismiss.
class _AvatarLightbox extends StatelessWidget {
  const _AvatarLightbox({
    required this.letter,
    required this.name,
    required this.heroTag,
    required this.animation,
    this.imageUrl,
  });

  final String letter;
  final String name;
  final String? imageUrl;
  final String heroTag;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final url = imageUrl?.trim();

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: SafeArea(
          child: FadeTransition(
            opacity: curved,
            child: Stack(
              children: [
                Center(
                  child: ScaleTransition(
                    scale: Tween<double>(begin: .86, end: 1).animate(curved),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Hero(
                          tag: heroTag,
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  BrandColors.secondarySurface,
                                  Color(0xFF8A93A8),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .9),
                                width: 3,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: url != null && url.isNotEmpty
                                ? Image.network(url, fit: BoxFit.cover)
                                : Center(
                                    child: Text(
                                      letter,
                                      style: const TextStyle(
                                        fontSize: 96,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.postId});
  final String postId;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _api = FeedApi();
  final _controller = TextEditingController();
  final _comments = <FeedComment>[];
  var _loading = true;
  var _sending = false;
  var _added = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.comments(postId: widget.postId);
      if (!mounted) return;
      setState(() {
        _comments
          ..clear()
          ..addAll(list);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final created = await _api.createComment(
        postId: widget.postId,
        content: text,
      );
      if (!mounted) return;
      setState(() {
        _comments.insert(0, created);
        _controller.clear();
        _sending = false;
        _added += 1;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: .72,
          child: Material(
            color: BrandColors.canvas,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _ink.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Comments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context, _added),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : _error != null
                          ? Center(child: Text(_error!))
                          : _comments.isEmpty
                              ? const Center(child: Text('No comments yet'))
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    12,
                                  ),
                                  itemCount: _comments.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (_, i) {
                                    final c = _comments[i];
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _Avatar(
                                          letter: (c.username ?? '?')[0],
                                          imageUrl: c.avatar,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                c.username ?? 'User',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                c.content ?? '',
                                                style: TextStyle(
                                                  color: _ink.withValues(
                                                    alpha: .78,
                                                  ),
                                                  height: 1.35,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'Add a comment…',
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: .7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _sending ? null : _send,
                          style: IconButton.styleFrom(
                            backgroundColor: BrandColors.secondarySurface,
                          ),
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Collapses long captions to 3 lines with a liquid-light “see more”.
class _ExpandableStatus extends StatefulWidget {
  const _ExpandableStatus({required this.text});

  final String text;

  @override
  State<_ExpandableStatus> createState() => _ExpandableStatusState();
}

class _ExpandableStatusState extends State<_ExpandableStatus> {
  static const _maxLines = 3;

  bool _expanded = false;
  bool _hasOverflow = false;
  double _measuredWidth = -1;

  static final _style = TextStyle(
    fontSize: 13.5,
    height: 1.5,
    color: _ink.withValues(alpha: .82),
  );

  void _measureIfNeeded(double maxWidth) {
    if (maxWidth <= 0 || maxWidth == _measuredWidth) return;
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: _style),
      maxLines: _maxLines,
      textDirection: TextDirection.ltr,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    final overflows = painter.didExceedMaxLines;
    _measuredWidth = maxWidth;
    if (overflows == _hasOverflow) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _hasOverflow = overflows);
    });
  }

  @override
  void didUpdateWidget(covariant _ExpandableStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _measuredWidth = -1;
      _hasOverflow = false;
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _measureIfNeeded(constraints.maxWidth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: _style,
              maxLines: _expanded ? null : _maxLines,
              overflow:
                  _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (_hasOverflow) ...[
              const SizedBox(height: 4),
              FastTap(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _expanded = !_expanded);
                },
                borderRadius: BorderRadius.circular(6),
                child: Text(
                  _expanded ? 'see less' : 'see more',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _ink.withValues(alpha: .5),
                    letterSpacing: -.1,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Tiny verified mark that sits flush beside the author name.
class _NameBadge extends StatelessWidget {
  const _NameBadge();

  @override
  Widget build(BuildContext context) {
    return const Tooltip(
      message: 'Verified Innovator',
      child: Padding(
        padding: EdgeInsets.only(top: .5),
        child: Icon(
          Icons.verified_rounded,
          size: 15,
          color: BrandColors.accent,
        ),
      ),
    );
  }
}

/// Lightweight follow pill — FastTap + AnimatedContainer (no idle tickers).
class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.following, required this.onTap});

  final bool following;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor = following ? _ink : Colors.white;
    return FastTap(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: following
              ? Colors.white.withValues(alpha: .78)
              : BrandColors.secondarySurface,
          border: Border.all(
            color: following
                ? _ink.withValues(alpha: .22)
                : Colors.white.withValues(alpha: .28),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              following ? Icons.check_rounded : Icons.add_rounded,
              size: 14,
              color: labelColor,
            ),
            const SizedBox(width: 4),
            Text(
              following ? 'Following' : 'Follow',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: labelColor,
                letterSpacing: .2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Adaptive feed media — network image/video thumb.
class _MediaSection extends StatelessWidget {
  const _MediaSection({
    required this.isVideo,
    required this.label,
    required this.imageUrl,
  });

  final bool isVideo;
  final String label;
  final String imageUrl;

  double get _frameRatio => (4 / 5).clamp(_mediaMinRatio, _mediaMaxRatio);

  @override
  Widget build(BuildContext context) {
    final ratio = _frameRatio;
    final screenCap = MediaQuery.sizeOf(context).height * .62;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = math.min(width / ratio, screenCap);

        return RepaintBoundary(
          child: SizedBox(
            width: width,
            height: height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: .4)),
                color: const Color(0xFF1B1E28),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl.isNotEmpty)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: width,
                        height: height,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: Color(0xFF1B1E28),
                        ),
                      )
                    else
                      const ColoredBox(color: Color(0xFF1B1E28)),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x2E000000),
                            Color(0x00000000),
                            Color(0x8C000000),
                          ],
                          stops: [0, .45, 1],
                        ),
                      ),
                    ),
                    if (isVideo)
                      Center(
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: .35),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .55),
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.black.withValues(alpha: .4),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isVideo
                                  ? Icons.videocam_outlined
                                  : Icons.image_outlined,
                              size: 12,
                              color: Colors.white.withValues(alpha: .9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isVideo ? 'Video' : 'Photo',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: .9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      bottom: 12,
                      right: 14,
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: .92),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.activeColor = _ink,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : _ink.withValues(alpha: .55);

    return FastTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              // Small pop when the action toggles on.
              scale: active ? 1.18 : 1,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- post menu

enum _FeedMenuAction { repost, copy, block, delete }

class _FeedMenuRoute extends PopupRoute<_FeedMenuAction> {
  _FeedMenuRoute({required this.anchorRect});

  final Rect anchorRect;

  @override
  Color? get barrierColor => _ink.withValues(alpha: .12);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 280);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _FeedMenuPopover(anchorRect: anchorRect, animation: animation);
  }
}

class _FeedMenuPopover extends StatelessWidget {
  const _FeedMenuPopover({required this.anchorRect, required this.animation});

  final Rect anchorRect;
  final Animation<double> animation;

  static const _width = 168.0;
  static const _height = 156.0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);

    var left = anchorRect.right - _width;
    left = left.clamp(12.0, size.width - _width - 12);

    var top = anchorRect.bottom + 6;
    final maxTop = size.height - padding.bottom - _height - 12;
    final openAbove = top > maxTop;
    if (openAbove) top = anchorRect.top - _height - 6;
    top = top.clamp(padding.top + 8, maxTop);

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            width: _width,
            child: FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: .92, end: 1).animate(curved),
                alignment: openAbove
                    ? Alignment.bottomRight
                    : Alignment.topRight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: .9),
                            Colors.white.withValues(alpha: .62),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .95),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _ink.withValues(alpha: .16),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _FeedMenuTile(
                              icon: Icons.repeat_rounded,
                              label: 'Repost',
                              onTap: () => Navigator.of(
                                context,
                              ).pop(_FeedMenuAction.repost),
                            ),
                            const SizedBox(height: 4),
                            _FeedMenuTile(
                              icon: Icons.copy_rounded,
                              label: 'Copy',
                              onTap: () => Navigator.of(
                                context,
                              ).pop(_FeedMenuAction.copy),
                            ),
                            const SizedBox(height: 4),
                            if (AuthSession.instance.userId != null) ...[
                              // Delete shown for everyone; server enforces ownership.
                              _FeedMenuTile(
                                icon: Icons.delete_outline_rounded,
                                label: 'Delete',
                                destructive: true,
                                onTap: () => Navigator.of(
                                  context,
                                ).pop(_FeedMenuAction.delete),
                              ),
                              const SizedBox(height: 4),
                            ],
                            _FeedMenuTile(
                              icon: Icons.block_rounded,
                              label: 'Block',
                              destructive: true,
                              onTap: () => Navigator.of(
                                context,
                              ).pop(_FeedMenuAction.block),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedMenuTile extends StatelessWidget {
  const _FeedMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? const Color(0xFFC0392B) : _ink;

    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      rippleColor: destructive ? accent : _ink,
      intensity: 1.1,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: destructive
              ? accent.withValues(alpha: .08)
              : Colors.white.withValues(alpha: .42),
          border: Border.all(
            color: destructive
                ? accent.withValues(alpha: .2)
                : Colors.white.withValues(alpha: .7),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: accent.withValues(alpha: .85)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -.1,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
