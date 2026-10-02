import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_profile_controller.dart';
import '../../controllers/language_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

class MoreView extends StatelessWidget {
  const MoreView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthProfileController>();
    final langController = Get.find<LanguageController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'nav_more'.tr,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Banner
          Obx(() {
            final user = authController.user.value;
            final isManager = user?.preferredRole == 'manager';

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      (user?.name.isNotEmpty ?? false) ? user!.name[0] : 'U',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'User',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.phone ?? '01700000000',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isManager ? AppColors.primary.withValues(alpha: 0.12) : AppColors.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isManager ? 'manager'.tr : 'member'.tr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isManager ? AppColors.primary : AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                    onPressed: () => Get.toNamed(AppRoutes.profile),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),

          // Settings Section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                // Profile Edit ListTile
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                  title: Text('edit_profile'.tr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                  onTap: () => Get.toNamed(AppRoutes.profile),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // Language Switch ListTile
                Obx(() => ListTile(
                      leading: const Icon(Icons.language_rounded, color: AppColors.secondary),
                      title: Text('language'.tr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(
                        langController.isBangla ? 'বাংলা (ডিফল্ট)' : 'English',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      trailing: Switch.adaptive(
                        value: !langController.isBangla,
                        activeTrackColor: AppColors.secondary,
                        onChanged: (val) => langController.toggleLanguage(),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About & Developer Branding
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Match Manager',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, color: AppColors.primaryLight, size: 15),
                      SizedBox(width: 6),
                      Text(
                        'Developed by Learn with Noman',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
