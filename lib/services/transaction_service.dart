import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of transactions for the current user
  Stream<List<TransactionModel>> getTransactions() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addTransaction({
    required double amount,
    required String category,
    required DateTime date,
    required String type, // 'income' or 'expense'
    required String description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .add({
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'type': type,
      'description': description,
    });
  }

  Future<void> updateTransaction({
    required String id,
    required double amount,
    required String category,
    required DateTime date,
    required String type,
    required String description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .doc(id)
        .update({
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'type': type,
      'description': description,
    });
  }

  Future<void> deleteTransaction(String id) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .doc(id)
        .delete();
  }

  // Get monthly expense summary by category
  Stream<Map<String, double>> getMonthlyExpenseSummaryByCategory(String monthKey) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value({});

    // Calculate start and end dates for the monthKey
    final year = int.parse(monthKey.split('-')[0]);
    final month = int.parse(monthKey.split('-')[1]);
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59); // Last day of the month

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .where('type', isEqualTo: 'expense')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .snapshots()
        .map((snapshot) {
      final Map<String, double> summary = {};
      for (final doc in snapshot.docs) {
        final transaction = TransactionModel.fromMap(doc.data(), doc.id);
        summary.update(transaction.category, (value) => value + transaction.amount, ifAbsent: () => transaction.amount);
      }
      return summary;
    });
  }

  // Get monthly spending trends for the last 12 months
  Stream<Map<String, double>> getSpendingTrendsMonthly() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value({});

    final now = DateTime.now();
    final twelveMonthsAgo = DateTime(now.year, now.month - 11, 1); // Start of the month 12 months ago

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .where('type', isEqualTo: 'expense')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(twelveMonthsAgo))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('date') // Order by date to group by month easily
        .snapshots()
        .map((snapshot) {
      final Map<String, double> monthlyTotals = {};
      for (final doc in snapshot.docs) {
        final transaction = TransactionModel.fromMap(doc.data(), doc.id);
        final monthKey = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
        monthlyTotals.update(monthKey, (value) => value + transaction.amount, ifAbsent: () => transaction.amount);
      }
      return monthlyTotals;
    });
  }
} 