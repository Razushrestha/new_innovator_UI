import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/search_models.dart';
import 'api_client.dart';

/// Search service — http://36.253.137.34:8015/swagger
class SearchApi {
  SearchApi({ApiClient? client}) : _client = client ?? ApiClient.shared;

  final ApiClient _client;

  // ---------------------------------------------------------------- Search

  /// Combined search. [type] defaults to `all` (also: `users`, `posts`, …).
  Future<CombinedSearchResult> search({
    required String q,
    String type = 'all',
  }) async {
    final envelope = await _client.get<CombinedSearchResult>(
      ApiConfig.searchBaseUrl,
      '/api/search',
      query: {
        'q': q,
        'type': type,
      },
      parse: (raw) => CombinedSearchResult.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    return envelope.data ?? const CombinedSearchResult();
  }

  Future<List<SearchUserHit>> searchUsers(String q) async {
    final envelope = await _client.get<List<SearchUserHit>>(
      ApiConfig.searchBaseUrl,
      '/api/search/users',
      query: {'q': q},
      parse: _parseUsers,
    );
    return envelope.data ?? const [];
  }

  Future<List<SearchPostHit>> searchPosts(String q) async {
    final envelope = await _client.get<List<SearchPostHit>>(
      ApiConfig.searchBaseUrl,
      '/api/search/posts',
      query: {'q': q},
      parse: _parsePosts,
    );
    return envelope.data ?? const [];
  }

  Future<List<String>> searchHashtags(String q) async {
    final envelope = await _client.get<List<String>>(
      ApiConfig.searchBaseUrl,
      '/api/search/hashtags',
      query: {'q': q},
      parse: (raw) {
        if (raw is! List) return <String>[];
        return raw.map((e) => e.toString()).toList();
      },
    );
    return envelope.data ?? const [];
  }

  /// Suggested users — tries primary path, falls back once.
  Future<List<SearchUserHit>> suggestedUsers() async {
    try {
      return await _suggested('/api/suggested-users');
    } on ApiException {
      return _suggested('/api/users/suggested');
    }
  }

  Future<List<SearchUserHit>> _suggested(String path) async {
    final envelope = await _client.get<List<SearchUserHit>>(
      ApiConfig.searchBaseUrl,
      path,
      parse: _parseUsers,
    );
    return envelope.data ?? const [];
  }

  Future<List<SearchHistoryItem>> history() async {
    final envelope = await _client.get<List<SearchHistoryItem>>(
      ApiConfig.searchBaseUrl,
      '/api/search/history',
      parse: (raw) {
        if (raw is! List) return <SearchHistoryItem>[];
        return raw
            .whereType<Map>()
            .map(
              (e) => SearchHistoryItem.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      },
    );
    return envelope.data ?? const [];
  }

  Future<void> clearHistory() async {
    await _client.delete<Object?>(
      ApiConfig.searchBaseUrl,
      '/api/search/history',
      parse: (_) => null,
    );
  }

  // ------------------------------------------------------------- IndexSync

  Future<void> upsertUser(UpsertUserIndexRequest request) async {
    await _client.post<Object?>(
      ApiConfig.searchBaseUrl,
      '/api/internal/search/users',
      body: request.toJson(),
      parse: (_) => null,
    );
  }

  Future<void> deleteUser(String authUserId) async {
    await _client.delete<Object?>(
      ApiConfig.searchBaseUrl,
      '/api/internal/search/users/$authUserId',
      parse: (_) => null,
    );
  }

  Future<void> upsertPost(UpsertPostIndexRequest request) async {
    await _client.post<Object?>(
      ApiConfig.searchBaseUrl,
      '/api/internal/search/posts',
      body: request.toJson(),
      parse: (_) => null,
    );
  }

  Future<void> deletePost(String postId) async {
    await _client.delete<Object?>(
      ApiConfig.searchBaseUrl,
      '/api/internal/search/posts/$postId',
      parse: (_) => null,
    );
  }

  Future<void> syncFollow(SyncFollowRequest request) async {
    await _client.post<Object?>(
      ApiConfig.searchBaseUrl,
      '/api/internal/search/follows',
      body: request.toJson(),
      parse: (_) => null,
    );
  }

  List<SearchUserHit> _parseUsers(Object? raw) {
    if (raw is! List) return <SearchUserHit>[];
    return raw
        .whereType<Map>()
        .map((e) => SearchUserHit.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<SearchPostHit> _parsePosts(Object? raw) {
    if (raw is! List) return <SearchPostHit>[];
    return raw
        .whereType<Map>()
        .map((e) => SearchPostHit.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
