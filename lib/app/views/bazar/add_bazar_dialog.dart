import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_profile_controller.dart';
import '../../controllers/bazar_controller.dart';
import '../../data/models/bazar_model.dart';
import '../../data/models/board_model.dart';
import '../../data/models/member_model.dart';
import '../../theme/app_theme.dart';

class AddBazarDialog extends StatefulWidget {
  final BoardModel board;
  final BazarModel? bazarToEdit;

  const AddBazarDialog({
    super.key,
    required this.board,
    this.bazarToEdit,
  });

  @override
  State<AddBazarDialog> createState() => _AddBazarDialogState();
}

class _AddBazarDialogState extends State<AddBazarDialog> {
  final _formKey = GlobalKey<FormState>();
  final BazarController _bazarController = Get.find<BazarController>();
  final AuthProfileController _authController = Get.find<AuthProfileController>();

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TextEditingController _itemInputController;

  late DateTime _selectedDate;
  late BazarCategory _selectedCategory;
  late String _selectedShopperId;
  late String _selectedShopperName;
  late String _selectedShopperRole;
  final List<String> _items = [];

  bool _isEditing = false;

  final List<String> _quickSuggestions = [
    'সাপ্তাহিক বাজার',
    'মুরগি ও ডিম',
    'মাছ ও সবজি',
    'চাল, ডাল ও তেল',
    'দৈনিক কাঁচা বাজার',
    'মশলা ও পেঁয়াজ-রসুন',
    'নাস্তা ও চা-চিনি',
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.bazarToEdit != null;

    final edit = widget.bazarToEdit;
    _titleController = TextEditingController(text: edit?.title ?? '');
    _amountController = TextEditingController(
        text: edit != null ? (edit.amount % 1 == 0 ? edit.amount.toInt().toString() : edit.amount.toString()) : '');
    _noteController = TextEditingController(text: edit?.note ?? '');
    _itemInputController = TextEditingController();

    if (edit != null) {
      _selectedDate = DateTime.tryParse(edit.date) ?? DateTime.now();
      _selectedCategory = edit.category;
      _selectedShopperId = edit.shopperMemberId;
      _selectedShopperName = edit.shopperName;
      _selectedShopperRole = edit.shopperRole;
      _items.addAll(edit.items);
    } else {
      _selectedDate = DateTime.now();
      _selectedCategory = BazarCategory.groceries;

      // Default shopper to current logged-in user if found in board members, otherwise manager
      final currentUser = _authController.user.value;
      MemberModel? defaultShopper;

      if (currentUser != null) {
        defaultShopper = widget.board.members.firstWhereOrNull((m) =>
            m.id == currentUser.id ||
            (currentUser.phone.isNotEmpty && m.phone == currentUser.phone) ||
            m.name.trim().toLowerCase() == currentUser.name.trim().toLowerCase());
      }

      if (defaultShopper != null) {
        _selectedShopperId = defaultShopper.id;
        _selectedShopperName = defaultShopper.name;
        _selectedShopperRole = defaultShopper.role.name;
      } else if (widget.board.members.isNotEmpty) {
        final first = widget.board.members.first;
        _selectedShopperId = first.id;
        _selectedShopperName = first.name;
        _selectedShopperRole = first.role.name;
      } else {
        _selectedShopperId = currentUser?.id ?? '';
        _selectedShopperName = currentUser?.name ?? widget.board.managerName;
        _selectedShopperRole = 'manager';
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _itemInputController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(widget.board.themeColorValue),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addItemFromInput() {
    final text = _itemInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _items.add(text);
        _itemInputController.clear();
      });
    }
  }

  Future<void> _saveBazar() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    if (amount <= 0) {
      Get.snackbar(
        'সতর্কতা',
        'অনুগ্রহ করে সঠিক টাকার পরিমাণ লিখুন',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    if (_isEditing) {
      final success = await _bazarController.updateBazarEntry(
        boardId: widget.board.id,
        bazarId: widget.bazarToEdit!.id,
        title: title,
        amount: amount,
        date: dateStr,
        shopperMemberId: _selectedShopperId,
        shopperName: _selectedShopperName,
        shopperRole: _selectedShopperRole,
        category: _selectedCategory,
        items: _items,
        note: _noteController.text.trim(),
      );

      if (success) {
        Get.back();
        Get.snackbar(
          'সফল হয়েছে',
          'বাজারের তথ্য সফলভাবে আপডেট হয়েছে!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF059669),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
        );
      }
    } else {
      final success = await _bazarController.addBazarEntry(
        boardId: widget.board.id,
        title: title,
        amount: amount,
        date: dateStr,
        shopperMemberId: _selectedShopperId,
        shopperName: _selectedShopperName,
        shopperRole: _selectedShopperRole,
        category: _selectedCategory,
        items: _items,
        note: _noteController.text.trim(),
      );

      if (success) {
        Get.back();
        Get.snackbar(
          'সফল হয়েছে',
          'নতুন বাজার সফলভাবে যুক্ত হয়েছে!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF059669),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupColor = Color(widget.board.themeColorValue);
    final currentUser = _authController.user.value;
    final currentRole = _bazarController.getCurrentUserRoleInBoard(widget.board);
    final roleNameBn = currentRole == 'manager'
        ? 'ম্যানেজার'
        : (currentRole == 'co_manager' ? 'সহকারী ম্যানেজার' : 'মেম্বার');

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 720),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: groupColor.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: groupColor.withValues(alpha: 0.15))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: groupColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isEditing ? Icons.edit_note_rounded : Icons.add_shopping_cart_rounded,
                      color: groupColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'বাজারের তথ্য এডিট' : 'নতুন বাজার এন্ট্রি',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'এন্ট্রি করছেন: ${currentUser?.name ?? 'ব্যবহারকারী'} ($roleNameBn)',
                          style: TextStyle(
                            fontSize: 11,
                            color: groupColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),

            // Scrollable Form Content
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // 1. Amount Field (Large focus)
                    const Text(
                      'বাজারের মোট খরচ *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        prefixIcon: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Text(
                            '৳',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: groupColor,
                            ),
                          ),
                        ),
                        hintText: '০.০০',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: groupColor, width: 2),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'টাকার পরিমাণ লিখুন';
                        }
                        final parsed = double.tryParse(val.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'সঠিক টাকার পরিমাণ দিন';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 2. Title / Description
                    const Text(
                      'বাজারের বিবরণ / আইটেমের নাম *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF64748B)),
                        hintText: 'যেমন: চাল, ডাল, মুরগি ও শাক-সবজি',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: groupColor, width: 2),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'বাজারের নাম বা বিবরণ দিন';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Quick suggestion chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _quickSuggestions.map((suggestion) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(suggestion, style: const TextStyle(fontSize: 11)),
                              backgroundColor: const Color(0xFFF1F5F9),
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              onPressed: () {
                                _titleController.text = suggestion;
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Date & Category Row
                    Row(
                      children: [
                        // Date Picker Button
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'বাজারের তারিখ *',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today_rounded, size: 16, color: groupColor),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          DateFormat('d MMM yyyy').format(_selectedDate),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 4. Shopper Selection (কে বাজার করেছে?)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'কে বাজার করেছে? *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: groupColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'নির্বাচিত: $_selectedShopperName',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: groupColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Member Chips (horizontal scroll)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: widget.board.members.map((member) {
                          final isSelected = member.id == _selectedShopperId;
                          final isMgr = member.role == MemberRole.manager;
                          final isCoMgr = member.role == MemberRole.coManager;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedShopperId = member.id;
                                  _selectedShopperName = member.name;
                                  _selectedShopperRole = member.role.name;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? groupColor : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? groupColor : const Color(0xFFCBD5E1),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isMgr
                                          ? Icons.verified_user_rounded
                                          : (isCoMgr ? Icons.supervisor_account_rounded : Icons.person_outline_rounded),
                                      size: 15,
                                      color: isSelected ? Colors.white : (isMgr ? AppColors.primary : const Color(0xFF64748B)),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      member.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    if (isMgr || isCoMgr) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isMgr ? 'ম্যানেজার' : 'কো-ম্যানেজার',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : const Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Category Chips
                    const Text(
                      'বাজারের ধরণ / ক্যাটাগরি',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: BazarCategory.values.map((cat) {
                        final isSelected = cat == _selectedCategory;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? cat.color : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? cat.color : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  cat.iconData,
                                  size: 14,
                                  color: isSelected ? Colors.white : cat.color,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  cat.displayNameBn,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? Colors.white : const Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 6. Detailed Item Breakdown (Optional)
                    const Text(
                      'নির্দিষ্ট আইটেম সমূহ (ঐচ্ছিক)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _itemInputController,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'যেমন: আলু ২ কেজি, ডিম ১ ডজন',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                            ),
                            onSubmitted: (_) => _addItemFromInput(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _addItemFromInput,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: groupColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                    if (_items.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _items.map((item) {
                          return Chip(
                            label: Text(item, style: const TextStyle(fontSize: 11)),
                            deleteIcon: const Icon(Icons.close_rounded, size: 14),
                            onDeleted: () {
                              setState(() {
                                _items.remove(item);
                              });
                            },
                            backgroundColor: const Color(0xFFF1F5F9),
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // 7. Note / Memo
                    const Text(
                      'নোট / বিশেষ মন্তব্য (ঐচ্ছিক)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'রশিদ বা অন্য কোনো তথ্য লিখে রাখুন...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: Text(
                        'cancel'.tr,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saveBazar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: groupColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isEditing ? Icons.save_rounded : Icons.check_circle_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isEditing ? 'আপডেট করুন' : 'বাজার সংরক্ষণ',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
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
