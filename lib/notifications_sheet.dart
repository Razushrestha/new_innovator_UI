import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/brand_colors.dart';
import 'widgets/fast_glass.dart';
import 'widgets/liquid_pressable.dart';
import 'widgets/wave_fill_painter.dart';

const _ink = BrandColors.ink;

class _NotificationItem {
  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    this.unread = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final String time;
  final bool unread;
}

const _sampleNotifications = [
  _NotificationItem(
    icon: Icons.favorite_rounded,
    title: 'New like on your innovation',
    body: 'Maya Chen liked Liquid Glass Nav.',
    time: '2m',
    unread: true,
  ),
  _NotificationItem(
    icon: Icons.chat_bubble_rounded,
    title: 'New message',
    body: 'Aarav Sharma: The spring physics feel unreal.',
    time: '18m',
    unread: true,
  ),
  _NotificationItem(
    icon: Icons.school_rounded,
    title: 'Course reminder',
    body: 'Continue Pitch Storytelling — chapter 3 is ready.',
    time: '1h',
  ),
  _NotificationItem(
    icon: Icons.shopping_bag_rounded,
    title: 'Order update',
    body: 'Pitch Deck Kit is ready for download.',
    time: '3h',
  ),
  _NotificationItem(
    icon: Icons.verified_rounded,
    title: 'Profile tip',
    body: 'Add your CV to stand out to collaborators.',
    time: '1d',
  ),
];

/// Liquid glass notifications sheet opened from the drawer.
Future<void> showNotificationsSheet(BuildContext context) {
  HapticFeedback.mediumImpact();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: _ink.withValues(alpha: .28),
    builder: (_) => const _NotificationsSheet(),
  );
}

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * .78;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: FastGlass(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                opacity: .9,
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 42,
                        height: 4.5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _ink.withValues(alpha: .18),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 16, 14, 8),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Notifications',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                  letterSpacing: -.3,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.notifications_active_rounded,
                              size: 22,
                              color: BrandColors.accent.withValues(alpha: .9),
                            ),
                            const SizedBox(width: 8),
                            FastTap(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: .55),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .95),
                                  ),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: _ink.withValues(alpha: .75),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                          itemCount: _sampleNotifications.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _sampleNotifications[index];
                            return _NotificationTile(
                              item: item,
                              wave: _wave,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.wave});

  final _NotificationItem item;
  final AnimationController wave;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);

    return LiquidPressable(
      onTap: () => HapticFeedback.selectionClick(),
      borderRadius: radius,
      rippleColor: _ink,
      intensity: .7,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: Colors.white.withValues(alpha: item.unread ? .42 : .28),
              ),
            ),
            if (item.unread)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: wave,
                  builder: (context, _) => CustomPaint(
                    painter: WaveFillPainter(
                      phase: wave.value * 2 * pi,
                      fill: .22,
                      color: BrandColors.accent.withValues(alpha: .08),
                      amplitude: 2.2,
                      frequency: 1.3,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: BrandColors.accent.withValues(alpha: .16),
                    ),
                    child: Icon(
                      item.icon,
                      size: 18,
                      color: BrandColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                            ),
                            Text(
                              item.time,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _ink.withValues(alpha: .4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: _ink.withValues(alpha: .55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.unread) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: BrandColors.accent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
