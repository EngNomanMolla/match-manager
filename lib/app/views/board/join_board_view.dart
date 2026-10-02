import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/board_controller.dart';
import '../../theme/app_theme.dart';

class JoinBoardView extends StatefulWidget {
  const JoinBoardView({super.key});

  @override
  State<JoinBoardView> createState() => _JoinBoardViewState();
}

class _JoinBoardViewState extends State<JoinBoardView> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      Get.snackbar(
        'error_empty_name'.tr,
        'error_invalid_code'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0F172A),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    setState(() => _isLoading = true);

    final boardController = Get.find<BoardController>();
    final success = await boardController.joinBoardByCode(code);

    setState(() => _isLoading = false);

    if (success) {
      boardController.selectedTab.value = 1; // switch to joined messes tab
      Get.back();
      Get.snackbar(
        'success'.tr,
        'board_joined_success'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0F172A),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.primaryLight),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'join_board'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.groups_rounded,
                    color: AppColors.secondary,
                    size: 42,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'join_with_code'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'অন্য কোনো মেস ম্যানেজারের শেয়ার করা মেস কোডটি এখানে লিখুন।',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Code Input Field
            Text(
              'board_code'.tr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                color: Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'MESS-XXXX',
                hintStyle: const TextStyle(
                  fontSize: 18,
                  letterSpacing: 2,
                  color: Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(Icons.qr_code_rounded, color: AppColors.secondary),
              ),
            ),
            const SizedBox(height: 28),

            // Join Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _join,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.login_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'join_board'.tr,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 40),
            // Tips Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.warning),
                      SizedBox(width: 6),
                      Text(
                        'টিপস / টেস্ট মেস কোড',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'যেকোনো মেস কোড দিয়ে আপনি মেম্বার হিসেবে সেই মেসে যুক্ত হতে পারবেন (যেমন: MESS-4910 বা MESS-7821)।',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
