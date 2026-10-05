class MealVoteModel {
  final String id;
  final String boardId;
  final String mealId;
  final String memberId;
  final String memberName;
  final String date; // Format: YYYY-MM-DD
  final bool willEat; // true = will eat (হ্যাঁ), false = will not eat (না)
  final DateTime updatedAt;

  MealVoteModel({
    required this.id,
    required this.boardId,
    required this.mealId,
    required this.memberId,
    required this.memberName,
    required this.date,
    required this.willEat,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'boardId': boardId,
      'mealId': mealId,
      'memberId': memberId,
      'memberName': memberName,
      'date': date,
      'willEat': willEat,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MealVoteModel.fromJson(Map<String, dynamic> json) {
    return MealVoteModel(
      id: json['id'] ?? '',
      boardId: json['boardId'] ?? '',
      mealId: json['mealId'] ?? '',
      memberId: json['memberId'] ?? '',
      memberName: json['memberName'] ?? '',
      date: json['date'] ?? '',
      willEat: json['willEat'] ?? true,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  MealVoteModel copyWith({
    String? id,
    String? boardId,
    String? mealId,
    String? memberId,
    String? memberName,
    String? date,
    bool? willEat,
    DateTime? updatedAt,
  }) {
    return MealVoteModel(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      mealId: mealId ?? this.mealId,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      date: date ?? this.date,
      willEat: willEat ?? this.willEat,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
