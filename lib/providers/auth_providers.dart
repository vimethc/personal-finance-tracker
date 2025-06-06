import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// StreamProvider for authentication state
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// StreamProvider for user profile data
final userProfileProvider = StreamProvider.family<Map<String, dynamic>?, String?>((ref, uid) {
  if (uid == null) {
    return Stream.value(null);
  }
  final authService = ref.watch(authServiceProvider);
  return authService.getUserProfile(uid);
}); 