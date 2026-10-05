import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_profile_controller.dart';
import '../../controllers/board_controller.dart';
import '../../controllers/meal_controller.dart';
import '../../data/models/board_model.dart';
import '../../data/models/meal_type_model.dart';
import '../../theme/app_theme.dart';
import 'add_meal_dialog.dart';

class MealDetailView extends StatefulWidget {
  const MealDetailView({super.key});

  @override
  State<MealDetailView> createState() => _MealDetailViewState();
}

class _MealDetailViewState extends State<MealDetailView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MealController mealController = Get.find<MealController>();
  final BoardController boardController = Get.find<BoardController>();
  final AuthProfileController authController = Get.find<AuthProfileController>();

  bool _isReorderMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boardId = Get.arguments as String?;

    if (boardId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('meal_details'.tr)),
        body: Center(child: Text('no_data_found'.tr)),
      );
    }

    return Obx(() {
      final board = boardController.getBoardById(boardId);
      if (board == null) {
        return Scaffold(
          appBar: AppBar(title: Text('meal_details'.tr)),
          body: Center(child: Text('no_data_found'.tr)),
        );
      }

      final currentUserId = authController.user.value?.id ?? '';
      final isManager = mealController.isManagerOrCoManager(board);
      final groupColor = Color(board.themeColorValue);

      // Sort meals by order index
      final sortedMeals = List<MealTypeModel>.from(board.meals)
        ..sort((a, b) => a.order.compareTo(b.order));

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
            onPressed: () => Get.back(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'meal_details'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                board.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          actions: [
            // Manager / Member Role Indicator Tag
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isManager
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isManager
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isManager ? Icons.verified_user_rounded : Icons.person_rounded,
                    size: 14,
                    color: isManager ? AppColors.primary : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isManager ? 'ম্যানেজার' : 'মেম্বার',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isManager ? AppColors.primary : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: groupColor,
                indicatorWeight: 3,
                dividerColor: Colors.transparent,
                dividerHeight: 0,
                labelColor: groupColor,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                tabs: [
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.restaurant_menu_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text('meal_slots'.tr),
                      ],
                    ),
                  ),
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.how_to_vote_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text('meal_poll'.tr),
                      ],
                    ),
                  ),
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text('monthly_planner_tab'.tr),
                      ],
                    ),
                  ),
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.table_chart_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text('meal_sheet'.tr),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Meal Slots & Sequence
            _buildMealSlotsTab(context, board, sortedMeals, isManager, groupColor),

            // Tab 2: Meal Poll & Member Voting
            _buildMealPollTab(context, board, sortedMeals, currentUserId, groupColor),

            // Tab 3: Monthly Calendar Meal Planner
            _buildMonthlyPlannerTab(context, board, sortedMeals, currentUserId, groupColor),

            // Tab 4: Daily Meal Sheet / Member Schedule preview
            _buildMealSheetTab(context, board, sortedMeals, groupColor),
          ],
        ),
        // Floating button only for Manager & Co-Manager to add meals
        floatingActionButton: isManager
            ? FloatingActionButton.extended(
                onPressed: () {
                  Get.dialog(
                    AddMealDialog(board: board),
                  );
                },
                backgroundColor: groupColor,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text(
                  'create_meal'.tr,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )
            : null,
      );
    });
  }

  // ==========================================
  // TAB 1: MEAL SLOTS & SEQUENCE (Manager / Co-Manager Control)
  // ==========================================
  Widget _buildMealSlotsTab(
    BuildContext context,
    BoardModel board,
    List<MealTypeModel> meals,
    bool isManager,
    Color groupColor,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Section Title + Reorder Mode Toggle (for manager)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'সক্রিয় মিলের সূচী (${meals.length}টি)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'মিলের ক্রম অনুযায়ী অ্যাপে প্রদর্শিত হবে',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            if (isManager && meals.length > 1)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isReorderMode = !_isReorderMode;
                  });
                },
                icon: Icon(
                  _isReorderMode ? Icons.done_all_rounded : Icons.swap_vert_rounded,
                  size: 18,
                  color: groupColor,
                ),
                label: Text(
                  _isReorderMode ? 'সম্পন্ন' : 'reorder_meals'.tr,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: groupColor),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: groupColor.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // If in Reorder Mode, render ReorderableListView
        if (_isReorderMode && isManager) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.drag_indicator_rounded, color: Color(0xFFD97706), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'reorder_mode_hint'.tr,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) {
              mealController.reorderMeals(
                boardId: board.id,
                oldIndex: oldIndex,
                newIndex: newIndex,
              );
            },
            children: [
              for (int i = 0; i < meals.length; i++)
                _buildMealTile(
                  key: ValueKey(meals[i].id),
                  index: i,
                  meal: meals[i],
                  board: board,
                  isManager: isManager,
                  isReordering: true,
                ),
            ],
          ),
        ] else ...[
          // Normal List
          ...meals.asMap().entries.map((entry) {
            final index = entry.key;
            final meal = entry.value;
            return _buildMealTile(
              key: ValueKey(meal.id),
              index: index,
              meal: meal,
              board: board,
              isManager: isManager,
              isReordering: false,
            );
          }),
        ],
      ],
    );
  }

  Widget _buildMealTile({
    required Key key,
    required int index,
    required MealTypeModel meal,
    required BoardModel board,
    required bool isManager,
    required bool isReordering,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sequence Number Badge
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
            ),
            const SizedBox(width: 10),
            // Meal Icon
            CircleAvatar(
              radius: 20,
              backgroundColor: meal.defaultColor.withValues(alpha: 0.14),
              child: Icon(meal.iconData, size: 20, color: meal.defaultColor),
            ),
          ],
        ),
        title: Row(
          children: [
            Text(
              meal.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            // Default / Custom Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: meal.isDefault
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                meal.isDefault ? 'default_badge'.tr : 'custom_badge'.tr,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: meal.isDefault ? const Color(0xFF2563EB) : const Color(0xFF16A34A),
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          meal.time.isNotEmpty ? 'সময়: ${meal.time}' : 'সময় নির্ধারণ করা হয়নি',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        trailing: isReordering
            ? const Icon(Icons.drag_handle_rounded, color: Color(0xFF94A3B8))
            : isManager
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit Button
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                        tooltip: 'edit_meal'.tr,
                        onPressed: () {
                          Get.dialog(
                            AddMealDialog(
                              board: board,
                              mealToEdit: meal,
                            ),
                          );
                        },
                      ),
                      // Delete button (Only for custom created meals)
                      if (!meal.isDefault)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                          tooltip: 'delete'.tr,
                          onPressed: () {
                            _confirmDeleteMeal(board.id, meal);
                          },
                        ),
                    ],
                  )
                : null,
      ),
    );
  }

  void _confirmDeleteMeal(String boardId, MealTypeModel meal) {
    Get.defaultDialog(
      title: 'confirm_delete_meal'.tr,
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      middleText: '"${meal.name}" মিলটি তালিকা থেকে মুছে ফেলতে চান?',
      textConfirm: 'delete'.tr,
      textCancel: 'cancel'.tr,
      confirmTextColor: Colors.white,
      buttonColor: AppColors.danger,
      onConfirm: () async {
        await mealController.deleteMealType(boardId: boardId, mealId: meal.id);
        Get.back();
        Get.snackbar(
          'success'.tr,
          'মুছে ফেলা হয়েছে!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF0F172A),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      },
    );
  }

  // ==========================================
  // TAB 2: MEAL POLL & MEMBER VOTING ("member ra sudu meal er vote dite parbe")
  // ==========================================
  Widget _buildMealPollTab(
    BuildContext context,
    BoardModel board,
    List<MealTypeModel> meals,
    String currentUserId,
    Color groupColor,
  ) {
    final today = DateTime.now();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Today's Date Display Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: groupColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.calendar_today_rounded, size: 18, color: groupColor),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'আজকের তারিখ',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(today),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Voting Cards for each Meal
        Text(
          'মিলের ভোট দিন (${meals.length}টি মিল)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'members_can_only_vote'.tr,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),

        ...meals.map((meal) => _buildMealPollCard(board, meal, currentUserId, groupColor)),
      ],
    );
  }

  Widget _buildMealPollCard(
    BoardModel board,
    MealTypeModel meal,
    String currentUserId,
    Color groupColor,
  ) {
    return Obx(() {
      final dateStr = mealController.formattedSelectedDate;
      final votes = mealController.getVotesForMealAndDate(board.id, meal.id, dateStr);
      final myVote = mealController.getCurrentUserVote(board.id, meal.id, dateStr);

      final yesVotes = votes.where((v) => v.willEat).toList();
      final noVotes = votes.where((v) => !v.willEat).toList();

      final totalMembers = board.members.length;
      final totalVoted = votes.length;
      final percentEating = totalVoted > 0 ? (yesVotes.length / totalVoted) : 0.0;

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon, Name, Time
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: meal.defaultColor.withValues(alpha: 0.15),
                  child: Icon(meal.iconData, size: 20, color: meal.defaultColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (meal.time.isNotEmpty)
                        Text(
                          meal.time,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                    ],
                  ),
                ),
                // Quick tally badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${yesVotes.length} জন খাবেন',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percentEating,
                minHeight: 8,
                backgroundColor: const Color(0xFFFEE2E2),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            ),
            const SizedBox(height: 8),

            // Summary text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${yesVotes.length} ${'voted_yes_count'.tr} • ${noVotes.length} ${'voted_no_count'.tr}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                Text(
                  'মোট সদস্য: $totalMembers',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            // My Voting Action Buttons
            Row(
              children: [
                const Text(
                  'আপনার ভোট:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                const Spacer(),

                // Vote: Will Eat (খাবো)
                InkWell(
                  onTap: () {
                    mealController.castVote(
                      boardId: board.id,
                      mealId: meal.id,
                      willEat: true,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: (myVote != null && myVote.willEat)
                          ? const Color(0xFF10B981)
                          : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (myVote != null && myVote.willEat)
                            ? const Color(0xFF059669)
                            : const Color(0xFFA7F3D0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: (myVote != null && myVote.willEat) ? Colors.white : const Color(0xFF059669),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'vote_yes'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: (myVote != null && myVote.willEat) ? Colors.white : const Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Vote: Won't Eat (খাবো না)
                InkWell(
                  onTap: () {
                    mealController.castVote(
                      boardId: board.id,
                      mealId: meal.id,
                      willEat: false,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: (myVote != null && !myVote.willEat)
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (myVote != null && !myVote.willEat)
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFFECACA),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cancel_rounded,
                          size: 16,
                          color: (myVote != null && !myVote.willEat) ? Colors.white : const Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'vote_no'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: (myVote != null && !myVote.willEat) ? Colors.white : const Color(0xFF991B1B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Voters preview breakdown
            if (votes.isNotEmpty) ...[
              const SizedBox(height: 12),
              ExpansionTile(
                title: Text(
                  'কারা ভোট দিয়েছেন দেখুন (${votes.length} জন)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 6),
                dense: true,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: votes.map((v) {
                      return Chip(
                        avatar: Icon(
                          v.willEat ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 14,
                          color: v.willEat ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                        label: Text(
                          v.memberName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: v.willEat ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                          ),
                        ),
                        backgroundColor: v.willEat ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  // ==========================================
  // TAB 3: MONTHLY MEAL PLANNER (মাসিক ক্যালেন্ডার ও মিল প্ল্যানার)
  // ==========================================
  Widget _buildMonthlyPlannerTab(
    BuildContext context,
    BoardModel board,
    List<MealTypeModel> meals,
    String currentUserId,
    Color groupColor,
  ) {
    return Obx(() {
      final currentMonth = mealController.plannerMonth.value;
      final selectedDate = mealController.plannerSelectedDate.value;
      final selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final activeMeals = meals.where((m) => m.isActive).toList();

      final monthSummary = mealController.getUserMonthSummary(
        boardId: board.id,
        month: currentMonth,
        meals: activeMeals,
      );

      final selectedDayStatus = mealController.getUserDateStatus(
        boardId: board.id,
        dateStr: selectedDateStr,
        meals: activeMeals,
      );

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // 1. Group Selected Months (if configured)
          if (board.periodType == 'months' && board.selectedMonths.isNotEmpty) ...[
            _buildGroupMonthsPills(board, currentMonth, groupColor),
            const SizedBox(height: 12),
          ] else if (board.periodType == 'custom_date' && board.startDate != null && board.endDate != null) ...[
            _buildCustomDateBanner(board, groupColor),
            const SizedBox(height: 12),
          ],

          // 2. Month Selector Navigation Bar
          _buildMonthNavigationHeader(currentMonth, groupColor),
          const SizedBox(height: 14),

          // 3. Monthly Stats Summary Card
          _buildMonthlyStatsCard(monthSummary, currentMonth, activeMeals, groupColor),
          const SizedBox(height: 14),

          // 4. Quick 1-Click Bulk Action Buttons
          _buildQuickBulkActions(context, board, currentMonth, activeMeals, groupColor),
          const SizedBox(height: 16),

          // 5. Calendar Grid
          _buildCalendarSection(board, currentMonth, selectedDate, activeMeals, groupColor),
          const SizedBox(height: 16),

          // 6. Selected Date Detail & Individual Meal Toggle Controls
          _buildSelectedDateMealControls(
            context,
            board,
            selectedDate,
            selectedDateStr,
            selectedDayStatus,
            activeMeals,
            groupColor,
          ),
          const SizedBox(height: 30),
        ],
      );
    });
  }

  // Format month and year
  String _formatMonthYear(DateTime date) {
    const bnMonths = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    final isBn = Get.locale?.languageCode != 'en';
    if (isBn) {
      return '${bnMonths[date.month - 1]} ${date.year}';
    }
    return DateFormat('MMMM yyyy').format(date);
  }

  // Format date full with day name
  String _formatDateFull(DateTime date) {
    const bnMonths = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    const bnWeekdays = [
      'সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার', 'রবিবার'
    ];
    final isBn = Get.locale?.languageCode != 'en';
    if (isBn) {
      final dayName = bnWeekdays[date.weekday - 1];
      final monthName = bnMonths[date.month - 1];
      return '${date.day} $monthName, ${date.year} ($dayName)';
    }
    return DateFormat('d MMMM, yyyy (EEEE)').format(date);
  }

  // Group Months Pills
  Widget _buildGroupMonthsPills(BoardModel board, DateTime currentMonth, Color groupColor) {
    final currentMonthKey = DateFormat('yyyy-MM').format(currentMonth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range_rounded, size: 14, color: groupColor),
              const SizedBox(width: 6),
              Text(
                'active_group_months'.tr,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: board.selectedMonths.map((mKey) {
                final isSelected = mKey == currentMonthKey;
                // Parse year-month
                final parts = mKey.split('-');
                final y = int.tryParse(parts[0]) ?? currentMonth.year;
                final m = parts.length > 1 ? int.tryParse(parts[1]) ?? currentMonth.month : 1;
                final monthDate = DateTime(y, m, 1);
                final label = _formatMonthYear(monthDate);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      mealController.setPlannerMonth(monthDate);
                      mealController.setPlannerDate(DateTime(y, m, 1));
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? groupColor : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? groupColor : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Custom Date Range Banner
  Widget _buildCustomDateBanner(BoardModel board, Color groupColor) {
    final startStr = DateFormat('d MMM yyyy').format(board.startDate!);
    final endStr = DateFormat('d MMM yyyy').format(board.endDate!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: groupColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: groupColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_note_rounded, size: 16, color: groupColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${'custom_date_range'.tr}: $startStr - $endStr',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: groupColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Month Navigation Header
  Widget _buildMonthNavigationHeader(DateTime currentMonth, Color groupColor) {
    final now = DateTime.now();
    final isCurrentMonth = currentMonth.year == now.year && currentMonth.month == now.month;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 26, color: Color(0xFF1E293B)),
            onPressed: () {
              final prevMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
              mealController.setPlannerMonth(prevMonth);
            },
            tooltip: 'পূর্ববর্তী মাস',
          ),
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: groupColor, size: 20),
              const SizedBox(width: 8),
              Text(
                _formatMonthYear(currentMonth),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (!isCurrentMonth) ...[
                const SizedBox(width: 10),
                InkWell(
                  onTap: () {
                    mealController.setPlannerMonth(now);
                    mealController.setPlannerDate(now);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: groupColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'current_month'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: groupColor,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 26, color: Color(0xFF1E293B)),
            onPressed: () {
              final nextMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
              mealController.setPlannerMonth(nextMonth);
            },
            tooltip: 'পরবর্তী মাস',
          ),
        ],
      ),
    );
  }

  // Monthly Stats Summary Card
  Widget _buildMonthlyStatsCard(
    Map<String, dynamic> summary,
    DateTime currentMonth,
    List<MealTypeModel> activeMeals,
    Color groupColor,
  ) {
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final activeDays = summary['totalActiveDays'] as int? ?? 0;
    final totalMeals = summary['totalMeals'] as int? ?? 0;
    final breakdown = summary['mealBreakdown'] as Map<String, int>? ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            groupColor,
            groupColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: groupColor.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.insights_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'মাসের মিল সারাংশ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$activeDays / $daysInMonth দিন',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'total_eating_days'.tr,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$activeDays দিন',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'total_meals_count'.tr,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$totalMeals টি মিল',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (activeMeals.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: activeMeals.map((meal) {
                final count = breakdown[meal.id] ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(meal.iconData, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${meal.name}: $count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // Quick 1-Click Bulk Action Buttons
  Widget _buildQuickBulkActions(
    BuildContext context,
    BoardModel board,
    DateTime currentMonth,
    List<MealTypeModel> activeMeals,
    Color groupColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on_rounded, size: 18, color: Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              Text(
                'bulk_select_title'.tr,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 1. All Month ON
                _buildBulkActionChip(
                  icon: Icons.check_circle_rounded,
                  label: 'all_month_eat'.tr,
                  color: const Color(0xFF059669),
                  bgColor: const Color(0xFFECFDF5),
                  onTap: () => _applyBulkAction(
                    board: board,
                    month: currentMonth,
                    willEat: true,
                  ),
                ),
                const SizedBox(width: 8),

                // 2. All Month OFF
                _buildBulkActionChip(
                  icon: Icons.cancel_rounded,
                  label: 'all_month_stop'.tr,
                  color: const Color(0xFFDC2626),
                  bgColor: const Color(0xFFFEF2F2),
                  onTap: () => _applyBulkAction(
                    board: board,
                    month: currentMonth,
                    willEat: false,
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Weekdays Only (Sun-Thu)
                _buildBulkActionChip(
                  icon: Icons.work_rounded,
                  label: 'weekdays_only'.tr,
                  color: const Color(0xFF0284C7),
                  bgColor: const Color(0xFFF0F9FF),
                  onTap: () => _applyBulkAction(
                    board: board,
                    month: currentMonth,
                    willEat: true,
                    weekdaysOnly: true,
                  ),
                ),
                const SizedBox(width: 8),

                // 4. From Today to End
                _buildBulkActionChip(
                  icon: Icons.fast_forward_rounded,
                  label: 'today_to_end'.tr,
                  color: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFFFBEB),
                  onTap: () => _applyBulkAction(
                    board: board,
                    month: currentMonth,
                    willEat: true,
                    fromTodayOnly: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyBulkAction({
    required BoardModel board,
    required DateTime month,
    required bool willEat,
    bool weekdaysOnly = false,
    bool fromTodayOnly = false,
  }) async {
    await mealController.setMonthMealsBulk(
      boardId: board.id,
      month: month,
      willEat: willEat,
      weekdaysOnly: weekdaysOnly,
      fromTodayOnly: fromTodayOnly,
    );

    Get.snackbar(
      'success'.tr,
      'bulk_applied_success'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF0F172A),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
    );
  }

  // Calendar Section
  Widget _buildCalendarSection(
    BoardModel board,
    DateTime currentMonth,
    DateTime selectedDate,
    List<MealTypeModel> activeMeals,
    Color groupColor,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final leadingEmptyCount = firstDayOfMonth.weekday % 7; // Sunday = 0, Monday = 1, etc.

    final weekDays = Get.locale?.languageCode == 'en'
        ? ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
        : ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with hint
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'মাসিক ক্যালেন্ডার',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                'select_date_hint'.tr,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Weekday header
          Row(
            children: List.generate(7, (index) {
              final isWeekend = index == 5 || index == 6; // Friday & Saturday
              return Expanded(
                child: Center(
                  child: Text(
                    weekDays[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isWeekend ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              );
            }),
          ),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),

          // Calendar Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingEmptyCount + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (context, index) {
              if (index < leadingEmptyCount) {
                return const SizedBox.shrink();
              }

              final dayNum = index - leadingEmptyCount + 1;
              final cellDate = DateTime(currentMonth.year, currentMonth.month, dayNum);
              final cellDateStr = DateFormat('yyyy-MM-dd').format(cellDate);

              final isToday = cellDate.year == today.year &&
                  cellDate.month == today.month &&
                  cellDate.day == today.day;

              final isSelected = cellDate.year == selectedDate.year &&
                  cellDate.month == selectedDate.month &&
                  cellDate.day == selectedDate.day;

              final status = mealController.getUserDateStatus(
                boardId: board.id,
                dateStr: cellDateStr,
                meals: activeMeals,
              );

              final isAllEat = status['isAllEat'] as bool;
              final isPartialEat = status['isPartialEat'] as bool;
              final willEatCount = status['willEatCount'] as int;
              final totalActive = status['totalActiveMeals'] as int;

              Color cellBg;
              Color borderColor;
              if (isSelected) {
                cellBg = groupColor.withValues(alpha: 0.12);
                borderColor = groupColor;
              } else if (isAllEat) {
                cellBg = const Color(0xFFECFDF5);
                borderColor = const Color(0xFF6EE7B7);
              } else if (isPartialEat) {
                cellBg = const Color(0xFFFEF3C7);
                borderColor = const Color(0xFFFCD34D);
              } else {
                cellBg = const Color(0xFFFAFAFA);
                borderColor = const Color(0xFFE2E8F0);
              }

              return InkWell(
                onTap: () {
                  mealController.setPlannerDate(cellDate);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: cellBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? groupColor : borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: groupColor.withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Day number
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? groupColor
                              : (isToday ? const Color(0xFF0F172A) : const Color(0xFF334155)),
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Status badge
                      if (isAllEat)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$willEatCount/$totalActive',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else if (isPartialEat)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$willEatCount/$totalActive',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(
                color: const Color(0xFF10B981),
                label: 'day_status_all'.tr,
              ),
              _buildLegendItem(
                color: const Color(0xFFF59E0B),
                label: 'day_status_partial'.tr,
              ),
              _buildLegendItem(
                color: const Color(0xFF94A3B8),
                label: 'day_status_off'.tr,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // Selected Date Meal Controls Panel
  Widget _buildSelectedDateMealControls(
    BuildContext context,
    BoardModel board,
    DateTime selectedDate,
    String selectedDateStr,
    Map<String, dynamic> status,
    List<MealTypeModel> activeMeals,
    Color groupColor,
  ) {
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    final willEatMealIds = status['willEatMealIds'] as Set<String>? ?? <String>{};
    final isAllEat = status['isAllEat'] as bool? ?? false;
    final willEatCount = status['willEatCount'] as int? ?? 0;
    final totalActive = status['totalActiveMeals'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: groupColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Selected Date Title and All Toggle Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatDateFull(selectedDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'আজ',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$willEatCount / $totalActive টি মিল চালু রয়েছে',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: willEatCount > 0 ? const Color(0xFF059669) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // Day Toggle Button (All on / all off)
              InkWell(
                onTap: () async {
                  await mealController.toggleDayAllMeals(
                    boardId: board.id,
                    dateStr: selectedDateStr,
                    meals: activeMeals,
                    targetStatus: !isAllEat,
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAllEat ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isAllEat ? const Color(0xFFF87171) : const Color(0xFF34D399),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAllEat ? Icons.cancel_outlined : Icons.check_circle_outline_rounded,
                        size: 14,
                        color: isAllEat ? const Color(0xFFDC2626) : const Color(0xFF059669),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAllEat ? 'সব বন্ধ' : 'সব চালু',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isAllEat ? const Color(0xFFDC2626) : const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          // List of individual meals
          if (activeMeals.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'কোনো সক্রিয় মিল পাওয়া যায়নি',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            )
          else
            Column(
              children: activeMeals.map((meal) {
                final willEat = willEatMealIds.contains(meal.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: willEat
                        ? meal.defaultColor.withValues(alpha: 0.06)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: willEat
                          ? meal.defaultColor.withValues(alpha: 0.3)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Meal Icon
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: meal.defaultColor.withValues(alpha: 0.15),
                        child: Icon(meal.iconData, size: 16, color: meal.defaultColor),
                      ),
                      const SizedBox(width: 10),

                      // Meal Name & Time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meal.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (meal.time.isNotEmpty)
                              Text(
                                meal.time,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Toggle Buttons (খাবো / খাবো না)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Vote Yes Button
                          InkWell(
                            onTap: () async {
                              final statusMap = <String, bool>{};
                              for (final m in activeMeals) {
                                statusMap[m.id] = willEatMealIds.contains(m.id);
                              }
                              statusMap[meal.id] = true;
                              await mealController.setDayMeals(
                                boardId: board.id,
                                dateStr: selectedDateStr,
                                mealStatus: statusMap,
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: willEat ? const Color(0xFF059669) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: willEat ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_rounded,
                                    size: 13,
                                    color: willEat ? Colors.white : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'vote_yes'.tr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: willEat ? Colors.white : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Vote No Button
                          InkWell(
                            onTap: () async {
                              final statusMap = <String, bool>{};
                              for (final m in activeMeals) {
                                statusMap[m.id] = willEatMealIds.contains(m.id);
                              }
                              statusMap[meal.id] = false;
                              await mealController.setDayMeals(
                                boardId: board.id,
                                dateStr: selectedDateStr,
                                mealStatus: statusMap,
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: !willEat ? const Color(0xFFDC2626) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: !willEat ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.close_rounded,
                                    size: 13,
                                    color: !willEat ? Colors.white : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'vote_no'.tr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: !willEat ? Colors.white : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: DAILY MEAL SHEET (কার কবে মিল হবে)
  // ==========================================
  Widget _buildMealSheetTab(
    BuildContext context,
    BoardModel board,
    List<MealTypeModel> meals,
    Color groupColor,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Upcoming feature banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [groupColor, groupColor.withValues(alpha: 0.85)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: groupColor.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.date_range_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'কার কবে মিল হবে শিডিউল',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'মাসিক মিল তালিকা ও মেম্বার প্ল্যানিং',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'daily_meal_plan_notice'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Overview of members & active meal slots
        Text(
          'মেম্বার ও মিলের তালিকা (${board.members.length} জন সদস্য)',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),

        // Member meal matrix preview
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              // Header Row showing meal names
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 4,
                      child: Text(
                        'সদস্যের নাম',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                    ),
                    ...meals.take(3).map((m) {
                      return Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            m.name,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Member rows with indicator chips
              ...board.members.map((member) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              member.roleDisplayNameKey.tr,
                              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      ...meals.take(3).map((m) {
                        return Expanded(
                          flex: 2,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '১',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
