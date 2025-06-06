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
} 