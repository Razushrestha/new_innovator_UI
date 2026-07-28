import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../profile_page.dart';
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

enum FeedMediaType { none, image, video }

class FeedPost {
  const FeedPost({
    required this.author,
    required this.profession,
    required this.time,
    required this.status,
    this.mediaType = FeedMediaType.none,
    this.mediaLabel = '',
    this.imageAsset = '',
    this.aspectRatio,
    required this.likes,
    required this.comments,
    required this.reposts,
  });

  final String author;
  final String profession;
  final String time;
  final String status;
  final FeedMediaType mediaType;
  final String mediaLabel;

  /// Relative path under the project `Assets/` folder.
  final String imageAsset;

  /// Natural width ÷ height. When null, resolved from the asset.
  final double? aspectRatio;
  final int likes;
  final int comments;
  final int reposts;
}

const _samplePosts = [
  FeedPost(
    author: 'Aarav Sharma',
    profession: 'Product Designer',
    time: '25m',
    status:
        'Just shipped the new liquid glass onboarding flow. The spring physics '
        'on the buttons make such a difference — every tap feels alive. We also '
        'tuned the wave fill so it settles softer on release, and the dockable '
        'nav now remembers your last edge for the whole session.',
    mediaType: FeedMediaType.video,
    mediaLabel: 'Design walkthrough · 2:14',
    imageAsset: 'Assets/feed/post_01.jpg',
    aspectRatio: 16 / 9,
    likes: 128,
    comments: 24,
    reposts: 18,
  ),
  FeedPost(
    author: 'Maya Chen',
    profession: 'Innovation Lead',
    time: '2h',
    status:
        'Our team hit the weekly goal three days early. Huge thanks to everyone '
        'who jumped on the sprint review — recap notes are up.',
    mediaType: FeedMediaType.image,
    mediaLabel: 'Sprint review recap',
    imageAsset: 'Assets/feed/post_02.jpg',
    aspectRatio: 4 / 5,
    likes: 86,
    comments: 12,
    reposts: 7,
  ),
  FeedPost(
    author: 'Innovator Team',
    profession: 'Official',
    time: '1d',
    status:
        'New in the Shop: premium templates for pitch decks and product specs. '
        'E-learning members get early access this week.',
    mediaType: FeedMediaType.image,
    mediaLabel: 'Premium templates · Shop',
    imageAsset: 'Assets/feed/post_03.jpg',
    aspectRatio: 1,
    likes: 214,
    comments: 41,
    reposts: 39,
  ),
  FeedPost(
    author: 'Priya Thapa',
    profession: 'Founder',
    time: '3h',
    status:
        'Closed our seed round today. Grateful for every mentor who pushed us '
        'to tighten the pitch and ship the MVP before fundraising.',
    mediaType: FeedMediaType.image,
    mediaLabel: 'Seed close celebration',
    imageAsset: 'Assets/feed/post_04.jpg',
    aspectRatio: 3 / 2,
    likes: 342,
    comments: 58,
    reposts: 44,
  ),
  FeedPost(
    author: 'Rohan KC',
    profession: 'Flutter Dev',
    time: '4h',
    status:
        'BackdropFilter + soft wave fill is the combo. Sharing a short clip of '
        'the dockable nav morphing between docks.',
    mediaType: FeedMediaType.video,
    mediaLabel: 'Nav morph · 0:48',
    imageAsset: 'Assets/feed/post_05.jpg',
    aspectRatio: 9 / 16,
    likes: 167,
    comments: 31,
    reposts: 22,
  ),
  FeedPost(
    author: 'Sneha Rai',
    profession: 'UX Researcher',
    time: '5h',
    status:
        'Five user interviews later: people love the liquid press feedback but '
        'want clearer labels on the shop filters. Iterating tonight.',
    mediaType: FeedMediaType.image,
    mediaLabel: 'Research board',
    imageAsset: 'Assets/feed/post_06.jpg',
    aspectRatio: 16 / 9,
    likes: 94,
    comments: 19,
    reposts: 8,
  ),
  FeedPost(
    author: 'Kabir Joshi',
    profession: 'Growth Marketer',
    time: '6h',
    status:
        'Launch checklist pinned: waitlist → drip sequence → Khalti checkout '
        'smoke test. If you want the Notion template, ping me. Also covering '
        'analytics events, invite codes, and a soft launch window for early '
        'Innovators before we open the waitlist to everyone next week.',
    mediaType: FeedMediaType.image,
    mediaLabel: 'Launch checklist',
    imageAsset: 'Assets/feed/post_07.jpg',
    aspectRatio: 5 / 4,
    likes: 121,
    comments: 27,
    reposts: 16,
  ),
  FeedPost(
    author: 'Anisha Gurung',
    profession: 'Brand Designer',
    time: '8h',
    status:
        'Explored a warmer gold accent on deep navy. Feels premium without '
        'shouting — pairing it with the center logo mark next.',
    mediaType: FeedMediaType.image,
    mediaLabel: 'Brand exploration',
    imageAsset: 'Assets/feed/post_08.jpg',
    aspectRatio: 4 / 5,
    likes: 203,
    comments: 36,
    reposts: 29,
  ),
  FeedPost(
    author: 'Nischal Adhikari',
    profession: 'Product Manager',
    time: '10h',
    status:
        'Roadmap update: e-learning certificates, collaborator invites, and '
        'offline course downloads are next on the board.',
    mediaType: FeedMediaType.image,
    mediaLabel: 'Q3 roadmap',
    imageAsset: 'Assets/feed/post_09.jpg',
    aspectRatio: 21 / 9,
    likes: 156,
    comments: 22,
    reposts: 14,
  ),
  FeedPost(
    author: 'Elena Voss',
    profession: 'AI Engineer',
    time: '12h',
    status:
        'Prototyped an on-device summarizer for course notes. Still rough, but '
        'the latency already feels snappy enough for demos.',
    mediaType: FeedMediaType.video,
    mediaLabel: 'AI notes demo · 1:05',
    imageAsset: 'Assets/feed/post_10.jpg',
    aspectRatio: 1,
    likes: 278,
    comments: 47,
    reposts: 33,
  ),
  FeedPost(
    author: 'Samir Basnet',
    profession: 'Community Lead',
    time: '18h',
    status:
        'Kathmandu innovators meetup this Saturday — lightning talks, open '
        'desk critiques, and a liquid-UI build challenge. Who\'s in?',
    mediaType: FeedMediaType.image,
    mediaLabel: 'Meetup poster',
    imageAsset: 'Assets/feed/post_11.jpg',
    aspectRatio: 3 / 4,
    likes: 189,
    comments: 63,
    reposts: 41,
  ),
  FeedPost(
    author: 'Innovator Team',
    profession: 'Official',
    time: '2d',
    status:
        'Tip of the week: long-press the logo orb to drag the nav to any edge. '
        'Your dock preference sticks for the session.',
    mediaType: FeedMediaType.image,
    mediaLabel: 'Pro tip · Dock anywhere',
    imageAsset: 'Assets/feed/post_12.jpg',
    aspectRatio: 16 / 9,
    likes: 401,
    comments: 72,
    reposts: 88,
  ),
];

/// News feed in the liquid glass language: frosted post cards with an
/// author header (+Follow), status text, a media area, and springy
/// like / comment / repost / share actions.
///
/// Built as a lazy [ListView] so off-screen posts are not painted.
class NewsFeedSection extends StatelessWidget {
  const NewsFeedSection({
    super.key,
    this.controller,
    this.padding = EdgeInsets.zero,
  });

  final ScrollController? controller;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final cacheExtent = MediaQuery.sizeOf(context).height * 1.5;
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: _samplePosts.length,
      cacheExtent: cacheExtent,
      physics: const ClampingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      addSemanticIndexes: false,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == _samplePosts.length - 1 ? 0 : 12,
          ),
          child: _FeedCard(post: _samplePosts[index]),
        );
      },
    );
  }
}

class _FeedCard extends StatefulWidget {
  const _FeedCard({required this.post});

  final FeedPost post;

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> {
  bool _liked = false;
  bool _reposted = false;
  bool _following = false;

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
        HapticFeedback.lightImpact();
        setState(() => _reposted = !_reposted);
        _toast(_reposted ? 'Reposted' : 'Repost removed');
      case _FeedMenuAction.copy:
        await Clipboard.setData(ClipboardData(text: widget.post.status));
        HapticFeedback.selectionClick();
        _toast('Copied');
      case _FeedMenuAction.block:
        HapticFeedback.mediumImpact();
        _toast('Blocked ${widget.post.author}');
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
          child: AuthorProfilePage(name: widget.post.author),
        ),
      ),
    );
  }

  void _openAvatarFullscreen() {
    HapticFeedback.selectionClick();
    final letter = widget.post.author.isEmpty
        ? '?'
        : widget.post.author[0].toUpperCase();
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: .82),
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, animation, __) => _AvatarLightbox(
          letter: letter,
          name: widget.post.author,
          heroTag: 'feed-avatar-${widget.post.author}-${widget.post.time}',
          animation: animation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return FastGlass(
      borderRadius: BorderRadius.circular(26),
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Header: avatar · name/profession · +Follow · dots ----
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FastTap(
                    onTap: _openAvatarFullscreen,
                    borderRadius: BorderRadius.circular(999),
                    child: Hero(
                      tag: 'feed-avatar-${post.author}-${post.time}',
                      child: _Avatar(letter: post.author[0]),
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
                                  post.author,
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
                          '${post.profession} · ${post.time}',
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
                  _FollowButton(
                    following: _following,
                    onTap: () => setState(() => _following = !_following),
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
              const SizedBox(height: 12),
              // ---- Status ----
              _ExpandableStatus(text: post.status),
              if (post.mediaType != FeedMediaType.none) ...[
                const SizedBox(height: 12),
                _MediaSection(
                  type: post.mediaType,
                  label: post.mediaLabel,
                  imageAsset: post.imageAsset,
                  aspectRatio: post.aspectRatio,
                ),
              ],
              const SizedBox(height: 4),
              // ---- Actions: like · comment · repost · share ----
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ActionButton(
                    icon: _liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: '${post.likes + (_liked ? 1 : 0)}',
                    active: _liked,
                    activeColor: _likeRed,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _liked = !_liked);
                    },
                  ),
                  _ActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${post.comments}',
                    onTap: () {
                      HapticFeedback.selectionClick();
                    },
                  ),
                  _ActionButton(
                    icon: Icons.repeat_rounded,
                    label: '${post.reposts + (_reposted ? 1 : 0)}',
                    active: _reposted,
                    activeColor: _repostGreen,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _reposted = !_reposted);
                    },
                  ),
                  _ActionButton(
                    icon: Icons.ios_share_rounded,
                    label: 'Share',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _toast('Share coming soon');
                    },
                  ),
                ],
              ),
            ],
          ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
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
        child: Center(
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
  });

  final String letter;
  final String name;
  final String heroTag;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

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
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .35),
                                  blurRadius: 40,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: Center(
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
                        const SizedBox(height: 6),
                        Text(
                          'Tap to close',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: .55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 16,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: .9),
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

/// Adaptive feed media — portrait, square, and landscape each get a natural
/// frame (clamped like Instagram: 4:5 … 1.91:1) so every size fits cleanly.
class _MediaSection extends StatelessWidget {
  const _MediaSection({
    required this.type,
    required this.label,
    required this.imageAsset,
    this.aspectRatio,
  });

  final FeedMediaType type;
  final String label;
  final String imageAsset;
  final double? aspectRatio;

  double get _frameRatio {
    final raw = aspectRatio ?? 4 / 5;
    return raw.clamp(_mediaMinRatio, _mediaMaxRatio);
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = type == FeedMediaType.video;
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
                    if (imageAsset.isNotEmpty)
                      FastAssetImage(
                        asset: imageAsset,
                        fit: BoxFit.cover,
                        width: width,
                        height: height,
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

enum _FeedMenuAction { repost, copy, block }

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
