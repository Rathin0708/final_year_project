import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_data_model.dart';

class UserProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  String _username = '';
  String _email = '';
  String _userId = '';
  UserDataModel? _userData;
  
  UserProvider() {
    // Listen for auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        // User is signed out
        _clearUserData();
        notifyListeners();
      } else {
        // User is signed in
        fetchUserData();
      }
    });
  }
  
  bool get isLoading => _isLoading;
  String get username => _username;
  String get email => _email;
  String get userId => _userId;
  UserDataModel? get userData => _userData;
  bool get isAuthenticated => _auth.currentUser != null;
  String get phoneNumber => _userData?.phoneNo ?? '';
  String get location => _userData?.location ?? '';
  String? get photoUrl => _userData?.photo != null && _userData!.photo!.containsKey('url') 
      ? _userData!.photo!['url'] as String? 
      : _auth.currentUser?.photoURL;

  void _clearUserData() {
    _username = '';
    _email = '';
    _userId = '';
    _userData = null;
  }
  
  Future<void> fetchUserData() async {
    if (_auth.currentUser == null) {
      _clearUserData();
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final user = _auth.currentUser!;
      _userId = user.uid;
      _email = user.email ?? '';
      
      // First try to set username from Firebase Auth display name
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        _username = user.displayName!;
      }
      
      // Then try to get additional user data from Firestore
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        _userData = UserDataModel.fromJson(data);
        
        // Use Firestore username if available
        if (_userData!.username.isNotEmpty) {
          _username = _userData!.username;
        }
      } else {
        // If no Firestore document exists yet but we have a signed-in user,
        // create a basic user document
        if (_username.isEmpty) {
          _username = _email.split('@')[0]; // Use email prefix as default username
        }
        
        final userData = {
          'userId': _userId,
          'username': _username,
          'email': _email,
          'gmailid': _email, // Add required fields for UserDataModel
          'phoneNo': '',
          'Location': '',
          'password': '',
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        await _firestore.collection('users').doc(_userId).set(userData);
        _userData = UserDataModel.fromJson(userData);
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      // If there's an error, use basic data from FirebaseAuth
      _username = _auth.currentUser?.displayName ?? _email.split('@')[0];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to check if the user's auth token is still valid
  Future<bool> validateAuthToken() async {
    if (_auth.currentUser == null) return false;
    
    try {
      // Force token refresh to check validity
      await _auth.currentUser!.getIdToken(true);
      return true;
    } catch (e) {
      // If there's an error, the token might be invalid
      await _auth.signOut();
      _clearUserData();
      notifyListeners();
      return false;
    }
  }

  // Method to update user profile
  Future<void> updateUserProfile({
    required String username,
    required String phoneNumber,
    required String location,
  }) async {
    if (_auth.currentUser == null) {
      throw Exception('User not authenticated');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final userDoc = _firestore.collection('users').doc(_userId);

      // Update Firestore
      await userDoc.update({
        'username': username,
        'phoneNo': phoneNumber,
        'Location': location,
      });

      // Update local state
      _username = username;
      if (_userData != null) {
        _userData = _userData!.copyWith(
          username: username,
          phoneNo: phoneNumber,
          location: location,
        );
      }

      // Optionally update Firebase Auth display name
      await _auth.currentUser!.updateDisplayName(username);

    } catch (e) {
      debugPrint('Error updating profile: $e');
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}