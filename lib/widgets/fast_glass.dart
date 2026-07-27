import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lightweight “glass” fill — no live [BackdropFilter], no soft shadows.
/// Shadows and blur are the usual scroll killers on mid-range phones.
class FastGlass extends StatelessWidget {
  const FastGlass({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding,
    this.borderWidth = 1.0,
    this.opacity = .62,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final double borderWidth;

  /// Surface fill opacity — raise for sheets that must stay readable.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: Colors.white.withValues(alpha: opacity),
        border: Border.all(
          color: Colors.white.withValues(alpha: .85),
          width: borderWidth,
        ),
      ),
      child: padding == null
          ? child
          : Padding(padding: padding!, child: child),
    );
  }
}

/// Cheap tap target — no spring physics, no ripple painters.
class FastTap extends StatelessWidget {
  const FastTap({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius,
  });

  final VoidCallback onTap;
  final Widget child;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final content = borderRadius == null
        ? child
        : ClipRRect(borderRadius: borderRadius!, child: child);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}

/// Decodes [Image.asset] at a capped DPR so scroll stays light.
class FastAssetImage extends StatelessWidget {
  const FastAssetImage({
    super.key,
    required this.asset,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.errorColor,
  });

  final String asset;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? errorColor;

  @override
  Widget build(BuildContext context) {
    // Cap decode resolution — 1.5× is sharp enough and much cheaper.
    final dpr = math.min(MediaQuery.devicePixelRatioOf(context), 1.5);
    final cacheW = width != null ? (width! * dpr).round() : null;
    final cacheH = height != null ? (height! * dpr).round() : null;

    Widget image = Image.asset(
      asset,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: cacheW,
      cacheHeight: cacheH,
      filterQuality: FilterQuality.none,
      gaplessPlayback: true,
      isAntiAlias: false,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: errorColor ?? const Color(0xFF1B1E28),
      ),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

/// Pauses continuous [AnimationController]s while the user scrolls.
bool handleScrollAnimationPause(
  ScrollNotification notification,
  List<AnimationController> controllers,
) {
  // Only react to the outer vertical scroll, not nested rails.
  if (notification.depth != 0) return false;
  if (notification is ScrollStartNotification ||
      notification is ScrollUpdateNotification) {
    for (final c in controllers) {
      if (c.isAnimating) c.stop();
    }
  } else if (notification is ScrollEndNotification) {
    for (final c in controllers) {
      if (!c.isAnimating) c.repeat();
    }
  }
  return false;
}
