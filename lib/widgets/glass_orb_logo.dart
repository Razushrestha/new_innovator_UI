import 'package:flutter/material.dart';

import '../theme/brand_colors.dart';

/// Small glass sphere with the Innovator mark — used on auth screens.
class GlassOrbLogo extends StatelessWidget {
  const GlassOrbLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: BrandColors.secondarySurface,
        border: Border.all(
          color: BrandColors.accent.withValues(alpha: .8),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: BrandColors.accent.withValues(alpha: .22),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset('Assets/center_logo.png', fit: BoxFit.cover),
      ),
    );
  }
}
