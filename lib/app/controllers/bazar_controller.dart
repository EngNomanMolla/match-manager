import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../data/models/bazar_model.dart';
import '../data/models/board_model.dart';
import '../data/models/member_model.dart';
import '../data/services/storage_service.dart';
import 'auth_profile_controller.dart';
import 'board_controller.dart';

class BazarController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final BoardController _boardController = Get.find<BoardController>();
  final AuthProfileController _authProfileController = Get.find<AuthProfileController>();

  final RxList<BazarModel> bazarList = <BazarModel>[].obs;
  final Rx<DateTime> selectedMonth = DateTime.now().obs;
  final RxString selectedCategoryKey = 'all'.obs;
  final RxString selectedShopperMemberId = 'all'.obs;
  final RxString searchQuery = ''.obs;
  final Rx<DateTime?> selectedFilterDate = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    loadBazarList();
  }

  void loadBazarList() {
    final list = _storageService.getBazarList();
    bazarList.value = list;
  }

  void setSelectedMonth(DateTime month) {
    selectedMonth.value = DateTime(month.year, month.month, 1);
  }

  void setFilterDate(DateTime? date) {
    selectedFilterDate.value = date;
  }

  void setCategoryFilter(String categoryKey) {
    selectedCategoryKey.value = categoryKey;
  }

  void setShopperFilter(String memberId) {
    selectedShopperMemberId.value = memberId;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query.trim();
  }

  void resetFilters() {
    selectedCategoryKey.value = 'all';
    selectedShopperMemberId.value = 'all';
    searchQuery.value = '';
    selectedFilterDate.value = null;
  }

  // Check if current user is Manager or Co-Manager of the board
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

  // Get current user's role in this board
  String getCurrentUserRoleInBoard(BoardModel board) {
    final currentUser = _authProfileController.user.value;
    if (currentUser == null) return 'member';

    if (board.managerId == currentUser.id) return 'manager';

    final member = board.members.firstWhereOrNull((m) =>
        m.id == currentUser.id ||
        (currentUser.phone.isNotEmpty && m.phone == currentUser.phone) ||
        m.name.trim().toLowerCase() == currentUser.name.trim().toLowerCase());

    if (member != null) {
      if (member.role == MemberRole.manager) return 'manager';
      if (member.role == MemberRole.coManager) return 'co_manager';
    }
    return 'member';
  }

  // Add new Bazar entry
  Future<bool> addBazarEntry({
    required String boardId,
    required String title,
    required double amount,
    required String date,
    required String shopperMemberId,
    required String shopperName,
    required String shopperRole,
    BazarCategory category = BazarCategory.groceries,
    List<String> items = const [],
    String note = '',
  }) async {
    final board = _boardController.getBoardById(boardId);
    if (board == null) return false;

    final currentUser = _authProfileController.user.value;
    final entryById = currentUser?.id ?? '';
    final entryByName = currentUser?.name ?? shopperName;
    final entryByRole = getCurrentUserRoleInBoard(board);

    final newEntry = BazarModel(
      id: const Uuid().v4(),
      boardId: boardId,
      title: title.trim(),
      amount: amount,
      date: date,
      shopperMemberId: shopperMemberId,
      shopperName: shopperName.trim(),
      shopperRole: shopperRole,
      entryById: entryById,
      entryByName: entryByName.trim(),
      entryByRole: entryByRole,
      category: category,
      items: items,
      note: note.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bazarList.insert(0, newEntry);
    await _storageService.saveBazarList(bazarList);
    return true;
  }

  // Update existing Bazar entry
  Future<bool> updateBazarEntry({
    required String boardId,
    required String bazarId,
    required String title,
    required double amount,
    required String date,
    required String shopperMemberId,
    required String shopperName,
    required String shopperRole,
    BazarCategory category = BazarCategory.groceries,
    List<String> items = const [],
    String note = '',
  }) async {
    final index = bazarList.indexWhere((b) => b.id == bazarId && b.boardId == boardId);
    if (index == -1) return false;

    final existing = bazarList[index];
    final updated = existing.copyWith(
      title: title.trim(),
      amount: amount,
      date: date,
      shopperMemberId: shopperMemberId,
      shopperName: shopperName.trim(),
      shopperRole: shopperRole,
      category: category,
      items: items,
      note: note.trim(),
      updatedAt: DateTime.now(),
    );

    bazarList[index] = updated;
    await _storageService.saveBazarList(bazarList);
    return true;
  }

  // Delete Bazar entry
  Future<bool> deleteBazarEntry({
    required String boardId,
    required String bazarId,
  }) async {
    final index = bazarList.indexWhere((b) => b.id == bazarId && b.boardId == boardId);
    if (index == -1) return false;

    bazarList.removeAt(index);
    await _storageService.saveBazarList(bazarList);
    return true;
  }

  // Get all Bazar entries for a board
  List<BazarModel> getBazarForBoard(String boardId) {
    return bazarList.where((b) => b.boardId == boardId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Filtered entries for board based on month, category, shopper and search query
  List<BazarModel> getFilteredBazarList(String boardId) {
    final all = getBazarForBoard(boardId);
    final monthStr = DateFormat('yyyy-MM').format(selectedMonth.value);
    final query = searchQuery.value.toLowerCase();
    final filterCategory = selectedCategoryKey.value;
    final filterShopper = selectedShopperMemberId.value;
    final filterDateStr = selectedFilterDate.value != null
        ? DateFormat('yyyy-MM-dd').format(selectedFilterDate.value!)
        : null;

    return all.where((b) {
      // Month or Date filter
      if (filterDateStr != null) {
        if (b.date != filterDateStr) return false;
      } else {
        if (!b.date.startsWith(monthStr)) return false;
      }

      // Category filter
      if (filterCategory != 'all' && b.category.key != filterCategory) {
        return false;
      }

      // Shopper filter
      if (filterShopper != 'all' && b.shopperMemberId != filterShopper) {
        return false;
      }

      // Search query
      if (query.isNotEmpty) {
        final matchTitle = b.title.toLowerCase().contains(query);
        final matchShopper = b.shopperName.toLowerCase().contains(query);
        final matchItems = b.items.any((item) => item.toLowerCase().contains(query));
        final matchNote = b.note.toLowerCase().contains(query);
        if (!matchTitle && !matchShopper && !matchItems && !matchNote) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Group filtered entries by date (Map<dateStr, List<BazarModel>>)
  Map<String, List<BazarModel>> getGroupedFilteredBazar(String boardId) {
    final filtered = getFilteredBazarList(boardId);
    final map = <String, List<BazarModel>>{};

    for (final entry in filtered) {
      if (!map.containsKey(entry.date)) {
        map[entry.date] = [];
      }
      map[entry.date]!.add(entry);
    }
    return map;
  }

  // Total Bazar amount across all time for board
  double getTotalBazarAmount(String boardId) {
    return bazarList
        .where((b) => b.boardId == boardId)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // Total Bazar amount for selected month
  double getMonthBazarAmount(String boardId, DateTime month) {
    final monthStr = DateFormat('yyyy-MM').format(month);
    return bazarList
        .where((b) => b.boardId == boardId && b.date.startsWith(monthStr))
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // Today's Bazar amount
  double getTodayBazarAmount(String boardId) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return bazarList
        .where((b) => b.boardId == boardId && b.date == todayStr)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // Member shopping contribution totals (memberId -> { name, role, totalAmount, count })
  Map<String, Map<String, dynamic>> getMemberShopperSummary(String boardId, {DateTime? month}) {
    final monthStr = month != null ? DateFormat('yyyy-MM').format(month) : null;
    final entries = bazarList.where((b) {
      if (b.boardId != boardId) return false;
      if (monthStr != null && !b.date.startsWith(monthStr)) return false;
      return true;
    });

    final summary = <String, Map<String, dynamic>>{};

    for (final b in entries) {
      if (!summary.containsKey(b.shopperMemberId)) {
        summary[b.shopperMemberId] = {
          'id': b.shopperMemberId,
          'name': b.shopperName,
          'role': b.shopperRole,
          'totalAmount': 0.0,
          'count': 0,
        };
      }
      summary[b.shopperMemberId]!['totalAmount'] =
          (summary[b.shopperMemberId]!['totalAmount'] as double) + b.amount;
      summary[b.shopperMemberId]!['count'] =
          (summary[b.shopperMemberId]!['count'] as int) + 1;
    }

    return summary;
  }

  // Category totals for month (Category -> totalAmount)
  Map<BazarCategory, double> getCategorySummary(String boardId, {DateTime? month}) {
    final monthStr = month != null ? DateFormat('yyyy-MM').format(month) : null;
    final entries = bazarList.where((b) {
      if (b.boardId != boardId) return false;
      if (monthStr != null && !b.date.startsWith(monthStr)) return false;
      return true;
    });

    final summary = <BazarCategory, double>{};
    for (final b in entries) {
      summary[b.category] = (summary[b.category] ?? 0.0) + b.amount;
    }
    return summary;
  }
}
