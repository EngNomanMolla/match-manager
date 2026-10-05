import 'package:flutter/material.dart';

enum BazarCategory {
  groceries, // মুদি বাজার
  meatFish, // মাছ-মাংস
  vegetables, // শাক-সবজি
  spices, // তেল-মশলা
  fruits, // ফলমূল
  snacks, // নাস্তা
  utilities, // গ্যাস/পানি/পরিষ্কার
  others, // অন্যান্য
}

extension BazarCategoryExtension on BazarCategory {
  String get key {
    switch (this) {
      case BazarCategory.groceries:
        return 'groceries';
      case BazarCategory.meatFish:
        return 'meat_fish';
      case BazarCategory.vegetables:
        return 'vegetables';
      case BazarCategory.spices:
        return 'spices';
      case BazarCategory.fruits:
        return 'fruits';
      case BazarCategory.snacks:
        return 'snacks';
      case BazarCategory.utilities:
        return 'utilities';
      case BazarCategory.others:
        return 'others';
    }
  }

  String get displayNameBn {
    switch (this) {
      case BazarCategory.groceries:
        return 'মুদি বাজার';
      case BazarCategory.meatFish:
        return 'মাছ ও মাংস';
      case BazarCategory.vegetables:
        return 'শাক-সবজি';
      case BazarCategory.spices:
        return 'তেল ও মশলা';
      case BazarCategory.fruits:
        return 'ফলমূল';
      case BazarCategory.snacks:
        return 'নাস্তা';
      case BazarCategory.utilities:
        return 'ইউটিলিটি';
      case BazarCategory.others:
        return 'অন্যান্য বাজার';
    }
  }

  String get displayNameEn {
    switch (this) {
      case BazarCategory.groceries:
        return 'Groceries';
      case BazarCategory.meatFish:
        return 'Meat & Fish';
      case BazarCategory.vegetables:
        return 'Vegetables';
      case BazarCategory.spices:
        return 'Oil & Spices';
      case BazarCategory.fruits:
        return 'Fruits';
      case BazarCategory.snacks:
        return 'Snacks';
      case BazarCategory.utilities:
        return 'Utilities';
      case BazarCategory.others:
        return 'Others';
    }
  }

  IconData get iconData {
    switch (this) {
      case BazarCategory.groceries:
        return Icons.shopping_basket_rounded;
      case BazarCategory.meatFish:
        return Icons.set_meal_rounded;
      case BazarCategory.vegetables:
        return Icons.eco_rounded;
      case BazarCategory.spices:
        return Icons.soup_kitchen_rounded;
      case BazarCategory.fruits:
        return Icons.apple_rounded;
      case BazarCategory.snacks:
        return Icons.cookie_rounded;
      case BazarCategory.utilities:
        return Icons.cleaning_services_rounded;
      case BazarCategory.others:
        return Icons.shopping_bag_rounded;
    }
  }

  Color get color {
    switch (this) {
      case BazarCategory.groceries:
        return const Color(0xFF059669); // Emerald
      case BazarCategory.meatFish:
        return const Color(0xFFDC2626); // Red
      case BazarCategory.vegetables:
        return const Color(0xFF16A34A); // Green
      case BazarCategory.spices:
        return const Color(0xFFD97706); // Amber
      case BazarCategory.fruits:
        return const Color(0xFFEA580C); // Orange
      case BazarCategory.snacks:
        return const Color(0xFF7C3AED); // Purple
      case BazarCategory.utilities:
        return const Color(0xFF0284C7); // Sky blue
      case BazarCategory.others:
        return const Color(0xFF64748B); // Slate
    }
  }

  static BazarCategory fromString(String? key) {
    switch (key) {
      case 'groceries':
        return BazarCategory.groceries;
      case 'meat_fish':
        return BazarCategory.meatFish;
      case 'vegetables':
        return BazarCategory.vegetables;
      case 'spices':
        return BazarCategory.spices;
      case 'fruits':
        return BazarCategory.fruits;
      case 'snacks':
        return BazarCategory.snacks;
      case 'utilities':
        return BazarCategory.utilities;
      case 'others':
      default:
        return BazarCategory.others;
    }
  }
}

class BazarModel {
  final String id;
  final String boardId;
  final String title;
  final double amount;
  final String date; // Format: YYYY-MM-DD
  final String shopperMemberId;
  final String shopperName;
  final String shopperRole; // 'manager', 'co_manager', 'member'
  final String entryById;
  final String entryByName;
  final String entryByRole; // 'manager', 'co_manager', 'member'
  final BazarCategory category;
  final List<String> items;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  BazarModel({
    required this.id,
    required this.boardId,
    required this.title,
    required this.amount,
    required this.date,
    required this.shopperMemberId,
    required this.shopperName,
    this.shopperRole = 'manager',
    required this.entryById,
    required this.entryByName,
    this.entryByRole = 'manager',
    this.category = BazarCategory.groceries,
    this.items = const [],
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'boardId': boardId,
      'title': title,
      'amount': amount,
      'date': date,
      'shopperMemberId': shopperMemberId,
      'shopperName': shopperName,
      'shopperRole': shopperRole,
      'entryById': entryById,
      'entryByName': entryByName,
      'entryByRole': entryByRole,
      'category': category.key,
      'items': items,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BazarModel.fromJson(Map<String, dynamic> json) {
    return BazarModel(
      id: json['id'] ?? '',
      boardId: json['boardId'] ?? '',
      title: json['title'] ?? '',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      date: json['date'] ?? '',
      shopperMemberId: json['shopperMemberId'] ?? '',
      shopperName: json['shopperName'] ?? '',
      shopperRole: json['shopperRole'] ?? 'manager',
      entryById: json['entryById'] ?? '',
      entryByName: json['entryByName'] ?? '',
      entryByRole: json['entryByRole'] ?? 'manager',
      category: BazarCategoryExtension.fromString(json['category']),
      items: (json['items'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      note: json['note'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  BazarModel copyWith({
    String? id,
    String? boardId,
    String? title,
    double? amount,
    String? date,
    String? shopperMemberId,
    String? shopperName,
    String? shopperRole,
    String? entryById,
    String? entryByName,
    String? entryByRole,
    BazarCategory? category,
    List<String>? items,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BazarModel(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      shopperMemberId: shopperMemberId ?? this.shopperMemberId,
      shopperName: shopperName ?? this.shopperName,
      shopperRole: shopperRole ?? this.shopperRole,
      entryById: entryById ?? this.entryById,
      entryByName: entryByName ?? this.entryByName,
      entryByRole: entryByRole ?? this.entryByRole,
      category: category ?? this.category,
      items: items ?? this.items,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
