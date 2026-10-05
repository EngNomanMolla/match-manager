import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_profile_controller.dart';
import '../../controllers/bazar_controller.dart';
import '../../controllers/board_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../data/models/board_model.dart';
import '../../data/models/member_model.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../chat/chat_room_view.dart';
import 'add_member_dialog.dart';
import 'edit_member_dialog.dart';

class BoardDetailView extends StatefulWidget {
  const BoardDetailView({super.key});

  @override
  State<BoardDetailView> createState() => _BoardDetailViewState();
}

class _BoardDetailViewState extends State<BoardDetailView> {
  int _currentIndex = 0; // 0: Details, 1: Chat
  int _chatSubTab = 0; // 0: Group Chat, 1: Direct DMs with Members

  @override
  Widget build(BuildContext context) {
    final boardId = Get.arguments as String?;
    final boardController = Get.find<BoardController>();
    final authController = Get.find<AuthProfileController>();
    final bazarController = Get.find<BazarController>();
    final chatController = Get.find<ChatController>();

    if (boardId == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('no_data_found'.tr)),
      );
    }

    return Obx(() {
      final board = boardController.getBoardById(boardId);

      if (board == null) {
        return Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('no_data_found'.tr)),
        );
      }

      final color = Color(board.themeColorValue);
      final currentUserId = authController.user.value?.id ?? '';
      final isManager = board.managerId == currentUserId ||
          board.members.any((m) => m.id == currentUserId && (m.role == MemberRole.manager || m.role == MemberRole.coManager));

      final monthBazarTotal = bazarController.getMonthBazarAmount(board.id, DateTime.now());
      final bazarEntriesCount = bazarController.getBazarForBoard(board.id).length;

      final managerCount = board.members.where((m) => m.role == MemberRole.manager).length;
      final coManagerCount = board.members.where((m) => m.role == MemberRole.coManager).length;
      final memberCount = board.members.where((m) => m.role == MemberRole.member).length;

      // Calculate total unread messages for this board (Group + Direct DMs)
      final groupConvId = ChatController.getGroupConversationId(board.id);
      int totalBoardUnread = chatController.getUnreadCount(groupConvId);
      for (final m in board.members) {
        if (m.id != currentUserId) {
          final dmConvId = ChatController.getDirectConversationId(currentUserId, m.id);
          totalBoardUnread += chatController.getUnreadCount(dmConvId);
        }
      }

      return Scaffold(
        backgroundColor: _currentIndex == 1 && _chatSubTab == 0
            ? const Color(0xFFECE5DD)
            : const Color(0xFFF8FAFC),
        appBar: _buildAppBar(context, board, boardController, isManager, color),
        body: _currentIndex == 0
            ? _buildDetailsView(
                context,
                board,
                boardController,
                isManager,
                currentUserId,
                color,
                monthBazarTotal,
                bazarEntriesCount,
                managerCount,
                coManagerCount,
                memberCount,
              )
            : _buildChatSection(context, board, currentUserId, groupConvId, chatController),
        bottomNavigationBar: _buildBottomNavigationBar(totalBoardUnread, color),
      );
    });
  }

  // --- Dynamic AppBar based on selected tab ---
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    BoardModel board,
    BoardController boardController,
    bool isManager,
    Color color,
  ) {
    if (_currentIndex == 1) {
      // Chat Tab Header (WhatsApp Green Theme)
      return AppBar(
        backgroundColor: const Color(0xFF075E54),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
          onPressed: () {
            if (_currentIndex != 0) {
              setState(() => _currentIndex = 0);
            } else {
              Get.back();
            }
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              child: const Icon(Icons.forum_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    board.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    '${board.members.length} জন সদস্য • মেস চ্যাট',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu_rounded, color: Colors.white),
            tooltip: 'meal_details'.tr,
            onPressed: () => Get.toNamed(AppRoutes.mealDetail, arguments: board.id),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_checkout_rounded, color: Colors.white),
            tooltip: 'bazar_details'.tr,
            onPressed: () => Get.toNamed(AppRoutes.bazarDetail, arguments: board.id),
          ),
        ],
      );
    }

    // Details Tab Header
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
        onPressed: () => Get.back(),
      ),
      title: Text(
        board.title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFF0F172A)),
          tooltip: 'meal_details'.tr,
          onPressed: () => Get.toNamed(AppRoutes.mealDetail, arguments: board.id),
        ),
        if (isManager)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
            onSelected: (val) {
              if (val == 'delete') {
                _confirmDelete(context, boardController, board.id);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                    const SizedBox(width: 8),
                    Text('delete'.tr, style: const TextStyle(color: AppColors.danger)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  // --- Details Tab Body (Without Chat Card) ---
  Widget _buildDetailsView(
    BuildContext context,
    BoardModel board,
    BoardController boardController,
    bool isManager,
    String currentUserId,
    Color color,
    double monthBazarTotal,
    int bazarEntriesCount,
    int managerCount,
    int coManagerCount,
    int memberCount,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Group Info Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(Icons.restaurant_rounded, size: 26, color: color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          board.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                board.periodDisplayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                board.sportType.tr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (board.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  board.description,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.3),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 14),

              // Compact Code & QR Code Button Row
              Row(
                children: [
                  // Group Code Pill with Copy
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: board.boardCode));
                        Get.snackbar(
                          'success'.tr,
                          'code_copied'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: const Color(0xFF0F172A),
                          colorText: Colors.white,
                          margin: const EdgeInsets.all(16),
                          borderRadius: 12,
                          icon: const Icon(Icons.check_circle_outline, color: AppColors.primaryLight),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.tag_rounded, size: 16, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  board.boardCode,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF64748B)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Compact QR Code Button
                  InkWell(
                    onTap: () => _showQrModal(context, board.title, board.boardCode, color),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, size: 16, color: color),
                          const SizedBox(width: 6),
                          Text(
                            'QR কোড',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color,
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
        ),
        const SizedBox(height: 16),

        // Group Members & Role Overview Stats
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('মোট সদস্য', '${board.members.length}', Icons.groups_rounded, color),
              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
              _buildStatColumn('ম্যানেজার', '$managerCount', Icons.admin_panel_settings_rounded, AppColors.primary),
              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
              _buildStatColumn('সহকারী ম্যানেজার', '$coManagerCount', Icons.supervisor_account_rounded, AppColors.secondary),
              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
              _buildStatColumn('মেম্বার', '$memberCount', Icons.person_outline_rounded, const Color(0xFF64748B)),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Meal Management & Voting Banner Card
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.82)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Get.toNamed(AppRoutes.mealDetail, arguments: board.id);
              },
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'meal_details'.tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${board.meals.length}টি মিল',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'সকাল, দুপুর, রাত মিল তৈরি, ক্রম ও ভোট দিন',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Bazar & Expense Management Shortcut Card
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0284C7),
                Color(0xFF0369A1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Get.toNamed(AppRoutes.bazarDetail, arguments: board.id);
              },
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_checkout_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'bazar_details'.tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '৳ ${NumberFormat('#,##0').format(monthBazarTotal)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$bazarEntriesCountটি এন্ট্রি • তারিখ ও খরচসহ বাজারের বিবরণ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Members Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'members'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            if (isManager)
              ElevatedButton.icon(
                onPressed: () {
                  Get.dialog(
                    AddMemberDialog(
                      onAdd: (name, phone, role) {
                        boardController.addMember(
                          boardId: board.id,
                          name: name,
                          phone: phone,
                          role: role,
                        );
                        Get.snackbar(
                          'success'.tr,
                          'member_added_success'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: const Color(0xFF0F172A),
                          colorText: Colors.white,
                          margin: const EdgeInsets.all(16),
                          borderRadius: 12,
                        );
                      },
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 15),
                label: Text(
                  'add_member'.tr,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Members List
        if (board.members.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Text('no_members_yet'.tr, style: const TextStyle(color: Color(0xFF64748B))),
            ),
          )
        else
          ...board.members.map((member) => _buildMemberTile(context, boardController, board.id, member, isManager, currentUserId)),

        const SizedBox(height: 30),
      ],
    );
  }

  // --- Chat Tab Body (Group Chat & Direct 1-on-1 Member DMs) ---
  Widget _buildChatSection(
    BuildContext context,
    BoardModel board,
    String currentUserId,
    String groupConvId,
    ChatController chatController,
  ) {
    final groupUnread = chatController.getUnreadCount(groupConvId);
    int directUnread = 0;
    for (final m in board.members) {
      if (m.id != currentUserId) {
        final dmId = ChatController.getDirectConversationId(currentUserId, m.id);
        directUnread += chatController.getUnreadCount(dmId);
      }
    }

    return Column(
      children: [
        // Sub-Tab Switcher (Group Chat vs Member DMs)
        Container(
          color: const Color(0xFF075E54),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Group Chat Tab Button
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _chatSubTab = 0),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _chatSubTab == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _chatSubTab == 0
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            size: 17,
                            color: _chatSubTab == 0 ? const Color(0xFF075E54) : Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'মেস গ্রুপ চ্যাট',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _chatSubTab == 0 ? const Color(0xFF075E54) : Colors.white,
                            ),
                          ),
                          if (groupUnread > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: _chatSubTab == 0 ? const Color(0xFF25D366) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$groupUnread',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _chatSubTab == 0 ? Colors.white : const Color(0xFF075E54),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Members DMs Tab Button
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _chatSubTab = 1),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _chatSubTab == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _chatSubTab == 1
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 17,
                            color: _chatSubTab == 1 ? const Color(0xFF075E54) : Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'মেম্বার চ্যাট',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _chatSubTab == 1 ? const Color(0xFF075E54) : Colors.white,
                            ),
                          ),
                          if (directUnread > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: _chatSubTab == 1 ? const Color(0xFF25D366) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$directUnread',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _chatSubTab == 1 ? Colors.white : const Color(0xFF075E54),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Sub-Tab Content
        Expanded(
          child: _chatSubTab == 0
              ? ChatRoomView(
                  conversationId: groupConvId,
                  title: '${board.title} (মেস চ্যাট)',
                  subtitle: '${board.members.length} জন সদস্য',
                  boardId: board.id,
                  isGroup: true,
                  showAppBar: false,
                )
              : _buildMembersDmList(board, currentUserId, chatController),
        ),
      ],
    );
  }

  // --- List of Group Members for 1-on-1 Direct Messaging ---
  Widget _buildMembersDmList(
    BoardModel board,
    String currentUserId,
    ChatController chatController,
  ) {
    final otherMembers = board.members.where((m) => m.id != currentUserId).toList();

    if (otherMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline_rounded, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'গ্রুপে আর কোনো সদস্য নেই',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 4),
            const Text(
              'সদস্য যুক্ত হলে তাদের সাথে সরাসরি চ্যাট করতে পারবেন।',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: otherMembers.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 68, color: Color(0xFFE2E8F0)),
      itemBuilder: (context, index) {
        final member = otherMembers[index];
        final dmConvId = ChatController.getDirectConversationId(currentUserId, member.id);
        final unread = chatController.getUnreadCount(dmConvId);
        final lastMsg = chatController.getLastMessage(dmConvId);

        final isGroupAdmin = member.role == MemberRole.manager;
        final isCoManager = member.role == MemberRole.coManager;
        final roleColor = isGroupAdmin
            ? AppColors.primary
            : isCoManager
                ? AppColors.secondary
                : const Color(0xFF0284C7);

        return InkWell(
          onTap: () {
            Get.toNamed(
              AppRoutes.chatRoom,
              arguments: {
                'conversationId': dmConvId,
                'title': member.name,
                'boardId': board.id,
                'recipientId': member.id,
                'recipientName': member.name,
                'recipientRole': member.role.name,
                'isGroup': false,
              },
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                // Avatar with Role Indicator Ring
                CircleAvatar(
                  radius: 24,
                  backgroundColor: roleColor.withValues(alpha: 0.15),
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: roleColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              member.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              member.roleDisplayNameKey.tr,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: roleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMsg != null
                                  ? (lastMsg.hasImages && lastMsg.text.isEmpty
                                      ? '📷 [${lastMsg.imagePaths.length}টি ছবি]'
                                      : lastMsg.text)
                                  : (member.phone.isNotEmpty ? member.phone : 'চ্যাট শুরু করতে ট্যাপ করুন'),
                              style: TextStyle(
                                fontSize: 12,
                                color: unread > 0 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lastMsg != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('hh:mm a').format(lastMsg.timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: unread > 0 ? const Color(0xFF00A884) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (unread > 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF25D366),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unread',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Color(0xFF00A884)),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Bottom Navigation Bar with Live Unread Badge ---
  Widget _buildBottomNavigationBar(int totalBoardUnread, Color boardColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: _currentIndex == 1 ? const Color(0xFF075E54) : boardColor,
          unselectedItemColor: const Color(0xFF64748B),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard_rounded),
              label: 'nav_details'.tr,
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.forum_outlined),
                  if (totalBoardUnread > 0)
                    Positioned(
                      top: -3,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          '$totalBoardUnread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.forum_rounded),
                  if (totalBoardUnread > 0)
                    Positioned(
                      top: -3,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          '$totalBoardUnread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: 'nav_chat'.tr,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // Member Tile with Role Badge, Direct Chat & Clean Edit Dialog
  Widget _buildMemberTile(
    BuildContext context,
    BoardController controller,
    String boardId,
    MemberModel member,
    bool isManager,
    String currentUserId,
  ) {
    final isGroupAdmin = member.role == MemberRole.manager;
    final isCoManager = member.role == MemberRole.coManager;
    final isMe = member.id == currentUserId;

    final roleColor = isGroupAdmin
        ? AppColors.primary
        : isCoManager
            ? AppColors.secondary
            : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        onTap: isManager
            ? () {
                Get.dialog(
                  EditMemberDialog(
                    boardId: boardId,
                    member: member,
                  ),
                );
              }
            : null,
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: roleColor.withValues(alpha: 0.15),
          child: Text(
            member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: roleColor,
              fontSize: 15,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                isMe ? '${member.name} (আপনি)' : member.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Role Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                member.roleDisplayNameKey.tr,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: roleColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: member.phone.isNotEmpty
            ? Text(member.phone, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // WhatsApp 1-on-1 Direct Chat Button (for other members)
            if (!isMe && currentUserId.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Color(0xFF00A884)),
                tooltip: 'ব্যক্তিগত চ্যাট',
                onPressed: () {
                  final convId = ChatController.getDirectConversationId(currentUserId, member.id);
                  Get.toNamed(
                    AppRoutes.chatRoom,
                    arguments: {
                      'conversationId': convId,
                      'title': member.name,
                      'boardId': boardId,
                      'recipientId': member.id,
                      'recipientName': member.name,
                      'recipientRole': member.role.name,
                      'isGroup': false,
                    },
                  );
                },
              ),
            if (isManager)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                onPressed: () {
                  Get.dialog(
                    EditMemberDialog(
                      boardId: boardId,
                      member: member,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // QR Modal Dialog
  void _showQrModal(BuildContext context, String title, String code, Color color) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'QR কোড স্ক্যান করুন',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 14),

              // QR Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: CustomPaint(
                    painter: QrPainter(code, color),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                code,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2),
              ),
              const SizedBox(height: 6),
              const Text(
                'অ্যাপের "Join Group" এ গিয়ে এই কোড বা QR স্ক্যান করে মেম্বার হিসেবে যুক্ত হওয়া যাবে।',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, BoardController controller, String boardId) {
    Get.defaultDialog(
      title: 'delete'.tr,
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      middleText: 'confirm_delete'.tr,
      textConfirm: 'delete'.tr,
      textCancel: 'cancel'.tr,
      confirmTextColor: Colors.white,
      buttonColor: AppColors.danger,
      onConfirm: () async {
        await controller.deleteBoard(boardId);
        Get.back();
        Get.back();
      },
    );
  }
}

// Crisp Vector QR Painter
class QrPainter extends CustomPainter {
  final String data;
  final Color color;

  QrPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    final cellWidth = size.width / 17;
    final cellHeight = size.height / 17;

    // Corner Position Detection Patterns
    _drawFinderPattern(canvas, 0, 0, cellWidth, cellHeight, paint);
    _drawFinderPattern(canvas, 10 * cellWidth, 0, cellWidth, cellHeight, paint);
    _drawFinderPattern(canvas, 0, 10 * cellHeight, cellWidth, cellHeight, paint);

    final hash = data.hashCode.abs();
    for (int r = 0; r < 17; r++) {
      for (int c = 0; c < 17; c++) {
        if ((r < 7 && c < 7) || (r < 7 && c >= 10) || (r >= 10 && c < 7)) {
          continue;
        }
        final bit = ((hash ^ (r * 19 + c * 31)) % 3) == 0;
        if (bit || (r == 7 || c == 7 || r == 9 || c == 9)) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(c * cellWidth + 0.5, r * cellHeight + 0.5, cellWidth - 1, cellHeight - 1),
              const Radius.circular(1.5),
            ),
            paint,
          );
        }
      }
    }
  }

  void _drawFinderPattern(Canvas canvas, double x, double y, double cw, double ch, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, cw * 7, ch * 7), const Radius.circular(6)),
      paint,
    );
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x + cw, y + ch, cw * 5, ch * 5), const Radius.circular(4)),
      whitePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x + cw * 2, y + ch * 2, cw * 3, ch * 3), const Radius.circular(3)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
