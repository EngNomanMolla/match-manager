import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../data/models/board_model.dart';
import '../data/models/member_model.dart';
import '../data/services/storage_service.dart';
import 'auth_profile_controller.dart';

class BoardController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final AuthProfileController _authProfileController = Get.find<AuthProfileController>();

  final RxList<BoardModel> boards = <BoardModel>[].obs;
  final RxList<String> joinedCodes = <String>[].obs;
  final RxString searchQuery = ''.obs;
  final RxInt selectedTab = 0.obs; // 0: My Messes, 1: Joined Messes

  @override
  void onInit() {
    super.onInit();
    loadBoards();
  }

  void loadBoards() {
    final storedBoards = _storageService.getBoards();
    joinedCodes.value = _storageService.getJoinedBoardCodes();

    if (storedBoards.isEmpty) {
      _seedDemoData();
    } else {
      boards.value = storedBoards;
    }
  }

  void _seedDemoData() {
    final currentUserId = _authProfileController.user.value?.id ?? const Uuid().v4();
    final currentUserName = _authProfileController.user.value?.name ?? 'নোমান হোসেন';

    final demoBoards = [
      BoardModel(
        id: const Uuid().v4(),
        title: 'ধানমন্ডি ব্যাচেলর মেস ২০২৬',
        sportType: 'bachelor_mess',
        description: 'দৈনিক মিল, বাজার ও ইউটিলিটি বিলের হিসাব খাতা',
        boardCode: 'MESS-7821',
        managerId: currentUserId,
        managerName: currentUserName,
        themeColorValue: 0xFF059669,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        members: [
          MemberModel(
            id: const Uuid().v4(),
            name: currentUserName,
            phone: '01700000000',
            role: MemberRole.manager,
            joinedAt: DateTime.now().subtract(const Duration(days: 4)),
          ),
          MemberModel(
            id: const Uuid().v4(),
            name: 'তানভীর আহমেদ',
            phone: '01812345678',
            role: MemberRole.coManager,
            joinedAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
          MemberModel(
            id: const Uuid().v4(),
            name: 'মাহমুদুল হাসান',
            phone: '01912345678',
            role: MemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          MemberModel(
            id: const Uuid().v4(),
            name: 'সাকিব আল হাসান',
            phone: '01712345678',
            role: MemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ],
      ),
      BoardModel(
        id: const Uuid().v4(),
        title: 'মিরপুর গ্রিন ভ্যালি হোস্টেল',
        sportType: 'hostel_mess',
        description: 'ফ্ল্যাট ৪/বি - লাঞ্চ ও ডিনার মিল ব্যবস্থাপনা',
        boardCode: 'MESS-4910',
        managerId: 'other_manager_id_101',
        managerName: 'আরিফুল ইসলাম',
        themeColorValue: 0xFF2563EB,
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
        members: [
          MemberModel(
            id: const Uuid().v4(),
            name: 'আরিফুল ইসলাম',
            phone: '01511223344',
            role: MemberRole.manager,
            joinedAt: DateTime.now().subtract(const Duration(days: 6)),
          ),
          MemberModel(
            id: currentUserId,
            name: currentUserName,
            phone: '01700000000',
            role: MemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
          MemberModel(
            id: const Uuid().v4(),
            name: 'রাকিবুল করিম',
            phone: '01699887766',
            role: MemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
      ),
    ];

    boards.value = demoBoards;
    joinedCodes.value = ['MESS-4910'];
    _storageService.saveBoards(demoBoards);
    _storageService.saveJoinedBoardCodes(joinedCodes);
  }

  // Filtered lists
  List<BoardModel> get myBoards {
    final currentUserId = _authProfileController.user.value?.id ?? '';
    return boards.where((b) {
      final isCreator = b.managerId == currentUserId;
      final matchesQuery = searchQuery.isEmpty ||
          b.title.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          b.boardCode.toLowerCase().contains(searchQuery.value.toLowerCase());
      return isCreator && matchesQuery;
    }).toList();
  }

  List<BoardModel> get joinedBoards {
    final currentUserId = _authProfileController.user.value?.id ?? '';
    return boards.where((b) {
      final isJoined = b.managerId != currentUserId &&
          (joinedCodes.contains(b.boardCode) ||
              b.members.any((m) => m.id == currentUserId || m.name == _authProfileController.user.value?.name));
      final matchesQuery = searchQuery.isEmpty ||
          b.title.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          b.boardCode.toLowerCase().contains(searchQuery.value.toLowerCase());
      return isJoined && matchesQuery;
    }).toList();
  }

  // Search user by phone number across all boards and known directory
  Map<String, String>? findUserByPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '').trim();
    if (cleanPhone.length < 5) return null;

    // Search existing members across all boards
    for (var b in boards) {
      for (var m in b.members) {
        final mPhone = m.phone.replaceAll(RegExp(r'\D'), '').trim();
        if (mPhone.isNotEmpty && mPhone == cleanPhone) {
          return {'name': m.name, 'phone': m.phone, 'id': m.id};
        }
      }
    }

    // Default system directory for quick testing
    final demoUsers = {
      '01700000000': 'নোমান হোসেন',
      '01812345678': 'তানভীর আহমেদ',
      '01912345678': 'মাহমুদুল হাসান',
      '01712345678': 'সাকিব আল হাসান',
      '01511223344': 'আরিফুল ইসলাম',
      '01699887766': 'রাকিবুল করিম',
      '01711223344': 'শাহরিয়ার নাফিস',
      '01899887766': 'জাহিদুল ইসলাম',
    };

    for (var entry in demoUsers.entries) {
      final dPhone = entry.key.replaceAll(RegExp(r'\D'), '').trim();
      if (dPhone == cleanPhone) {
        return {'name': entry.value, 'phone': entry.key, 'id': 'uid_${entry.key}'};
      }
    }

    return null;
  }

  // Generate unique 6-digit mess code
  String _generateBoardCode() {
    final random = Random();
    final number = 1000 + random.nextInt(9000);
    return 'MESS-$number';
  }

  // Create Mess
  Future<bool> createBoard({
    required String title,
    required String sportType,
    required String description,
    required Color themeColor,
  }) async {
    final currentUser = _authProfileController.user.value;
    if (currentUser == null) return false;

    final newBoard = BoardModel(
      id: const Uuid().v4(),
      title: title.trim(),
      sportType: sportType,
      description: description.trim(),
      boardCode: _generateBoardCode(),
      managerId: currentUser.id,
      managerName: currentUser.name,
      themeColorValue: themeColor.toARGB32(),
      createdAt: DateTime.now(),
      members: [
        MemberModel(
          id: currentUser.id,
          name: currentUser.name,
          phone: currentUser.phone,
          role: MemberRole.manager,
          joinedAt: DateTime.now(),
        ),
      ],
    );

    boards.insert(0, newBoard);
    await _storageService.saveBoards(boards);
    return true;
  }

  // Add Member
  Future<bool> addMember({
    required String boardId,
    required String name,
    required String phone,
    required MemberRole role,
  }) async {
    final index = boards.indexWhere((b) => b.id == boardId);
    if (index == -1) return false;

    final newMember = MemberModel(
      id: const Uuid().v4(),
      name: name.trim(),
      phone: phone.trim(),
      role: role,
      joinedAt: DateTime.now(),
    );

    final updatedMembers = List<MemberModel>.from(boards[index].members)..add(newMember);
    final updatedBoard = boards[index].copyWith(members: updatedMembers);

    boards[index] = updatedBoard;
    await _storageService.saveBoards(boards);
    return true;
  }

  // Remove Member
  Future<bool> removeMember({
    required String boardId,
    required String memberId,
  }) async {
    final index = boards.indexWhere((b) => b.id == boardId);
    if (index == -1) return false;

    final updatedMembers = boards[index].members.where((m) => m.id != memberId).toList();
    final updatedBoard = boards[index].copyWith(members: updatedMembers);

    boards[index] = updatedBoard;
    await _storageService.saveBoards(boards);
    return true;
  }

  // Update Member Role and Details
  Future<bool> updateMemberRole({
    required String boardId,
    required String memberId,
    required MemberRole newRole,
    String? newName,
    String? newPhone,
  }) async {
    final index = boards.indexWhere((b) => b.id == boardId);
    if (index == -1) return false;

    final updatedMembers = boards[index].members.map((m) {
      if (m.id == memberId) {
        return MemberModel(
          id: m.id,
          name: (newName != null && newName.trim().isNotEmpty) ? newName.trim() : m.name,
          phone: newPhone != null ? newPhone.trim() : m.phone,
          role: newRole,
          joinedAt: m.joinedAt,
        );
      }
      return m;
    }).toList();

    final updatedBoard = boards[index].copyWith(members: updatedMembers);
    boards[index] = updatedBoard;
    await _storageService.saveBoards(boards);
    return true;
  }

  // Delete Board
  Future<bool> deleteBoard(String boardId) async {
    boards.removeWhere((b) => b.id == boardId);
    await _storageService.saveBoards(boards);
    return true;
  }

  // Join Board using Code
  Future<bool> joinBoardByCode(String code) async {
    final cleanCode = code.trim().toUpperCase();
    final currentUser = _authProfileController.user.value;
    if (currentUser == null) return false;

    final existingBoardIndex = boards.indexWhere((b) => b.boardCode.toUpperCase() == cleanCode);

    if (existingBoardIndex != -1) {
      final board = boards[existingBoardIndex];
      final alreadyMember = board.members.any((m) => m.id == currentUser.id || m.name == currentUser.name);

      if (!alreadyMember) {
        final newMember = MemberModel(
          id: currentUser.id,
          name: currentUser.name,
          phone: currentUser.phone,
          role: MemberRole.member,
          joinedAt: DateTime.now(),
        );
        final updatedMembers = List<MemberModel>.from(board.members)..add(newMember);
        boards[existingBoardIndex] = board.copyWith(members: updatedMembers);
        await _storageService.saveBoards(boards);
      }

      if (!joinedCodes.contains(cleanCode)) {
        joinedCodes.add(cleanCode);
        await _storageService.saveJoinedBoardCodes(joinedCodes);
      }
      return true;
    } else {
      final sampleNewJoined = BoardModel(
        id: const Uuid().v4(),
        title: 'ব্যাচেলর মেস ($cleanCode)',
        sportType: 'bachelor_mess',
        description: 'কোডের মাধ্যমে যুক্ত হওয়া মেস গ্রুপ',
        boardCode: cleanCode,
        managerId: 'external_manager_${cleanCode.hashCode}',
        managerName: 'মেস ম্যানেজার',
        themeColorValue: 0xFF7C3AED,
        createdAt: DateTime.now(),
        members: [
          MemberModel(
            id: 'external_manager_${cleanCode.hashCode}',
            name: 'মেস ম্যানেজার',
            phone: '018XXXXXXXX',
            role: MemberRole.manager,
            joinedAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          MemberModel(
            id: currentUser.id,
            name: currentUser.name,
            phone: currentUser.phone,
            role: MemberRole.member,
            joinedAt: DateTime.now(),
          ),
        ],
      );

      boards.insert(0, sampleNewJoined);
      joinedCodes.add(cleanCode);
      await _storageService.saveBoards(boards);
      await _storageService.saveJoinedBoardCodes(joinedCodes);
      return true;
    }
  }

  BoardModel? getBoardById(String id) {
    try {
      return boards.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}
