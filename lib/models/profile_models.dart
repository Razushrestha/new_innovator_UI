class UserProfile {
  const UserProfile({
    required this.id,
    required this.authUserId,
    this.username,
    this.fullName,
    this.email,
    this.role,
    this.bio,
    this.avatar,
    this.dateOfBirth,
    this.phone,
    this.gender,
    this.address,
    this.education,
    this.occupation,
    this.interests = const [],
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowed = false,
    this.createdAt,
  });

  final String id;
  final String authUserId;
  final String? username;
  final String? fullName;
  final String? email;
  final String? role;
  final String? bio;
  final String? avatar;
  final String? dateOfBirth;
  final String? phone;
  final String? gender;
  final String? address;
  final String? education;
  final String? occupation;
  final List<String> interests;
  final int followersCount;
  final int followingCount;
  final bool isFollowed;
  final DateTime? createdAt;

  String get displayName {
    final full = fullName?.trim();
    if (full != null && full.isNotEmpty) return full;
    final user = username?.trim();
    if (user != null && user.isNotEmpty) return user;
    return 'Innovator';
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawInterests = json['interests'];
    return UserProfile(
      id: json['id'] as String? ?? '',
      authUserId: json['auth_user_id'] as String? ?? '',
      username: json['username'] as String?,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      bio: json['bio'] as String?,
      avatar: json['avatar'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      education: json['education'] as String?,
      occupation: json['occupation'] as String?,
      interests: rawInterests is List
          ? rawInterests.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
      isFollowed: json['is_followed'] == true,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class ProfileListUser {
  const ProfileListUser({
    required this.id,
    this.username,
    this.fullName,
    this.avatar,
    this.role,
    this.isFollowed = false,
  });

  /// Auth user id (used by follow/block endpoints).
  final String id;
  final String? username;
  final String? fullName;
  final String? avatar;
  final String? role;
  final bool isFollowed;

  String get displayName {
    final full = fullName?.trim();
    if (full != null && full.isNotEmpty) return full;
    final user = username?.trim();
    if (user != null && user.isNotEmpty) return user;
    return 'User';
  }

  factory ProfileListUser.fromJson(Map<String, dynamic> json) {
    return ProfileListUser(
      id: json['id'] as String? ?? '',
      username: json['username'] as String?,
      fullName: json['full_name'] as String?,
      avatar: json['avatar'] as String?,
      role: json['role'] as String?,
      isFollowed: json['is_followed'] == true,
    );
  }
}

class FollowToggleResult {
  const FollowToggleResult({
    required this.isFollowing,
    this.message,
  });

  final bool isFollowing;
  final String? message;

  factory FollowToggleResult.fromJson(Map<String, dynamic> json) {
    return FollowToggleResult(
      isFollowing: json['is_following'] == true,
      message: json['message'] as String?,
    );
  }
}

class BlockToggleResult {
  const BlockToggleResult({
    required this.isBlocked,
    this.message,
  });

  final bool isBlocked;
  final String? message;

  factory BlockToggleResult.fromJson(Map<String, dynamic> json) {
    return BlockToggleResult(
      isBlocked: json['is_blocked'] == true,
      message: json['message'] as String?,
    );
  }
}

class UpdateProfileRequest {
  const UpdateProfileRequest({
    this.fullName,
    this.bio,
    this.dateOfBirth,
    this.phone,
    this.gender,
    this.address,
    this.education,
    this.occupation,
    this.interests,
  });

  final String? fullName;
  final String? bio;
  final String? dateOfBirth;
  final String? phone;
  final String? gender;
  final String? address;
  final String? education;
  final String? occupation;
  final List<String>? interests;

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'bio': bio,
        'date_of_birth': dateOfBirth,
        'phone': phone,
        'gender': gender,
        'address': address,
        'education': education,
        'occupation': occupation,
        'interests': interests,
      };
}
