import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/board_controller.dart';
import '../../controllers/language_controller.dart';
import '../../data/models/board_model.dart';
import '../../data/models/member_model.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilter = 0; // 0: All, 1: Groups, 2: Persons

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boardController = Get.find<BoardController>();
    final langController = Get.find<LanguageController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Match Manager',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          // Language Switcher Chip
          GestureDetector(
            onTap: () => langController.toggleLanguage(),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Obx(() => Text(
                    langController.isBangla ? '🇧🇩 বাংলা' : '🇬🇧 EN',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  )),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // WhatsApp-style Clean Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      boardController.searchQuery.value = val;
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'search_hint'.tr,
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                              onPressed: () {
                                _searchController.clear();
                                boardController.searchQuery.value = '';
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Small Compact Filter Chips (All, Groups, Persons)
                Row(
                  children: [
                    _buildFilterChip(0, 'filter_all'.tr),
                    const SizedBox(width: 8),
                    _buildFilterChip(1, 'filter_groups'.tr),
                    const SizedBox(width: 8),
                    _buildFilterChip(2, 'filter_persons'.tr),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Content List
          Expanded(
            child: Obx(() {
              final query = boardController.searchQuery.value.toLowerCase().trim();
              final allBoards = boardController.boards;

              // Filter Groups
              final matchingBoards = allBoards.where((b) {
                if (query.isEmpty) return true;
                return b.title.toLowerCase().contains(query) ||
                    b.boardCode.toLowerCase().contains(query);
              }).toList();

              // Extract & Filter Persons across all groups
              final List<Map<String, dynamic>> matchingPersons = [];
              for (var b in allBoards) {
                for (var m in b.members) {
                  final matchesQuery = query.isEmpty ||
                      m.name.toLowerCase().contains(query) ||
                      m.phone.contains(query) ||
                      b.title.toLowerCase().contains(query);
                  if (matchesQuery) {
                    matchingPersons.add({
                      'member': m,
                      'groupTitle': b.title,
                      'groupId': b.id,
                      'groupColor': Color(b.themeColorValue),
                    });
                  }
                }
              }

              final showGroups = _selectedFilter == 0 || _selectedFilter == 1;
              final showPersons = _selectedFilter == 0 || _selectedFilter == 2;

              final isEmpty = (_selectedFilter == 1 && matchingBoards.isEmpty) ||
                  (_selectedFilter == 2 && matchingPersons.isEmpty) ||
                  (_selectedFilter == 0 && matchingBoards.isEmpty && matchingPersons.isEmpty);

              if (isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 54, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'no_data_found'.tr,
                        style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                children: [
                  // Groups Section
                  if (showGroups && matchingBoards.isNotEmpty) ...[
                    if (_selectedFilter == 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                        child: Text(
                          'nav_groups'.tr.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ...matchingBoards.map((board) => _buildSimpleGroupTile(board)),
                  ],

                  // Persons Section
                  if (showPersons && matchingPersons.isNotEmpty) ...[
                    if (_selectedFilter == 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                        child: Text(
                          'filter_persons'.tr.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ...matchingPersons.map((item) => _buildSimplePersonTile(
                          item['member'] as MemberModel,
                          item['groupTitle'] as String,
                          item['groupId'] as String,
                          item['groupColor'] as Color,
                        )),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // Simple, nice WhatsApp-style Group Card
  Widget _buildSimpleGroupTile(BoardModel board) {
    final color = Color(board.themeColorValue);
    final dateStr = DateFormat('d MMM yyyy').format(board.createdAt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: () {
          Get.toNamed(AppRoutes.boardDetail, arguments: board.id);
        },
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            Icons.restaurant_rounded,
            color: color,
            size: 22,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                board.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              dateStr,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            '${board.members.length} ${'members'.tr} • ${board.periodDisplayName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  // WhatsApp-style Person Tile: Profile Avatar, Name, Last Message & Last Conversion/Activity Date
  Widget _buildSimplePersonTile(
    MemberModel member,
    String groupTitle,
    String groupId,
    Color groupColor,
  ) {
    final dateStr = DateFormat('d MMM yyyy').format(member.joinedAt);

    // Realistic WhatsApp style last messages for mess management
    final List<String> lastMessages = [
      'আজকে রাতের মিল কাউন্ট বন্ধ থাকবে।',
      'বাজারের খরচ আপডেট করে দিয়েছি।',
      'আগামীকাল দুপুরের মিল চালু রাখব।',
      'মেসের ইউটিলিটি বিল পরিশোধ করা হয়েছে।',
      'টাকা পাঠিয়েছি, চেক করে নিয়েন।',
      'আজকে বাজার করতে কে যাবে?',
    ];
    final sampleMsg = lastMessages[member.name.hashCode.abs() % lastMessages.length];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: () {
          Get.toNamed(AppRoutes.boardDetail, arguments: groupId);
        },
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFFE2E8F0),
          child: Text(
            member.name.isNotEmpty ? member.name[0] : '?',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
              fontSize: 17,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                member.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              dateStr,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            children: [
              const Icon(
                Icons.done_all_rounded,
                size: 16,
                color: Color(0xFF0EA5E9),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  sampleMsg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
