class ChatParticipant {
  const ChatParticipant({
    required this.userId,
    this.username,
    this.avatar,
    this.lastReadAt,
  });

  final String userId;
  final String? username;
  final String? avatar;
  final DateTime? lastReadAt;

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String?,
      avatar: json['avatar'] as String?,
      lastReadAt: _parseDate(json['last_read_at']),
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderUsername,
    this.senderAvatar,
    this.content,
    this.messageType,
    this.mediaUrl,
    this.isRead = false,
    this.isDeleted = false,
    this.replyToId,
    this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String? senderUsername;
  final String? senderAvatar;
  final String? content;
  final String? messageType;
  final String? mediaUrl;
  final bool isRead;
  final bool isDeleted;
  final String? replyToId;
  final DateTime? createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      conversationId: json['conversation_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderUsername: json['sender_username'] as String?,
      senderAvatar: json['sender_avatar'] as String?,
      content: json['content'] as String?,
      messageType: json['message_type'] as String?,
      mediaUrl: json['media_url'] as String?,
      isRead: json['is_read'] == true,
      isDeleted: json['is_deleted'] == true,
      replyToId: json['reply_to_id'] as String?,
      createdAt: _parseDate(json['created_at']),
    );
  }

  ChatMessage copyWith({String? content}) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderUsername: senderUsername,
      senderAvatar: senderAvatar,
      content: content ?? this.content,
      messageType: messageType,
      mediaUrl: mediaUrl,
      isRead: isRead,
      isDeleted: isDeleted,
      replyToId: replyToId,
      createdAt: createdAt,
    );
  }
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    this.type,
    this.participants = const [],
    this.lastMessage,
    this.unreadCount = 0,
    this.createdAt,
  });

  final String id;
  final String? type;
  final List<ChatParticipant> participants;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime? createdAt;

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final rawParts = json['participants'];
    return ChatConversation(
      id: json['id'] as String? ?? '',
      type: json['type'] as String?,
      participants: rawParts is List
          ? rawParts
              .whereType<Map>()
              .map((e) => ChatParticipant.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      lastMessage: json['last_message'] is Map
          ? ChatMessage.fromJson(
              Map<String, dynamic>.from(json['last_message'] as Map),
            )
          : null,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(json['created_at']),
    );
  }

  ChatParticipant? peerOf(String? myUserId) {
    if (myUserId == null || myUserId.isEmpty) {
      return participants.isEmpty ? null : participants.first;
    }
    for (final p in participants) {
      if (p.userId != myUserId) return p;
    }
    return participants.isEmpty ? null : participants.first;
  }
}

DateTime? _parseDate(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}
