import 'package:flutter/material.dart';

class MealTypeModel {
  final String id;
  final String name; // e.g. 'সকাল', 'দুপুর', 'রাত', 'বিকালের নাস্তা'
  final String time; // e.g. '০৮:০০ AM', '০১:৩০ PM'
  final int order; // Order index: determines which meal displays after which meal
  final bool isDefault; // true for morning, lunch, dinner
  final bool isActive;
  final String iconKey; // 'breakfast', 'lunch', 'dinner', 'snack', 'meal', 'fastfood'

  MealTypeModel({
    required this.id,
    required this.name,
    this.time = '',
    required this.order,
    this.isDefault = false,
    this.isActive = true,
    this.iconKey = 'meal',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'time': time,
      'order': order,
      'isDefault': isDefault,
      'isActive': isActive,
      'iconKey': iconKey,
    };
  }

  factory MealTypeModel.fromJson(Map<String, dynamic> json) {
    return MealTypeModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      time: json['time'] ?? '',
      order: json['order'] is int
          ? json['order']
          : (int.tryParse(json['order']?.toString() ?? '0') ?? 0),
      isDefault: json['isDefault'] ?? false,
      isActive: json['isActive'] ?? true,
      iconKey: json['iconKey'] ?? 'meal',
    );
  }

  MealTypeModel copyWith({
    String? id,
    String? name,
    String? time,
    int? order,
    bool? isDefault,
    bool? isActive,
    String? iconKey,
  }) {
    return MealTypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      time: time ?? this.time,
      order: order ?? this.order,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      iconKey: iconKey ?? this.iconKey,
    );
  }

  IconData get iconData {
    switch (iconKey) {
      case 'breakfast':
        return Icons.wb_sunny_rounded;
      case 'lunch':
        return Icons.lunch_dining_rounded;
      case 'dinner':
        return Icons.nightlight_round;
      case 'snack':
        return Icons.local_cafe_rounded;
      case 'fastfood':
        return Icons.fastfood_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  Color get defaultColor {
    switch (iconKey) {
      case 'breakfast':
        return const Color(0xFFEA580C); // Warm amber
      case 'lunch':
        return const Color(0xFF0284C7); // Sky blue
      case 'dinner':
        return const Color(0xFF6366F1); // Indigo / Night purple
      case 'snack':
        return const Color(0xFFD97706); // Golden
      default:
        return const Color(0xFF059669); // Emerald
    }
  }

  // 3 Default Meals: সকাল (Morning), দুপুর (Noon/Lunch), রাত (Night/Dinner)
  static List<MealTypeModel> get defaultMeals => [
        MealTypeModel(
          id: 'default_sokal',
          name: 'সকাল',
          time: '০৮:০০ AM',
          order: 0,
          isDefault: true,
          isActive: true,
          iconKey: 'breakfast',
        ),
        MealTypeModel(
          id: 'default_dupur',
          name: 'দুপুর',
          time: '০১:৩০ PM',
          order: 1,
          isDefault: true,
          isActive: true,
          iconKey: 'lunch',
        ),
        MealTypeModel(
          id: 'default_rat',
          name: 'রাত',
          time: '০৮:৩০ PM',
          order: 2,
          isDefault: true,
          isActive: true,
          iconKey: 'dinner',
        ),
      ];
}
