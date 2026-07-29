import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/media_cache.dart';

/// Fast feed image — disk cache, resized decode, no fade delay.
class CachedFeedImage extends StatelessWidget {
  const CachedFeedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.memCacheWidth,
    this.memCacheHeight,
    this.borderRadius,
    this.placeholderColor = const Color(0xFF1B1E28),
    this.errorWidget,
    this.fadeDuration = Duration.zero,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final BorderRadius? borderRadius;
  final Color placeholderColor;
  final Widget? errorWidget;
  final Duration fadeDuration;

  @override
  Widget build(BuildContext context) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return ColoredBox(color: placeholderColor);
    }

    final screenW = MediaQuery.sizeOf(context).width;
    final resolvedMemW = (memCacheWidth ??
            (width != null
                ? InnovatorMediaCache.memCachePx(context, width!)
                : InnovatorMediaCache.memCachePx(context, screenW)))
        .clamp(48, 900);

    // Keep a smaller copy on disk so repeat loads are tiny/fast.
    final diskW = resolvedMemW.clamp(64, 900);
    final diskH = (memCacheHeight ?? (diskW * 1.35).round()).clamp(64, 1200);

    final image = CachedNetworkImage(
      imageUrl: trimmed,
      cacheManager: InnovatorMediaCache.instance,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: resolvedMemW,
      memCacheHeight: memCacheHeight,
      maxWidthDiskCache: diskW,
      maxHeightDiskCache: diskH,
      fadeInDuration: fadeDuration,
      fadeOutDuration: Duration.zero,
      filterQuality: FilterQuality.low,
      placeholder: (_, __) => ColoredBox(color: placeholderColor),
      errorWidget: (_, __, ___) =>
          errorWidget ??
          ColoredBox(
            color: placeholderColor,
            child: const Center(
              child: Icon(Icons.broken_image_outlined, color: Colors.white24),
            ),
          ),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}
