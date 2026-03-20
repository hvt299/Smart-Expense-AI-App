import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../utils/snackbar_helper.dart';
import '../utils/currency_formatter.dart';

class AddTransactionBottomSheet extends StatefulWidget {
  final String? transactionId;
  final String? initialType;

  final double? initialAmount;
  final String? initialCategory;
  final String? initialNote;

  const AddTransactionBottomSheet({
    super.key,
    this.transactionId,
    this.initialType,
    this.initialAmount,
    this.initialCategory,
    this.initialNote,
  });

  @override
  State<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends State<AddTransactionBottomSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late String _transactionType;
  final List<String> _expenseCategories = List.from(
    AppConstants.defaultExpenseCategories,
  );
  final List<String> _incomeCategories = List.from(
    AppConstants.defaultIncomeCategories,
  );
  late String _selectedCategory;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _transactionType = widget.initialType ?? 'expense';

    final currentCategories = _transactionType == 'expense'
        ? _expenseCategories
        : _incomeCategories;
    _selectedCategory = currentCategories.first;

    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _amountController.text = NumberFormat(
        '#,##0',
      ).format(widget.initialAmount!.toInt()).replaceAll(',', '.');
    }
    if (widget.initialNote != null) {
      _noteController.text = widget.initialNote!;
    }
    if (widget.initialCategory != null) {
      if (!currentCategories.contains(widget.initialCategory!)) {
        currentCategories.add(widget.initialCategory!);
      }
      _selectedCategory = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addNewCategory() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm danh mục mới', style: TextStyle(fontSize: 18)),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: 'Nhập tên danh mục...'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () {
              final newCat = textController.text.trim();
              if (newCat.isEmpty) return;

              final currentCategories = _transactionType == 'expense'
                  ? _expenseCategories
                  : _incomeCategories;
              final oppositeCategories = _transactionType == 'expense'
                  ? _incomeCategories
                  : _expenseCategories;

              if (oppositeCategories.contains(newCat)) {
                SnackBarHelper.showSuccess(
                  context,
                  'Danh mục "$newCat" đã được dùng cho phần ${_transactionType == 'expense' ? 'Thu nhập' : 'Chi tiêu'}!',
                );
                return;
              }

              if (!currentCategories.contains(newCat)) {
                setState(() {
                  currentCategories.add(newCat);
                  _selectedCategory = newCat;
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Theme.of(context).colorScheme.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Theme.of(context).colorScheme.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;

    final amount =
        double.tryParse(amountText.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (amount <= 0) return;

    final finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final payload = {
      'amount': amount,
      'category': _selectedCategory,
      'note': _noteController.text.trim(),
      'dateTime': Timestamp.fromDate(finalDateTime),
      'type': _transactionType,
      'uid': FirebaseAuth.instance.currentUser?.uid,
    };

    try {
      if (widget.transactionId != null) {
        await FirebaseFirestore.instance
            .collection('transactions')
            .doc(widget.transactionId)
            .update(payload);
      } else {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('transactions')
            .add(payload);
      }

      if (!mounted) return;
      Navigator.pop(context);

      SnackBarHelper.showSuccess(
        context,
        widget.transactionId != null
            ? 'Đã cập nhật giao dịch!'
            : 'Đã lưu giao dịch thành công!',
      );
    } catch (e) {
      debugPrint('Lỗi lưu Firebase: $e');
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Lỗi khi lưu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentCategories = _transactionType == 'expense'
        ? _expenseCategories
        : _incomeCategories;
    if (!currentCategories.contains(_selectedCategory)) {
      _selectedCategory = currentCategories.first;
    }

    return AnimatedPadding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: Container(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.transactionId != null
                    ? 'Sửa giao dịch'
                    : 'Thêm giao dịch',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _transactionType = 'expense'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _transactionType == 'expense'
                                ? theme.colorScheme.surface
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _transactionType == 'expense'
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Chi tiêu',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _transactionType == 'expense'
                                    ? Colors.red.shade500
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _transactionType = 'income'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _transactionType == 'income'
                                ? theme.colorScheme.surface
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _transactionType == 'income'
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Thu nhập',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _transactionType == 'income'
                                    ? Colors.green.shade600
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                  LengthLimitingTextInputFormatter(15),
                ],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _transactionType == 'expense'
                      ? const Color(0xFF00B4D8)
                      : Colors.green.shade600,
                ),
                decoration: InputDecoration(
                  labelText: 'Số tiền *',
                  suffixText: 'VNĐ',
                  suffixStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Danh mục',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...currentCategories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = category);
                        }
                      },
                      selectedColor: theme.colorScheme.primary.withValues(
                        alpha: 0.2,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodyMedium?.color,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      showCheckmark: false,
                    );
                  }),
                  ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Tùy chọn',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    selected: false,
                    onSelected: (_) => _addNewCategory(),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.grey.shade400,
                        style: BorderStyle.solid,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _noteController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Ghi chú (Không bắt buộc)',
                  prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd/MM/yyyy').format(_selectedDate),
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.edit_calendar_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00',
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.edit_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(
                    widget.transactionId != null
                        ? 'CẬP NHẬT GIAO DỊCH'
                        : 'LƯU GIAO DỊCH',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
