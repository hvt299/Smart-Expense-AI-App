import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/ai_chat_input.dart';
import '../widgets/budget_alert_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final Stream<QuerySnapshot> _transactionsStream;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    _transactionsStream = FirebaseFirestore.instance
        .collection('transactions')
        .where(
          'dateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth),
        )
        .orderBy('dateTime', descending: true)
        .snapshots();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Chào buổi sáng,';
    if (hour >= 12 && hour < 18) return 'Chào buổi chiều,';
    return 'Chào buổi tối,';
  }

  void _showTransactionDetails(
    BuildContext context,
    Map<String, dynamic> data,
    double amount,
  ) {
    final isIncome = (data['type'] ?? 'expense') == 'income';
    final sign = isIncome ? '+' : '-';
    final color = isIncome ? Colors.green.shade600 : Colors.red;

    final timestamp = data['dateTime'] ?? data['date'];
    final dateTime = timestamp != null
        ? (timestamp as Timestamp).toDate()
        : DateTime.now();
    final timeString = DateFormat('HH:mm - dd/MM/yyyy').format(dateTime);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(
                isIncome
                    ? Icons.account_balance_wallet_rounded
                    : Icons.receipt_long,
                size: 30,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              data['category'] ?? 'Khác',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$sign ${NumberFormat('#,##0').format(amount).replaceAll(',', '.')} đ',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    Icons.notes,
                    'Ghi chú',
                    data['note'] ?? 'Không có ghi chú',
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    Icons.access_time_rounded,
                    'Thời gian',
                    timeString,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'ĐÓNG',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).value;

    final displayName = user?.displayName ?? 'Bạn';
    final firstName = displayName.split(' ').last;
    final avatarUrl =
        user?.photoURL ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=random';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.grey.shade50,
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
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(avatarUrl),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  Text(
                    firstName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.black87,
              ),
              onPressed: () {},
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _transactionsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            double totalExpense = 0;
            double totalIncome = 0;
            Map<String, double> expenseCategories = {};
            Map<String, double> incomeCategories = {};

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final amount = (data['amount'] ?? 0).toDouble();
              final category = data['category'] ?? 'Khác';
              final type = data['type'] ?? 'expense';

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

            return SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SummaryCard(
                            totalExpense: totalExpense,
                            totalIncome: totalIncome,
                            expenseCategories: expenseCategories,
                            incomeCategories: incomeCategories,
                          ),
                          const SizedBox(height: 16),
                          const BudgetAlertBar(),
                          const SizedBox(height: 24),
                          const Text(
                            'Giao dịch gần đây',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (docs.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40,
                                ),
                                child: Text(
                                  'Chưa có giao dịch nào.\nHãy thử nhập liệu bên dưới nhé!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: docs.length > 5 ? 5 : docs.length,
                              itemBuilder: (context, index) {
                                final data =
                                    docs[index].data() as Map<String, dynamic>;
                                final amount = (data['amount'] ?? 0).toDouble();
                                final isIncome =
                                    (data['type'] ?? 'expense') == 'income';
                                return Card(
                                  elevation: 0,
                                  color: Colors.white,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListTile(
                                    onTap: () {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      _showTransactionDetails(
                                        context,
                                        data,
                                        amount,
                                      );
                                    },
                                    leading: CircleAvatar(
                                      backgroundColor: theme.colorScheme.primary
                                          .withValues(alpha: 0.1),
                                      child: Icon(
                                        Icons.receipt_long,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    title: Text(
                                      data['note'] ?? data['category'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(data['category'] ?? ''),
                                    trailing: Text(
                                      '${isIncome ? '+' : '-'} ${NumberFormat('#,##0').format(amount).replaceAll(',', '.')} đ',
                                      style: TextStyle(
                                        color: isIncome
                                            ? Colors.green.shade600
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const AiChatInput(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
