import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String uid;
  final double amount;
  final String category;
  final String note;
  final String type;
  final DateTime dateTime;

  TransactionModel({
    required this.id,
    required this.uid,
    required this.amount,
    required this.category,
    this.note = '',
    required this.type,
    required this.dateTime,
  });

  factory TransactionModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    final timestamp = map['dateTime'] ?? map['createdAt'];

    return TransactionModel(
      id: documentId,
      uid: map['uid'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      category: map['category'] ?? 'Khác',
      note: map['note'] ?? '',
      type: map['type'] ?? 'expense',
      dateTime: timestamp != null
          ? (timestamp as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
