import 'package:cloud_firestore/cloud_firestore.dart';

class BillModel {
  final String id;
  final String description;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;
  // Add more fields if needed, e.g., recurrence, category

  BillModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
  });

  // Convert Firestore DocumentSnapshot to BillModel
  factory BillModel.fromMap(Map<String, dynamic> map, String id) {
    return BillModel(
      id: id,
      description: map['description'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: (map['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPaid: map['isPaid'] ?? false,
    );
  }

  // Convert BillModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'isPaid': isPaid,
    };
  }

  // Copy with method for easy updates
  BillModel copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? dueDate,
    bool? isPaid,
  }) {
    return BillModel(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
    );
  }
} 