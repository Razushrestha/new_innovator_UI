import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/brand_colors.dart';

import 'liquid_pressable.dart';

const _ink = BrandColors.ink;

/// Primary glass button with the liquid press feel (see [LiquidPressable]).
///
/// [dark] switches between the ink-glass primary style and a white-glass
/// secondary style (used for e.g. the Google button). [leading] renders a
/// widget before the label.
class LiquidButton extends StatelessWidget {
  const LiquidButton({
    super.key,
    required this.label,
    required this.onTap,
    this.dark = true,
    this.leading,
  });

  final String label;
  final VoidCallback onTap;
  final bool dark;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final gradientColors = dark
        ? [
            BrandColors.secondarySurface.withValues(alpha: .96),
            BrandColors.secondarySurface.withValues(alpha: .90),
          ]
        : [
            BrandColors.text.withValues(alpha: .95),
            BrandColors.text.withValues(alpha: .55),
          ];
    final borderColor = dark
        ? BrandColors.accent.withValues(alpha: .5)
        : BrandColors.text;
    final textColor = dark ? BrandColors.text : _ink;

    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(23),
      rippleColor: dark ? BrandColors.accent : _ink,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 17.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 10)],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .4,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
