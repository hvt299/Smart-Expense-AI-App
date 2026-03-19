import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/add_transaction_bottom_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filterType = 'all';
  String _filterCategory = 'all';
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  List<String> _dynamicCategories = [];

  bool get _isFilterActive =>
      _filterType != 'all' ||
      _filterCategory != 'all' ||
      _filterStartDate != null ||
      _filterEndDate != null;

  Future<void> _deleteTransaction(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(docId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa giao dịch thành công'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } catch (e) {
      debugPrint('Lỗi xóa: $e');
    }
  }

  void _showTransactionDetails(
    BuildContext context,
    Map<String, dynamic> data,
    double amount,
  ) {
    final isIncome = (data['type'] ?? 'expense') == 'income';
    final sign = isIncome ? '+' : '-';
    final color = isIncome ? Colors.green.shade600 : Colors.red;

    final timestamp = data['dateTime'] ?? data['createdAt'];
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

  void _showFilterBottomSheet(List<String> availableCategories) {
    String tempType = _filterType;
    String tempCategory = _filterCategory;
    DateTime? tempStartDate = _filterStartDate;
    DateTime? tempEndDate = _filterEndDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final theme = Theme.of(context);

          Future<void> pickDateRange() async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2000),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              initialDateRange: tempStartDate != null && tempEndDate != null
                  ? DateTimeRange(start: tempStartDate!, end: tempEndDate!)
                  : null,
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: theme.colorScheme.primary,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              setModalState(() {
                tempStartDate = picked.start;
                tempEndDate = picked.end;
              });
            }
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Lọc giao dịch',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                const Text(
                  'Loại giao dịch',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('Tất cả')),
                    ButtonSegment(value: 'expense', label: Text('Chi tiêu')),
                    ButtonSegment(value: 'income', label: Text('Thu nhập')),
                  ],
                  selected: {tempType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setModalState(() => tempType = newSelection.first);
                  },
                ),
                const SizedBox(height: 20),

                const Text(
                  'Danh mục',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: availableCategories.contains(tempCategory)
                      ? tempCategory
                      : 'all',
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text(
                        'Tất cả danh mục',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    ...availableCategories.map(
                      (c) => DropdownMenuItem(value: c, child: Text(c)),
                    ),
                  ],
                  onChanged: (val) => setModalState(() => tempCategory = val!),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Thời gian',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: pickDateRange,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          tempStartDate != null && tempEndDate != null
                              ? '${DateFormat('dd/MM/yyyy').format(tempStartDate!)}  -  ${DateFormat('dd/MM/yyyy').format(tempEndDate!)}'
                              : 'Chọn khoảng thời gian...',
                          style: TextStyle(
                            fontWeight: tempStartDate != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: tempStartDate != null
                                ? Colors.black87
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (tempStartDate != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setModalState(() {
                        tempStartDate = null;
                        tempEndDate = null;
                      }),
                      child: const Text(
                        'Xóa thời gian',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),

                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _filterType = tempType;
                        _filterCategory = tempCategory;
                        _filterStartDate = tempStartDate;
                        _filterEndDate = tempEndDate;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'ÁP DỤNG',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: const Text(
          'Lịch sử giao dịch',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.filter_list_rounded,
                  color: _isFilterActive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.black87,
                ),
                onPressed: () {
                  final categoriesToShow = _dynamicCategories.isNotEmpty
                      ? _dynamicCategories
                      : [
                          'Ăn uống',
                          'Di chuyển',
                          'Mua sắm',
                          'Hóa đơn',
                          'Lương',
                          'Thưởng',
                          'Freelance',
                          'Kinh doanh',
                          'Khác',
                        ];

                  categoriesToShow.sort();

                  _showFilterBottomSheet(categoriesToShow);
                },
              ),
              if (_isFilterActive)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          if (_isFilterActive)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_rounded, color: Colors.red),
              onPressed: () => setState(() {
                _filterType = 'all';
                _filterCategory = 'all';
                _filterStartDate = null;
                _filterEndDate = null;
              }),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .orderBy('dateTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rawDocs = snapshot.data?.docs ?? [];

          _dynamicCategories = rawDocs
              .map(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['category'] as String?,
              )
              .where((c) => c != null)
              .cast<String>()
              .toSet()
              .toList();

          final filteredDocs = rawDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final type = data['type'] ?? 'expense';
            final category = data['category'] ?? 'Khác';
            final timestamp = data['dateTime'] ?? data['createdAt'];
            final date = timestamp != null
                ? (timestamp as Timestamp).toDate()
                : DateTime.now();

            if (_filterType != 'all' && type != _filterType) return false;
            if (_filterCategory != 'all' && category != _filterCategory) {
              return false;
            }
            if (_filterStartDate != null && date.isBefore(_filterStartDate!)) {
              return false;
            }
            if (_filterEndDate != null &&
                date.isAfter(
                  _filterEndDate!.add(const Duration(hours: 23, minutes: 59)),
                )) {
              return false;
            }

            return true;
          }).toList();

          if (filteredDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isFilterActive
                        ? Icons.search_off_rounded
                        : Icons.receipt_long_rounded,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isFilterActive
                        ? 'Không tìm thấy giao dịch nào phù hợp.'
                        : 'Chưa có dữ liệu giao dịch.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final amount = (data['amount'] ?? 0).toDouble();
              final isIncome = (data['type'] ?? 'expense') == 'income';
              final timestamp = data['dateTime'] ?? data['createdAt'];
              final timeString = timestamp != null
                  ? DateFormat(
                      'dd/MM/yyyy • HH:mm',
                    ).format((timestamp as Timestamp).toDate())
                  : '';

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.horizontal,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                secondaryBackground: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade400,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Text(
                          "Xóa giao dịch?",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        content: const Text(
                          "Hành động này không thể hoàn tác.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text(
                              "HỦY",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("XÓA"),
                          ),
                        ],
                      ),
                    );
                  } else if (direction == DismissDirection.endToStart) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AddTransactionBottomSheet(
                        transactionId: doc.id,
                        initialType: data['type'],
                        initialAmount: amount,
                        initialCategory: data['category'],
                        initialNote: data['note'],
                      ),
                    );
                    return false;
                  }
                  return false;
                },
                onDismissed: (direction) {
                  if (direction == DismissDirection.startToEnd) {
                    _deleteTransaction(doc.id);
                  }
                },
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade100),
                  ),
                  child: ListTile(
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      _showTransactionDetails(context, data, amount);
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: (isIncome ? Colors.green : Colors.red)
                          .withValues(alpha: 0.1),
                      child: Icon(
                        isIncome
                            ? Icons.account_balance_wallet_rounded
                            : Icons.receipt_long_rounded,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      data['note']?.toString().isNotEmpty == true
                          ? data['note']
                          : (data['category'] ?? 'Khác'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$timeString\n${data['category']}',
                        style: TextStyle(
                          height: 1.4,
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${isIncome ? '+' : '-'} ${NumberFormat('#,##0').format(amount).replaceAll(',', '.')} đ',
                          style: TextStyle(
                            color: isIncome
                                ? Colors.green.shade600
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
