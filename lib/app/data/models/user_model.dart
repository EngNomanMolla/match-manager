class UserModel {
  final String id;
  final String name;
  final String phone;
  final String preferredRole; // 'manager' or 'member'

  UserModel({
    required this.id,
    required this.name,
    this.phone = '',
    this.preferredRole = 'manager',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'preferredRole': preferredRole,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      preferredRole: json['preferredRole'] ?? 'manager',
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? preferredRole,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      preferredRole: preferredRole ?? this.preferredRole,
    );
  }
}
