import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/board_controller.dart';
import '../../data/models/board_model.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

class GroupsView extends StatelessWidget {
  const GroupsView({super.key});

  @override
  Widget build(BuildContext context) {
    final boardController = Get.find<BoardController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'nav_groups'.tr,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.login_rounded, color: AppColors.secondary),
            tooltip: 'join_group'.tr,
            onPressed: () => Get.toNamed(AppRoutes.joinBoard),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            tooltip: 'create_group'.tr,
            onPressed: () => Get.toNamed(AppRoutes.createBoard),
          ),
        ],
      ),
      body: Obx(() {
        final myBoards = boardController.myBoards;
        final joinedBoards = boardController.joinedBoards;

        if (myBoards.isEmpty && joinedBoards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cottage_rounded, size: 48, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  'no_boards_title'.tr,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.createBoard),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text('create_group'.tr),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Action Banner
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Get.toNamed(AppRoutes.createBoard),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'create_group'.tr,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => Get.toNamed(AppRoutes.joinBoard),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.qr_code_rounded, color: AppColors.secondary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'join_group'.tr,
                            style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // My Groups
            if (myBoards.isNotEmpty) ...[
              Text(
                'my_groups'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 10),
              ...myBoards.map((b) => _buildGroupCard(b, true)),
              const SizedBox(height: 16),
            ],

            // Joined Groups
            if (joinedBoards.isNotEmpty) ...[
              Text(
                'joined_groups'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 10),
              ...joinedBoards.map((b) => _buildGroupCard(b, false)),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildGroupCard(BoardModel board, bool isOwner) {
    final color = Color(board.themeColorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: () {
          Get.toNamed(AppRoutes.boardDetail, arguments: board.id);
        },
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.restaurant_rounded, color: color, size: 24),
        ),
        title: Text(
          board.title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          '${board.members.length} ${'members'.tr} • ${board.periodDisplayName}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                board.boardCode,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
