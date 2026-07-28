import 'dart:typed_data';

import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/profile_models.dart';
import '../models/search_models.dart';
import 'api_client.dart';
import 'auth_session.dart';
import 'search_api.dart';

/// Profile service — http://36.253.137.34:8011/swagger
class ProfileApi {
  ProfileApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Creates the profile row if missing (InternalProfile).
  Future<void> ensureProfile({
    required String authUserId,
    String? username,
    String? email,
    String? role,
  }) async {
    await _client.post<Object?>(
      ApiConfig.profileBaseUrl,
      '/api/internal/profiles/ensure',
      body: {
        'auth_user_id': authUserId,
        'username': username,
        'email': email,
        'role': role,
      },
      parse: (_) => null,
    );
    try {
      await SearchApi().upsertUser(
        UpsertUserIndexRequest(
          authUserId: authUserId,
          username: username,
          fullName: username,
          role: role,
        ),
      );
    } catch (_) {
      // Search index sync is best-effort.
    }
  }

  /// Ensures then returns the signed-in user's profile.
  Future<UserProfile> getMe({bool ensureIfMissing = true}) async {
    try {
      return await _getMeOnce();
    } on ApiException catch (e) {
      if (!ensureIfMissing || e.statusCode != 404) rethrow;
      final session = AuthSession.instance;
      final userId = session.userId;
      if (userId == null || userId.isEmpty) rethrow;
      await ensureProfile(
        authUserId: userId,
        username: session.username,
        email: session.email,
        role: 'user',
      );
      return _getMeOnce();
    }
  }

  Future<UserProfile> _getMeOnce() async {
    final envelope = await _client.get<UserProfile>(
      ApiConfig.profileBaseUrl,
      '/api/users/me',
      parse: (raw) => UserProfile.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Profile not found');
    }
    return data;
  }

  Future<UserProfile> getByAuthUserId(String authUserId) async {
    final envelope = await _client.get<UserProfile>(
      ApiConfig.profileBaseUrl,
      '/api/users/$authUserId',
      parse: (raw) => UserProfile.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'User not found');
    }
    return data;
  }

  Future<UserProfile> getByUsername(String username) async {
    final envelope = await _client.get<UserProfile>(
      ApiConfig.profileBaseUrl,
      '/api/users/$username',
      parse: (raw) => UserProfile.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'User not found');
    }
    return data;
  }

  Future<UserProfile> updateProfile(UpdateProfileRequest request) async {
    final envelope = await _client.put<UserProfile>(
      ApiConfig.profileBaseUrl,
      '/api/profile',
      body: request.toJson(),
      parse: (raw) => UserProfile.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Could not update profile');
    }
    try {
      await SearchApi().upsertUser(
        UpsertUserIndexRequest(
          authUserId: data.authUserId,
          username: data.username,
          fullName: data.fullName,
          avatar: data.avatar,
          bio: data.bio,
          role: data.role,
          interests: data.interests,
          followersCount: data.followersCount,
          followingCount: data.followingCount,
        ),
      );
    } catch (_) {}
    return data;
  }

  Future<UserProfile> patchProfile(UpdateProfileRequest request) async {
    final envelope = await _client.patch<UserProfile>(
      ApiConfig.profileBaseUrl,
      '/api/profile',
      body: request.toJson(),
      parse: (raw) => UserProfile.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Could not update profile');
    }
    try {
      await SearchApi().upsertUser(
        UpsertUserIndexRequest(
          authUserId: data.authUserId,
          username: data.username,
          fullName: data.fullName,
          avatar: data.avatar,
          bio: data.bio,
          role: data.role,
          interests: data.interests,
          followersCount: data.followersCount,
          followingCount: data.followingCount,
        ),
      );
    } catch (_) {}
    return data;
  }

  Future<String> uploadAvatar(
    Uint8List bytes, {
    String filename = 'avatar.png',
  }) async {
    final envelope = await _client.multipart(
      ApiConfig.profileBaseUrl,
      '/api/users/me/avatar',
      method: 'POST',
      fileField: 'file',
      bytes: bytes,
      filename: filename,
      parse: (raw) => raw?.toString() ?? '',
    );
    final url = envelope.data?.trim() ?? '';
    if (url.isEmpty) {
      throw ApiException(envelope.message ?? 'Avatar upload failed');
    }
    return url;
  }

  Future<List<ProfileListUser>> followers({String? authUserId}) async {
    final path = authUserId == null || authUserId.isEmpty
        ? '/api/users/followers'
        : '/api/users/$authUserId/followers';
    return _listUsers(path);
  }

  Future<List<ProfileListUser>> following({String? authUserId}) async {
    final path = authUserId == null || authUserId.isEmpty
        ? '/api/users/following'
        : '/api/users/$authUserId/following';
    return _listUsers(path);
  }

  Future<List<ProfileListUser>> blockedList() =>
      _listUsers('/api/users/blocked-list');

  Future<FollowToggleResult> toggleFollow(String targetAuthUserId) async {
    final envelope = await _client.post<FollowToggleResult>(
      ApiConfig.profileBaseUrl,
      '/api/users/$targetAuthUserId/follow',
      parse: (raw) => FollowToggleResult.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Follow failed');
    }
    final me = AuthSession.instance.userId;
    if (me != null && me.isNotEmpty) {
      try {
        await SearchApi().syncFollow(
          SyncFollowRequest(
            followerId: me,
            followingId: targetAuthUserId,
            isFollowing: data.isFollowing,
          ),
        );
      } catch (_) {}
    }
    return data;
  }

  Future<BlockToggleResult> block(String targetAuthUserId) async {
    final envelope = await _client.post<BlockToggleResult>(
      ApiConfig.profileBaseUrl,
      '/api/users/$targetAuthUserId/block',
      parse: (raw) => BlockToggleResult.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Block failed');
    }
    return data;
  }

  Future<BlockToggleResult> unblock(String targetAuthUserId) async {
    final envelope = await _client.post<BlockToggleResult>(
      ApiConfig.profileBaseUrl,
      '/api/users/$targetAuthUserId/unblock',
      parse: (raw) => BlockToggleResult.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Unblock failed');
    }
    return data;
  }

  Future<List<ProfileListUser>> _listUsers(String path) async {
    final envelope = await _client.get<List<ProfileListUser>>(
      ApiConfig.profileBaseUrl,
      path,
      parse: (raw) {
        if (raw is! List) return <ProfileListUser>[];
        return raw
            .whereType<Map>()
            .map((e) => ProfileListUser.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
    return envelope.data ?? const [];
  }
}
