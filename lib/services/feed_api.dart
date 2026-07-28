import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/feed_models.dart';
import '../models/search_models.dart';
import 'api_client.dart';
import 'memory_cache.dart';
import 'search_api.dart';

/// Feed / posts / comments / reactions / notifications
/// — http://36.253.137.34:8012/swagger
class FeedApi {
  FeedApi({ApiClient? client}) : _client = client ?? ApiClient.shared;

  final ApiClient _client;

  static const _categoriesKey = 'feed.categories';

  // ----------------------------------------------------------------- feed

  Future<FeedPage> getFeed({
    int page = 1,
    int pageSize = ApiConfig.feedPageSize,
  }) async {
    final envelope = await _client.get<FeedPage>(
      ApiConfig.feedBaseUrl,
      '/api/feed',
      query: {
        'page': '$page',
        'pageSize': '$pageSize',
      },
      parse: (raw) => FeedPage.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    return envelope.data ?? const FeedPage(results: []);
  }

  Future<FeedPage> postsByAuthor(
    String authorId, {
    int page = 1,
    int pageSize = ApiConfig.feedPageSize,
  }) async {
    final envelope = await _client.get<FeedPage>(
      ApiConfig.feedBaseUrl,
      '/api/users/$authorId/posts',
      query: {
        'page': '$page',
        'pageSize': '$pageSize',
      },
      parse: (raw) => FeedPage.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    return envelope.data ?? const FeedPage(results: []);
  }

  Future<FeedPage> getReels({
    int page = 1,
    int pageSize = ApiConfig.feedPageSize,
  }) async {
    final envelope = await _client.get<FeedPage>(
      ApiConfig.feedBaseUrl,
      '/api/reels',
      query: {
        'page': '$page',
        'pageSize': '$pageSize',
      },
      parse: (raw) => FeedPage.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    return envelope.data ?? const FeedPage(results: []);
  }

  Future<FeedPostDto> getPost(String postId) async {
    final envelope = await _client.get<FeedPostDto>(
      ApiConfig.feedBaseUrl,
      '/api/posts/$postId',
      parse: (raw) => FeedPostDto.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) throw ApiException(envelope.message ?? 'Post not found');
    return data;
  }

  Future<FeedPostDto> createPost({
    required String content,
    List<String> categoryIds = const [],
    String? sharedPostId,
    List<({Uint8List bytes, String filename})> media = const [],
  }) async {
    final fields = <String, String>{
      'content': content,
      if (sharedPostId != null && sharedPostId.isNotEmpty)
        'sharedPostId': sharedPostId,
    };
    final files = <http.MultipartFile>[
      for (final m in media)
        http.MultipartFile.fromBytes('media', m.bytes, filename: m.filename),
      for (final id in categoryIds)
        http.MultipartFile.fromString('categoryIds', id),
    ];

    final envelope = await _client.multipartForm<FeedPostDto>(
      ApiConfig.feedBaseUrl,
      '/api/posts',
      fields: fields,
      files: files,
      parse: (raw) => FeedPostDto.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Could not create post');
    }
    MemoryCache.invalidate('feed.page1');
    // Don't block publish on search indexing.
    unawaited(_indexPost(data));
    return data;
  }

  Future<void> deletePost(String postId) async {
    await _client.delete<Object?>(
      ApiConfig.feedBaseUrl,
      '/api/posts/$postId',
      parse: (_) => null,
    );
    MemoryCache.invalidate('feed.page1');
    unawaited(() async {
      try {
        await SearchApi().deletePost(postId);
      } catch (_) {}
    }());
  }

  Future<int> recordView(String postId) async {
    final envelope = await _client.post<int>(
      ApiConfig.feedBaseUrl,
      '/api/posts/$postId/view',
      parse: (raw) => (raw as num?)?.toInt() ?? 0,
    );
    return envelope.data ?? 0;
  }

  Future<List<FeedCategory>> categories({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = MemoryCache.get<List<FeedCategory>>(_categoriesKey);
      if (cached != null) return cached;
    }
    final envelope = await _client.get<List<FeedCategory>>(
      ApiConfig.feedBaseUrl,
      '/api/categories',
      parse: (raw) {
        if (raw is! List) return <FeedCategory>[];
        return raw
            .whereType<Map>()
            .map((e) => FeedCategory.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
    final list = envelope.data ?? const <FeedCategory>[];
    MemoryCache.set(_categoriesKey, list);
    return list;
  }

  // ------------------------------------------------------------- reactions

  /// Toggle / set reaction. Sending the same type again often clears it (204).
  Future<FeedReaction?> react({
    required String postId,
    String type = 'like',
  }) async {
    final envelope = await _client.post<FeedReaction?>(
      ApiConfig.feedBaseUrl,
      '/api/reactions',
      body: {'post': postId, 'type': type},
      parse: (raw) {
        if (raw == null) return null;
        if (raw is! Map) return null;
        return FeedReaction.fromJson(Map<String, dynamic>.from(raw));
      },
    );
    return envelope.data;
  }

  Future<List<FeedReaction>> reactionsForPost(String postId) async {
    final envelope = await _client.get<List<FeedReaction>>(
      ApiConfig.feedBaseUrl,
      '/api/reactions/posts/$postId',
      parse: (raw) {
        if (raw is! List) return <FeedReaction>[];
        return raw
            .whereType<Map>()
            .map((e) => FeedReaction.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
    return envelope.data ?? const [];
  }

  // -------------------------------------------------------------- comments

  Future<List<FeedComment>> comments({
    String? postId,
    String? reelId,
    int page = 1,
  }) async {
    final query = <String, String>{
      'page': '$page',
      if (postId != null && postId.isNotEmpty) 'post': postId,
      if (reelId != null && reelId.isNotEmpty) 'reel': reelId,
    };
    final envelope = await _client.get<List<FeedComment>>(
      ApiConfig.feedBaseUrl,
      '/api/comments',
      query: query,
      parse: _parseComments,
    );
    return envelope.data ?? const [];
  }

  Future<FeedComment> createComment({
    required String content,
    String? postId,
    String? reelId,
  }) async {
    final envelope = await _client.post<FeedComment>(
      ApiConfig.feedBaseUrl,
      '/api/comments',
      body: {
        'content': content,
        'post': postId,
        'reel': reelId,
      },
      parse: (raw) => FeedComment.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Could not comment');
    }
    return data;
  }

  Future<FeedComment> updateComment(String commentId, String content) async {
    final envelope = await _client.patch<FeedComment>(
      ApiConfig.feedBaseUrl,
      '/api/comments/$commentId',
      body: {'content': content},
      parse: (raw) => FeedComment.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Could not update comment');
    }
    return data;
  }

  Future<void> deleteComment(String commentId) async {
    await _client.delete<Object?>(
      ApiConfig.feedBaseUrl,
      '/api/comments/$commentId',
      parse: (_) => null,
    );
  }

  Future<List<FeedComment>> replies(String parentId) async {
    final envelope = await _client.get<List<FeedComment>>(
      ApiConfig.feedBaseUrl,
      '/api/replies',
      query: {'parent': parentId},
      parse: _parseComments,
    );
    return envelope.data ?? const [];
  }

  Future<FeedComment> createReply({
    required String parentId,
    required String content,
  }) async {
    final envelope = await _client.post<FeedComment>(
      ApiConfig.feedBaseUrl,
      '/api/replies',
      body: {'parent': parentId, 'content': content},
      parse: (raw) => FeedComment.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Could not reply');
    }
    return data;
  }

  Future<void> deleteReply(String replyId) async {
    await _client.delete<Object?>(
      ApiConfig.feedBaseUrl,
      '/api/replies/$replyId',
      parse: (_) => null,
    );
  }

  // --------------------------------------------------------- notifications

  Future<List<FeedNotification>> notifications() async {
    final envelope = await _client.get<List<FeedNotification>>(
      ApiConfig.feedBaseUrl,
      '/api/notifications',
      parse: (raw) {
        if (raw is! List) return <FeedNotification>[];
        return raw
            .whereType<Map>()
            .map(
              (e) => FeedNotification.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      },
    );
    return envelope.data ?? const [];
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _client.post<Object?>(
      ApiConfig.feedBaseUrl,
      '/api/notifications/$notificationId/mark-as-read',
      parse: (_) => null,
    );
  }

  Future<void> markAllNotificationsRead() async {
    await _client.post<Object?>(
      ApiConfig.feedBaseUrl,
      '/api/notifications/mark-all-as-read',
      parse: (_) => null,
    );
  }

  Future<void> deleteNotification(String notificationId) async {
    await _client.delete<Object?>(
      ApiConfig.feedBaseUrl,
      '/api/notifications/$notificationId',
      parse: (_) => null,
    );
  }

  Future<void> registerFcmToken({
    required String token,
    String? deviceName,
  }) async {
    await _client.post<Object?>(
      ApiConfig.feedBaseUrl,
      '/api/fcm-tokens',
      body: {'token': token, 'device_name': deviceName},
      parse: (_) => null,
    );
  }

  List<FeedComment> _parseComments(Object? raw) {
    if (raw is! List) return <FeedComment>[];
    return raw
        .whereType<Map>()
        .map((e) => FeedComment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _indexPost(FeedPostDto post) async {
    try {
      final tags = RegExp(r'#(\w+)')
          .allMatches(post.content ?? '')
          .map((m) => m.group(1)!)
          .toList();
      await SearchApi().upsertPost(
        UpsertPostIndexRequest(
          postId: post.id,
          authorId: post.userId,
          username: post.username,
          avatar: post.avatar,
          content: post.content,
          type: post.type,
          hashtags: tags,
          categories: post.categories.map((c) => c.name).toList(),
          reactionsCount: post.reactionsCount,
          commentsCount: post.commentsCount,
          viewsCount: post.viewsCount,
          isReel: post.isReel,
        ),
      );
    } catch (_) {}
  }
}
