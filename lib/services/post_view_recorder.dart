import 'dart:async';

import 'feed_api.dart';

/// Batches post-view analytics so opening the feed doesn't fire N POSTs at once.
class PostViewRecorder {
  PostViewRecorder._();

  static final Set<String> _done = {};
  static final Set<String> _pending = {};
  static Timer? _timer;
  static var _flushing = false;

  static void schedule(String postId) {
    if (postId.isEmpty || _done.contains(postId)) return;
    _pending.add(postId);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 700), _flush);
  }

  static Future<void> _flush() async {
    if (_flushing) return;
    _flushing = true;
    final ids = _pending.where((id) => !_done.contains(id)).toList();
    _pending.clear();
    final api = FeedApi();
    // Send in small parallel chunks to keep sockets busy without a storm.
    for (var i = 0; i < ids.length; i += 3) {
      final chunk = ids.skip(i).take(3).toList();
      await Future.wait(
        chunk.map((id) async {
          _done.add(id);
          try {
            await api.recordView(id);
          } catch (_) {}
        }),
      );
    }
    _flushing = false;
  }

  static void clearSession() {
    _timer?.cancel();
    _pending.clear();
    _done.clear();
  }
}
