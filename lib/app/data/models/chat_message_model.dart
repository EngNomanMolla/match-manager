class ChatMessageModel {
  final String id;
  final String conversationId; // 'group_<boardId>' or 'dm_<user1Id>_<user2Id>'
  final String? boardId;
  final String senderId;
  final String senderName;
  final String senderRole; // 'manager', 'co_manager', 'member'
  final String? senderAvatar;
  final String? recipientId; // Null for group chat
  final String? recipientName;
  final String text;
  final List<String> imagePaths; // Max 5 images
  final DateTime timestamp;
  final bool isRead;
  final bool isDeleted;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    this.boardId,
    required this.senderId,
    required this.senderName,
    this.senderRole = 'member',
    this.senderAvatar,
    this.recipientId,
    this.recipientName,
    this.text = '',
    this.imagePaths = const [],
    required this.timestamp,
    this.isRead = false,
    this.isDeleted = false,
  });

  bool get isGroup => conversationId.startsWith('group_');
  bool get hasImages => imagePaths.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'boardId': boardId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'senderAvatar': senderAvatar,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'text': text,
      'imagePaths': imagePaths,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'isDeleted': isDeleted,
    };
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      boardId: json['boardId'],
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderRole: json['senderRole'] ?? 'member',
      senderAvatar: json['senderAvatar'],
      recipientId: json['recipientId'],
      recipientName: json['recipientName'],
      text: json['text'] ?? '',
      imagePaths: (json['imagePaths'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  ChatMessageModel copyWith({
    String? id,
    String? conversationId,
    String? boardId,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? senderAvatar,
    String? recipientId,
    String? recipientName,
    String? text,
    List<String>? imagePaths,
    DateTime? timestamp,
    bool? isRead,
    bool? isDeleted,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      boardId: boardId ?? this.boardId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      text: text ?? this.text,
      imagePaths: imagePaths ?? this.imagePaths,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
