import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';

class MediaView extends StatelessWidget {
  const MediaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'nav_media'.tr,
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
          // Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF047857)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'media_title'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'media_subtitle'.tr,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Button
          ElevatedButton.icon(
            onPressed: () {
              Get.snackbar(
                'nav_media'.tr,
                'upload_receipt'.tr,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: const Color(0xFF0F172A),
                colorText: Colors.white,
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
                icon: const Icon(Icons.check_circle_outline, color: AppColors.primaryLight),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.upload_file_rounded, size: 20),
            label: Text(
              'upload_receipt'.tr,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),

          // Sample recent files
          const Text(
            'সাম্প্রতিক ডকুমেন্টস (Recent)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 10),

          _buildDocTile(
            icon: Icons.receipt_rounded,
            color: Colors.amber.shade700,
            title: 'আজকের বাজার রশিদ (চাল, ডাল, তেল)',
            sub: 'ধানমন্ডি মেস • ২ অক্টোবর ২০২৬',
            size: '১.২ MB',
          ),
          _buildDocTile(
            icon: Icons.table_chart_rounded,
            color: Colors.blue.shade700,
            title: 'অক্টোবর মাসের মিল শিট (Meal Sheet)',
            sub: 'ধানমন্ডি মেস • ১ অক্টোবর ২০২৬',
            size: '৫২০ KB',
          ),
          _buildDocTile(
            icon: Icons.campaign_rounded,
            color: Colors.purple.shade700,
            title: 'মেসের নতুন নিয়মাবলী নোটিশ',
            sub: 'মিরপুর মেস • ২৮ সেপ্টেম্বর ২০২৬',
            size: '৩৪০ KB',
          ),
        ],
      ),
    );
  }

  Widget _buildDocTile({
    required IconData icon,
    required Color color,
    required String title,
    required String sub,
    required String size,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        trailing: Text(
          size,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}
