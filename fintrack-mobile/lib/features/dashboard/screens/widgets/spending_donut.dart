import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import 'package:fintrack_mobile/core/constants/app_text_styles.dart';
import 'package:fintrack_mobile/features/dashboard/providers/dashboard_provider.dart';

class SpendingDonutCard extends ConsumerWidget {
  const SpendingDonutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthDate = DateTime(now.year, now.month);
    final summaryAsync = ref.watch(budgetSummaryProvider(monthDate));

    return summaryAsync.when(
      data: (summary) {
        final Map<String, dynamic> breakdown = Map<String, dynamic>.from(summary['per_category_breakdown'] ?? {});
        final double totalExpenses = (summary['total_expenses'] as num).toDouble();

        final List<_Category> categories = [];
        final List<Color> colors = [
          Colors.orangeAccent,
          AppColors.primary,
          Colors.purpleAccent,
          Colors.redAccent,
          Colors.teal,
          Colors.amber,
          Colors.grey
        ];
        
        int colorIndex = 0;
        breakdown.forEach((categoryName, amountVal) {
          final double amount = (amountVal as num).toDouble();
          final double percentage = totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0.0;
          categories.add(_Category(
            categoryName,
            percentage,
            colors[colorIndex % colors.length],
          ));
          colorIndex++;
        });

        return _buildCard(context, categories, totalExpenses);
      },
      loading: () => _buildLoadingCard(),
      error: (err, stack) => _buildCard(context, [], 0.0),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 240,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const CircularProgressIndicator(),
    );
  }

  Widget _buildCard(BuildContext context, List<_Category> categories, double totalExpenses) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spending by Category', style: AppTextStyles.headingSmall),
          const SizedBox(height: 4),
          Text('This month', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 20),
          if (categories.isEmpty || totalExpenses <= 0)
            SizedBox(
              height: 160,
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No expenses recorded this month',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  height: 160,
                  width: 160,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: categories.map((c) {
                        return PieChartSectionData(
                          value: c.percentage,
                          color: c.color,
                          radius: 30,
                          showTitle: false,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: categories.map((c) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: c.color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.label,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${c.percentage.toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Category {
  final String label;
  final double percentage;
  final Color color;
  _Category(this.label, this.percentage, this.color);
}
