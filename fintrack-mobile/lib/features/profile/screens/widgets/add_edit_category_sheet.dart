// lib/features/profile/screens/widgets/add_edit_category_sheet.dart
//
// Bottom sheet for creating or editing a category.
// Shows: name field, type toggle (locked in edit mode), color swatches, icon grid.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import 'package:fintrack_mobile/core/constants/app_text_styles.dart';
import 'package:fintrack_mobile/core/constants/category_visuals.dart';
import 'package:fintrack_mobile/features/budget/models/category.dart';
import 'package:fintrack_mobile/features/profile/providers/category_provider.dart';

// ─── Preset palettes ──────────────────────────────────────────────────────────

const _presetColors = [
  '#D85A30', '#E24B4A', '#EF9F27', '#EF9F55', '#639922',
  '#1D9E75', '#0F6E56', '#5DCAA5', '#9FE1CB', '#378ADD',
  '#185FA5', '#7F77DD', '#D4537E', '#888780', '#085041',
];

const _presetIcons = [
  'utensils', 'car', 'shopping-bag', 'file-text', 'film',
  'heart', 'book', 'briefcase', 'laptop', 'trending-up',
  'store', 'map-pin', 'more-horizontal', 'plus-circle',
];

// ─── Sheet ────────────────────────────────────────────────────────────────────

class AddEditCategorySheet extends ConsumerStatefulWidget {
  /// Pass a category to edit; null = create mode.
  final Category? existing;

  const AddEditCategorySheet({super.key, this.existing});

  @override
  ConsumerState<AddEditCategorySheet> createState() =>
      _AddEditCategorySheetState();
}

class _AddEditCategorySheetState extends ConsumerState<AddEditCategorySheet> {
  final _nameController = TextEditingController();
  late String _selectedColor;
  late String _selectedIcon;
  late String _selectedType; // 'expense' or 'income'
  bool _isSaving = false;
  String? _errorText;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final cat = widget.existing;
    _nameController.text = cat?.name ?? '';
    _selectedColor = cat?.colorHex ?? _presetColors.first;
    _selectedIcon = cat?.icon ?? _presetIcons.first;
    _selectedType = cat?.type ?? 'expense';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Name cannot be empty');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final data = {
        'name': name,
        'icon': _selectedIcon,
        'color_hex': _selectedColor,
        'type': _selectedType,
      };

      if (_isEditing) {
        await ref.read(updateCategoryProvider)(widget.existing!.id, data);
      } else {
        await ref.read(createCategoryProvider)(data);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorText = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title bar ────────────────────────────────────────────────────
          Row(
            children: [
              Text(
                _isEditing ? 'Edit Category' : 'New Category',
                style: AppTextStyles.headingSmall,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Name ─────────────────────────────────────────────────────────
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Category Name',
              errorText: _errorText,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),

          // ── Type toggle (locked in edit mode) ────────────────────────────
          Text('Type', style: AppTextStyles.labelSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              _TypeChip(
                label: 'Expense',
                selected: _selectedType == 'expense',
                color: AppColors.error,
                onTap: _isEditing
                    ? null
                    : () => setState(() => _selectedType = 'expense'),
              ),
              const SizedBox(width: 10),
              _TypeChip(
                label: 'Income',
                selected: _selectedType == 'income',
                color: AppColors.accent,
                onTap: _isEditing
                    ? null
                    : () => setState(() => _selectedType = 'income'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Color picker ─────────────────────────────────────────────────
          Text('Color', style: AppTextStyles.labelSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _presetColors.map((hex) {
              final isSelected = hex == _selectedColor;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = hex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colorFromHex(hex),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.textPrimary
                          : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colorFromHex(hex).withValues(alpha: 0.5),
                              blurRadius: 6,
                            )
                          ]
                        : [],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // ── Icon picker ──────────────────────────────────────────────────
          Text('Icon', style: AppTextStyles.labelSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _presetIcons.map((name) {
              final isSelected = name == _selectedIcon;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorFromHex(_selectedColor).withValues(alpha: 0.15)
                        : AppColors.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? colorFromHex(_selectedColor)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    iconForName(name),
                    size: 20,
                    color: isSelected
                        ? colorFromHex(_selectedColor)
                        : AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // ── Save button ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(Colors.white)),
                    )
                  : Text(_isEditing ? 'Save Changes' : 'Create Category'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small helper widget ──────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : AppColors.textSecondary,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
