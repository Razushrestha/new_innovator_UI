import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/brand_colors.dart';
import 'widgets/fast_glass.dart';

const _ink = BrandColors.ink;

/// Where a notification should land when opened.
enum NotificationDestination { feed, chat, elearning, shop, profile }

enum _NotifFilter { all, unread, activity, learning }

enum _NotifKind { like, message, course, order, tip, follow, collaboration }

class _AppNotification {
  _AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.time,
    required this.unread,
  });

  final String id;
  final _NotifKind kind;
  final String title;
  final String body;
  final String time;
  bool unread;

  NotificationDestination get destination => switch (kind) {
        _NotifKind.like => NotificationDestination.feed,
        _NotifKind.message => NotificationDestination.chat,
        _NotifKind.course => NotificationDestination.elearning,
        _NotifKind.order => NotificationDestination.shop,
        _NotifKind.tip => NotificationDestination.profile,
        _NotifKind.follow => NotificationDestination.profile,
        _NotifKind.collaboration => NotificationDestination.profile,
      };

  /// Professional outlined icons matched to each notification area.
  IconData get icon => switch (kind) {
        _NotifKind.like => Icons.favorite_border_rounded,
        _NotifKind.message => Icons.chat_bubble_outline_rounded,
        _NotifKind.course => Icons.school_outlined,
        _NotifKind.order => Icons.storefront_outlined,
        _NotifKind.tip => Icons.person_outline_rounded,
        _NotifKind.follow => Icons.person_add_alt_1_outlined,
        _NotifKind.collaboration => Icons.groups_outlined,
      };
}

/// Full-page liquid notifications experience inside the dashboard shell.
class NotificationsSection extends StatefulWidget {
  const NotificationsSection({
    super.key,
    this.contentPadding = EdgeInsets.zero,
    this.onOpen,
  });

  final EdgeInsets contentPadding;

  /// Opens the related product area (feed, chat, shop, etc.).
  final ValueChanged<NotificationDestination>? onOpen;

  @override
  State<NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<NotificationsSection> {
  _NotifFilter _filter = _NotifFilter.all;

  late final List<_AppNotification> _items = [
    _AppNotification(
      id: 'n1',
      kind: _NotifKind.like,
      title: 'New like on your innovation',
      body: 'Maya Chen liked Liquid Glass Nav.',
      time: '2m',
      unread: true,
    ),
    _AppNotification(
      id: 'n2',
      kind: _NotifKind.message,
      title: 'New message',
      body: 'Aarav Sharma: The spring physics feel unreal.',
      time: '18m',
      unread: true,
    ),
    _AppNotification(
      id: 'n3',
      kind: _NotifKind.collaboration,
      title: 'New collaboration',
      body: 'Priya Thapa started collaborating with you.',
      time: '42m',
      unread: true,
    ),
    _AppNotification(
      id: 'n3b',
      kind: _NotifKind.follow,
      title: 'New collaborator',
      body: 'Rohan Karki is now following your innovations.',
      time: '55m',
      unread: true,
    ),
    _AppNotification(
      id: 'n4',
      kind: _NotifKind.course,
      title: 'Course reminder',
      body: 'Continue Pitch Storytelling — chapter 3 is ready.',
      time: '1h',
      unread: false,
    ),
    _AppNotification(
      id: 'n5',
      kind: _NotifKind.order,
      title: 'Order update',
      body: 'Pitch Deck Kit is ready for download.',
      time: '3h',
      unread: false,
    ),
    _AppNotification(
      id: 'n6',
      kind: _NotifKind.like,
      title: 'Innovation trending',
      body: 'Your Spring Physics post reached 120 likes today.',
      time: '5h',
      unread: false,
    ),
    _AppNotification(
      id: 'n7',
      kind: _NotifKind.tip,
      title: 'Profile tip',
      body: 'Add your CV to stand out to collaborators.',
      time: '1d',
      unread: false,
    ),
    _AppNotification(
      id: 'n8',
      kind: _NotifKind.course,
      title: 'Certificate unlocked',
      body: 'You finished Intro to Liquid Product Design.',
      time: '2d',
      unread: false,
    ),
  ];

  int get _unreadCount => _items.where((n) => n.unread).length;

  List<_AppNotification> get _visible {
    switch (_filter) {
      case _NotifFilter.all:
        return _items;
      case _NotifFilter.unread:
        return _items.where((n) => n.unread).toList();
      case _NotifFilter.activity:
        return _items
            .where(
              (n) =>
                  n.kind == _NotifKind.like ||
                  n.kind == _NotifKind.message ||
                  n.kind == _NotifKind.follow ||
                  n.kind == _NotifKind.collaboration,
            )
            .toList();
      case _NotifFilter.learning:
        return _items
            .where(
              (n) =>
                  n.kind == _NotifKind.course ||
                  n.kind == _NotifKind.tip ||
                  n.kind == _NotifKind.order,
            )
            .toList();
    }
  }

  void _markAllRead() {
    HapticFeedback.mediumImpact();
    setState(() {
      for (final n in _items) {
        n.unread = false;
      }
    });
  }

  void _open(_AppNotification item) {
    HapticFeedback.selectionClick();
    if (item.unread) {
      setState(() => item.unread = false);
    }
    widget.onOpen?.call(item.destination);
  }

  void _dismiss(_AppNotification item) {
    HapticFeedback.lightImpact();
    setState(() => _items.removeWhere((n) => n.id == item.id));
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.contentPadding;
    final visible = _visible;
    final empty = visible.isEmpty;
    // Filter + (empty state | rows) + optional footer tip.
    final itemCount = 1 + (empty ? 1 : visible.length + 1);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        20,
        padding.top + 6,
        20,
        padding.bottom + 8,
      ),
      cacheExtent: 480,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      addSemanticIndexes: false,
      physics: const ClampingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _FilterBar(
              selected: _filter,
              onChanged: (f) {
                HapticFeedback.selectionClick();
                setState(() => _filter = f);
              },
              onMarkAllRead: _unreadCount == 0 ? null : _markAllRead,
            ),
          );
        }

        if (empty) {
          return const _EmptyState();
        }

        final rowIndex = index - 1;
        if (rowIndex == visible.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Text(
                'Swipe left to clear · Tap to open',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _ink.withValues(alpha: .4),
                ),
              ),
            ),
          );
        }

        final item = visible[rowIndex];
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _dismiss(item),
          background: const _DismissBackground(),
          child: Column(
            children: [
              _NotificationCard(
                item: item,
                onTap: () => _open(item),
              ),
              if (rowIndex != visible.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: _ink.withValues(alpha: .06),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.onChanged,
    this.onMarkAllRead,
  });

  final _NotifFilter selected;
  final ValueChanged<_NotifFilter> onChanged;
  final VoidCallback? onMarkAllRead;

  static const _options = [
    (_NotifFilter.all, 'All'),
    (_NotifFilter.unread, 'Unread'),
    (_NotifFilter.activity, 'Activity'),
    (_NotifFilter.learning, 'Learning'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final option in _options) ...[
                  _FilterChip(
                    label: option.$2,
                    selected: selected == option.$1,
                    onTap: () => onChanged(option.$1),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
        if (onMarkAllRead != null) ...[
          const SizedBox(width: 4),
          FastTap(
            onTap: onMarkAllRead!,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha: .45),
                border: Border.all(color: Colors.white.withValues(alpha: .9)),
              ),
              child: Text(
                'Mark as read',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _ink.withValues(alpha: .75),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    return FastTap(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: radius,
          color: selected
              ? BrandColors.secondarySurface.withValues(alpha: .92)
              : Colors.white.withValues(alpha: .4),
          border: Border.all(
            color: selected
                ? BrandColors.accent.withValues(alpha: .4)
                : Colors.white.withValues(alpha: .85),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : _ink.withValues(alpha: .7),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
  });

  final _AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FastTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconOrb(icon: item.icon),
            const SizedBox(width: 14),
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
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: item.unread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: _ink,
                            letterSpacing: -.15,
                          ),
                        ),
                      ),
                      Text(
                        item.time,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: _ink.withValues(alpha: .38),
                        ),
                      ),
                      if (item.unread) ...[
                        const SizedBox(width: 7),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: BrandColors.accent,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: _ink.withValues(
                        alpha: item.unread ? .62 : .5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: _ink.withValues(alpha: .28),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconOrb extends StatelessWidget {
  const _IconOrb({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _ink.withValues(alpha: .06),
        border: Border.all(color: _ink.withValues(alpha: .08)),
      ),
      child: Icon(
        icon,
        size: 20,
        color: _ink.withValues(alpha: .72),
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 18),
      child: Icon(
        Icons.delete_outline_rounded,
        color: const Color(0xFFC0392B).withValues(alpha: .75),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return FastGlass(
      borderRadius: BorderRadius.circular(24),
      opacity: .4,
      padding: const EdgeInsets.fromLTRB(22, 36, 22, 36),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BrandColors.accent.withValues(alpha: .14),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 28,
              color: BrandColors.accent,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No notifications here',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try another filter or check back soon.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _ink.withValues(alpha: .48),
            ),
          ),
        ],
      ),
    );
  }
}
