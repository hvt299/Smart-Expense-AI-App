import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BudgetAlertBar extends StatelessWidget {
  const BudgetAlertBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSkeleton(context);
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final double budget =
            (userData?['monthlyBudget'] as num?)?.toDouble() ?? 0;

        if (budget <= 0) {
          return _buildContainer(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Ngân sách tháng',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bạn chưa thiết lập hạn mức chi tiêu.\nHãy vào phần Cá nhân để cập nhật nhé!',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('transactions')
              .where('uid', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, txSnapshot) {
            if (txSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingSkeleton(context);
            }

            double spent = 0;
            if (txSnapshot.hasData) {
              for (var doc in txSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['dateTime'] == null) continue;

                final date = (data['dateTime'] as Timestamp).toDate();
                if (data['type'] == 'expense' &&
                    date.isAfter(
                      startOfMonth.subtract(const Duration(seconds: 1)),
                    ) &&
                    date.isBefore(endOfMonth.add(const Duration(seconds: 1)))) {
                  spent += (data['amount'] as num).toDouble();
                }
              }
            }

            double percent = spent / budget;
            final double safePercent = percent > 1.0 ? 1.0 : percent;

            final Color progressColor = percent > 0.9
                ? Colors.red.shade500
                : (percent > 0.7
                      ? Colors.orange.shade400
                      : const Color(0xFF00B4D8));

            final formatter = NumberFormat('#,##0');
            final formattedSpent = formatter.format(spent).replaceAll(',', '.');

            final double remaining = budget - spent;
            final String remainingText = remaining >= 0
                ? 'Còn lại: ${formatter.format(remaining).replaceAll(',', '.')} đ'
                : 'Vượt ngân sách: ${formatter.format(remaining.abs()).replaceAll(',', '.')} đ';

            return _buildContainer(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ngân sách tháng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${(percent * 100).toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: safePercent,
                      minHeight: 10,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đã chi: $formattedSpent đ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        remainingText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: remaining >= 0
                              ? theme.textTheme.bodyMedium?.color
                              : Colors.red.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContainer(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);

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
      child: child,
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    final theme = Theme.of(context);

    return _buildContainer(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 120,
                height: 20,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              Container(
                width: 40,
                height: 20,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 100,
                height: 16,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              Container(
                width: 100,
                height: 16,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
