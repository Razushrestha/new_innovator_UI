import 'dart:ui';

import 'package:flutter/material.dart';

/// Frosted glass panel: backdrop blur, inner sheen gradient, and a
/// specular rim that is brighter on the top-left (where the "light" hits).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.width = 390,
    this.borderRadius = 34,
    this.padding = const EdgeInsets.fromLTRB(30, 38, 30, 32),
  });

  final Widget child;
  final double width;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return Container(
      // Soft drop shadow lives outside the clip so it isn't cut off.
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF272C3A).withValues(alpha: .12),
            blurRadius: 45,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: CustomPaint(
            foregroundPainter: _SpecularRimPainter(borderRadius),
            child: Container(
              width: width,
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: .60),
                    Colors.white.withValues(alpha: .30),
                  ],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws the rim with a sweep gradient so the edge highlight is strongest
/// at the top-left and bottom-right catches a faint counter-light,
/// mimicking how light wraps around real glass.
class _SpecularRimPainter extends CustomPainter {
  _SpecularRimPainter(this.borderRadius);

  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(.75),
      Radius.circular(borderRadius),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = SweepGradient(
        center: Alignment.topLeft,
        colors: [
          Colors.white.withValues(alpha: .95),
          Colors.white.withValues(alpha: .35),
          Colors.white.withValues(alpha: .65),
          Colors.white.withValues(alpha: .35),
          Colors.white.withValues(alpha: .95),
        ],
        stops: const [0, .3, .5, .75, 1],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_SpecularRimPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius;
}
