import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../data/models/board_model.dart';
import '../data/models/chat_conversation_model.dart';
import '../data/models/chat_message_model.dart';
import '../data/services/storage_service.dart';
import 'auth_profile_controller.dart';
import 'board_controller.dart';

class ChatController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final AuthProfileController _authController = Get.find<AuthProfileController>();
  final BoardController _boardController = Get.find<BoardController>();

  final RxList<ChatMessageModel> allMessages = <ChatMessageModel>[].obs;
  final RxList<String> pendingImages = <String>[].obs;
  final ImagePicker _picker = ImagePicker();

  static const int maxImagesPerMessage = 5;

  @override
  void onInit() {
    super.onInit();
    loadMessages();
  }

  void loadMessages() {
    final list = _storageService.getChatMessages();
    allMessages.value = list;
  }

  // Conversation ID Generator Helpers
  static String getGroupConversationId(String boardId) => 'group_$boardId';

  static String getDirectConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return 'dm_${ids[0]}_${ids[1]}';
  }

  // Get messages for a specific conversation (ordered chronologically)
  List<ChatMessageModel> getMessagesForConversation(String conversationId) {
    return allMessages
        .where((m) => m.conversationId == conversationId && !m.isDeleted)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  // Get last message of a conversation
  ChatMessageModel? getLastMessage(String conversationId) {
    final msgs = getMessagesForConversation(conversationId);
    return msgs.isNotEmpty ? msgs.last : null;
  }

  // Pick multiple images from gallery (enforcing max 5 at once)
  Future<void> pickImagesFromGallery() async {
    try {
      final availableSlots = maxImagesPerMessage - pendingImages.length;
      if (availableSlots <= 0) {
        Get.snackbar(
          'ছবি সীমাবদ্ধতা',
          'একবারে সর্বোচ্চ $maxImagesPerMessageটি ছবি পাঠানো যাবে',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        );
        return;
      }

      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
        limit: availableSlots,
      );

      if (pickedFiles.isNotEmpty) {
        if (pickedFiles.length > availableSlots) {
          Get.snackbar(
            'সতর্কতা',
            'একবারে সর্বোচ্চ $maxImagesPerMessageটি ছবি পাঠানো সম্ভব। অতিরিক্ত ছবি বাদ দেওয়া হয়েছে।',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFF59E0B),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
          );
        }

        final filesToAdd = pickedFiles.take(availableSlots).map((f) => f.path).toList();
        pendingImages.addAll(filesToAdd);
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  // Capture single image from camera
  Future<void> pickImageFromCamera() async {
    try {
      if (pendingImages.length >= maxImagesPerMessage) {
        Get.snackbar(
          'ছবি সীমাবদ্ধতা',
          'একবারে সর্বোচ্চ $maxImagesPerMessageটি ছবি পাঠানো যাবে',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        );
        return;
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        pendingImages.add(photo.path);
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  void removePendingImage(int index) {
    if (index >= 0 && index < pendingImages.length) {
      pendingImages.removeAt(index);
    }
  }

  void clearPendingImages() {
    pendingImages.clear();
  }

  // Send message
  Future<bool> sendMessage({
    required String conversationId,
    String? boardId,
    String? recipientId,
    String? recipientName,
    required String text,
    List<String>? images,
  }) async {
    final currentUser = _authController.user.value;
    if (currentUser == null) return false;

    final trimmedText = text.trim();
    final imagesToSend = List<String>.from(images ?? pendingImages);

    // Enforce max 5 images limit strictly
    final finalImages = imagesToSend.take(maxImagesPerMessage).toList();

    if (trimmedText.isEmpty && finalImages.isEmpty) {
      return false;
    }

    // Determine sender role in the context of the board
    String senderRole = 'member';
    if (boardId != null) {
      final board = _boardController.getBoardById(boardId);
      if (board != null) {
        if (board.managerId == currentUser.id) {
          senderRole = 'manager';
        } else {
          final m = board.members.firstWhereOrNull((mem) =>
              mem.id == currentUser.id ||
              (currentUser.phone.isNotEmpty && mem.phone == currentUser.phone) ||
              mem.name.trim().toLowerCase() == currentUser.name.trim().toLowerCase());
          if (m != null) {
            senderRole = m.role.name;
          }
        }
      }
    }

    final newMessage = ChatMessageModel(
      id: const Uuid().v4(),
      conversationId: conversationId,
      boardId: boardId,
      senderId: currentUser.id,
      senderName: currentUser.name,
      senderRole: senderRole,
      recipientId: recipientId,
      recipientName: recipientName,
      text: trimmedText,
      imagePaths: finalImages,
      timestamp: DateTime.now(),
      isRead: false,
      isDeleted: false,
    );

    allMessages.add(newMessage);
    await _storageService.saveChatMessages(allMessages);

    clearPendingImages();
    return true;
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    final index = allMessages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      allMessages[index] = allMessages[index].copyWith(isDeleted: true);
      await _storageService.saveChatMessages(allMessages);
    }
  }

  // Mark all unread messages in conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    final currentUserId = _authController.user.value?.id;
    if (currentUserId == null) return;

    bool hasChanges = false;
    final updatedList = List<ChatMessageModel>.from(allMessages);

    for (int i = 0; i < updatedList.length; i++) {
      final msg = updatedList[i];
      if (msg.conversationId == conversationId &&
          msg.senderId != currentUserId &&
          !msg.isRead) {
        updatedList[i] = msg.copyWith(isRead: true);
        hasChanges = true;
      }
    }

    if (hasChanges) {
      allMessages.value = updatedList;
      await _storageService.saveChatMessages(allMessages);
    }
  }

  // Unread count for a conversation
  int getUnreadCount(String conversationId) {
    final currentUserId = _authController.user.value?.id;
    if (currentUserId == null) return 0;

    return allMessages.where((m) =>
        m.conversationId == conversationId &&
        m.senderId != currentUserId &&
        !m.isRead &&
        !m.isDeleted).length;
  }

  // Total unread count for current user
  int getTotalUnreadCount() {
    final currentUserId = _authController.user.value?.id;
    if (currentUserId == null) return 0;

    return allMessages.where((m) =>
        m.senderId != currentUserId &&
        !m.isRead &&
        !m.isDeleted).length;
  }

  // Get list of all conversations for the active user
  List<ChatConversationModel> getConversationsList(List<BoardModel> boards) {
    final currentUser = _authController.user.value;
    if (currentUser == null) return [];

    final conversationsMap = <String, ChatConversationModel>{};

    // 1. Group Conversations for all joined/created boards
    for (final board in boards) {
      final groupConvId = getGroupConversationId(board.id);
      final groupMsgs = getMessagesForConversation(groupConvId);
      final lastMsg = groupMsgs.isNotEmpty ? groupMsgs.last : null;
      final unread = getUnreadCount(groupConvId);

      String lastPreview = 'কোনো মেসেজ নেই';
      if (lastMsg != null) {
        if (lastMsg.text.isNotEmpty) {
          lastPreview = '${lastMsg.senderName}: ${lastMsg.text}';
        } else if (lastMsg.hasImages) {
          lastPreview = '${lastMsg.senderName}: 📷 [${lastMsg.imagePaths.length}টি ছবি]';
        }
      }

      conversationsMap[groupConvId] = ChatConversationModel(
        id: groupConvId,
        title: '${board.title} (মেস চ্যাট)',
        subtitle: lastPreview,
        boardId: board.id,
        boardTitle: board.title,
        isGroup: true,
        participantIds: board.members.map((m) => m.id).toList(),
        participantNames: board.members.map((m) => m.name).toList(),
        lastMessage: lastPreview,
        lastMessageTime: lastMsg?.timestamp ?? board.createdAt,
        unreadCount: unread,
      );
    }

    // 2. Direct 1-on-1 Conversations
    for (final msg in allMessages) {
      if (!msg.isGroup && !msg.isDeleted) {
        if (msg.senderId == currentUser.id || msg.recipientId == currentUser.id) {
          final isMeSender = msg.senderId == currentUser.id;
          final otherId = isMeSender ? (msg.recipientId ?? '') : msg.senderId;
          final otherName = isMeSender ? (msg.recipientName ?? 'সদস্য') : msg.senderName;
          final otherRole = isMeSender ? 'member' : msg.senderRole;

          if (otherId.isNotEmpty) {
            final convId = msg.conversationId;
            final unread = getUnreadCount(convId);

            String preview = msg.text.isNotEmpty
                ? (isMeSender ? 'আপনি: ${msg.text}' : msg.text)
                : (isMeSender ? 'আপনি: 📷 [${msg.imagePaths.length}টি ছবি]' : '📷 [${msg.imagePaths.length}টি ছবি]');

            if (!conversationsMap.containsKey(convId) ||
                msg.timestamp.isAfter(conversationsMap[convId]!.lastMessageTime)) {
              conversationsMap[convId] = ChatConversationModel(
                id: convId,
                title: otherName,
                subtitle: preview,
                boardId: msg.boardId,
                isGroup: false,
                participantIds: [currentUser.id, otherId],
                participantNames: [currentUser.name, otherName],
                lastMessage: preview,
                lastMessageTime: msg.timestamp,
                unreadCount: unread,
                otherMemberRole: otherRole,
              );
            }
          }
        }
      }
    }

    final list = conversationsMap.values.toList()
      ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

    return list;
  }
}
