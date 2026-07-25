import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

/// Wraps any widget with the signature liquid press behavior:
///
/// * Press: squashes like a droplet — slightly wider, noticeably shorter.
/// * Release: an underdamped spring simulation makes it overshoot and
///   wobble a few times before settling instead of snapping back.
/// * A soft ripple of light expands from the exact touch point.
///
/// [intensity] scales how strong the squash is (1 = button strength,
/// lower values suit smaller tap targets like list tiles).
class LiquidPressable extends StatefulWidget {
  const LiquidPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = BorderRadius.zero,
    this.rippleColor = Colors.white,
    this.intensity = 1,
  });

  final Widget child;
  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final Color rippleColor;
  final double intensity;

  @override
  State<LiquidPressable> createState() => _LiquidPressableState();
}

class _LiquidPressableState extends State<LiquidPressable>
    with TickerProviderStateMixin {
  /// 0 = at rest, 1 = fully pressed. Goes negative during the spring-back
  /// overshoot, which reads as the droplet stretching upward.
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
  )..value = 0;

  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  Offset _touchPoint = Offset.zero;

  // Underdamped spring: damping low enough to oscillate 2-3 times.
  static final SpringDescription _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 320,
    ratio: 0.32,
  );

  @override
  void dispose() {
    _press.dispose();
    _ripple.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    _touchPoint = details.localPosition;
    _ripple.forward(from: 0);
    _press.animateTo(
      1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
    );
  }

  void _release({bool impulse = false}) {
    // A quick click releases before the squash has built up, which would
    // make the spring-back invisible. Top the value up on real taps so
    // even the fastest click wobbles back like liquid.
    var from = _press.value;
    if (impulse && from < .5) from = .5;
    _press.animateWith(SpringSimulation(_spring, from, 0, -6));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: (_) {
        _release(impulse: true);
        widget.onTap();
      },
      onTapCancel: _release,
      child: AnimatedBuilder(
        animation: _press,
        builder: (context, child) {
          final v = _press.value * widget.intensity;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(1 + .06 * v, 1 - .12 * v, 1),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: AnimatedBuilder(
            animation: _ripple,
            builder: (context, child) => CustomPaint(
              foregroundPainter: _TouchRipplePainter(
                progress: _ripple.value,
                center: _touchPoint,
                color: widget.rippleColor,
              ),
              child: child,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Expanding circle of light emanating from the touch point, fading as
/// it grows — reads as the liquid surface being displaced.
class _TouchRipplePainter extends CustomPainter {
  _TouchRipplePainter({
    required this.progress,
    required this.center,
    required this.color,
  });

  final double progress;
  final Offset center;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1) return;
    final radius = lerpDouble(20, size.width * .9, progress)!;
    final opacity = (1 - progress) * .3;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_TouchRipplePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.center != center ||
      oldDelegate.color != color;
}
