import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_profile_controller.dart';
import '../../controllers/board_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../data/models/chat_message_model.dart';
import '../../theme/app_theme.dart';
import 'image_viewer_dialog.dart';

class ChatRoomView extends StatefulWidget {
  final String? conversationId;
  final String? title;
  final String? subtitle;
  final String? boardId;
  final String? recipientId;
  final String? recipientName;
  final String? recipientRole;
  final bool? isGroup;
  final bool showAppBar;

  const ChatRoomView({
    super.key,
    this.conversationId,
    this.title,
    this.subtitle,
    this.boardId,
    this.recipientId,
    this.recipientName,
    this.recipientRole,
    this.isGroup,
    this.showAppBar = true,
  });

  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<ChatRoomView> {
  final ChatController chatController = Get.find<ChatController>();
  final AuthProfileController authController = Get.find<AuthProfileController>();
  final BoardController boardController = Get.find<BoardController>();

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late String conversationId;
  late String title;
  String? subtitle;
  String? boardId;
  String? recipientId;
  String? recipientName;
  String? recipientRole;
  late bool isGroup;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    conversationId = widget.conversationId ?? args['conversationId'] ?? '';
    title = widget.title ?? args['title'] ?? 'চ্যাট';
    subtitle = widget.subtitle ?? args['subtitle'];
    boardId = widget.boardId ?? args['boardId'];
    recipientId = widget.recipientId ?? args['recipientId'];
    recipientName = widget.recipientName ?? args['recipientName'];
    recipientRole = widget.recipientRole ?? args['recipientRole'];
    isGroup = widget.isGroup ?? args['isGroup'] ?? conversationId.startsWith('group_');

    // Mark conversation as read on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (conversationId.isNotEmpty) {
        chatController.markConversationAsRead(conversationId);
        _scrollToBottom(animate: false);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    chatController.clearPendingImages();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    if (_scrollController.hasClients) {
      if (animate) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  String _formatMessageTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final isYesterday = date.year == now.year && date.month == now.month && date.day == now.day - 1;

    const bnMonths = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];

    final isBn = Get.locale?.languageCode != 'en';
    if (isToday) return isBn ? 'আজকে' : 'Today';
    if (isYesterday) return isBn ? 'গতকাল' : 'Yesterday';

    if (isBn) {
      return '${date.day} ${bnMonths[date.month - 1]}, ${date.year}';
    }
    return DateFormat('d MMMM, yyyy').format(date);
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
        return const Color(0xFF0284C7);
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && chatController.pendingImages.isEmpty) return;

    final imagesToSend = List<String>.from(chatController.pendingImages);
    _textController.clear();

    await chatController.sendMessage(
      conversationId: conversationId,
      boardId: boardId,
      recipientId: recipientId,
      recipientName: recipientName,
      text: text,
      images: imagesToSend,
    );

    _scrollToBottom(animate: true);
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ছবি বা ফাইল নির্বাচন করুন',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'একবারে সর্বোচ্চ ৫টি ছবি',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAttachmentOption(
                      icon: Icons.photo_library_rounded,
                      label: 'গ্যালারি',
                      color: const Color(0xFF7C3AED),
                      onTap: () {
                        Get.back();
                        chatController.pickImagesFromGallery();
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'ক্যামেরা',
                      color: const Color(0xFFE11D48),
                      onTap: () {
                        Get.back();
                        chatController.pickImageFromCamera();
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.receipt_long_rounded,
                      label: 'বাজার রশিদ',
                      color: const Color(0xFF059669),
                      onTap: () {
                        Get.back();
                        chatController.pickImagesFromGallery();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(ChatMessageModel msg, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (msg.text.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.copy_rounded, color: Color(0xFF475569)),
                  title: const Text('মেসেজ কপি করুন', style: TextStyle(fontSize: 14)),
                  onTap: () {
                    Get.back();
                    Clipboard.setData(ClipboardData(text: msg.text));
                    Get.snackbar(
                      'কপি হয়েছে',
                      'মেসেজ ক্লিপবোর্ডে কপি করা হয়েছে',
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 1),
                      margin: const EdgeInsets.all(16),
                      borderRadius: 12,
                    );
                  },
                ),
              if (msg.hasImages)
                ListTile(
                  leading: const Icon(Icons.fullscreen_rounded, color: Color(0xFF475569)),
                  title: const Text('ছবি বড় করে দেখুন', style: TextStyle(fontSize: 14)),
                  onTap: () {
                    Get.back();
                    Get.to(() => ImageViewerDialog(
                          imagePaths: msg.imagePaths,
                          title: msg.senderName,
                        ));
                  },
                ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                  title: const Text('মেসেজ মুছে ফেলুন', style: TextStyle(fontSize: 14, color: Color(0xFFEF4444))),
                  onTap: () {
                    Get.back();
                    chatController.deleteMessage(msg.id);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = authController.user.value?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD), // WhatsApp Classic Chat Background Tint
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: const Color(0xFF075E54), // WhatsApp Classic Green Header
              elevation: 1,
        leadingWidth: 32,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              child: Icon(
                isGroup ? Icons.groups_rounded : Icons.person_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    )
                  else if (!isGroup && recipientRole != null)
                    Text(
                      _getRoleDisplayName(recipientRole!),
                      style: const TextStyle(fontSize: 11, color: Color(0xFFB2DFDB)),
                    )
                  else
                    const Text(
                      'সদস্যবৃন্দ যুক্ত আছেন',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.image_outlined, color: Colors.white),
            tooltip: 'ছবি পাঠাতে ট্যাপ করুন (সর্বোচ্চ ৫টি)',
            onPressed: () => chatController.pickImagesFromGallery(),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onPressed: () {
              // Quick action info
              Get.bottomSheet(
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('হোয়াটসঅ্যাপের মতো ইনস্ট্যান্ট চ্যাট ও ছবি আদান-প্রদান।'),
                      const SizedBox(height: 6),
                      const Text('• একবারে সর্বোচ্চ ৫টি ছবি পাঠানো সম্ভব।', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      )
    : null,
      body: Column(
        children: [
          // Messages List View
          Expanded(
            child: Obx(() {
              final messages = chatController.getMessagesForConversation(conversationId);

              if (messages.isEmpty) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isGroup ? Icons.forum_rounded : Icons.chat_bubble_outline_rounded,
                            size: 36, color: const Color(0xFF075E54)),
                        const SizedBox(height: 8),
                        Text(
                          isGroup ? 'মেস গ্রুপ চ্যাটে স্বাগতম!' : 'ডিরেক্ট চ্যাট শুরু করুন',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'নিচে মেসেজ লিখুন বা ছবি পাঠিয়ে চ্যাট শুরু করুন (সর্বোচ্চ ৫টি ছবি)',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Auto scroll to bottom when new messages arrive
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom(animate: true);
              });

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg.senderId == currentUserId;

                  // Check if need date separator
                  bool showDateSeparator = false;
                  if (index == 0) {
                    showDateSeparator = true;
                  } else {
                    final prevMsg = messages[index - 1];
                    if (prevMsg.timestamp.day != msg.timestamp.day ||
                        prevMsg.timestamp.month != msg.timestamp.month ||
                        prevMsg.timestamp.year != msg.timestamp.year) {
                      showDateSeparator = true;
                    }
                  }

                  return Column(
                    children: [
                      if (showDateSeparator) _buildDateSeparator(msg.timestamp),
                      _buildMessageBubble(msg, isMe),
                    ],
                  );
                },
              );
            }),
          ),

          // Pending Images Preview Strip (Max 5 images banner)
          Obx(() {
            final images = chatController.pendingImages;
            if (images.isEmpty) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                border: Border(top: BorderSide(color: Color(0xFFCBD5E1))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.collections_rounded, size: 16, color: Color(0xFF075E54)),
                          const SizedBox(width: 6),
                          Text(
                            'নির্বাচিত ছবি: ${images.length}/${ChatController.maxImagesPerMessage}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      if (images.length < ChatController.maxImagesPerMessage)
                        InkWell(
                          onTap: () => chatController.pickImagesFromGallery(),
                          child: const Text(
                            '+ আরও যোগ করুন',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF075E54)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: images.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final path = entry.value;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 10, top: 4),
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF075E54), width: 1.5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(File(path), fit: BoxFit.cover),
                              ),
                            ),
                            PositionActionRemove(onTap: () => chatController.removePendingImage(idx)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          }),

          // WhatsApp Style Bottom Input Bar
          _buildInputBar(),
        ],
      ),
    );
  }

  // Date Separator Pill
  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F3FB),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4),
        ],
      ),
      child: Text(
        _formatDateSeparator(date),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4A6572)),
      ),
    );
  }

  // Message Bubble
  Widget _buildMessageBubble(ChatMessageModel msg, bool isMe) {
    final senderColor = _getRoleColor(msg.senderRole);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageOptions(msg, isMe),
        child: Container(
          margin: EdgeInsets.only(
            bottom: 6,
            left: isMe ? 48 : 0,
            right: isMe ? 0 : 48,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFE7FFDB) : Colors.white, // WhatsApp Sent vs Received
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: isMe ? const Radius.circular(14) : Radius.zero,
              bottomRight: isMe ? Radius.zero : const Radius.circular(14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // In Group chat, show sender name & role on received messages
              if (!isMe && isGroup) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: senderColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: senderColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getRoleDisplayName(msg.senderRole),
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: senderColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
              ],

              // Images Grid (1 to 5 images layout)
              if (msg.hasImages) ...[
                _buildImagesCollage(msg.imagePaths, msg.senderName),
                const SizedBox(height: 4),
              ],

              // Message Text
              if (msg.text.isNotEmpty) ...[
                Text(
                  msg.text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111B21),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
              ],

              // Timestamp & Double Ticks
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _formatMessageTime(msg.timestamp),
                    style: const TextStyle(fontSize: 10, color: Color(0xFF667781)),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all_rounded,
                      size: 14,
                      color: msg.isRead ? const Color(0xFF53BDEB) : const Color(0xFF8696A0),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Collage Layout for 1 to 5 images
  Widget _buildImagesCollage(List<String> paths, String senderName) {
    final count = paths.length.clamp(1, 5);

    if (count == 1) {
      return InkWell(
        onTap: () => Get.to(() => ImageViewerDialog(imagePaths: paths, initialIndex: 0, title: senderName)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 220, maxWidth: 260),
            child: _buildThumbnailImage(paths[0]),
          ),
        ),
      );
    }

    if (count == 2) {
      return SizedBox(
        width: 240,
        height: 120,
        child: Row(
          children: [
            Expanded(child: _buildThumbnailGridItem(paths, 0, senderName)),
            const SizedBox(width: 3),
            Expanded(child: _buildThumbnailGridItem(paths, 1, senderName)),
          ],
        ),
      );
    }

    if (count == 3) {
      return SizedBox(
        width: 240,
        height: 180,
        child: Column(
          children: [
            Expanded(flex: 3, child: _buildThumbnailGridItem(paths, 0, senderName)),
            const SizedBox(height: 3),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(child: _buildThumbnailGridItem(paths, 1, senderName)),
                  const SizedBox(width: 3),
                  Expanded(child: _buildThumbnailGridItem(paths, 2, senderName)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (count == 4) {
      return SizedBox(
        width: 240,
        height: 200,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildThumbnailGridItem(paths, 0, senderName)),
                  const SizedBox(width: 3),
                  Expanded(child: _buildThumbnailGridItem(paths, 1, senderName)),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildThumbnailGridItem(paths, 2, senderName)),
                  const SizedBox(width: 3),
                  Expanded(child: _buildThumbnailGridItem(paths, 3, senderName)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 5 Images Collage Layout (2 top, 3 bottom)
    return SizedBox(
      width: 250,
      height: 210,
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(child: _buildThumbnailGridItem(paths, 0, senderName)),
                const SizedBox(width: 3),
                Expanded(child: _buildThumbnailGridItem(paths, 1, senderName)),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(child: _buildThumbnailGridItem(paths, 2, senderName)),
                const SizedBox(width: 3),
                Expanded(child: _buildThumbnailGridItem(paths, 3, senderName)),
                const SizedBox(width: 3),
                Expanded(child: _buildThumbnailGridItem(paths, 4, senderName)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailGridItem(List<String> allPaths, int index, String senderName) {
    return InkWell(
      onTap: () => Get.to(() => ImageViewerDialog(imagePaths: allPaths, initialIndex: index, title: senderName)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: _buildThumbnailImage(allPaths[index]),
      ),
    );
  }

  Widget _buildThumbnailImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFFE2E8F0),
          child: const Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8)),
        ),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8)),
    );
  }

  // Bottom Input Bar
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: const Color(0xFFF0F2F5),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment Button
            IconButton(
              icon: const Icon(Icons.attach_file_rounded, color: Color(0xFF54656F), size: 24),
              onPressed: _showAttachmentSheet,
              tooltip: 'ছবি বা ফাইল যোগ করুন (সর্বোচ্চ ৫টি)',
            ),

            // Text Input Box
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                        decoration: const InputDecoration(
                          hintText: 'মেসেজ লিখুন...',
                          hintStyle: TextStyle(color: Color(0xFF8696A0), fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onSubmitted: (_) => _handleSendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF54656F), size: 20),
                      onPressed: () => chatController.pickImageFromCamera(),
                      tooltip: 'ক্যামেরা',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Send Floating Button (WhatsApp Green Circle)
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF00A884), // WhatsApp Send Action Green
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: _handleSendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PositionActionRemove extends StatelessWidget {
  final VoidCallback onTap;
  const PositionActionRemove({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -2,
      right: 4,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Color(0xFFEF4444),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}
