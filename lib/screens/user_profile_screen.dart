import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart'; // Import auth providers
import '../services/auth_service.dart'; // Import AuthService
import 'auth_screen.dart'; // Import AuthScreen

class UserProfileScreen extends ConsumerStatefulWidget { // Changed to StatefulWidget
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  String _selectedGender = 'Prefer not to say';
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  // Function to load initial user data
  void _loadUserData(Map<String, dynamic>? userData) {
    if (userData != null) {
      _usernameController.text = userData['username'] ?? '';
      _phoneNumberController.text = userData['phoneNumber'] ?? '';
      _selectedGender = userData['gender'] ?? 'Prefer not to say';
    }
  }

  // Function to save user data
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser; // Get current user from auth service

    if (user == null) {
      setState(() {
        _error = 'User not logged in.';
        _isLoading = false;
      });
      return;
    }

    try {
      await authService.updateUserProfile(
        user.uid,
        username: _usernameController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        gender: _selectedGender,
      );
      // Optionally show a success message
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Profile updated successfully!'))
       );
       Navigator.of(context).pop(); // Go back after saving
    } catch (e) {
      setState(() {
        _error = 'Failed to update profile: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF512DA8);
    final accentColor = const Color(0xFF9575CD);
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser; // Get current user for email

    // Stream to listen to user profile changes from Firestore
    final userProfileAsync = ref.watch(userProfileProvider(user?.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: themeColor,
      ),
      body: userProfileAsync.when(
        data: (userData) {
           // Load initial data when data is first received
           WidgetsBinding.instance.addPostFrameCallback((_) {
             _loadUserData(userData);
           });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Icon(Icons.account_circle_rounded, size: 100, color: themeColor),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Username Field
                   TextFormField(
                    controller: _usernameController,
                     decoration: InputDecoration(
                       labelText: 'Username',
                       prefixIcon: Icon(Icons.person_outline, color: accentColor),
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                     ),
                    validator: (value) => value != null && value.isNotEmpty ? null : 'Please enter a username',
                   ),
                   const SizedBox(height: 18),
                  // Email Field (Read-only)
                  TextFormField(
                    initialValue: user?.email ?? 'N/A', // Display email from auth
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined, color: accentColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.grey[200], // Indicate read-only
                    ),
                    readOnly: true,
                  ),
                  const SizedBox(height: 18),
                  // Phone Number Field
                   TextFormField(
                    controller: _phoneNumberController,
                     decoration: InputDecoration(
                       labelText: 'Phone Number',
                       prefixIcon: Icon(Icons.phone_outlined, color: accentColor),
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                     ),
                    keyboardType: TextInputType.phone,
                     validator: (value) {
                       if (value == null || value.isEmpty) {
                         return 'Please enter your phone number';
                       }
                       // Simple regex for basic phone number validation (adjust as needed)
                       if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                         return 'Please enter a valid phone number';
                       }
                       return null;
                     },
                   ),
                   const SizedBox(height: 18),
                  // Gender Dropdown
                   DropdownButtonFormField<String>(
                     value: _selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.person_outline, color: accentColor),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                     items: <String>['Male', 'Female', 'Prefer not to say'].map((String value) {
                       return DropdownMenuItem<String>(
                         value: value,
                         child: Text(value),
                       );
                     }).toList(),
                     onChanged: (newValue) {
                       if (newValue != null) {
                         setState(() {
                           _selectedGender = newValue;
                         });
                       }
                     },
                      validator: (value) => value != null && value.isNotEmpty ? null : 'Please select your gender',
                   ),
                  const SizedBox(height: 40),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50), // Green for Save
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(10),
                                ),
                            ),
                            onPressed: _saveProfile,
                            child: const Text('Save', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                  const SizedBox(height: 16),
                   SizedBox(
                     width: double.infinity,
                     child: OutlinedButton(
                       style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                         textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                           ),
                          side: BorderSide(color: themeColor),
                          foregroundColor: themeColor,
                       ),
                       onPressed: () {
                         Navigator.of(context).pop(); // Go back without saving
                       },
                       child: const Text('Cancel'),
                     ),
                   ),
                   const SizedBox(height: 30),
                   Center(
                      child: TextButton(
                         onPressed: () async {
                           final authService = ref.read(authServiceProvider);
                           await authService.signOut();
                           // Explicitly navigate to AuthScreen and clear stack
                           Navigator.of(context).pushAndRemoveUntil(
                             MaterialPageRoute(builder: (context) => const AuthScreen()),
                             (Route<dynamic> route) => false,
                           );
                         },
                         child: Text(
                           'Logout',
                            style: TextStyle(
                               fontSize: 18,
                              color: Colors.redAccent,
                               fontWeight: FontWeight.bold,
                             ),
                          ),
                        ),
                   ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading profile: ${e.toString()}')),
      ),
    );
  }
} 