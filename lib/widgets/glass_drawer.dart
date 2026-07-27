import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/brand_colors.dart';
import 'liquid_pressable.dart';
import 'wave_fill_painter.dart';

const _ink = BrandColors.ink;

class GlassDrawerItem {
  const GlassDrawerItem({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
}

/// Navigation drawer in the liquid glass language: a frosted panel with a
/// profile header on top, menu items in the middle, and logout pinned to
/// the bottom. Every tile presses like liquid.
class GlassDrawer extends StatelessWidget {
  const GlassDrawer({
    super.key,
    required this.name,
    required this.title,
    required this.onLogout,
    this.onShop,
    this.onELearning,
    this.onProfile,
  });

  final String name;
  final String title;
  final VoidCallback onLogout;
  final VoidCallback? onShop;
  final VoidCallback? onELearning;
  final VoidCallback? onProfile;

  /// Let the liquid wobble play before the drawer slides away.
  void _closeThen(BuildContext context, VoidCallback? action) {
    Future.delayed(const Duration(milliseconds: 260), () {
      if (context.mounted) {
        Navigator.of(context).pop();
        action?.call();
      }
    });
  }

  List<GlassDrawerItem> get _items => [
    GlassDrawerItem(
      icon: Icons.person_outline_rounded,
      label: 'Profile',
      onTap: onProfile,
    ),
    GlassDrawerItem(
      icon: Icons.storefront_outlined,
      label: 'Shop',
      onTap: onShop,
    ),
    GlassDrawerItem(
      icon: Icons.school_outlined,
      label: 'E-learning',
      onTap: onELearning,
    ),
    const GlassDrawerItem(
      icon: Icons.shield_outlined,
      label: 'Privacy & Policy',
    ),
    const GlassDrawerItem(icon: Icons.settings_outlined, label: 'Settings'),
    const GlassDrawerItem(icon: Icons.help_outline_rounded, label: 'FAQ'),
  ];

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(32);

    // The panel floats clear of every screen edge so all four rounded
    // corners actually show — a curved sheet of glass, not a slab.
    return Drawer(
      width: 316,
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 12, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: .06),
                blurRadius: 42,
                offset: const Offset(4, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: _LiquidDrawerSurface(
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileHeader(
                        name: name,
                        title: title,
                        onTap: onProfile == null
                            ? null
                            : () => _closeThen(context, onProfile),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Container(
                          height: 1,
                          color: _ink.withValues(alpha: .06),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                          children: [
                            for (final item in _items)
                              _DrawerTile(
                                icon: item.icon,
                                label: item.label,
                                onTap: () => _closeThen(context, item.onTap),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Container(
                          height: 1,
                          color: _ink.withValues(alpha: .06),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                        child: _DrawerTile(
                          icon: Icons.logout_rounded,
                          label: 'Logout',
                          destructive: true,
                          onTap: () => _closeThen(context, onLogout),
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

/// Near-clear glass fill with a soft liquid pool waving at the bottom.
class _LiquidDrawerSurface extends StatefulWidget {
  const _LiquidDrawerSurface({required this.child});

  final Widget child;

  @override
  State<_LiquidDrawerSurface> createState() => _LiquidDrawerSurfaceState();
}

class _LiquidDrawerSurfaceState extends State<_LiquidDrawerSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _wave,
      builder: (context, child) {
        final phase = _wave.value * 2 * pi;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: .035),
                Colors.white.withValues(alpha: .01),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: .14),
              width: 1.0,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: WaveFillPainter(
                  phase: phase + 1.4,
                  fill: .26,
                  color: BrandColors.accent.withValues(alpha: .03),
                  amplitude: 7,
                  frequency: 1.25,
                ),
              ),
              CustomPaint(
                painter: WaveFillPainter(
                  phase: phase,
                  fill: .16,
                  color: Colors.white.withValues(alpha: .025),
                  amplitude: 4.5,
                  frequency: 1.6,
                ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, .35, 1],
                      colors: [
                        Colors.white.withValues(alpha: .06),
                        Colors.white.withValues(alpha: .0),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, required this.title, this.onTap});

  final String name;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
      child: Row(
        children: [
          // Gradient ring around the avatar for a premium touch. Swap the
          // inner container for a real photo when one is available.
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [BrandColors.secondarySurface, Color(0xFF8A93A8)],
              ),
            ),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: .98),
                    Colors.white.withValues(alpha: .6),
                  ],
                ),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                    letterSpacing: -.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _ink.withValues(alpha: .5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return LiquidPressable(
      onTap: onTap!,
      borderRadius: BorderRadius.circular(22),
      rippleColor: _ink,
      intensity: .55,
      child: content,
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
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
    final color = destructive ? const Color(0xFFC0392B) : _ink;

    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      rippleColor: color,
      intensity: .55,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .14),
                border: Border.all(color: Colors.white.withValues(alpha: .22)),
              ),
              child: Icon(icon, size: 18, color: color.withValues(alpha: .75)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: destructive ? .85 : .8),
                ),
              ),
            ),
            if (!destructive)
              Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: _ink.withValues(alpha: .3),
              ),
          ],
        ),
      ),
    );
  }
}
