class SearchUserHit {
  const SearchUserHit({
    required this.id,
    this.username,
    this.fullName,
    this.avatar,
    this.bio,
    this.role,
    this.interests = const [],
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
    this.followsMe = false,
    this.mutualCount = 0,
    this.affinityScore = 0,
    this.sharedTags = const [],
    this.reason,
  });

  /// Auth user id (follow / profile lookup).
  final String id;
  final String? username;
  final String? fullName;
  final String? avatar;
  final String? bio;
  final String? role;
  final List<String> interests;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final bool followsMe;
  final int mutualCount;
  final double affinityScore;
  final List<String> sharedTags;
  final String? reason;

  String get displayName {
    final full = fullName?.trim();
    if (full != null && full.isNotEmpty) return full;
    final user = username?.trim();
    if (user != null && user.isNotEmpty) return user;
    return 'User';
  }

  factory SearchUserHit.fromJson(Map<String, dynamic> json) {
    final rawInterests = json['interests'] ?? json['shared_tags'];
    return SearchUserHit(
      id: (json['user_id'] ??
              json['auth_user_id'] ??
              json['id'] ??
              '')
          .toString(),
      username: json['username'] as String?,
      fullName: json['full_name'] as String?,
      avatar: json['avatar'] as String?,
      bio: json['bio'] as String?,
      role: json['role'] as String?,
      interests: rawInterests is List
          ? rawInterests.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
      isFollowing: json['is_following'] == true,
      followsMe: json['follows_me'] == true,
      mutualCount: (json['mutual_count'] as num?)?.toInt() ?? 0,
      affinityScore: (json['affinity_score'] as num?)?.toDouble() ?? 0,
      sharedTags: json['shared_tags'] is List
          ? (json['shared_tags'] as List)
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList()
          : const [],
      reason: json['reason'] as String?,
    );
  }
}

class SearchPostHit {
  const SearchPostHit({
    required this.id,
    required this.authorId,
    this.username,
    this.avatar,
    this.content,
    this.type,
    this.hashtags = const [],
    this.categories = const [],
    this.reactionsCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
    this.isReel = false,
    this.createdAt,
  });

  final String id;
  final String authorId;
  final String? username;
  final String? avatar;
  final String? content;
  final String? type;
  final List<String> hashtags;
  final List<String> categories;
  final int reactionsCount;
  final int commentsCount;
  final int viewsCount;
  final bool isReel;
  final DateTime? createdAt;

  factory SearchPostHit.fromJson(Map<String, dynamic> json) {
    return SearchPostHit(
      id: json['id']?.toString() ?? json['post_id']?.toString() ?? '',
      authorId: json['author_id']?.toString() ?? '',
      username: json['username'] as String?,
      avatar: json['avatar'] as String?,
      content: json['content'] as String?,
      type: json['type'] as String?,
      hashtags: json['hashtags'] is List
          ? (json['hashtags'] as List).map((e) => e.toString()).toList()
          : const [],
      categories: json['categories'] is List
          ? (json['categories'] as List).map((e) => e.toString()).toList()
          : const [],
      reactionsCount: (json['reactions_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      isReel: json['is_reel'] == true,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class CombinedSearchResult {
  const CombinedSearchResult({
    this.users = const [],
    this.posts = const [],
    this.hashtags = const [],
    this.totalUsers = 0,
    this.totalPosts = 0,
  });

  final List<SearchUserHit> users;
  final List<SearchPostHit> posts;
  final List<String> hashtags;
  final int totalUsers;
  final int totalPosts;

  int get totalCount => users.length + posts.length + hashtags.length;

  factory CombinedSearchResult.fromJson(Map<String, dynamic> json) {
    return CombinedSearchResult(
      users: json['users'] is List
          ? (json['users'] as List)
              .whereType<Map>()
              .map((e) => SearchUserHit.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      posts: json['posts'] is List
          ? (json['posts'] as List)
              .whereType<Map>()
              .map((e) => SearchPostHit.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      hashtags: json['hashtags'] is List
          ? (json['hashtags'] as List).map((e) => e.toString()).toList()
          : const [],
      totalUsers: (json['total_users'] as num?)?.toInt() ?? 0,
      totalPosts: (json['total_posts'] as num?)?.toInt() ?? 0,
    );
  }
}

class SearchHistoryItem {
  const SearchHistoryItem({
    required this.id,
    required this.query,
    this.searchType,
    this.createdAt,
  });

  final String id;
  final String query;
  final String? searchType;
  final DateTime? createdAt;

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      id: json['id']?.toString() ?? '',
      query: json['query'] as String? ?? '',
      searchType: json['search_type'] as String?,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class UpsertUserIndexRequest {
  const UpsertUserIndexRequest({
    required this.authUserId,
    this.username,
    this.fullName,
    this.avatar,
    this.bio,
    this.role,
    this.interests,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  final String authUserId;
  final String? username;
  final String? fullName;
  final String? avatar;
  final String? bio;
  final String? role;
  final List<String>? interests;
  final int followersCount;
  final int followingCount;

  Map<String, dynamic> toJson() => {
        'auth_user_id': authUserId,
        'username': username,
        'full_name': fullName,
        'avatar': avatar,
        'bio': bio,
        'role': role,
        'interests': interests,
        'followers_count': followersCount,
        'following_count': followingCount,
      };
}

class UpsertPostIndexRequest {
  const UpsertPostIndexRequest({
    required this.postId,
    required this.authorId,
    this.username,
    this.avatar,
    this.content,
    this.type,
    this.hashtags,
    this.categories,
    this.reactionsCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
    this.isReel = false,
  });

  final String postId;
  final String authorId;
  final String? username;
  final String? avatar;
  final String? content;
  final String? type;
  final List<String>? hashtags;
  final List<String>? categories;
  final int reactionsCount;
  final int commentsCount;
  final int viewsCount;
  final bool isReel;

  Map<String, dynamic> toJson() => {
        'post_id': postId,
        'author_id': authorId,
        'username': username,
        'avatar': avatar,
        'content': content,
        'type': type,
        'hashtags': hashtags,
        'categories': categories,
        'reactions_count': reactionsCount,
        'comments_count': commentsCount,
        'views_count': viewsCount,
        'is_reel': isReel,
      };
}

class SyncFollowRequest {
  const SyncFollowRequest({
    required this.followerId,
    required this.followingId,
    required this.isFollowing,
  });

  final String followerId;
  final String followingId;
  final bool isFollowing;

  Map<String, dynamic> toJson() => {
        'follower_id': followerId,
        'following_id': followingId,
        'is_following': isFollowing,
      };
}
