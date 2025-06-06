import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bill_model.dart';

class BillService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of bills for the current user
  Stream<List<BillModel>> getBills() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bills')
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BillModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Add a new bill
  Future<void> addBill({
    required String description,
    required double amount,
    required DateTime dueDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bills')
        .add({
      'description': description,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'isPaid': false,
    });
  }

  // Update an existing bill
  Future<void> updateBill(BillModel bill) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bills')
        .doc(bill.id)
        .update(bill.toMap());
  }

  // Delete a bill
  Future<void> deleteBill(String billId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bills')
        .doc(billId)
        .delete();
  }

  // Mark a bill as paid
  Future<void> markBillAsPaid(BillModel bill) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bills')
        .doc(bill.id)
        .update({'isPaid': true});
  }
} 