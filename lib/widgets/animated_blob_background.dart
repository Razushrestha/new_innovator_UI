import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Clean, colorless backdrop: soft off-white base with a few barely-there
/// gray orbs drifting very slowly. The motion is subtle on purpose — just
/// enough for the glass surfaces above to have something to blur so they
/// still read as glass instead of flat panels.
class AnimatedBlobBackground extends StatefulWidget {
  const AnimatedBlobBackground({super.key});

  @override
  State<AnimatedBlobBackground> createState() => _AnimatedBlobBackgroundState();
}

class _AnimatedBlobBackgroundState extends State<AnimatedBlobBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 26),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _BlobPainter(_controller.value),
        child: const SizedBox.expand(),
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

  // Neutral grays only — depth without color.
  static const _blobs = [
    _Blob(Color(0xFFDDE0E6), .22, .25, 230, 0.0, 60),
    _Blob(Color(0xFFE8EAEF), .80, .20, 190, 2.1, 50),
    _Blob(Color(0xFFD6D9E0), .68, .80, 240, 4.0, 70),
    _Blob(Color(0xFFE4E6EC), .15, .82, 180, 1.2, 55),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Base: clean off-white with a faint bright lift in the center.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF4F5F8),
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Colors.white.withValues(alpha: .8),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );

    final angle = t * 2 * math.pi;
    for (final blob in _blobs) {
      final dx = size.width * blob.x + math.cos(angle + blob.phase) * blob.drift;
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
