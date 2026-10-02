import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import '../models/board_model.dart';
import '../models/user_model.dart';

class StorageService {
  final _box = GetStorage();

  static const String _keyUser = 'active_user';
  static const String _keyBoards = 'created_boards';
  static const String _keyJoinedBoardCodes = 'joined_board_codes';
  static const String _keyLanguage = 'selected_language';

  Future<void> init() async {
    await GetStorage.init();
  }

  // User
  UserModel? getUser() {
    final data = _box.read(_keyUser);
    if (data != null) {
      if (data is Map<String, dynamic>) {
        return UserModel.fromJson(data);
      } else if (data is String) {
        return UserModel.fromJson(jsonDecode(data));
      }
    }
    return null;
  }

  Future<void> saveUser(UserModel user) async {
    await _box.write(_keyUser, user.toJson());
  }

  // Boards
  List<BoardModel> getBoards() {
    final raw = _box.read(_keyBoards);
    if (raw == null) return [];
    try {
      final List<dynamic> list = raw is String ? jsonDecode(raw) : raw;
      return list.map((item) => BoardModel.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBoards(List<BoardModel> boards) async {
    final jsonList = boards.map((b) => b.toJson()).toList();
    await _box.write(_keyBoards, jsonList);
  }

  // Joined Board Codes
  List<String> getJoinedBoardCodes() {
    final raw = _box.read(_keyJoinedBoardCodes);
    if (raw == null) return [];
    try {
      final List<dynamic> list = raw is String ? jsonDecode(raw) : raw;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveJoinedBoardCodes(List<String> codes) async {
    await _box.write(_keyJoinedBoardCodes, codes);
  }

  // Language
  String getLanguageCode() {
    return _box.read(_keyLanguage) ?? 'bn';
  }

  Future<void> saveLanguageCode(String code) async {
    await _box.write(_keyLanguage, code);
  }
}
