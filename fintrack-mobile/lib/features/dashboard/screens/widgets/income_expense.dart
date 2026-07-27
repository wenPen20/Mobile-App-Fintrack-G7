import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import 'package:fintrack_mobile/core/constants/app_text_styles.dart';
import 'package:fintrack_mobile/features/dashboard/providers/dashboard_provider.dart';

class IncomeExpenseCard extends ConsumerWidget {
  const IncomeExpenseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(dashboardTrendProvider);

    return trendAsync.when(
      data: (trendData) {
        final List<FlSpot> incomeSpots = [];
        final List<FlSpot> expenseSpots = [];
        final List<String> labels = [];

        final now = DateTime.now();
        const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

        for (int i = 0; i < trendData.length; i++) {
          final summary = trendData[i];
          final double income = (summary['total_income'] as num).toDouble();
          final double expenses = (summary['total_expenses'] as num).toDouble();

          incomeSpots.add(FlSpot(i.toDouble(), income));
          expenseSpots.add(FlSpot(i.toDouble(), expenses));

          final targetMonth = DateTime(now.year, now.month - (5 - i));
          labels.add(monthNames[targetMonth.month - 1]);
        }

        return _buildChart(incomeSpots, expenseSpots, labels);
      },
      loading: () => _buildLoadingCard(),
      error: (err, stack) => _buildChart([], [], []),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 260,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const CircularProgressIndicator(),
    );
  }

  Widget _buildChart(List<FlSpot> incomeSpots, List<FlSpot> expenseSpots, List<String> labels) {
    final safeIncomeSpots = incomeSpots.isEmpty
        ? const [FlSpot(0, 0), FlSpot(1, 0), FlSpot(2, 0), FlSpot(3, 0), FlSpot(4, 0), FlSpot(5, 0)]
        : incomeSpots;
    final safeExpenseSpots = expenseSpots.isEmpty
        ? const [FlSpot(0, 0), FlSpot(1, 0), FlSpot(2, 0), FlSpot(3, 0), FlSpot(4, 0), FlSpot(5, 0)]
        : expenseSpots;
    final safeLabels = labels.isEmpty ? const ['-', '-', '-', '-', '-', '-'] : labels;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Income vs Expenses', style: AppTextStyles.headingSmall),
          const SizedBox(height: 4),
          Text('Last 6 months', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= safeLabels.length) return const SizedBox();
                        return Text(safeLabels[index], style: const TextStyle(fontSize: 11));
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.white.withValues(alpha: 0.95),
                    tooltipRoundedRadius: 8,
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: safeIncomeSpots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: safeExpenseSpots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: Colors.redAccent,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.redAccent.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend(AppColors.primary, 'Income'),
              const SizedBox(width: 24),
              _legend(Colors.redAccent, 'Expenses'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
