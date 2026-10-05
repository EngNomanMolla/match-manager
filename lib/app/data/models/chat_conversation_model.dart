class ChatConversationModel {
  final String id; // 'group_<boardId>' or 'dm_<user1Id>_<user2Id>'
  final String title;
  final String? subtitle;
  final String? boardId;
  final String? boardTitle;
  final bool isGroup;
  final List<String> participantIds;
  final List<String> participantNames;
  final String? lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String? otherMemberRole; // For 1-on-1 chats: 'manager', 'co_manager', 'member'

  ChatConversationModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.boardId,
    this.boardTitle,
    required this.isGroup,
    required this.participantIds,
    required this.participantNames,
    this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.otherMemberRole,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'boardId': boardId,
      'boardTitle': boardTitle,
      'isGroup': isGroup,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'otherMemberRole': otherMemberRole,
    };
  }

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    return ChatConversationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      boardId: json['boardId'],
      boardTitle: json['boardTitle'],
      isGroup: json['isGroup'] ?? false,
      participantIds: (json['participantIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      participantNames: (json['participantNames'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.tryParse(json['lastMessageTime']) ?? DateTime.now()
          : DateTime.now(),
      unreadCount: json['unreadCount'] ?? 0,
      otherMemberRole: json['otherMemberRole'],
    );
  }
}
