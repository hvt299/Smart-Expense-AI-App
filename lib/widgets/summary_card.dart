import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class SummaryCard extends StatelessWidget {
  final double totalSpent;
  final Map<String, double> categoryTotals;

  const SummaryCard({
    super.key,
    required this.totalSpent,
    required this.categoryTotals,
  });

  @override
  Widget build(BuildContext context) {
    Color getColorForCategory(String category) {
      final Map<String, Color> defaultColors = {
        'Ăn uống': Colors.orange.shade400,
        'Di chuyển': const Color(0xFF00B4D8),
        'Mua sắm': Colors.purple.shade400,
        'Hóa đơn': Colors.red.shade400,
        'Khác': Colors.green.shade400,
      };

      if (defaultColors.containsKey(category)) {
        return defaultColors[category]!;
      }

      final int hash = category.hashCode;
      final int colorIndex = hash.abs() % Colors.primaries.length;
      return Colors.primaries[colorIndex];
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: totalSpent <= 0
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text(
                  'Tháng này chưa có chi tiêu nào.\nHãy bắt đầu nhập liệu nhé!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, height: 1.5),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tổng chi tháng này',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${NumberFormat('#,##0').format(totalSpent).replaceAll(',', '.')} đ',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 30,
                          sections: categoryTotals.entries.map((entry) {
                            final category = entry.key;
                            final amount = entry.value;
                            final percentage = (amount / totalSpent) * 100;

                            return PieChartSectionData(
                              color: getColorForCategory(category),
                              value: amount,
                              title: '${percentage.toStringAsFixed(0)}%',
                              radius: percentage > 30 ? 18 : 14,
                              titleStyle: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: Colors.black45, blurRadius: 2),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: categoryTotals.keys.map((category) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: getColorForCategory(category),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}
