import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../services/media_cache.dart';
import 'cached_feed_image.dart';

/// Fast feed / lightbox video — streams immediately, poster while buffering.
class FeedVideoPlayer extends StatefulWidget {
  const FeedVideoPlayer({
    super.key,
    required this.url,
    this.posterUrl,
    this.fit = BoxFit.cover,
    this.autoplay = false,
    this.looping = true,
    this.muted = true,
    this.showControls = true,
    this.onTap,
    this.requireVisible = true,
    this.visibleFraction = 0.35,
  });

  final String url;
  final String? posterUrl;
  final BoxFit fit;
  final bool autoplay;
  final bool looping;
  final bool muted;
  final bool showControls;
  final VoidCallback? onTap;

  /// Only initialize when enough of the widget is on screen.
  final bool requireVisible;
  final double visibleFraction;

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  VideoPlayerController? _controller;
  var _ready = false;
  var _failed = false;
  var _visible = false;
  var _booting = false;
  String? _error;
  String? _activeUrl;

  @override
  void initState() {
    super.initState();
    if (!widget.requireVisible) {
      _visible = true;
      _boot();
    }
  }

  @override
  void didUpdateWidget(covariant FeedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeController();
      if (_visible || !widget.requireVisible) {
        _boot();
      }
      return;
    }
    final c = _controller;
    if (c == null || !_ready) return;
    if (oldWidget.muted != widget.muted) {
      c.setVolume(widget.muted ? 0 : 1);
    }
    if (oldWidget.looping != widget.looping) {
      c.setLooping(widget.looping);
    }
    if (oldWidget.autoplay != widget.autoplay) {
      if (widget.autoplay && _visible) {
        c.play();
      } else if (!widget.autoplay) {
        c.pause();
      }
    }
  }

  void _onVisibility(VisibilityInfo info) {
    final nowVisible = info.visibleFraction >= widget.visibleFraction;
    if (nowVisible == _visible) return;
    _visible = nowVisible;
    if (_visible) {
      if (_controller == null && !_booting) {
        _boot();
      } else if (_ready && widget.autoplay) {
        _controller?.play();
      }
    } else {
      _controller?.pause();
    }
  }

  Future<void> _boot() async {
    final raw = widget.url.trim();
    if (raw.isEmpty) {
      setState(() {
        _failed = true;
        _error = 'Missing video URL';
      });
      return;
    }

    if (_booting && _activeUrl == raw) return;
    _booting = true;
    _activeUrl = raw;
    _failed = false;
    _error = null;
    _ready = false;

    try {
      // Prefer local file only if already cached — never wait on a download.
      File? local;
      try {
        local = await InnovatorMediaCache.cachedFile(raw)
            .timeout(const Duration(milliseconds: 30));
      } catch (_) {
        local = null;
      }

      late final VideoPlayerController controller;
      if (local != null && await local.exists()) {
        controller = VideoPlayerController.file(
          local,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      } else {
        final uri = Uri.tryParse(raw);
        if (uri == null || !uri.hasScheme) {
          if (!mounted) return;
          setState(() {
            _failed = true;
            _error = 'Invalid video URL';
            _booting = false;
          });
          return;
        }
        // Stream — do not download the whole file into cache first.
        controller = VideoPlayerController.networkUrl(
          uri,
          httpHeaders: const {'Connection': 'keep-alive'},
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      }

      _controller?.removeListener(_onTick);
      await _controller?.dispose();
      _controller = controller;
      controller.addListener(_onTick);

      await controller.initialize();
      await controller.setLooping(widget.looping);
      await controller.setVolume(widget.muted ? 0 : 1);
      if (!mounted || _activeUrl != raw) {
        await controller.dispose();
        return;
      }
      setState(() {
        _ready = true;
        _booting = false;
      });
      if (widget.autoplay && (_visible || !widget.requireVisible)) {
        await controller.play();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _error = 'Could not load video';
        _booting = false;
      });
    }
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _disposeController() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    _controller = null;
    _ready = false;
    _failed = false;
    _error = null;
    _booting = false;
    _activeUrl = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final c = _controller;
    if (c == null || !_ready) return;
    HapticFeedback.selectionClick();
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (!widget.requireVisible) return body;
    return VisibilityDetector(
      key: Key('feed-video-${widget.url}'),
      onVisibilityChanged: _onVisibility,
      child: body,
    );
  }

  Widget _poster() {
    final poster = widget.posterUrl?.trim() ?? '';
    if (poster.isEmpty) {
      return const ColoredBox(color: Color(0xFF1B1E28));
    }
    return CachedFeedImage(
      url: poster,
      fit: widget.fit,
      memCacheWidth: 720,
    );
  }

  Widget _buildBody() {
    if (_failed) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _poster(),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off_outlined,
                    color: Colors.white38, size: 36),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .55),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    if (!_ready || _controller == null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _poster(),
          const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white54,
              ),
            ),
          ),
          if (widget.showControls)
            Center(
              child: IgnorePointer(
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: .35),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .45),
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 30,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    final c = _controller!;
    final playing = c.value.isPlaying;
    final size = c.value.size;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap ?? _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: const Color(0xFF0E1016),
            child: FittedBox(
              fit: widget.fit,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: size.width == 0 ? 16 : size.width,
                height: size.height == 0 ? 9 : size.height,
                child: VideoPlayer(c),
              ),
            ),
          ),
          if (widget.showControls)
            AnimatedOpacity(
              opacity: playing ? 0 : 1,
              duration: const Duration(milliseconds: 120),
              child: Center(
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: .4),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .55),
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (widget.showControls)
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: VideoProgressIndicator(
                c,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: const VideoProgressColors(
                  playedColor: Color(0xFFF4B400),
                  bufferedColor: Color(0x55FFFFFF),
                  backgroundColor: Color(0x33FFFFFF),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
