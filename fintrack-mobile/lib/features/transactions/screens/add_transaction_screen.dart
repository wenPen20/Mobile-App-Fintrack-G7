// lib/features/transactions/screens/add_transaction_screen.dart
//
// The Add / Edit Transaction form. One screen handles BOTH:
//   - add  : push with no argument            -> AddTransactionScreen()
//   - edit : push with an existing transaction -> AddTransactionScreen(existing: model)
//
// On save/delete it calls the backend API, then pops.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import 'package:fintrack_mobile/core/constants/app_text_styles.dart';
import '../data/mock_categories.dart';
import 'package:fintrack_mobile/features/budget/models/category.dart';
import '../models/transaction_model.dart';
import '../utils/date_format.dart';
import '../providers/transaction_provider.dart';
import 'widgets/category_avatar.dart';
import 'package:fintrack_mobile/features/budget/providers/budget_provider.dart';

/// Form screen for creating or editing a transaction record.
class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? existing; // null = add, non-null = edit
  const AddTransactionScreen({super.key, this.existing});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  // ===== form state =====
  bool _isExpense = true;
  Category? _category;
  late DateTime _date; // date part only
  late TimeOfDay _time; // time part only
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      // Pre-fill every field from the TransactionModel being edited.
      _isExpense = e.type == 'expense';
      final dbCats = ref.read(categoriesProvider).value ?? [];
      _category = dbCats.firstWhere(
        (c) => c.id == e.categoryId,
        orElse: () => mockCategories.firstWhere(
          (c) => c.id == e.categoryId,
          orElse: () => mockCategories.first,
        ),
      );
      _date = DateTime(
        e.transactionDate.year,
        e.transactionDate.month,
        e.transactionDate.day,
      );
      _time = TimeOfDay.fromDateTime(e.transactionDate);
      _amountController.text = e.amount.toStringAsFixed(2);
      _titleController.text = e.title ?? '';
      _notesController.text = e.note ?? '';
    } else {
      // Add mode: default to right now.
      final now = DateTime.now();
      _date = DateTime(now.year, now.month, now.day);
      _time = TimeOfDay.fromDateTime(now);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ===== build =====
  @override
  Widget build(BuildContext context) {
    final combined = _combinedDateTime();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Edit Transaction' : 'Add Transaction',
                style: AppTextStyles.headingLarge,
              ),
              const SizedBox(height: 20),

              _buildTypeToggle(),
              const SizedBox(height: 24),

              // Category box (left) + amount (right), on one row.
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildCategoryBox(),
                  const SizedBox(width: 16),
                  Expanded(child: _buildAmountField()),
                ],
              ),
              const SizedBox(height: 24),

              // Date + time, side by side.
              Row(
                children: [
                  Expanded(
                    child: _buildPickerBox(
                      icon: Icons.calendar_today_rounded,
                      label: formatRelativeDate(_date),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickerBox(
                      icon: Icons.access_time_rounded,
                      label: formatTime(combined),
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildTextField(controller: _titleController, hint: 'Title'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _notesController,
                hint: 'Notes',
                maxLines: 3,
              ),
              const SizedBox(height: 28),

              // Save (full width).
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save'),
                ),
              ),

              // Delete (edit mode only).
              if (_isEditing) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      side: BorderSide(color: Colors.red.shade200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isSaving ? null : _confirmDelete,
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ===== small pieces =====

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _typeTab('Expense', expenseValue: true),
          _typeTab('Income', expenseValue: false),
        ],
      ),
    );
  }

  Widget _typeTab(String label, {required bool expenseValue}) {
    final selected = _isExpense == expenseValue;
    // Expense highlights red-ish, income green-ish, to reinforce the meaning.
    final activeColor = expenseValue
        ? Colors.red.shade400
        : Colors.green.shade600;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setType(expenseValue),
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? activeColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? activeColor : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBox() {
    return GestureDetector(
      onTap: _pickCategory,
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: _category == null
            ? const Icon(Icons.add, color: AppColors.textSecondary)
            : CategoryAvatar(category: _category!, size: 48),
      ),
    );
  }

  Widget _buildAmountField() {
    const amountStyle = TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    );
    // "RM" is a permanent sibling Text (not the field's prefixText, which Flutter
    // hides until the field is focused/non-empty). IntrinsicWidth sizes the field
    // to its content so "RM 0.00" stays tight and right-aligned.
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'RM ',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        IntrinsicWidth(
          child: TextField(
            controller: _amountController,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: amountStyle,
            decoration: const InputDecoration(
              hintText: '0.00',
              border: InputBorder.none,
              isCollapsed: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerBox({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  // ===== actions =====

  DateTime _combinedDateTime() =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  void _setType(bool expense) {
    setState(() {
      _isExpense = expense;
      // A category belongs to one type; clear it if it no longer matches.
      if (_category != null && _category!.isExpense != _isExpense) {
        _category = null;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _pickCategory() async {
    // Only show categories that match the current Expense/Income choice.
    final dbCats = ref.read(categoriesProvider).value ?? [];
    final options = dbCats.where((c) => c.isExpense == _isExpense).toList();
    if (options.isEmpty) {
      options.addAll(mockCategories.where((c) => c.isExpense == _isExpense));
    }

    final picked = await showModalBottomSheet<Category>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Category', style: AppTextStyles.headingSmall),
                const SizedBox(height: 16),
                Flexible(
                  child: GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 8,
                    children: options.map((c) {
                      return GestureDetector(
                        onTap: () => Navigator.pop(sheetContext, c),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CategoryAvatar(category: c, size: 48),
                            const SizedBox(height: 6),
                            Text(
                              c.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null && mounted) setState(() => _category = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();

    if (_category == null) return _snack('Please pick a category');
    if (amount == null || amount <= 0) return _snack('Enter a valid amount');

    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        // Update existing transaction via API
        final updateTx = ref.read(updateTransactionProvider);
        final payload = <String, dynamic>{
          'category_id': _category!.id,
          'type': _isExpense ? 'expense' : 'income',
          'amount': amount,
          'title': title.isNotEmpty ? title : null,
          'note': notes.isNotEmpty ? notes : null,
          'transaction_date': _combinedDateTime().toUtc().toIso8601String(),
        };
        await updateTx(transactionId: widget.existing!.id, data: payload);
      } else {
        // Create new transaction via API
        final addTx = ref.read(addTransactionProvider);
        await addTx(
          categoryId: _category!.id,
          type: _isExpense ? 'expense' : 'income',
          amount: amount,
          title: title.isNotEmpty ? title : null,
          note: notes.isNotEmpty ? notes : null,
          transactionDate: _combinedDateTime(),
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      _snack('Failed to save transaction: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This transaction will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Delete', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _isSaving = true);
      try {
        final deleteTx = ref.read(deleteTransactionProvider);
        await deleteTx(transactionId: widget.existing!.id);
        if (mounted) context.pop();
      } catch (e) {
        _snack('Failed to delete transaction: $e');
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
