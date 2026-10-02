import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/board_controller.dart';
import '../../data/models/member_model.dart';
import '../../theme/app_theme.dart';

class EditMemberDialog extends StatefulWidget {
  final String boardId;
  final MemberModel member;

  const EditMemberDialog({
    super.key,
    required this.boardId,
    required this.member,
  });

  @override
  State<EditMemberDialog> createState() => _EditMemberDialogState();
}

class _EditMemberDialogState extends State<EditMemberDialog> {
  late TextEditingController _nameController;
  late MemberRole _selectedRole;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _selectedRole = widget.member.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final boardController = Get.find<BoardController>();
    boardController.updateMemberRole(
      boardId: widget.boardId,
      memberId: widget.member.id,
      newRole: _selectedRole,
      newName: _nameController.text.trim(),
    );

    Get.back();
    Get.snackbar(
      'success'.tr,
      'member_updated_success'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF0F172A),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.check_circle_rounded, color: AppColors.primaryLight),
    );
  }

  void _removeMember() {
    Get.defaultDialog(
      title: 'remove_member'.tr,
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      middleText: 'confirm_remove_member'.tr,
      textConfirm: 'delete'.tr,
      textCancel: 'cancel'.tr,
      confirmTextColor: Colors.white,
      buttonColor: AppColors.danger,
      onConfirm: () {
        final boardController = Get.find<BoardController>();
        boardController.removeMember(
          boardId: widget.boardId,
          memberId: widget.member.id,
        );
        Get.back(); // close confirm dialog
        Get.back(); // close edit dialog
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'edit_member'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Name Field
            Text(
              'member_name'.tr,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                hintText: 'member_name_hint'.tr,
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
              ),
            ),
            const SizedBox(height: 14),

            // Role Selector Dropdown
            Text(
              'role'.tr,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<MemberRole>(
                  value: _selectedRole,
                  isExpanded: true,
                  items: MemberRole.values.map((role) {
                    return DropdownMenuItem<MemberRole>(
                      value: role,
                      child: Text(
                        role == MemberRole.manager
                            ? 'manager'.tr
                            : role == MemberRole.coManager
                                ? 'co_manager'.tr
                                : 'member'.tr,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onChanged: (newRole) {
                    if (newRole != null) {
                      setState(() => _selectedRole = newRole);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons Row: Delete Icon + Save Button
            Row(
              children: [
                IconButton(
                  onPressed: _removeMember,
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 22),
                  tooltip: 'remove_member'.tr,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'save'.tr,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
