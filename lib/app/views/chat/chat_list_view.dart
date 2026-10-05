import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_profile_controller.dart';
import '../../controllers/board_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../data/models/board_model.dart';
import '../../data/models/member_model.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  final ChatController chatController = Get.find<ChatController>();
  final BoardController boardController = Get.find<BoardController>();
  final AuthProfileController authController = Get.find<AuthProfileController>();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatConversationTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      return DateFormat('hh:mm a').format(time);
    }
    if (time.year == now.year && time.month == now.month && time.day == now.day - 1) {
      return 'গতকাল';
    }
    return DateFormat('dd/MM/yy').format(time);
  }

  String _getRoleDisplayName(String? role) {
    if (role == null) return 'মেম্বার';
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

  Color _getRoleColor(String? role) {
    if (role == null) return const Color(0xFF64748B);
    switch (role.toLowerCase()) {
      case 'manager':
        return AppColors.primary;
      case 'co_manager':
      case 'comanager':
        return AppColors.secondary;
      default:
        return const Color(0xFF0284C7);
    }
  }

  void _showNewChatMemberPicker(BuildContext context, List<BoardModel> boards) {
    final currentUser = authController.user.value;
    final allMembersMap = <String, MemberModel>{};

    for (final b in boards) {
      for (final m in b.members) {
        if (currentUser == null || (m.id != currentUser.id && m.phone != currentUser.phone)) {
          allMembersMap[m.id] = m;
        }
      }
    }

    final uniqueMembers = allMembersMap.values.toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'কাকে মেসেজ পাঠাবেন?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (uniqueMembers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'কোনো সক্রিয় মেম্বার পাওয়া যায়নি',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: uniqueMembers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        final member = uniqueMembers[index];
                        final roleColor = _getRoleColor(member.role.name);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: roleColor.withValues(alpha: 0.15),
                            child: Text(
                              member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
                              style: TextStyle(fontWeight: FontWeight.bold, color: roleColor),
                            ),
                          ),
                          title: Text(
                            member.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            member.phone.isNotEmpty ? member.phone : 'সদস্য',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getRoleDisplayName(member.role.name),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: roleColor),
                            ),
                          ),
                          onTap: () {
                            Get.back();
                            if (currentUser != null) {
                              final convId = ChatController.getDirectConversationId(currentUser.id, member.id);
                              Get.toNamed(
                                AppRoutes.chatRoom,
                                arguments: {
                                  'conversationId': convId,
                                  'title': member.name,
                                  'recipientId': member.id,
                                  'recipientName': member.name,
                                  'recipientRole': member.role.name,
                                  'isGroup': false,
                                },
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54), // WhatsApp Green Header
        elevation: 0,
        title: const Text(
          'মেসেজ ও চ্যাট (WhatsApp Style)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
      ),
      body: Obx(() {
        final boards = boardController.boards;
        final conversations = chatController.getConversationsList(boards);

        final filtered = conversations.where((c) {
          if (_searchQuery.isEmpty) return true;
          return c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (c.subtitle?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        }).toList();

        return Column(
          children: [
            // Search Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF075E54),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'চ্যাট বা মেম্বার খুঁজুন...',
                    prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                ),
              ),
            ),

            // Conversation List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'কোনো চ্যাট পাওয়া যায়নি',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'নিচের বাটনে চাপ দিয়ে যেকোনো মেম্বারের সাথে চ্যাট শুরু করুন',
                            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 72),
                      itemBuilder: (context, index) {
                        final conv = filtered[index];
                        final isUnread = conv.unreadCount > 0;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: conv.isGroup
                                ? const Color(0xFF075E54).withValues(alpha: 0.15)
                                : _getRoleColor(conv.otherMemberRole).withValues(alpha: 0.15),
                            child: Icon(
                              conv.isGroup ? Icons.groups_rounded : Icons.person_rounded,
                              color: conv.isGroup ? const Color(0xFF075E54) : _getRoleColor(conv.otherMemberRole),
                              size: 24,
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  conv.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Text(
                                _formatConversationTime(conv.lastMessageTime),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                  color: isUnread ? const Color(0xFF00A884) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  conv.subtitle ?? 'কোনো মেসেজ নেই',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                    color: isUnread ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              if (isUnread) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF25D366), // WhatsApp Green Badge
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${conv.unreadCount}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          onTap: () {
                            Get.toNamed(
                              AppRoutes.chatRoom,
                              arguments: {
                                'conversationId': conv.id,
                                'title': conv.title,
                                'subtitle': conv.isGroup ? '${conv.participantIds.length} জন সদস্য' : null,
                                'boardId': conv.boardId,
                                'isGroup': conv.isGroup,
                                'recipientRole': conv.otherMemberRole,
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatMemberPicker(context, boardController.boards),
        backgroundColor: const Color(0xFF00A884), // WhatsApp Action Button
        child: const Icon(Icons.chat_rounded, color: Colors.white),
      ),
    );
  }
}
