import 'dart:math';

import 'package:flutter/material.dart';

/// Paints a body of liquid filled to [fill] (0..1+ of the height) whose
/// surface undulates with a travelling sine wave. Drive [phase] from a
/// repeating animation to keep the surface in motion.
class WaveFillPainter extends CustomPainter {
  WaveFillPainter({
    required this.phase,
    required this.fill,
    required this.color,
    this.amplitude = 4,
    this.frequency = 1.4,
  });

  final double phase;
  final double fill;
  final Color color;
  final double amplitude;
  final double frequency;

  @override
  void paint(Canvas canvas, Size size) {
    if (fill <= 0) return;
    final level = size.height * (1 - fill);
    final path = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width + 3; x += 3) {
      final y =
          level +
          sin(phase + (x / size.width) * frequency * 2 * pi) * amplitude;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(WaveFillPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.fill != fill ||
      oldDelegate.color != color;
}
