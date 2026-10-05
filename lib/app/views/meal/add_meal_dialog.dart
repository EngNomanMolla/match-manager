import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/meal_controller.dart';
import '../../data/models/board_model.dart';
import '../../data/models/meal_type_model.dart';
import '../../theme/app_theme.dart';

class AddMealDialog extends StatefulWidget {
  final BoardModel board;
  final MealTypeModel? mealToEdit;

  const AddMealDialog({
    super.key,
    required this.board,
    this.mealToEdit,
  });

  @override
  State<AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<AddMealDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _timeController;
  late String _selectedIconKey;
  late String _afterMealId;

  final List<Map<String, dynamic>> _iconOptions = [
    {'key': 'breakfast', 'icon': Icons.wb_sunny_rounded, 'label': 'সকাল / নাস্তা'},
    {'key': 'lunch', 'icon': Icons.lunch_dining_rounded, 'label': 'দুপুর / লাঞ্চ'},
    {'key': 'dinner', 'icon': Icons.nightlight_round, 'label': 'রাত / ডিনার'},
    {'key': 'snack', 'icon': Icons.local_cafe_rounded, 'label': 'স্ন্যাক্স / চা'},
    {'key': 'meal', 'icon': Icons.restaurant_rounded, 'label': 'সাধারণ মিল'},
  ];

  @override
  void initState() {
    super.initState();
    final isEditing = widget.mealToEdit != null;
    _nameController = TextEditingController(text: widget.mealToEdit?.name ?? '');
    _timeController = TextEditingController(text: widget.mealToEdit?.time ?? '');
    _selectedIconKey = widget.mealToEdit?.iconKey ?? 'snack';

    // Default placement: after the last meal
    if (isEditing) {
      final currentMeals = widget.board.meals;
      final currentIndex = currentMeals.indexWhere((m) => m.id == widget.mealToEdit!.id);
      if (currentIndex > 0) {
        _afterMealId = currentMeals[currentIndex - 1].id;
      } else {
        _afterMealId = 'start';
      }
    } else {
      if (widget.board.meals.isNotEmpty) {
        _afterMealId = widget.board.meals.last.id;
      } else {
        _afterMealId = 'end';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _selectTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
    );
    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      setState(() {
        _timeController.text = '$hour:$minute $period';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.mealToEdit != null;
    final mealController = Get.find<MealController>();

    // Available meals to place after (excluding the one being edited)
    final existingMeals = widget.board.meals
        .where((m) => !isEditing || m.id != widget.mealToEdit!.id)
        .toList();

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
                      isEditing ? 'edit_meal'.tr : 'create_meal'.tr,
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

                // Meal Name
                Text(
                  'meal_name'.tr,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'মিলের নাম লিখুন';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'meal_name_hint'.tr,
                    prefixIcon: const Icon(Icons.restaurant_menu_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 14),

                // Ordering: "kon meal er pore kon meal name show korbe atao set korte parbe"
                Text(
                  'order_after'.tr,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _afterMealId,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B)),
                      items: [
                        DropdownMenuItem<String>(
                          value: 'start',
                          child: Text(
                            'at_beginning'.tr,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ),
                        ...existingMeals.map((m) {
                          return DropdownMenuItem<String>(
                            value: m.id,
                            child: Row(
                              children: [
                                Icon(m.iconData, size: 16, color: m.defaultColor),
                                const SizedBox(width: 8),
                                Text(
                                  '${m.name} এর পরে',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        }),
                        DropdownMenuItem<String>(
                          value: 'end',
                          child: Text(
                            'at_end'.tr,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _afterMealId = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Time picker
                Text(
                  'meal_time'.tr,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _timeController,
                  readOnly: true,
                  onTap: _selectTime,
                  decoration: InputDecoration(
                    hintText: 'সময় নির্বাচন করুন (ঐচ্ছিক)',
                    prefixIcon: const Icon(Icons.access_time_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.schedule_rounded, size: 18),
                      onPressed: _selectTime,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Icon Picker
                Text(
                  'meal_icon'.tr,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _iconOptions.map((opt) {
                      final isSelected = _selectedIconKey == opt['key'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedIconKey = opt['key'] as String;
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              opt['icon'] as IconData,
                              size: 24,
                              color: isSelected ? AppColors.primary : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
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
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            if (isEditing) {
                              await mealController.updateMealType(
                                boardId: widget.board.id,
                                mealId: widget.mealToEdit!.id,
                                newName: _nameController.text,
                                newTime: _timeController.text,
                                newIconKey: _selectedIconKey,
                                afterMealId: _afterMealId,
                              );
                            } else {
                              await mealController.addMealType(
                                boardId: widget.board.id,
                                name: _nameController.text,
                                time: _timeController.text,
                                afterMealId: _afterMealId,
                                iconKey: _selectedIconKey,
                              );
                            }
                            Get.back();
                            Get.snackbar(
                              'success'.tr,
                              'order_updated'.tr,
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: const Color(0xFF0F172A),
                              colorText: Colors.white,
                              margin: const EdgeInsets.all(16),
                              borderRadius: 12,
                            );
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
}
