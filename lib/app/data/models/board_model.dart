import 'package:intl/intl.dart';
import 'meal_type_model.dart';
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
  final List<MealTypeModel> meals;
  final String periodType; // 'months' or 'custom_date'
  final List<String> selectedMonths; // e.g. ['2026-10', '2026-11']
  final DateTime? startDate;
  final DateTime? endDate;

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
    List<MealTypeModel>? meals,
    this.periodType = 'months',
    this.selectedMonths = const [],
    this.startDate,
    this.endDate,
  }) : meals = meals ?? MealTypeModel.defaultMeals;

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
      'meals': meals.map((m) => m.toJson()).toList(),
      'periodType': periodType,
      'selectedMonths': selectedMonths,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
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
      meals: (json['meals'] as List<dynamic>?)
              ?.map((m) => MealTypeModel.fromJson(m as Map<String, dynamic>))
              .toList() ??
          MealTypeModel.defaultMeals,
      periodType: json['periodType'] ?? 'months',
      selectedMonths: (json['selectedMonths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'])
          : null,
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
    List<MealTypeModel>? meals,
    String? periodType,
    List<String>? selectedMonths,
    DateTime? startDate,
    DateTime? endDate,
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
      meals: meals ?? this.meals,
      periodType: periodType ?? this.periodType,
      selectedMonths: selectedMonths ?? this.selectedMonths,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  String get periodDisplayName {
    if (periodType == 'custom_date' && startDate != null && endDate != null) {
      final startStr = DateFormat('d MMM yyyy').format(startDate!);
      final endStr = DateFormat('d MMM yyyy').format(endDate!);
      return '$startStr - $endStr';
    }

    if (selectedMonths.isNotEmpty) {
      return selectedMonths.map((ym) {
        try {
          final parts = ym.split('-');
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          return formatMonthYear(month, year);
        } catch (_) {
          return ym;
        }
      }).join(', ');
    }

    return formatMonthYear(createdAt.month, createdAt.year);
  }

  static String formatMonthYear(int month, int year) {
    const bnMonths = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    if (month >= 1 && month <= 12) {
      return '${bnMonths[month - 1]} $year';
    }
    return '$month/$year';
  }
}
