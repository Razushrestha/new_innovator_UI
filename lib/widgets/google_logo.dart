import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The Google "G" drawn with vector arcs — no image asset needed.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * .22;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    double deg(double d) => d * math.pi / 180;

    // Angles are clockwise from the +x axis (screen coordinates).
    // The G opens at the upper right, between red's end and the bar.
    canvas.drawArc(rect, deg(0), deg(45), false, paint..color = _blue);
    canvas.drawArc(rect, deg(45), deg(90), false, paint..color = _green);
    canvas.drawArc(rect, deg(135), deg(80), false, paint..color = _yellow);
    canvas.drawArc(rect, deg(215), deg(100), false, paint..color = _red);

    // Horizontal bar of the G.
    final center = size.center(Offset.zero);
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx,
        center.dy - strokeWidth / 2,
        size.width / 2,
        strokeWidth,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter oldDelegate) => false;
}
