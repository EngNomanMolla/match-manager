import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_profile_controller.dart';
import '../../controllers/bazar_controller.dart';
import '../../controllers/board_controller.dart';
import '../../data/models/bazar_model.dart';
import '../../data/models/board_model.dart';
import '../../theme/app_theme.dart';
import 'add_bazar_dialog.dart';

class BazarDetailView extends StatefulWidget {
  const BazarDetailView({super.key});

  @override
  State<BazarDetailView> createState() => _BazarDetailViewState();
}

class _BazarDetailViewState extends State<BazarDetailView> {
  final BazarController bazarController = Get.find<BazarController>();
  final BoardController boardController = Get.find<BoardController>();
  final AuthProfileController authController = Get.find<AuthProfileController>();

  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  String _formatDateHeader(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;

    const bnMonths = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    const bnWeekdays = [
      'সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার', 'রবিবার'
    ];

    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final isYesterday = date.year == now.year && date.month == now.month && date.day == now.day - 1;

    final isBn = Get.locale?.languageCode != 'en';
    if (isToday) return isBn ? 'আজকে (${date.day} ${bnMonths[date.month - 1]})' : 'Today (${DateFormat('d MMM').format(date)})';
    if (isYesterday) return isBn ? 'গতকাল (${date.day} ${bnMonths[date.month - 1]})' : 'Yesterday (${DateFormat('d MMM').format(date)})';

    if (isBn) {
      final dayName = bnWeekdays[date.weekday - 1];
      return '${date.day} ${bnMonths[date.month - 1]}, ${date.year} ($dayName)';
    }
    return DateFormat('d MMMM, yyyy (EEEE)').format(date);
  }

  String _formatCurrency(double amount) {
    if (amount % 1 == 0) {
      return NumberFormat('#,##0').format(amount);
    }
    return NumberFormat('#,##0.00').format(amount);
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'manager':
        return 'ম্যানেজার';
      case 'co_manager':
      case 'comanager':
        return 'সহকারী ম্যানেজার';
      default:
        return 'মেম্বার';
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'manager':
        return AppColors.primary;
      case 'co_manager':
      case 'comanager':
        return AppColors.secondary;
      default:
        return const Color(0xFF64748B);
    }
  }

  void _confirmDelete(BuildContext context, BoardModel board, BazarModel entry) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('বাজার মুছে ফেলুন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'আপনি কি নিশ্চিত "${entry.title}" (${_formatCurrency(entry.amount)} ৳) এন্ট্রিটি মুছে ফেলতে চান?',
          style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: const TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await bazarController.deleteBazarEntry(
                boardId: board.id,
                bazarId: entry.id,
              );
              Get.snackbar(
                'মুছে ফেলা হয়েছে',
                'বাজারের এন্ট্রিটি সফলভাবে রিমুভ করা হয়েছে',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: const Color(0xFF0F172A),
                colorText: Colors.white,
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('মুছে ফেলুন'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boardId = Get.arguments as String?;

    if (boardId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('বাজারের হিসাব')),
        body: Center(child: Text('no_data_found'.tr)),
      );
    }

    return Obx(() {
      final board = boardController.getBoardById(boardId);
      if (board == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('বাজারের হিসাব')),
          body: Center(child: Text('no_data_found'.tr)),
        );
      }

      final isManager = bazarController.isManagerOrCoManager(board);
      final groupColor = Color(board.themeColorValue);
      final currentMonth = bazarController.selectedMonth.value;

      final totalAllTime = bazarController.getTotalBazarAmount(board.id);
      final totalThisMonth = bazarController.getMonthBazarAmount(board.id, currentMonth);
      final totalToday = bazarController.getTodayBazarAmount(board.id);

      final groupedEntries = bazarController.getGroupedFilteredBazar(board.id);
      final totalFilteredEntries = bazarController.getFilteredBazarList(board.id).length;

      final shopperSummary = bazarController.getMemberShopperSummary(board.id, month: currentMonth);
      final categorySummary = bazarController.getCategorySummary(board.id, month: currentMonth);

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
              const Text(
                'বাজারের হিসাব ও তালিকা',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
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
            IconButton(
              icon: Icon(
                _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
                color: const Color(0xFF0F172A),
              ),
              onPressed: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchController.clear();
                    bazarController.setSearchQuery('');
                  }
                });
              },
              tooltip: 'সার্চ করুন',
            ),
            // User Role Tag
            Container(
              margin: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
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
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            bazarController.loadBazarList();
          },
          color: groupColor,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              // Search Field (if toggled)
              if (_showSearch) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: groupColor.withValues(alpha: 0.3)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'বাজারের নাম, মেম্বার বা আইটেম খুঁজুন...',
                      prefixIcon: Icon(Icons.search_rounded, color: groupColor),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                bazarController.setSearchQuery('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
                      bazarController.setSearchQuery(val);
                    },
                  ),
                ),
              ],

              // 1. Group Selected Months Navigation (if configured)
              if (board.periodType == 'months' && board.selectedMonths.isNotEmpty) ...[
                _buildGroupMonthsBar(board, currentMonth, groupColor),
                const SizedBox(height: 12),
              ],

              // 2. Month Selector Bar
              _buildMonthNavigator(currentMonth, groupColor),
              const SizedBox(height: 14),

              // 3. Overview Stats Banner Card
              _buildStatsBanner(
                totalThisMonth: totalThisMonth,
                totalToday: totalToday,
                totalAllTime: totalAllTime,
                totalEntries: totalFilteredEntries,
                groupColor: groupColor,
              ),
              const SizedBox(height: 16),

              // 4. Shopper Member Summary Carousel (কার মাধ্যমে কত টাকার বাজার হয়েছে)
              if (shopperSummary.isNotEmpty) ...[
                _buildShopperSummarySection(shopperSummary, totalThisMonth, groupColor),
                const SizedBox(height: 16),
              ],

              // 5. Category Breakdown (if any entries exist)
              if (categorySummary.isNotEmpty) ...[
                _buildCategorySummarySection(categorySummary, groupColor),
                const SizedBox(height: 16),
              ],

              // 6. Filter Chips (Categories & Shopper)
              _buildFilterChipsBar(board, groupColor),
              const SizedBox(height: 14),

              // 7. Grouped Bazar Entries List
              if (groupedEntries.isEmpty)
                _buildEmptyState(context, board, isManager, groupColor)
              else
                ...groupedEntries.entries.map((group) {
                  final dateStr = group.key;
                  final entries = group.value;
                  final dateTotal = entries.fold(0.0, (sum, e) => sum + e.amount);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Header with Total for the Day
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                                  Icon(Icons.event_available_rounded, size: 16, color: groupColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDateHeader(dateStr),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: groupColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'মোট: ৳ ${_formatCurrency(dateTotal)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: groupColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Entries for this date
                        ...entries.map((entry) => _buildBazarCard(context, board, entry, isManager, groupColor)),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 70), // Bottom padding for FAB
            ],
          ),
        ),
        // Floating Action Button (Only Manager & Co-Manager can add)
        floatingActionButton: isManager
            ? FloatingActionButton.extended(
                onPressed: () {
                  Get.dialog(
                    AddBazarDialog(board: board),
                  );
                },
                backgroundColor: groupColor,
                icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
                label: const Text(
                  'নতুন বাজার এন্ট্রি',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )
            : null,
      );
    });
  }

  // Group Months Bar (if configured on board)
  Widget _buildGroupMonthsBar(BoardModel board, DateTime currentMonth, Color groupColor) {
    final currentMonthKey = DateFormat('yyyy-MM').format(currentMonth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range_rounded, size: 14, color: groupColor),
          const SizedBox(width: 6),
          const Text(
            'গ্রুপের মাস:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: board.selectedMonths.map((mKey) {
                  final isSelected = mKey == currentMonthKey;
                  final parts = mKey.split('-');
                  final y = int.tryParse(parts[0]) ?? currentMonth.year;
                  final m = parts.length > 1 ? int.tryParse(parts[1]) ?? currentMonth.month : 1;
                  final monthDate = DateTime(y, m, 1);
                  final label = _formatMonthYear(monthDate);

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () {
                        bazarController.setSelectedMonth(monthDate);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? groupColor : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? groupColor : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
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
          ),
        ],
      ),
    );
  }

  // Month Navigator
  Widget _buildMonthNavigator(DateTime currentMonth, Color groupColor) {
    final now = DateTime.now();
    final isCurrentMonth = currentMonth.year == now.year && currentMonth.month == now.month;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
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
              final prev = DateTime(currentMonth.year, currentMonth.month - 1, 1);
              bazarController.setSelectedMonth(prev);
            },
            tooltip: 'পূর্ববর্তী মাস',
          ),
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: groupColor, size: 18),
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
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    bazarController.setSelectedMonth(now);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: groupColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'current_month'.tr,
                      style: TextStyle(
                        fontSize: 10,
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
              final next = DateTime(currentMonth.year, currentMonth.month + 1, 1);
              bazarController.setSelectedMonth(next);
            },
            tooltip: 'পরবর্তী মাস',
          ),
        ],
      ),
    );
  }

  // Stats Banner Card
  Widget _buildStatsBanner({
    required double totalThisMonth,
    required double totalToday,
    required double totalAllTime,
    required int totalEntries,
    required Color groupColor,
  }) {
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: groupColor.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 5),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'বাজার ব্যয়ের হিসাব',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$totalEntries টি এন্ট্রি',
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

          // Primary Focus: This Month Total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'চলতি মাসের মোট বাজার',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    SizedBox(height: 2),
                  ],
                ),
                Text(
                  '৳ ${_formatCurrency(totalThisMonth)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Secondary Sub-stats (Today & All Time)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'আজকের বাজার',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '৳ ${_formatCurrency(totalToday)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'সর্বমোট বাজার খরচ',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '৳ ${_formatCurrency(totalAllTime)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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
  }

  // Shopper Contribution Summary Section (কার মাধ্যমে কত বাজার হয়েছে)
  Widget _buildShopperSummarySection(
    Map<String, Map<String, dynamic>> summary,
    double totalMonth,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF475569)),
                  const SizedBox(width: 6),
                  const Text(
                    'সদস্যভিত্তিক বাজার খরচ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Text(
                '${summary.length} জন বাজার করেছেন',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: summary.values.map((item) {
                final name = item['name'] as String;
                final role = item['role'] as String;
                final total = item['totalAmount'] as double;
                final count = item['count'] as int;
                final isShopperFiltered = bazarController.selectedShopperMemberId.value == item['id'];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      if (isShopperFiltered) {
                        bazarController.setShopperFilter('all');
                      } else {
                        bazarController.setShopperFilter(item['id']);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isShopperFiltered ? groupColor.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isShopperFiltered ? groupColor : const Color(0xFFE2E8F0),
                          width: isShopperFiltered ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: _getRoleColor(role).withValues(alpha: 0.15),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'M',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getRoleColor(role)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(role).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getRoleDisplayName(role),
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: _getRoleColor(role),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '৳ ${_formatCurrency(total)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: groupColor,
                            ),
                          ),
                          Text(
                            '$count বার বাজার',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        ],
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

  // Category Breakdown Section
  Widget _buildCategorySummarySection(Map<BazarCategory, double> summary, Color groupColor) {
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
            children: const [
              Icon(Icons.category_rounded, size: 16, color: Color(0xFF475569)),
              SizedBox(width: 6),
              Text(
                'ক্যাটাগরিভিত্তিক খরচ',
                style: TextStyle(
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
              children: summary.entries.map((entry) {
                final cat = entry.key;
                final amount = entry.value;
                final isSelected = bazarController.selectedCategoryKey.value == cat.key;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      if (isSelected) {
                        bazarController.setCategoryFilter('all');
                      } else {
                        bazarController.setCategoryFilter(cat.key);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? cat.color : cat.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: cat.color.withValues(alpha: isSelected ? 1 : 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.iconData, size: 14, color: isSelected ? Colors.white : cat.color),
                          const SizedBox(width: 5),
                          Text(
                            '${cat.displayNameBn}: ৳ ${_formatCurrency(amount)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        ],
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

  // Filter Chips Bar (Category & Shopper filter)
  Widget _buildFilterChipsBar(BoardModel board, Color groupColor) {
    final selectedCat = bazarController.selectedCategoryKey.value;
    final selectedShopper = bazarController.selectedShopperMemberId.value;
    final isAnyFilterActive = selectedCat != 'all' || selectedShopper != 'all' || bazarController.searchQuery.value.isNotEmpty;

    return Row(
      children: [
        // "সকল" Chip
        InkWell(
          onTap: () => bazarController.resetFilters(),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: !isAnyFilterActive ? groupColor : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'সকল তালিকা',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: !isAnyFilterActive ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Quick Category Filter Dropdown / Chips
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...BazarCategory.values.map((cat) {
                  final isSelected = selectedCat == cat.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () {
                        bazarController.setCategoryFilter(isSelected ? 'all' : cat.key);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? cat.color : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? cat.color : const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat.iconData, size: 12, color: isSelected ? Colors.white : cat.color),
                            const SizedBox(width: 4),
                            Text(
                              cat.displayNameBn,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Individual Bazar Card
  Widget _buildBazarCard(
    BuildContext context,
    BoardModel board,
    BazarModel entry,
    bool isManager,
    Color groupColor,
  ) {
    final cat = entry.category;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category Icon + Title + Amount
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(cat.iconData, color: cat.color, size: 22),
                ),
                const SizedBox(width: 12),

                // Title and Category Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              cat.displayNameBn,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: cat.color,
                              ),
                            ),
                          ),
                          if (entry.note.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                entry.note,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Amount Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF6EE7B7)),
                  ),
                  child: Text(
                    '৳ ${_formatCurrency(entry.amount)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),

            // Items Tags (if breakdown exists)
            if (entry.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 5,
                runSpacing: 4,
                children: entry.items.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '• $item',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
              ),
            ],

            const Divider(height: 18, color: Color(0xFFF1F5F9)),

            // Bottom Info: Shopper info & Entry By Role Info + Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Shopper & Entry info
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Shopped by badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shopping_cart_outlined, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 3),
                          const Text('বাজার: ', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          Text(
                            entry.shopperName,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: _getRoleColor(entry.shopperRole).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getRoleDisplayName(entry.shopperRole),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: _getRoleColor(entry.shopperRole),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Entry by badge (if different from shopper or explicitly show)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_note_rounded, size: 13, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 2),
                          const Text('এন্ট্রি: ', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                          Text(
                            entry.entryByName,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '(${_getRoleDisplayName(entry.entryByRole)})',
                            style: TextStyle(
                              fontSize: 8,
                              color: _getRoleColor(entry.entryByRole),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Edit & Delete Action Buttons (Manager & Co-Manager only)
                if (isManager) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF64748B)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'এডিট',
                        onPressed: () {
                          Get.dialog(
                            AddBazarDialog(board: board, bazarToEdit: entry),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'মুছে ফেলুন',
                        onPressed: () => _confirmDelete(context, board, entry),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState(BuildContext context, BoardModel board, bool isManager, Color groupColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: groupColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.remove_shopping_cart_rounded, size: 36, color: groupColor),
          ),
          const SizedBox(height: 14),
          const Text(
            'এই মাসে কোনো বাজার এন্ট্রি নেই',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'ম্যানেজার বা সহকারী ম্যানেজার নতুন বাজার এন্ট্রি করতে পারবেন',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          if (isManager) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Get.dialog(AddBazarDialog(board: board));
              },
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 16, color: Colors.white),
              label: const Text('নতুন বাজার এন্ট্রি করুন', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: groupColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
