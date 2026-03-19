import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DateTime _selectedMonth = DateTime.now();

  bool _showExpense = true;

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
        1,
      );
    });
  }

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
    return Colors.primaries[hash.abs() % Colors.primaries.length];
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
      23,
      59,
      59,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.75),
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: const Text(
          'Thống kê chi tiết',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed:
                      _selectedMonth.year == 2000 && _selectedMonth.month == 1
                      ? null
                      : () => _changeMonth(-1),
                ),
                Text(
                  'Tháng ${_selectedMonth.month}, ${_selectedMonth.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed:
                      _selectedMonth.month == DateTime.now().month &&
                          _selectedMonth.year == DateTime.now().year
                      ? null
                      : () => _changeMonth(1),
                ),
              ],
            ),
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .where(
              'dateTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(firstDay),
            )
            .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(lastDay))
            .orderBy('dateTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Lỗi tải dữ liệu: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          double totalExpense = 0;
          double totalIncome = 0;
          Map<String, double> expenseCategories = {};
          Map<String, double> incomeCategories = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['amount'] ?? 0).toDouble();
            final type = data['type'] ?? 'expense';
            final category = data['category'] ?? 'Khác';

            if (type == 'expense') {
              totalExpense += amount;
              expenseCategories[category] =
                  (expenseCategories[category] ?? 0) + amount;
            } else {
              totalIncome += amount;
              incomeCategories[category] =
                  (incomeCategories[category] ?? 0) + amount;
            }
          }

          final balance = totalIncome - totalExpense;
          final currentTotal = _showExpense ? totalExpense : totalIncome;
          final currentCategoriesMap = _showExpense
              ? expenseCategories
              : incomeCategories;
          final themeColor = _showExpense
              ? Colors.red.shade500
              : Colors.green.shade600;

          var sortedCategories = currentCategoriesMap.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 160, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
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
                  child: Column(
                    children: [
                      const Text(
                        'Số dư khả dụng',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${balance >= 0 ? '+' : ''}${NumberFormat('#,##0').format(balance).replaceAll(',', '.')} đ',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: balance >= 0
                              ? Colors.green.shade600
                              : Colors.red,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_downward_rounded,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Tổng thu',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${NumberFormat('#,##0').format(totalIncome).replaceAll(',', '.')} đ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey.shade200,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_upward_rounded,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Tổng chi',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${NumberFormat('#,##0').format(totalExpense).replaceAll(',', '.')} đ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showExpense = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _showExpense
                                  ? Colors.red.shade50
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Chi tiêu',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _showExpense
                                      ? Colors.red.shade600
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
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_showExpense
                                  ? Colors.green.shade50
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Thu nhập',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: !_showExpense
                                      ? Colors.green.shade700
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

                if (currentTotal > 0) ...[
                  Text(
                    _showExpense ? 'Cơ cấu chi tiêu' : 'Cơ cấu thu nhập',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
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
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: Stack(
                            children: [
                              PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 60,
                                  sections: sortedCategories.map((entry) {
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
                                      title:
                                          '${percentage.toStringAsFixed(0)}%',
                                      radius: percentage > 30 ? 24 : 18,
                                      titleStyle: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
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
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _showExpense ? 'Tổng chi' : 'Tổng thu',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      NumberFormat.compact(
                                        locale: "vi",
                                      ).format(currentTotal),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20,
                                        color: themeColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...sortedCategories.map((entry) {
                          final category = entry.key;
                          final amount = entry.value;
                          final percentage = (amount / currentTotal);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getColorForCategory(
                                      category,
                                      _showExpense,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            category,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '${NumberFormat('#,##0').format(amount).replaceAll(',', '.')} đ',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                        value: percentage,
                                        backgroundColor: Colors.grey.shade100,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              _getColorForCategory(
                                                category,
                                                _showExpense,
                                              ),
                                            ),
                                        borderRadius: BorderRadius.circular(4),
                                        minHeight: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.pie_chart_outline_rounded,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có khoản ${_showExpense ? 'chi' : 'thu'} nào trong tháng.',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
