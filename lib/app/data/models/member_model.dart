enum MemberRole {
  manager,
  coManager,
  member,
}

class MemberModel {
  final String id;
  final String name;
  final String phone;
  final MemberRole role;
  final DateTime joinedAt;

  MemberModel({
    required this.id,
    required this.name,
    this.phone = '',
    this.role = MemberRole.member,
    required this.joinedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role.name,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: MemberRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => MemberRole.member,
      ),
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
    );
  }

  String get roleDisplayNameKey {
    switch (role) {
      case MemberRole.manager:
        return 'manager';
      case MemberRole.coManager:
        return 'co_manager';
      case MemberRole.member:
        return 'member';
    }
  }
}
