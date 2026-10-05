import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/board_controller.dart';
import '../../data/models/board_model.dart';
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

  // Group Duration / Month Selection States
  String _durationMode = 'months'; // 'months' or 'custom_date'
  List<String> _selectedMonths = []; // list of 'YYYY-MM'
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  final List<Map<String, dynamic>> _messTypes = [
    {'key': 'bachelor_mess', 'icon': Icons.rice_bowl_rounded, 'nameKey': 'bachelor_mess'},
    {'key': 'hostel_mess', 'icon': Icons.apartment_rounded, 'nameKey': 'hostel_mess'},
    {'key': 'family_mess', 'icon': Icons.soup_kitchen_rounded, 'nameKey': 'family_mess'},
    {'key': 'office_mess', 'icon': Icons.lunch_dining_rounded, 'nameKey': 'office_mess'},
    {'key': 'custom_mess', 'icon': Icons.cottage_rounded, 'nameKey': 'custom_mess'},
  ];

  @override
  void initState() {
    super.initState();
    // Default selected month is the current month
    final now = DateTime.now();
    _selectedMonths = ['${now.year}-${now.month.toString().padLeft(2, '0')}'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // Generates upcoming 12 months for manager selection
  List<Map<String, dynamic>> _generateUpcomingMonths() {
    final months = <Map<String, dynamic>>[];
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final d = DateTime(now.year, now.month + i, 1);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      final label = BoardModel.formatMonthYear(d.month, d.year);
      months.add({
        'key': key,
        'label': label,
        'year': d.year,
        'month': d.month,
      });
    }
    return months;
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isAfter(_startDate) ? _endDate : _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_durationMode == 'months' && _selectedMonths.isEmpty) {
      Get.snackbar(
        'সতর্কতা',
        'please_select_month'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    setState(() => _isLoading = true);

    final boardController = Get.find<BoardController>();
    final success = await boardController.createBoard(
      title: _titleController.text,
      sportType: _selectedSport,
      description: _descController.text,
      themeColor: _selectedColor,
      periodType: _durationMode,
      selectedMonths: _selectedMonths,
      startDate: _durationMode == 'custom_date' ? _startDate : null,
      endDate: _durationMode == 'custom_date' ? _endDate : null,
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
    final upcomingMonths = _generateUpcomingMonths();

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

              // Group Duration / Month Selection Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'group_duration'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    _durationMode == 'months'
                        ? '${_selectedMonths.length}টি মাস নির্বাচিত'
                        : '${_endDate.difference(_startDate).inDays + 1} ${'total_days'.tr}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _selectedColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Segmented Toggle between 'By Month' and 'Custom Date'
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _durationMode = 'months';
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _durationMode == 'months' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _durationMode == 'months'
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 16,
                                color: _durationMode == 'months' ? _selectedColor : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'by_month'.tr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _durationMode == 'months' ? _selectedColor : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _durationMode = 'custom_date';
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _durationMode == 'custom_date' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _durationMode == 'custom_date'
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.date_range_rounded,
                                size: 16,
                                color: _durationMode == 'custom_date' ? _selectedColor : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'custom_date'.tr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _durationMode == 'custom_date' ? _selectedColor : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // View 1: Month Selection (Chips + Presets)
              if (_durationMode == 'months') ...[
                // Quick Presets Row
                Row(
                  children: [
                    _buildPresetChip(
                      label: 'current_month'.tr,
                      onTap: () {
                        final now = DateTime.now();
                        setState(() {
                          _selectedMonths = ['${now.year}-${now.month.toString().padLeft(2, '0')}'];
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildPresetChip(
                      label: 'next_month'.tr,
                      onTap: () {
                        final next = DateTime(DateTime.now().year, DateTime.now().month + 1, 1);
                        setState(() {
                          _selectedMonths = ['${next.year}-${next.month.toString().padLeft(2, '0')}'];
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildPresetChip(
                      label: 'next_3_months'.tr,
                      onTap: () {
                        final now = DateTime.now();
                        final list = <String>[];
                        for (int i = 0; i < 3; i++) {
                          final d = DateTime(now.year, now.month + i, 1);
                          list.add('${d.year}-${d.month.toString().padLeft(2, '0')}');
                        }
                        setState(() {
                          _selectedMonths = list;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Selectable Months Wrap
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'select_months'.tr,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: upcomingMonths.map((m) {
                          final key = m['key'] as String;
                          final label = m['label'] as String;
                          final isSelected = _selectedMonths.contains(key);

                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  if (_selectedMonths.length > 1) {
                                    _selectedMonths.remove(key);
                                  }
                                } else {
                                  _selectedMonths.add(key);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _selectedColor.withValues(alpha: 0.12)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? _selectedColor : const Color(0xFFE2E8F0),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    Icon(Icons.check_circle_rounded, size: 14, color: _selectedColor),
                                    const SizedBox(width: 5),
                                  ],
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 12,
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
                    ],
                  ),
                ),
              ] else ...[
                // View 2: Custom Date Range Pickers
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Start Date
                          Expanded(
                            child: InkWell(
                              onTap: _selectStartDate,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.play_circle_outline_rounded, size: 14, color: _selectedColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          'start_date'.tr,
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('d MMM yyyy').format(_startDate),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // End Date
                          Expanded(
                            child: InkWell(
                              onTap: _selectEndDate,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.stop_circle_outlined, size: 14, color: AppColors.danger),
                                        const SizedBox(width: 4),
                                        Text(
                                          'end_date'.tr,
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('d MMM yyyy').format(_endDate),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 14, color: _selectedColor),
                            const SizedBox(width: 6),
                            Text(
                              'গ্রুপের মোট কার্যদিবস: ${_endDate.difference(_startDate).inDays + 1} দিন',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _selectedColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

  Widget _buildPresetChip({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
        ),
      ),
    );
  }
}
