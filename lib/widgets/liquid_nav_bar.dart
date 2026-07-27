import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/brand_colors.dart';

import 'liquid_pressable.dart';
import 'wave_fill_painter.dart';

const _ink = BrandColors.ink;

/// Shared motion for the travelling curve: a slight overshoot before
/// settling, like liquid finding its level.
const Curve _liquidCurve = Curves.easeOutBack;
const Duration _liquidDuration = Duration(milliseconds: 520);

/// Where the nav bar is docked on screen.
enum NavDock { bottom, top, left, right }

class LiquidNavItem {
  const LiquidNavItem({
    required this.icon,
    required this.label,
    this.destructive = false,
    this.pinBottom = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  /// In the vertical rail, pin this item at the bottom (e.g. the menu).
  final bool pinBottom;
}

/// The Innovator logo as a dark glass orb — also used as the drag ghost.
class NavLogoOrb extends StatelessWidget {
  const NavLogoOrb({super.key, this.size = 56, this.onTap});

  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final orb = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BrandColors.secondarySurface, BrandColors.secondarySurface],
        ),
        border: Border.all(
          color: BrandColors.accent.withValues(alpha: .75),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: BrandColors.accent.withValues(alpha: .28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      // Innovator mark fills the dark orb completely.
      child: ClipOval(
        child: Image.asset(
          'Assets/center_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );

    if (onTap == null) return orb;
    return Tooltip(
      message: 'Feed',
      child: LiquidPressable(
        onTap: onTap!,
        borderRadius: BorderRadius.circular(999),
        rippleColor: BrandColors.accent,
        child: orb,
      ),
    );
  }
}

/// Dockable liquid glass navigation bar.
///
/// Horizontal (top/bottom): [leading] icons sit left of the raised logo
/// orb, [trailing] icons to its right. The selected icon rises out of the
/// bar into a floating orb and the bar's curved notch slides under it —
/// the same cutout the logo rests in, travelling with the selection.
/// Vertical (left/right): a slim drawer-like rail with the logo on top
/// and [LiquidNavItem.pinBottom] items pinned at the bottom.
class LiquidNavBar extends StatelessWidget {
  const LiquidNavBar({
    super.key,
    required this.dock,
    required this.leading,
    required this.trailing,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogoTap,
  });

  final NavDock dock;
  final List<LiquidNavItem> leading;
  final List<LiquidNavItem> trailing;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogoTap;

  List<LiquidNavItem> get _all => [...leading, ...trailing];

  bool get _horizontal => dock == NavDock.bottom || dock == NavDock.top;

  @override
  Widget build(BuildContext context) {
    return _horizontal ? _buildHorizontal(context) : _buildVertical(context);
  }

  // ------------------------------------------------- horizontal (curved)

  static const _barHeight = 62.0;
  static const _orbSize = 56.0;
  static const _overhang = 20.0;
  static const _iconOrb = 46.0;

  Widget _buildHorizontal(BuildContext context) {
    final onBottom = dock == NavDock.bottom;
    final items = _all;
    const totalHeight = _barHeight + _overhang;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const centerGap = _orbSize + 12;
        final regionWidth = (width - centerGap) / 2;

        // Horizontal centers of every icon slot.
        final centers = <double>[
          for (var i = 0; i < leading.length; i++)
            regionWidth * (i + .5) / leading.length,
          for (var i = 0; i < trailing.length; i++)
            width - regionWidth + regionWidth * (i + .5) / trailing.length,
        ];

        final hasSelection =
            selectedIndex >= 0 && selectedIndex < centers.length;

        // A single travelling notch: under the selected tab, or under the
        // logo at the center when nothing is selected.
        final targetX = hasSelection ? centers[selectedIndex] : width / 2;
        final targetR = hasSelection ? _iconOrb / 2 + 7 : _orbSize / 2 + 7;
        final notchY = onBottom ? 7.0 : _barHeight - 7.0;

        final iconRestTop = onBottom
            ? _overhang + (_barHeight - _iconOrb) / 2
            : (_barHeight - _iconOrb) / 2;
        final iconRaisedTop = onBottom ? 0.0 : totalHeight - _iconOrb;

        // Logo positions: raised in the notch, or sunk inline in the bar.
        final logoRaisedTop = onBottom ? 0.0 : _barHeight - _overhang - 2;
        final logoSunkTop = onBottom
            ? _overhang + (_barHeight - _orbSize) / 2
            : (_barHeight - _orbSize) / 2;

        return SizedBox(
          height: totalHeight,
          // The moving notch: one tween drives both its position and depth.
          child: TweenAnimationBuilder<Offset>(
            tween: Tween(
              begin: Offset(width / 2, _orbSize / 2 + 7),
              end: Offset(targetX, targetR),
            ),
            duration: _liquidDuration,
            curve: _liquidCurve,
            builder: (context, notch, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: onBottom ? _overhang : 0,
                    height: _barHeight,
                    child: _NotchedGlassBar(
                      notches: [(notch.dx, notchY, notch.dy)],
                    ),
                  ),
                  // Icons: the selected one floats up out of the bar.
                  for (var i = 0; i < items.length; i++)
                    AnimatedPositioned(
                      duration: _liquidDuration,
                      curve: _liquidCurve,
                      left: centers[i] - _iconOrb / 2,
                      top: selectedIndex == i ? iconRaisedTop : iconRestTop,
                      child: _CurveNavIcon(
                        item: items[i],
                        selected: selectedIndex == i,
                        onTap: () => onSelect(i),
                      ),
                    ),
                  // Logo: rides the notch at rest, sinks inline when a tab
                  // takes the curve.
                  AnimatedPositioned(
                    duration: _liquidDuration,
                    curve: _liquidCurve,
                    top: hasSelection ? logoSunkTop : logoRaisedTop,
                    left: width / 2 - _orbSize / 2,
                    child: AnimatedScale(
                      duration: _liquidDuration,
                      curve: _liquidCurve,
                      scale: hasSelection ? .7 : 1,
                      child: NavLogoOrb(size: _orbSize, onTap: onLogoTap),
                    ),
                  ),
                  // Accent dot that follows the notch.
                  AnimatedPositioned(
                    duration: _liquidDuration,
                    curve: _liquidCurve,
                    left: targetX - 2.5,
                    top: onBottom ? totalHeight - 10 : 4,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: BrandColors.accent,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // --------------------------------------------------- vertical (rail)

  Widget _buildVertical(BuildContext context) {
    final all = _all;
    final pinned = all.where((i) => i.pinBottom || i.destructive).toList();
    final regular = all.where((i) => !i.pinBottom && !i.destructive).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: _LiquidGlassFill(
          borderRadius: BorderRadius.circular(28),
          bordered: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NavLogoOrb(size: 48, onTap: onLogoTap),
                const SizedBox(height: 14),
                Container(
                  width: 26,
                  height: 1,
                  color: _ink.withValues(alpha: .10),
                ),
                const SizedBox(height: 8),
                for (final item in regular) ...[
                  _CurveNavIcon(
                    item: item,
                    selected: selectedIndex == all.indexOf(item),
                    onTap: () => onSelect(all.indexOf(item)),
                  ),
                  const SizedBox(height: 4),
                ],
                if (pinned.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 26,
                    height: 1,
                    color: _ink.withValues(alpha: .10),
                  ),
                  const SizedBox(height: 8),
                  for (final item in pinned)
                    _CurveNavIcon(
                      item: item,
                      selected: false,
                      onTap: () => onSelect(all.indexOf(item)),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Near-clear glass with a soft waving liquid pool.
class _LiquidGlassFill extends StatefulWidget {
  const _LiquidGlassFill({
    required this.child,
    this.borderRadius,
    this.bordered = false,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final bool bordered;

  @override
  State<_LiquidGlassFill> createState() => _LiquidGlassFillState();
}

class _LiquidGlassFillState extends State<_LiquidGlassFill>
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
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: .012),
                Colors.white.withValues(alpha: .004),
              ],
            ),
            border: widget.bordered
                ? Border.all(
                    color: Colors.white.withValues(alpha: .10),
                    width: 0.8,
                  )
                : null,
          ),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: WaveFillPainter(
                    phase: phase + 1.2,
                    fill: .36,
                    color: BrandColors.accent.withValues(alpha: .015),
                    amplitude: 3,
                    frequency: 1.35,
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: WaveFillPainter(
                    phase: phase,
                    fill: .22,
                    color: Colors.white.withValues(alpha: .012),
                    amplitude: 2.2,
                    frequency: 1.7,
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: widget.borderRadius,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0, .4, 1],
                        colors: [
                          Colors.white.withValues(alpha: .03),
                          Colors.white.withValues(alpha: .0),
                          Colors.white.withValues(alpha: .008),
                        ],
                      ),
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

/// Frosted bar whose shape has circular notches carved out of its rim.
/// Heavy blur, whisper of white, waving liquid pool, soft specular sheen.
class _NotchedGlassBar extends StatefulWidget {
  const _NotchedGlassBar({required this.notches});

  /// Bar-local (x, y, radius) of each carved notch.
  final List<(double, double, double)> notches;

  @override
  State<_NotchedGlassBar> createState() => _NotchedGlassBarState();
}

class _NotchedGlassBarState extends State<_NotchedGlassBar>
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

  Path _buildPath(Size size) {
    var path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(26)),
      );
    for (final (x, y, r) in widget.notches) {
      final circle = Path()
        ..addOval(Rect.fromCircle(center: Offset(x, y), radius: r));
      path = Path.combine(PathOperation.difference, path, circle);
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PathShadowPainter(_buildPath),
      child: ClipPath(
        clipper: _PathClipper(_buildPath),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: CustomPaint(
            foregroundPainter: _PathBorderPainter(_buildPath),
            child: AnimatedBuilder(
              animation: _wave,
              builder: (context, _) {
                final phase = _wave.value * 2 * pi;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: .012),
                            Colors.white.withValues(alpha: .004),
                          ],
                        ),
                      ),
                    ),
                    CustomPaint(
                      painter: WaveFillPainter(
                        phase: phase + 1.1,
                        fill: .48,
                        color: BrandColors.accent.withValues(alpha: .015),
                        amplitude: 2.8,
                        frequency: 1.4,
                      ),
                    ),
                    CustomPaint(
                      painter: WaveFillPainter(
                        phase: phase,
                        fill: .30,
                        color: Colors.white.withValues(alpha: .012),
                        amplitude: 2.0,
                        frequency: 1.8,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0, .45, 1],
                          colors: [
                            Colors.white.withValues(alpha: .03),
                            Colors.white.withValues(alpha: .0),
                            Colors.white.withValues(alpha: .008),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PathShadowPainter extends CustomPainter {
  const _PathShadowPainter(this.builder);

  final Path Function(Size) builder;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawShadow(
      builder(size).shift(const Offset(0, 2)),
      _ink.withValues(alpha: .025),
      8,
      true,
    );
  }

  @override
  bool shouldRepaint(covariant _PathShadowPainter oldDelegate) => true;
}

class _PathClipper extends CustomClipper<Path> {
  const _PathClipper(this.builder);

  final Path Function(Size) builder;

  @override
  Path getClip(Size size) => builder(size);

  @override
  bool shouldReclip(covariant _PathClipper oldClipper) => true;
}

class _PathBorderPainter extends CustomPainter {
  const _PathBorderPainter(this.builder);

  final Path Function(Size) builder;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      builder(size),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withValues(alpha: .10),
    );
  }

  @override
  bool shouldRepaint(covariant _PathBorderPainter oldDelegate) => true;
}

/// Nav icon that morphs into a floating ink orb when selected.
class _CurveNavIcon extends StatelessWidget {
  const _CurveNavIcon({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final LiquidNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = item.destructive
        ? const Color(0xFFC0392B)
        : selected
        ? Colors.white
        : _ink.withValues(alpha: .45);

    return Tooltip(
      message: item.label,
      child: LiquidPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        rippleColor: selected ? Colors.white : _ink,
        intensity: .6,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      BrandColors.secondarySurface,
                      BrandColors.secondarySurface,
                    ],
                  )
                : null,
            border: Border.all(
              color: selected
                  ? BrandColors.accent.withValues(alpha: .7)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _ink.withValues(alpha: .3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [],
          ),
          child: Icon(item.icon, size: 20, color: color),
        ),
      ),
    );
  }
}
