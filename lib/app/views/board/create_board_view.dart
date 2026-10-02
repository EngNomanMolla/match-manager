import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/board_controller.dart';
import '../../theme/app_theme.dart';

class CreateBoardView extends StatefulWidget {
  const CreateBoardView({super.key});

  @override
  State<CreateBoardView> createState() => _CreateBoardViewState();
}

class _CreateBoardViewState extends State<CreateBoardView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedSport = 'bachelor_mess';
  Color _selectedColor = AppColors.boardColors[0];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _messTypes = [
    {'key': 'bachelor_mess', 'icon': Icons.rice_bowl_rounded, 'nameKey': 'bachelor_mess'},
    {'key': 'hostel_mess', 'icon': Icons.apartment_rounded, 'nameKey': 'hostel_mess'},
    {'key': 'family_mess', 'icon': Icons.soup_kitchen_rounded, 'nameKey': 'family_mess'},
    {'key': 'office_mess', 'icon': Icons.lunch_dining_rounded, 'nameKey': 'office_mess'},
    {'key': 'custom_mess', 'icon': Icons.cottage_rounded, 'nameKey': 'custom_mess'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final boardController = Get.find<BoardController>();
    final success = await boardController.createBoard(
      title: _titleController.text,
      sportType: _selectedSport,
      description: _descController.text,
      themeColor: _selectedColor,
    );

    setState(() => _isLoading = false);

    if (success) {
      Get.back();
      Get.snackbar(
        'success'.tr,
        'board_created_success'.tr,
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
          'create_board'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mess Name
              Text(
                'board_name'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'error_empty_name'.tr;
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'board_name_hint'.tr,
                  prefixIcon: const Icon(Icons.cottage_outlined, color: Color(0xFF64748B)),
                ),
              ),
              const SizedBox(height: 20),

              // Mess Type Category Selector
              Text(
                'mess_type'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _messTypes.map((type) {
                  final isSelected = _selectedSport == type['key'];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedSport = type['key'];
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? _selectedColor.withValues(alpha: 0.12) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? _selectedColor : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type['icon'] as IconData,
                            size: 18,
                            color: isSelected ? _selectedColor : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (type['nameKey'] as String).tr,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? _selectedColor : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Theme Color
              Text(
                'board_color'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: AppColors.boardColors.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.45),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ]
                            : [],
                      ),
                      child: isSelected
                          ? const Center(
                              child: Icon(Icons.check, color: Colors.white, size: 20),
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Description
              Text(
                'description'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'description_hint'.tr,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.notes_rounded, color: Color(0xFF64748B)),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_task_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'create_board_btn'.tr,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
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
