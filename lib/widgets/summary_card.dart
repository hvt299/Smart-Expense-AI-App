import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class SummaryCard extends StatefulWidget {
  final double totalExpense;
  final double totalIncome;
  final Map<String, double> expenseCategories;
  final Map<String, double> incomeCategories;

  const SummaryCard({
    super.key,
    required this.totalExpense,
    required this.totalIncome,
    required this.expenseCategories,
    required this.incomeCategories,
  });

  @override
  State<SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard> {
  bool _showExpense = true;

  Color _getColorForCategory(String category, bool isExpense) {
    final Map<String, Color> defaultExpenseColors = {
      'Ăn uống': Colors.orange.shade400,
      'Di chuyển': const Color(0xFF00B4D8),
      'Mua sắm': Colors.purple.shade400,
      'Hóa đơn': Colors.red.shade400,
      'Khác': Colors.grey.shade500,
    };

    final Map<String, Color> defaultIncomeColors = {
      'Lương': Colors.green.shade500,
      'Thưởng': Colors.teal.shade400,
      'Freelance': Colors.blue.shade400,
      'Kinh doanh': Colors.indigo.shade400,
      'Khác': Colors.grey.shade500,
    };

    final targetMap = isExpense ? defaultExpenseColors : defaultIncomeColors;

    if (targetMap.containsKey(category)) return targetMap[category]!;

    final int hash = category.hashCode;
    final int colorIndex = hash.abs() % Colors.primaries.length;
    return Colors.primaries[colorIndex];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final currentTotal = _showExpense
        ? widget.totalExpense
        : widget.totalIncome;
    final currentCategories = _showExpense
        ? widget.expenseCategories
        : widget.incomeCategories;
    final themeColor = _showExpense
        ? Colors.red.shade500
        : Colors.green.shade600;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                    onTap: () => setState(() => _showExpense = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _showExpense
                            ? theme.colorScheme.surface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _showExpense
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Chi tiêu',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _showExpense
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
                    onTap: () => setState(() => _showExpense = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_showExpense
                            ? theme.colorScheme.surface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: !_showExpense
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Thu nhập',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: !_showExpense
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
          const SizedBox(height: 20),

          currentTotal <= 0
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text(
                      'Tháng này chưa có khoản ${_showExpense ? 'chi' : 'thu'} nào.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        height: 1.5,
                      ),
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
                              Text(
                                _showExpense
                                    ? 'Tổng chi tháng này'
                                    : 'Tổng thu tháng này',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_showExpense ? '-' : '+'}${NumberFormat('#,##0').format(currentTotal).replaceAll(',', '.')} đ',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: themeColor,
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
                              sections: currentCategories.entries.map((entry) {
                                final category = entry.key;
                                final amount = entry.value;
                                final percentage =
                                    (amount / currentTotal) * 100;

                                return PieChartSectionData(
                                  color: _getColorForCategory(
                                    category,
                                    _showExpense,
                                  ),
                                  value: amount,
                                  title: '${percentage.toStringAsFixed(0)}%',
                                  radius: percentage > 30 ? 18 : 14,
                                  titleStyle: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 2,
                                      ),
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
                      children: currentCategories.keys.map((category) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _getColorForCategory(
                                  category,
                                  _showExpense,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              category,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textTheme.bodyMedium?.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
