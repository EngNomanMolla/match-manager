import 'member_model.dart';

class BoardModel {
  final String id;
  final String title;
  final String sportType; // Holds mess type key: 'bachelor_mess', 'hostel_mess', 'family_mess', 'office_mess', 'custom_mess'
  final String description;
  final String boardCode;
  final String managerId;
  final String managerName;
  final int themeColorValue;
  final DateTime createdAt;
  final List<MemberModel> members;

  BoardModel({
    required this.id,
    required this.title,
    this.sportType = 'bachelor_mess',
    this.description = '',
    required this.boardCode,
    required this.managerId,
    required this.managerName,
    this.themeColorValue = 0xFF059669,
    required this.createdAt,
    required this.members,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'sportType': sportType,
      'description': description,
      'boardCode': boardCode,
      'managerId': managerId,
      'managerName': managerName,
      'themeColorValue': themeColorValue,
      'createdAt': createdAt.toIso8601String(),
      'members': members.map((m) => m.toJson()).toList(),
    };
  }

  factory BoardModel.fromJson(Map<String, dynamic> json) {
    return BoardModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      sportType: json['sportType'] ?? 'bachelor_mess',
      description: json['description'] ?? '',
      boardCode: json['boardCode'] ?? '',
      managerId: json['managerId'] ?? '',
      managerName: json['managerName'] ?? '',
      themeColorValue: json['themeColorValue'] ?? 0xFF059669,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => MemberModel.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  BoardModel copyWith({
    String? id,
    String? title,
    String? sportType,
    String? description,
    String? boardCode,
    String? managerId,
    String? managerName,
    int? themeColorValue,
    DateTime? createdAt,
    List<MemberModel>? members,
  }) {
    return BoardModel(
      id: id ?? this.id,
      title: title ?? this.title,
      sportType: sportType ?? this.sportType,
      description: description ?? this.description,
      boardCode: boardCode ?? this.boardCode,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      themeColorValue: themeColorValue ?? this.themeColorValue,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
    );
  }
}
