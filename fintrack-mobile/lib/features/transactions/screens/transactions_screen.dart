// lib/features/transactions/screens/transactions_screen.dart
//
// The main Transactions tab. This is a StatefulWidget because the screen has
// CHANGING state: which month is selected, the sort order, and the type filter.
// When any of those change we call setState(), and Flutter re-runs build() to
// redraw the list. (No Riverpod — just plain Flutter state, on purpose.)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import 'package:fintrack_mobile/core/constants/app_text_styles.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/transaction_helpers.dart';
import 'package:fintrack_mobile/core/widgets/month_selector.dart';
import 'transaction_search_screen.dart';
import 'widgets/transaction_summary_bar.dart';
import 'widgets/day_section_header.dart';
import 'widgets/transaction_list_item.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  late DateTime _selectedMonth;
  TxSort _sort = TxSort.dateDesc;
  TxTypeFilter _typeFilter = TxTypeFilter.all;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    // Generate a fixed list of the last 12 months for the selector since we load one month at a time
    final now = DateTime.now();
    final months = List.generate(12, (index) {
      return DateTime(now.year, now.month - 11 + index);
    });

    final asyncTransactions = ref.watch(transactionsProvider(_selectedMonth));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildHeader(),
              const SizedBox(height: 8),
              MonthSelector(
                months: months,
                selectedMonth: _selectedMonth,
                onSelected: (month) => setState(() => _selectedMonth = month),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: asyncTransactions.when(
                  data: (models) {
                    final monthTx = models.map((m) => m.toUiModel()).toList();
                    final visible = sorted(byType(monthTx, _typeFilter), _sort);
                    final sections = groupByDay(visible);

                    return Column(
                      children: [
                        TransactionSummaryBar(transactions: monthTx),
                        const SizedBox(height: 8),
                        Expanded(child: _buildList(sections, models)),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text(
                      'Failed to load transactions: $error',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text('Transactions', style: AppTextStyles.headingLarge),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.search, color: AppColors.textPrimary),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TransactionSearchScreen(),
              ),
            );
          },
        ),
        _buildSortFilterMenu(),
      ],
    );
  }

  Widget _buildSortFilterMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
      onSelected: (value) {
        setState(() {
          switch (value) {
            case 'date_desc':
              _sort = TxSort.dateDesc;
              break;
            case 'date_asc':
              _sort = TxSort.dateAsc;
              break;
            case 'amount_desc':
              _sort = TxSort.amountDesc;
              break;
            case 'amount_asc':
              _sort = TxSort.amountAsc;
              break;
            case 'all':
              _typeFilter = TxTypeFilter.all;
              break;
            case 'income':
              _typeFilter = TxTypeFilter.all;
              break;
            case 'expense':
              _typeFilter = TxTypeFilter.expense;
              break;
          }
        });
      },
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: 'date_desc',
          checked: _sort == TxSort.dateDesc,
          child: const Text('Date: Descending'),
        ),
        CheckedPopupMenuItem(
          value: 'date_asc',
          checked: _sort == TxSort.dateAsc,
          child: const Text('Date: Ascending'),
        ),
        CheckedPopupMenuItem(
          value: 'amount_desc',
          checked: _sort == TxSort.amountDesc,
          child: const Text('Amount: Descending'),
        ),
        CheckedPopupMenuItem(
          value: 'amount_asc',
          checked: _sort == TxSort.amountAsc,
          child: const Text('Amount: Ascending'),
        ),
        const PopupMenuDivider(),
        CheckedPopupMenuItem(
          value: 'all',
          checked: _typeFilter == TxTypeFilter.all,
          child: const Text('Show all'),
        ),
        CheckedPopupMenuItem(
          value: 'income',
          checked: _typeFilter == TxTypeFilter.income,
          child: const Text('Income only'),
        ),
        CheckedPopupMenuItem(
          value: 'expense',
          checked: _typeFilter == TxTypeFilter.expense,
          child: const Text('Expenses only'),
        ),
      ],
    );
  }

  Widget _buildList(List<DaySection> sections, List<TransactionModel> models) {
    if (sections.isEmpty) return _buildEmptyState();

    final children = <Widget>[];
    for (final section in sections) {
      children.add(DaySectionHeader(day: section.day));
      for (final t in section.items) {
        // Find the matching TransactionModel by matching on dateTime + amount + name
        final model = models.firstWhere(
          (m) =>
              m.transactionDate == t.dateTime &&
              m.amount == t.amount.abs() &&
              ((m.title != null && m.title!.isNotEmpty)
                  ? m.title == t.name
                  : m.categoryName == t.name),
          orElse: () => models.first,
        );

        children.add(
          Dismissible(
            key: ValueKey(model.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red.shade400,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (_) => _confirmSwipeDelete(model),
            child: InkWell(
              onTap: () => _openEdit(model),
              child: TransactionListItem(transaction: t),
            ),
          ),
        );
      }
    }

    return ListView(children: children);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text('No transactions yet', style: AppTextStyles.headingSmall),
          const SizedBox(height: 4),
          Text(
            'Tap + to add your first transaction',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _openEdit(TransactionModel model) {
    context.push('/add_transaction', extra: model);
  }

  Future<bool> _confirmSwipeDelete(TransactionModel model) async {
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

    if (confirmed == true) {
      try {
        final deleteTx = ref.read(deleteTransactionProvider);
        await deleteTx(transactionId: model.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
        }
        return true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
        return false;
      }
    }
    return false;
  }
}
