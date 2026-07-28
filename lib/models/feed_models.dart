class FeedMediaItem {
  const FeedMediaItem({
    required this.id,
    required this.file,
    this.mediaType,
    this.thumbnail,
  });

  final String id;
  final String file;
  final String? mediaType;
  final String? thumbnail;

  bool get isVideo =>
      (mediaType ?? '').toLowerCase().contains('video') ||
      file.toLowerCase().endsWith('.mp4') ||
      file.toLowerCase().endsWith('.mov');

  factory FeedMediaItem.fromJson(Map<String, dynamic> json) {
    return FeedMediaItem(
      id: json['id']?.toString() ?? '',
      file: json['file']?.toString() ?? '',
      mediaType: json['media_type'] as String?,
      thumbnail: json['thumbnail'] as String?,
    );
  }
}

class FeedCategory {
  const FeedCategory({
    required this.id,
    required this.name,
    this.description,
  });

  final String id;
  final String name;
  final String? description;

  factory FeedCategory.fromJson(Map<String, dynamic> json) {
    return FeedCategory(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}

class FeedPostDto {
  const FeedPostDto({
    required this.id,
    required this.userId,
    this.username,
    this.avatar,
    this.content,
    this.type,
    this.isReel = false,
    this.media = const [],
    this.categories = const [],
    this.reactionsCount = 0,
    this.commentsCount = 0,
    this.shareCount = 0,
    this.viewsCount = 0,
    this.currentUserReaction,
    this.isFollowed = false,
    this.sharedPostId,
    this.sharedPost,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String? username;
  final String? avatar;
  final String? content;
  final String? type;
  final bool isReel;
  final List<FeedMediaItem> media;
  final List<FeedCategory> categories;
  final int reactionsCount;
  final int commentsCount;
  final int shareCount;
  final int viewsCount;
  final String? currentUserReaction;
  final bool isFollowed;
  final String? sharedPostId;
  final FeedPostDto? sharedPost;
  final DateTime? createdAt;

  String get displayAuthor {
    final u = username?.trim();
    if (u != null && u.isNotEmpty) return u;
    return 'Innovator';
  }

  bool get likedByMe {
    final r = currentUserReaction?.toLowerCase();
    return r == 'like' || r == 'love';
  }

  FeedPostDto copyWith({
    int? reactionsCount,
    int? commentsCount,
    int? shareCount,
    String? currentUserReaction,
    bool clearReaction = false,
    bool? isFollowed,
  }) {
    return FeedPostDto(
      id: id,
      userId: userId,
      username: username,
      avatar: avatar,
      content: content,
      type: type,
      isReel: isReel,
      media: media,
      categories: categories,
      reactionsCount: reactionsCount ?? this.reactionsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      shareCount: shareCount ?? this.shareCount,
      viewsCount: viewsCount,
      currentUserReaction:
          clearReaction ? null : (currentUserReaction ?? this.currentUserReaction),
      isFollowed: isFollowed ?? this.isFollowed,
      sharedPostId: sharedPostId,
      sharedPost: sharedPost,
      createdAt: createdAt,
    );
  }

  factory FeedPostDto.fromJson(Map<String, dynamic> json) {
    final shared = json['shared_post_details'] ?? json['shared_post'];
    return FeedPostDto(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      username: json['username'] as String?,
      avatar: json['avatar'] as String?,
      content: json['content'] as String?,
      type: json['type'] as String?,
      isReel: json['is_reel'] == true,
      media: json['media'] is List
          ? (json['media'] as List)
              .whereType<Map>()
              .map((e) => FeedMediaItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      categories: json['categories_detail'] is List
          ? (json['categories_detail'] as List)
              .whereType<Map>()
              .map((e) => FeedCategory.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      reactionsCount: (json['reactions_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      shareCount: (json['share_count'] as num?)?.toInt() ?? 0,
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      currentUserReaction: json['current_user_reaction']?.toString(),
      isFollowed: json['is_followed'] == true,
      sharedPostId: json['shared_post'] is String
          ? json['shared_post'] as String
          : json['shared_post']?.toString(),
      sharedPost: shared is Map
          ? FeedPostDto.fromJson(Map<String, dynamic>.from(shared))
          : null,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class FeedPage {
  const FeedPage({
    required this.results,
    this.count = 0,
    this.next,
    this.previous,
  });

  final List<FeedPostDto> results;
  final int count;
  final String? next;
  final String? previous;

  bool get hasMore => next != null && next!.isNotEmpty;

  factory FeedPage.fromJson(Map<String, dynamic> json) {
    return FeedPage(
      results: json['results'] is List
          ? (json['results'] as List)
              .whereType<Map>()
              .map((e) => FeedPostDto.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      count: (json['count'] as num?)?.toInt() ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
    );
  }
}

class FeedComment {
  const FeedComment({
    required this.id,
    this.username,
    this.avatar,
    this.postId,
    this.parentId,
    this.content,
    this.replyCount = 0,
    this.createdAt,
  });

  final String id;
  final String? username;
  final String? avatar;
  final String? postId;
  final String? parentId;
  final String? content;
  final int replyCount;
  final DateTime? createdAt;

  factory FeedComment.fromJson(Map<String, dynamic> json) {
    return FeedComment(
      id: json['id']?.toString() ?? '',
      username: json['username'] as String?,
      avatar: json['avatar'] as String?,
      postId: json['post']?.toString(),
      parentId: json['parent']?.toString(),
      content: json['content'] as String?,
      replyCount: (json['reply_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class FeedReaction {
  const FeedReaction({
    required this.id,
    required this.postId,
    this.type,
    this.createdAt,
  });

  final String id;
  final String postId;
  final String? type;
  final DateTime? createdAt;

  factory FeedReaction.fromJson(Map<String, dynamic> json) {
    return FeedReaction(
      id: json['id']?.toString() ?? '',
      postId: json['post']?.toString() ?? '',
      type: json['type'] as String?,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class FeedNotification {
  const FeedNotification({
    required this.id,
    this.title,
    this.message,
    this.type,
    this.senderId,
    this.senderUsername,
    this.senderAvatar,
    this.relatedPostId,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String? title;
  final String? message;
  final String? type;
  final String? senderId;
  final String? senderUsername;
  final String? senderAvatar;
  final String? relatedPostId;
  final bool isRead;
  final DateTime? createdAt;

  factory FeedNotification.fromJson(Map<String, dynamic> json) {
    return FeedNotification(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String?,
      message: json['message'] as String? ?? json['body'] as String?,
      type: json['type'] as String?,
      senderId: json['sender_id']?.toString(),
      senderUsername: json['sender_username'] as String?,
      senderAvatar: json['sender_avatar'] as String?,
      relatedPostId: json['related_post_id']?.toString(),
      isRead: json['is_read'] == true || json['read'] == true,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

String formatFeedTime(DateTime? createdAt) {
  if (createdAt == null) return '';
  final diff = DateTime.now().toUtc().difference(createdAt.toUtc());
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${createdAt.month}/${createdAt.day}';
}
