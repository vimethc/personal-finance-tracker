import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Set budget for a specific month (e.g., '2024-06')
  Future<void> setBudget(double amount, String monthKey) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .doc(monthKey)
        .set({'amount': amount});
  }

  // Get budget for a specific month
  Stream<double?> getBudget(String monthKey) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .doc(monthKey)
        .snapshots()
        .map((doc) => doc.data()?['amount'] != null ? (doc.data()!['amount'] as num).toDouble() : null);
  }
} 