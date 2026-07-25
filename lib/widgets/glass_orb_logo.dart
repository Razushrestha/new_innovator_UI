import 'package:flutter/material.dart';

const _ink = Color(0xFF1B1E28);

/// Small glass sphere logo with a specular highlight, echoing the theme.
class GlassOrbLogo extends StatelessWidget {
  const GlassOrbLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .95),
            Colors.white.withValues(alpha: .45),
          ],
        ),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: .14),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.water_drop_rounded,
        size: 30,
        color: _ink,
      ),
    );
  }
}
