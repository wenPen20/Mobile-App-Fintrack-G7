// lib/features/transactions/screens/transaction_search_screen.dart
//
// The SEARCH screen (pushed on top of the Transactions tab, so it gets a back
// arrow from the default AppBar). Type to filter transactions by name; tap a
// chip to also filter by income / expense. Functional, on the mock data.
//
// StatefulWidget because it holds changing state: the search text + the chosen
// type filter.

import 'package:flutter/material.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import 'package:fintrack_mobile/core/constants/app_text_styles.dart';
import '../utils/transaction_helpers.dart';
import 'widgets/day_section_header.dart';
import 'widgets/transaction_list_item.dart';
import '../models/transaction_ui.dart';

class TransactionSearchScreen extends StatefulWidget {
  final List<TransactionUi> transactions;

  const TransactionSearchScreen({super.key, required this.transactions});

  @override
  State<TransactionSearchScreen> createState() =>
      _TransactionSearchScreenState();
}

class _TransactionSearchScreenState extends State<TransactionSearchScreen> {
  // Controls the text field's contents. We must dispose() it (see below).
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  TxTypeFilter _typeFilter = TxTypeFilter.all;

  @override
  void dispose() {
    // Controllers hold resources — always dispose them when the screen is gone,
    // or you leak memory. (A StatefulWidget gives us this dispose() hook.)
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Same pipeline as the main screen, but searching instead of month-filtering:
    final results = sorted(
      byType(bySearch(widget.transactions, _query), _typeFilter),
      TxSort.dateDesc,
    );
    final sections = groupByDay(results);

    return Scaffold(
      backgroundColor: AppColors.background,
      // A bare AppBar: we only want its automatic back button. Transparent so it
      // blends with the background.
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Search', style: AppTextStyles.headingLarge),
              const SizedBox(height: 12),

              // The search box. onChanged fires on every keystroke -> setState ->
              // build() re-runs -> results update live.
              TextField(
                controller: _controller,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search transactions…',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Income / Expense chips. ChoiceChip = a chip that's selected or not.
              Row(
                children: [
                  _typeChip('All', TxTypeFilter.all),
                  const SizedBox(width: 8),
                  _typeChip('Income', TxTypeFilter.income),
                  const SizedBox(width: 8),
                  _typeChip('Expense', TxTypeFilter.expense),
                ],
              ),
              const SizedBox(height: 8),

              Expanded(child: _buildResults(sections)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String label, TxTypeFilter value) {
    final selected = _typeFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _typeFilter = value),
    );
  }

  Widget _buildResults(List<DaySection> sections) {
    if (sections.isEmpty) {
      return Center(
        child: Text(
          'No matching transactions',
          style: AppTextStyles.bodyMedium,
        ),
      );
    }
    final children = <Widget>[];
    for (final section in sections) {
      children.add(DaySectionHeader(day: section.day));
      for (final t in section.items) {
        children.add(TransactionListItem(transaction: t));
      }
    }
    return ListView(children: children);
  }
}
