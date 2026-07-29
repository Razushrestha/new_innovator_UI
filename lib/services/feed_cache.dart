import '../models/feed_models.dart';

/// Dynamic in-memory feed page cache with soft (stale) + hard expiry.
///
/// Supports stale-while-revalidate: UI can paint expired pages while a
/// network refresh runs in the background.
class FeedCache {
  FeedCache._();

  static const freshTtl = Duration(minutes: 3);
  static const keepTtl = Duration(minutes: 45);
  static const maxPages = 12;

  static final Map<int, _FeedPageEntry> _pages = {};

  static void putPage(
    int page,
    List<FeedPostDto> posts, {
    required bool hasMore,
  }) {
    if (page < 1) return;
    _pages[page] = _FeedPageEntry(
      posts: List<FeedPostDto>.from(posts),
      hasMore: hasMore,
      fetchedAt: DateTime.now(),
    );
    _trim();
  }

  /// Returns a cached page even if soft-stale. Null only after hard expiry.
  static CachedFeedPage? getPage(int page, {bool allowStale = true}) {
    final entry = _pages[page];
    if (entry == null) return null;
    final age = DateTime.now().difference(entry.fetchedAt);
    if (age > keepTtl) {
      _pages.remove(page);
      return null;
    }
    if (!allowStale && age > freshTtl) return null;
    return CachedFeedPage(
      page: page,
      posts: List<FeedPostDto>.from(entry.posts),
      hasMore: entry.hasMore,
      isFresh: age <= freshTtl,
      fetchedAt: entry.fetchedAt,
    );
  }

  static bool isFresh(int page) => getPage(page, allowStale: false) != null;

  /// Consecutive pages from 1 for instant list hydration.
  static CachedFeedSnapshot? snapshot() {
    if (!_pages.containsKey(1)) return null;
    final posts = <FeedPostDto>[];
    var page = 1;
    var highest = 0;
    var hasMore = true;
    var allFresh = true;

    while (page <= maxPages) {
      final cached = getPage(page);
      if (cached == null) break;
      posts.addAll(cached.posts);
      hasMore = cached.hasMore;
      highest = page;
      if (!cached.isFresh) allFresh = false;
      if (!cached.hasMore) break;
      page += 1;
    }

    if (posts.isEmpty || highest < 1) return null;
    return CachedFeedSnapshot(
      posts: posts,
      highestPage: highest,
      hasMore: hasMore,
      isFresh: allFresh,
    );
  }

  static void invalidate() => _pages.clear();

  static void _trim() {
    if (_pages.length <= maxPages) return;
    final keys = _pages.keys.toList()..sort();
    while (_pages.length > maxPages && keys.isNotEmpty) {
      final drop = keys.removeLast();
      _pages.remove(drop);
    }
  }
}

class CachedFeedPage {
  const CachedFeedPage({
    required this.page,
    required this.posts,
    required this.hasMore,
    required this.isFresh,
    required this.fetchedAt,
  });

  final int page;
  final List<FeedPostDto> posts;
  final bool hasMore;
  final bool isFresh;
  final DateTime fetchedAt;
}

class CachedFeedSnapshot {
  const CachedFeedSnapshot({
    required this.posts,
    required this.highestPage,
    required this.hasMore,
    required this.isFresh,
  });

  final List<FeedPostDto> posts;
  final int highestPage;
  final bool hasMore;
  final bool isFresh;
}

class _FeedPageEntry {
  _FeedPageEntry({
    required this.posts,
    required this.hasMore,
    required this.fetchedAt,
  });

  final List<FeedPostDto> posts;
  final bool hasMore;
  final DateTime fetchedAt;
}
