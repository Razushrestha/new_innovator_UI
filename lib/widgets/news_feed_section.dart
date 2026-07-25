import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'liquid_pressable.dart';

const _ink = Color(0xFF1B1E28);
const _likeRed = Color(0xFFE0245E);
const _repostGreen = Color(0xFF17A275);

enum FeedMediaType { none, image, video }

class FeedPost {
  const FeedPost({
    required this.author,
    required this.profession,
    required this.time,
    required this.status,
    this.mediaType = FeedMediaType.none,
    this.mediaLabel = '',
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
        'on the buttons make such a difference — every tap feels alive.',
    mediaType: FeedMediaType.video,
    mediaLabel: 'Design walkthrough · 2:14',
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
    likes: 214,
    comments: 41,
    reposts: 39,
  ),
];

/// News feed in the liquid glass language: frosted post cards with an
/// author header (+Follow), status text, a media area, and springy
/// like / comment / repost / share actions.
class NewsFeedSection extends StatelessWidget {
  const NewsFeedSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final post in _samplePosts) ...[
          _FeedCard(post: post),
          const SizedBox(height: 14),
        ],
      ],
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: .62),
                Colors.white.withValues(alpha: .32),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: .9),
              width: 1.2,
            ),
          ),
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
                        Text(
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
                  LiquidPressable(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(999),
                    rippleColor: _ink,
                    intensity: .5,
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
              Text(
                post.status,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: _ink.withValues(alpha: .82),
                ),
              ),
              if (post.mediaType != FeedMediaType.none) ...[
                const SizedBox(height: 12),
                _MediaSection(
                  type: post.mediaType,
                  label: post.mediaLabel,
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
        ),
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
          colors: [Color(0xFF2A2F3E), Color(0xFF8A93A8)],
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

/// Pill that morphs between "+ Follow" (ink fill) and "Following" (glass).
class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.following, required this.onTap});

  final bool following;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      rippleColor: following ? _ink : Colors.white,
      intensity: .6,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: following
              ? LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: .8),
                    Colors.white.withValues(alpha: .5),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2A2F3E), Color(0xFF15181F)],
                ),
          border: Border.all(
            color: following
                ? _ink.withValues(alpha: .25)
                : Colors.white.withValues(alpha: .25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                following ? Icons.check_rounded : Icons.add_rounded,
                key: ValueKey(following),
                size: 14,
                color: following ? _ink : Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              following ? 'Following' : 'Follow',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: following ? _ink : Colors.white,
                letterSpacing: .2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Media area below the status: a deep glass surface with a frosted
/// play/photo bubble. Swap the decoration for an Image when real
/// content arrives.
class _MediaSection extends StatelessWidget {
  const _MediaSection({required this.type, required this.label});

  final FeedMediaType type;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isVideo = type == FeedMediaType.video;

    return LiquidPressable(
      onTap: () {},
      borderRadius: BorderRadius.circular(18),
      rippleColor: Colors.white,
      intensity: .45,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A4152), Color(0xFF1B1E28)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: .4)),
        ),
        child: Stack(
          children: [
            // Specular sheen across the top of the media surface.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 64,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: .14),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: .45)),
                ),
                child: Icon(
                  isVideo
                      ? Icons.play_arrow_rounded
                      : Icons.photo_outlined,
                  size: 26,
                  color: Colors.white,
                ),
              ),
            ),
            // Type badge, top-left.
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.black.withValues(alpha: .35),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: .3)),
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
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: .85),
                ),
              ),
            ),
          ],
        ),
      ),
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

    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      rippleColor: color,
      intensity: .55,
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
