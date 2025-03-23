import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  String _username = '';
  String _email = '';
  String _phoneNumber = '';
  String _location = '';
  bool _isLoading = true;
  String? _photoUrl;
  
  String get username => _username;
  String get email => _email;
  String get phoneNumber => _phoneNumber;
  String get location => _location;
  bool get isLoading => _isLoading;
  String? get photoUrl => _photoUrl;
  
  // Fetch user data from the service
  Future<void> fetchUserData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final userData = await _authService.getUserData();
      _username = userData['username'] ?? '';
      _phoneNumber = userData['phoneNumber'] ?? '';
      _location = userData['location'] ?? '';
      _photoUrl = userData['photoUrl'];
      
      // Get email from Firebase Auth
      _email = _authService.currentUser?.email ?? '';
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update user data
  Future<void> updateUserProfile({
    required String username,
    required String phoneNumber,
    required String location,
    String? photoUrl,
  }) async {
    try {
      await _authService.updateUserProfile(
        username: username,
        phoneNumber: phoneNumber,
        location: location,
        photoUrl: photoUrl,
      );
      
      // Update local state
      _username = username;
      _phoneNumber = phoneNumber;
      _location = location;
      if (photoUrl != null) {
        _photoUrl = photoUrl;
      }
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}