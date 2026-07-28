import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/brand_colors.dart';

/// Clean, colorless backdrop: soft off-white base with a few barely-there
/// gray orbs drifting very slowly. The motion is subtle on purpose — just
/// enough for the glass surfaces above to have something to blur so they
/// still read as glass instead of flat panels.
class AnimatedBlobBackground extends StatefulWidget {
  const AnimatedBlobBackground({super.key, this.animate = true});

  /// When false, the painter freezes on the current frame (cheap while scrolling).
  final bool animate;

  @override
  State<AnimatedBlobBackground> createState() => _AnimatedBlobBackgroundState();
}

class _AnimatedBlobBackgroundState extends State<AnimatedBlobBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 36),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedBlobBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate == oldWidget.animate) return;
    if (widget.animate) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _BlobPainter(_controller.value),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _Blob {
  const _Blob(this.color, this.x, this.y, this.radius, this.phase, this.drift);

  final Color color;
  final double x; // fraction of width
  final double y; // fraction of height
  final double radius;
  final double phase;
  final double drift; // orbit size in px
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.t);

  final double t;

  // Soft brand-tinted orbs — depth with a hint of gold / navy mist.
  static const _blobs = [
    _Blob(Color(0xFFE8E4D8), .22, .25, 230, 0.0, 60),
    _Blob(Color(0xFFD9DEE6), .80, .20, 190, 2.1, 50),
    _Blob(Color(0xFFE6E0D0), .68, .80, 240, 4.0, 70),
    _Blob(Color(0xFFD4DAE3), .15, .82, 180, 1.2, 55),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Base: clean canvas with a faint bright lift in the center.
    canvas.drawRect(Offset.zero & size, Paint()..color = BrandColors.canvas);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [Colors.white.withValues(alpha: .8), Colors.transparent],
        ).createShader(Offset.zero & size),
    );

    final angle = t * 2 * math.pi;
    for (final blob in _blobs) {
      final dx =
          size.width * blob.x + math.cos(angle + blob.phase) * blob.drift;
      final dy =
          size.height * blob.y + math.sin(angle * .8 + blob.phase) * blob.drift;
      canvas.drawCircle(
        Offset(dx, dy),
        blob.radius,
        Paint()
          ..color = blob.color.withValues(alpha: .8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80),
      );
    }
  }

  @override
  bool shouldRepaint(_BlobPainter oldDelegate) => oldDelegate.t != t;
}
