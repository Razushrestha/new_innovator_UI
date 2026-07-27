import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/brand_colors.dart';
import 'fast_glass.dart';
import 'liquid_pressable.dart';
import 'wave_fill_painter.dart';

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
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: _samplePosts.length,
      cacheExtent: 280,
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
                  _Avatar(letter: post.author[0]),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Row(
                        children: [
                          Flexible(
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
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _following = !_following);
                    },
                  ),
                  const SizedBox(width: 2),
                  FastTap(
                    onTap: () {},
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
                    onTap: () {},
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
                    onTap: () {},
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

  static final _style = TextStyle(
    fontSize: 13.5,
    height: 1.5,
    color: _ink.withValues(alpha: .82),
  );

  void _measure(double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: _style),
      maxLines: _maxLines,
      textDirection: TextDirection.ltr,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);

    final overflows = painter.didExceedMaxLines;
    if (overflows == _hasOverflow) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _hasOverflow = overflows);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _measure(constraints.maxWidth);

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

/// Pill that floods with liquid when tapped — ink rises into "+ Follow",
/// then washes out to a glass "Following" state (and back).
class _FollowButton extends StatefulWidget {
  const _FollowButton({required this.following, required this.onTap});

  final bool following;
  final VoidCallback onTap;

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton>
    with TickerProviderStateMixin {
  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
    value: widget.following ? 1 : 0,
  );

  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  late final AnimationController _bloom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  Future<void> _runTo(bool following) async {
    if (!_wave.isAnimating) _wave.repeat();
    if (following) {
      _bloom
        ..value = 0
        ..forward();
      await _fill.forward();
    } else {
      await _fill.reverse();
    }
    if (mounted) _wave.stop();
  }

  @override
  void didUpdateWidget(covariant _FollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.following == widget.following) return;
    _runTo(widget.following);
  }

  @override
  void dispose() {
    _fill.dispose();
    _wave.dispose();
    _bloom.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(999),
      rippleColor: widget.following ? _ink : Colors.white,
      intensity: 1.15,
      child: AnimatedBuilder(
        animation: Listenable.merge([_fill, _wave, _bloom]),
        builder: (context, _) {
          final raw = _fill.value;
          final level = Curves.easeOutCubic.transform(raw);
          final followingLook = level > .55;
          final labelColor = Color.lerp(
            Colors.white,
            _ink,
            ((level - .35) / .4).clamp(0, 1),
          )!;
          final bloom = Curves.easeOut.transform(_bloom.value);
          final waveFill = widget.following
              ? (level < 1 ? level * 1.15 : 0.0)
              : (level > 0 ? (1 - level) * 1.15 : 0.0);

          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12 + bloom * 2,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Color.lerp(
                BrandColors.secondarySurface,
                Colors.white.withValues(alpha: .78),
                level,
              ),
              border: Border.all(
                color: Color.lerp(
                  Colors.white.withValues(alpha: .28),
                  _ink.withValues(alpha: .22),
                  level,
                )!,
              ),
              boxShadow: [
                if (bloom > 0 && bloom < 1)
                  BoxShadow(
                    color: BrandColors.accent.withValues(
                      alpha: .35 * (1 - bloom),
                    ),
                    blurRadius: 16 * bloom + 4,
                    spreadRadius: 1,
                  ),
                if (level > .85)
                  BoxShadow(
                    color: _ink.withValues(alpha: .08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (waveFill > 0)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: WaveFillPainter(
                          phase: _wave.value * 2 * math.pi + level * 3,
                          fill: waveFill,
                          color: widget.following
                              ? BrandColors.accent.withValues(alpha: .52)
                              : BrandColors.secondarySurface.withValues(
                                  alpha: .95,
                                ),
                          amplitude: 3.2,
                          frequency: 1.6,
                        ),
                      ),
                    ),
                  if (waveFill > 0.05 && level < 0.98)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: WaveFillPainter(
                          phase: _wave.value * 2 * math.pi + 1.4,
                          fill: (waveFill * .7).clamp(0.0, 1.0),
                          color: Colors.white.withValues(alpha: .2),
                          amplitude: 2.2,
                          frequency: 2.1,
                        ),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          followingLook
                              ? Icons.check_rounded
                              : Icons.add_rounded,
                          key: ValueKey(followingLook),
                          size: 14,
                          color: labelColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: labelColor,
                          letterSpacing: .2,
                        ),
                        child: Text(followingLook ? 'Following' : 'Follow'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Adaptive feed media — portrait, square, and landscape each get a natural
/// frame (clamped like Instagram: 4:5 … 1.91:1) so every size fits cleanly.
class _MediaSection extends StatefulWidget {
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

  @override
  State<_MediaSection> createState() => _MediaSectionState();
}

class _MediaSectionState extends State<_MediaSection> {
  static final _ratioCache = <String, double>{};

  double? _naturalRatio;

  @override
  void initState() {
    super.initState();
    _naturalRatio = widget.aspectRatio;
    if (_naturalRatio == null) _resolveRatio();
  }

  @override
  void didUpdateWidget(covariant _MediaSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageAsset == widget.imageAsset &&
        oldWidget.aspectRatio == widget.aspectRatio) {
      return;
    }
    _naturalRatio = widget.aspectRatio;
    if (_naturalRatio == null) _resolveRatio();
  }

  Future<void> _resolveRatio() async {
    final asset = widget.imageAsset;
    if (asset.isEmpty) {
      if (mounted) setState(() => _naturalRatio = 16 / 9);
      return;
    }
    final cached = _ratioCache[asset];
    if (cached != null) {
      if (mounted) setState(() => _naturalRatio = cached);
      return;
    }
    try {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 64,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final ratio = image.width / math.max(image.height, 1);
      image.dispose();
      codec.dispose();
      _ratioCache[asset] = ratio;
      if (mounted) setState(() => _naturalRatio = ratio);
    } catch (_) {
      if (mounted) setState(() => _naturalRatio = 4 / 5);
    }
  }

  double get _frameRatio {
    final raw = _naturalRatio ?? 4 / 5;
    return raw.clamp(_mediaMinRatio, _mediaMaxRatio);
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.type == FeedMediaType.video;
    final ratio = _frameRatio;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final idealH = width / ratio;
        final screenCap = MediaQuery.sizeOf(context).height * .62;
        final height = math.min(idealH, screenCap);

        return FastTap(
          onTap: () {},
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: .4)),
              color: const Color(0xFF1B1E28),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.imageAsset.isNotEmpty)
                  FastAssetImage(
                    asset: widget.imageAsset,
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
                    widget.label,
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
