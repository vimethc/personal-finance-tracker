import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password and save initial user data
  Future<User?> signUpWithEmailAndPassword({required String email, required String password, required String username, required String phoneNumber, required String gender}) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      if (user != null) {
        // Save additional user data to Firestore
        await _firestore.collection('user_profiles').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'username': username,
          'phoneNumber': phoneNumber,
          'gender': gender,
          'createdAt': Timestamp.now(),
        });
      }
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword({required String email, required String password}) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user profile data from Firestore
  Stream<Map<String, dynamic>?> getUserProfile(String uid) {
    return _firestore.collection('user_profiles').doc(uid).snapshots().map((snapshot) => snapshot.data());
  }

  // Update user profile data in Firestore
  Future<void> updateUserProfile(String uid, {String? username, String? phoneNumber, String? gender}) async {
    await _firestore.collection('user_profiles').doc(uid).set({
      if (username != null) 'username': username,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (gender != null) 'gender': gender,
    }, SetOptions(merge: true));
  }
} 