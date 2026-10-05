import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/board_controller.dart';
import '../../data/models/member_model.dart';
import '../../theme/app_theme.dart';

class AddMemberDialog extends StatefulWidget {
  final Function(String name, String phone, MemberRole role) onAdd;

  const AddMemberDialog({super.key, required this.onAdd});

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  MemberRole _selectedRole = MemberRole.member;

  bool _userFound = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '').trim();
    if (cleanPhone.length >= 7) {
      final boardController = Get.find<BoardController>();
      final found = boardController.findUserByPhone(cleanPhone);

      setState(() {
        if (found != null) {
          _userFound = true;
          _nameController.text = found['name'] ?? '';
        } else {
          _userFound = false;
        }
      });
    } else {
      if (_userFound) {
        setState(() {
          _userFound = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'add_member'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Phone Number Field with Auto Search
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'member_phone'.tr,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                    if (_userFound)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'user_found'.tr,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  onChanged: _onPhoneChanged,
                  decoration: InputDecoration(
                    hintText: 'member_phone_hint'.tr,
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    helperText: 'phone_search_hint'.tr,
                    helperStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ),
                const SizedBox(height: 14),

                // Member Name Field (Auto-filled but editable by manager)
                Text(
                  'member_name'.tr,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'error_empty_name'.tr;
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'member_name_hint'.tr,
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                    suffixIcon: _nameController.text.isNotEmpty
                        ? const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF94A3B8))
                        : null,
                  ),
                ),
                const SizedBox(height: 18),

                // Role Selector with Visual Cards
                Text(
                  'role'.tr,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 8),

                // Role Cards
                _buildRoleOption(
                  role: MemberRole.member,
                  title: 'member'.tr,
                  icon: Icons.person_outline_rounded,
                  color: const Color(0xFF64748B),
                ),
                const SizedBox(height: 6),
                _buildRoleOption(
                  role: MemberRole.coManager,
                  title: 'co_manager'.tr,
                  icon: Icons.supervisor_account_rounded,
                  color: AppColors.secondary,
                ),
                const SizedBox(height: 22),

                // Dialog Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        child: Text('cancel'.tr, style: const TextStyle(color: Color(0xFF64748B))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            widget.onAdd(_nameController.text, _phoneController.text, _selectedRole);
                            Get.back();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'save'.tr,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required MemberRole role,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? color : const Color(0xFF64748B)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? color : const Color(0xFF1E293B),
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 18)
            else
              const Icon(Icons.radio_button_unchecked_rounded, color: Color(0xFFCBD5E1), size: 18),
          ],
        ),
      ),
    );
  }
}
