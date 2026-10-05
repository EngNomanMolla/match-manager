import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../data/models/board_model.dart';
import '../data/models/meal_type_model.dart';
import '../data/models/meal_vote_model.dart';
import '../data/models/member_model.dart';
import '../data/services/storage_service.dart';
import 'auth_profile_controller.dart';
import 'board_controller.dart';

class MealController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final BoardController _boardController = Get.find<BoardController>();
  final AuthProfileController _authProfileController = Get.find<AuthProfileController>();

  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxList<MealVoteModel> mealVotes = <MealVoteModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadVotes();
  }

  void loadVotes() {
    final votes = _storageService.getMealVotes();
    mealVotes.value = votes;
  }

  String get formattedSelectedDate {
    return DateFormat('yyyy-MM-dd').format(selectedDate.value);
  }

  void setDate(DateTime date) {
    selectedDate.value = date;
  }

  // Check if current user is manager or co-manager of the board
  bool isManagerOrCoManager(BoardModel board) {
    final currentUser = _authProfileController.user.value;
    if (currentUser == null) return false;

    // Creator / Owner is Manager
    if (board.managerId == currentUser.id) return true;

    // Check in board member roles
    return board.members.any((m) =>
        (m.id == currentUser.id ||
            (currentUser.phone.isNotEmpty && m.phone == currentUser.phone) ||
            m.name.trim().toLowerCase() == currentUser.name.trim().toLowerCase()) &&
        (m.role == MemberRole.manager || m.role == MemberRole.coManager));
  }

  // Add new meal with custom placement ("kon meal er pore kon meal name show korbe")
  Future<bool> addMealType({
    required String boardId,
    required String name,
    required String time,
    required String afterMealId, // 'start', 'end', or specific mealId
    required String iconKey,
  }) async {
    final board = _boardController.getBoardById(boardId);
    if (board == null) return false;

    final newMeal = MealTypeModel(
      id: const Uuid().v4(),
      name: name.trim(),
      time: time.trim(),
      order: 0, // will be recalculated below
      isDefault: false,
      isActive: true,
      iconKey: iconKey,
    );

    final currentMeals = List<MealTypeModel>.from(board.meals);

    if (afterMealId == 'start') {
      currentMeals.insert(0, newMeal);
    } else if (afterMealId == 'end' || afterMealId.isEmpty) {
      currentMeals.add(newMeal);
    } else {
      final targetIndex = currentMeals.indexWhere((m) => m.id == afterMealId);
      if (targetIndex != -1) {
        currentMeals.insert(targetIndex + 1, newMeal);
      } else {
        currentMeals.add(newMeal);
      }
    }

    // Reassign correct consecutive order indices
    final updatedMeals = <MealTypeModel>[];
    for (int i = 0; i < currentMeals.length; i++) {
      updatedMeals.add(currentMeals[i].copyWith(order: i));
    }

    final updatedBoard = board.copyWith(meals: updatedMeals);
    final boardIndex = _boardController.boards.indexWhere((b) => b.id == boardId);
    if (boardIndex != -1) {
      _boardController.boards[boardIndex] = updatedBoard;
      await _storageService.saveBoards(_boardController.boards);
      return true;
    }
    return false;
  }

  // Update existing meal (name, time, icon, and optional position change)
  Future<bool> updateMealType({
    required String boardId,
    required String mealId,
    required String newName,
    required String newTime,
    required String newIconKey,
    String? afterMealId,
  }) async {
    final board = _boardController.getBoardById(boardId);
    if (board == null) return false;

    final currentMeals = List<MealTypeModel>.from(board.meals);
    final targetIndex = currentMeals.indexWhere((m) => m.id == mealId);
    if (targetIndex == -1) return false;

    final existingMeal = currentMeals[targetIndex];
    final updated = existingMeal.copyWith(
      name: newName.trim(),
      time: newTime.trim(),
      iconKey: newIconKey,
    );

    currentMeals.removeAt(targetIndex);

    if (afterMealId == null) {
      // Keep in same place
      currentMeals.insert(targetIndex, updated);
    } else if (afterMealId == 'start') {
      currentMeals.insert(0, updated);
    } else if (afterMealId == 'end') {
      currentMeals.add(updated);
    } else {
      final insertAfter = currentMeals.indexWhere((m) => m.id == afterMealId);
      if (insertAfter != -1) {
        currentMeals.insert(insertAfter + 1, updated);
      } else {
        currentMeals.add(updated);
      }
    }

    // Re-index orders
    final updatedMeals = <MealTypeModel>[];
    for (int i = 0; i < currentMeals.length; i++) {
      updatedMeals.add(currentMeals[i].copyWith(order: i));
    }

    final updatedBoard = board.copyWith(meals: updatedMeals);
    final boardIndex = _boardController.boards.indexWhere((b) => b.id == boardId);
    if (boardIndex != -1) {
      _boardController.boards[boardIndex] = updatedBoard;
      await _storageService.saveBoards(_boardController.boards);
      return true;
    }
    return false;
  }

  // Delete custom meal
  Future<bool> deleteMealType({
    required String boardId,
    required String mealId,
  }) async {
    final board = _boardController.getBoardById(boardId);
    if (board == null) return false;

    final currentMeals = List<MealTypeModel>.from(board.meals);
    final mealToRemove = currentMeals.firstWhereOrNull((m) => m.id == mealId);
    if (mealToRemove == null || mealToRemove.isDefault) {
      // Cannot delete default meals
      return false;
    }

    currentMeals.removeWhere((m) => m.id == mealId);

    // Re-index orders
    final updatedMeals = <MealTypeModel>[];
    for (int i = 0; i < currentMeals.length; i++) {
      updatedMeals.add(currentMeals[i].copyWith(order: i));
    }

    final updatedBoard = board.copyWith(meals: updatedMeals);
    final boardIndex = _boardController.boards.indexWhere((b) => b.id == boardId);
    if (boardIndex != -1) {
      _boardController.boards[boardIndex] = updatedBoard;
      await _storageService.saveBoards(_boardController.boards);
      return true;
    }
    return false;
  }

  // Reorder meals (e.g. from drag & drop)
  Future<void> reorderMeals({
    required String boardId,
    required int oldIndex,
    required int newIndex,
  }) async {
    final board = _boardController.getBoardById(boardId);
    if (board == null) return;

    final currentMeals = List<MealTypeModel>.from(board.meals);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final item = currentMeals.removeAt(oldIndex);
    currentMeals.insert(newIndex, item);

    final updatedMeals = <MealTypeModel>[];
    for (int i = 0; i < currentMeals.length; i++) {
      updatedMeals.add(currentMeals[i].copyWith(order: i));
    }

    final updatedBoard = board.copyWith(meals: updatedMeals);
    final boardIndex = _boardController.boards.indexWhere((b) => b.id == boardId);
    if (boardIndex != -1) {
      _boardController.boards[boardIndex] = updatedBoard;
      await _storageService.saveBoards(_boardController.boards);
    }
  }

  // Member Meal Voting: members can cast vote for any meal on any date
  Future<void> castVote({
    required String boardId,
    required String mealId,
    required bool willEat,
  }) async {
    final currentUser = _authProfileController.user.value;
    if (currentUser == null) return;

    final dateStr = formattedSelectedDate;
    final voteIndex = mealVotes.indexWhere(
      (v) =>
          v.boardId == boardId &&
          v.mealId == mealId &&
          v.memberId == currentUser.id &&
          v.date == dateStr,
    );

    if (voteIndex != -1) {
      // Toggle or update vote
      final currentVote = mealVotes[voteIndex];
      if (currentVote.willEat == willEat) {
        // Already selected same, remove vote (unvote)
        mealVotes.removeAt(voteIndex);
      } else {
        mealVotes[voteIndex] = currentVote.copyWith(
          willEat: willEat,
          updatedAt: DateTime.now(),
        );
      }
    } else {
      final newVote = MealVoteModel(
        id: const Uuid().v4(),
        boardId: boardId,
        mealId: mealId,
        memberId: currentUser.id,
        memberName: currentUser.name,
        date: dateStr,
        willEat: willEat,
        updatedAt: DateTime.now(),
      );
      mealVotes.add(newVote);
    }

    await _storageService.saveMealVotes(mealVotes);
  }

  // Get votes for a specific meal on a date
  List<MealVoteModel> getVotesForMealAndDate(String boardId, String mealId, String date) {
    return mealVotes
        .where((v) => v.boardId == boardId && v.mealId == mealId && v.date == date)
        .toList();
  }

  // Get current user's vote
  MealVoteModel? getCurrentUserVote(String boardId, String mealId, String date) {
    final currentUser = _authProfileController.user.value;
    if (currentUser == null) return null;

    return mealVotes.firstWhereOrNull(
      (v) =>
          v.boardId == boardId &&
          v.mealId == mealId &&
          v.memberId == currentUser.id &&
          v.date == date,
    );
  }

  // ==========================================
  // MONTHLY MEAL PLANNER METHODS
  // ==========================================
  final Rx<DateTime> plannerMonth = DateTime.now().obs;
  final Rx<DateTime> plannerSelectedDate = DateTime.now().obs;

  void setPlannerMonth(DateTime month) {
    plannerMonth.value = DateTime(month.year, month.month, 1);
  }

  void setPlannerDate(DateTime date) {
    plannerSelectedDate.value = date;
  }

  // Bulk update month meals for current user
  Future<void> setMonthMealsBulk({
    required String boardId,
    required DateTime month,
    required bool willEat,
    List<String>? targetMealIds,
    bool weekdaysOnly = false,
    bool fromTodayOnly = false,
  }) async {
    final currentUser = _authProfileController.user.value;
    final board = _boardController.getBoardById(boardId);
    if (currentUser == null || board == null) return;

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final activeMeals = board.meals.where((m) => m.isActive).toList();
    final mealIdsToSet = targetMealIds ?? activeMeals.map((m) => m.id).toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final updatedVotes = List<MealVoteModel>.from(mealVotes);

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      if (fromTodayOnly && date.isBefore(today)) {
        continue;
      }
      if (weekdaysOnly) {
        // Exclude Friday and Saturday as weekends
        if (date.weekday == DateTime.friday || date.weekday == DateTime.saturday) {
          continue;
        }
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      for (final mealId in mealIdsToSet) {
        final existingIndex = updatedVotes.indexWhere(
          (v) =>
              v.boardId == boardId &&
              v.mealId == mealId &&
              v.memberId == currentUser.id &&
              v.date == dateStr,
        );

        if (existingIndex != -1) {
          updatedVotes[existingIndex] = updatedVotes[existingIndex].copyWith(
            willEat: willEat,
            updatedAt: DateTime.now(),
          );
        } else {
          updatedVotes.add(
            MealVoteModel(
              id: const Uuid().v4(),
              boardId: boardId,
              mealId: mealId,
              memberId: currentUser.id,
              memberName: currentUser.name,
              date: dateStr,
              willEat: willEat,
              updatedAt: DateTime.now(),
            ),
          );
        }
      }
    }

    mealVotes.value = updatedVotes;
    await _storageService.saveMealVotes(mealVotes);
  }

  // Set individual meal states for a single date
  Future<void> setDayMeals({
    required String boardId,
    required String dateStr,
    required Map<String, bool> mealStatus,
  }) async {
    final currentUser = _authProfileController.user.value;
    if (currentUser == null) return;

    final updatedVotes = List<MealVoteModel>.from(mealVotes);

    mealStatus.forEach((mealId, willEat) {
      final existingIndex = updatedVotes.indexWhere(
        (v) =>
            v.boardId == boardId &&
            v.mealId == mealId &&
            v.memberId == currentUser.id &&
            v.date == dateStr,
      );

      if (existingIndex != -1) {
        updatedVotes[existingIndex] = updatedVotes[existingIndex].copyWith(
          willEat: willEat,
          updatedAt: DateTime.now(),
        );
      } else {
        updatedVotes.add(
          MealVoteModel(
            id: const Uuid().v4(),
            boardId: boardId,
            mealId: mealId,
            memberId: currentUser.id,
            memberName: currentUser.name,
            date: dateStr,
            willEat: willEat,
            updatedAt: DateTime.now(),
          ),
        );
      }
    });

    mealVotes.value = updatedVotes;
    await _storageService.saveMealVotes(mealVotes);
  }

  // Toggle all meals for a day
  Future<void> toggleDayAllMeals({
    required String boardId,
    required String dateStr,
    required List<MealTypeModel> meals,
    required bool targetStatus,
  }) async {
    final map = <String, bool>{};
    for (final m in meals) {
      if (m.isActive) {
        map[m.id] = targetStatus;
      }
    }
    await setDayMeals(boardId: boardId, dateStr: dateStr, mealStatus: map);
  }

  // Query Day status for current user
  Map<String, dynamic> getUserDateStatus({
    required String boardId,
    required String dateStr,
    required List<MealTypeModel> meals,
  }) {
    final currentUser = _authProfileController.user.value;
    final activeMeals = meals.where((m) => m.isActive).toList();
    if (currentUser == null || activeMeals.isEmpty) {
      return {
        'totalActiveMeals': 0,
        'willEatCount': 0,
        'willEatMealIds': <String>{},
        'isAllEat': false,
        'isPartialEat': false,
        'isNoneEat': true,
      };
    }

    final userVotes = mealVotes.where(
      (v) =>
          v.boardId == boardId &&
          v.memberId == currentUser.id &&
          v.date == dateStr,
    ).toList();

    final willEatMealIds = <String>{};
    for (final meal in activeMeals) {
      final vote = userVotes.firstWhereOrNull((v) => v.mealId == meal.id);
      if (vote != null && vote.willEat) {
        willEatMealIds.add(meal.id);
      }
    }

    final totalActive = activeMeals.length;
    final willEatCount = willEatMealIds.length;

    return {
      'totalActiveMeals': totalActive,
      'willEatCount': willEatCount,
      'willEatMealIds': willEatMealIds,
      'isAllEat': willEatCount == totalActive && totalActive > 0,
      'isPartialEat': willEatCount > 0 && willEatCount < totalActive,
      'isNoneEat': willEatCount == 0,
    };
  }

  // Query Month statistics for current user
  Map<String, dynamic> getUserMonthSummary({
    required String boardId,
    required DateTime month,
    required List<MealTypeModel> meals,
  }) {
    final currentUser = _authProfileController.user.value;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    int totalActiveDays = 0;
    int totalMeals = 0;
    final mealBreakdown = <String, int>{};

    for (final m in meals) {
      mealBreakdown[m.id] = 0;
    }

    if (currentUser == null) {
      return {
        'totalActiveDays': 0,
        'totalMeals': 0,
        'mealBreakdown': mealBreakdown,
      };
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final status = getUserDateStatus(
        boardId: boardId,
        dateStr: dateStr,
        meals: meals,
      );

      final count = status['willEatCount'] as int;
      if (count > 0) {
        totalActiveDays++;
        totalMeals += count;
        final willEatIds = status['willEatMealIds'] as Set<String>;
        for (final id in willEatIds) {
          mealBreakdown[id] = (mealBreakdown[id] ?? 0) + 1;
        }
      }
    }

    return {
      'totalActiveDays': totalActiveDays,
      'totalMeals': totalMeals,
      'mealBreakdown': mealBreakdown,
    };
  }
}
