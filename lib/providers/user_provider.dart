import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/user_status_service.dart';

class UserProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final UserStatusService _statusService = UserStatusService();

  bool _isLoading = true;
  String _username = '';
  String _email = '';
  String? _photoUrl;
  Map<String, dynamic> _userData = {};
  StreamSubscription<DocumentSnapshot>? _userDataSubscription;
  
  // Getters
  bool get isLoading => _isLoading;
  String get username => _username;
  String get email => _email;
  String? get photoUrl => _photoUrl;
  Map<String, dynamic> get userData => _userData;
  String get phoneNumber => _userData['phoneNo'] ?? '';
  String get location => _userData['Location'] ?? '';
  String get bio => _userData['bio'] ?? '';
  bool get isOnline => _userData['isOnline'] ?? false;
  DateTime? get lastSeen {
    if (_userData['lastSeen'] != null) {
      return (_userData['lastSeen'] as Timestamp).toDate();
    }
    return null;
  }

  // Constructor that listens to auth state changes
  UserProvider() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _setupRealtimeUserDataListener();
      } else {
        _clearUserData();
        _cancelUserDataSubscription();
      }
    });
  }
  
  @override
  void dispose() {
    _cancelUserDataSubscription();
    super.dispose();
  }
  
  void _cancelUserDataSubscription() {
    _userDataSubscription?.cancel();
    _userDataSubscription = null;
  }
  
  // Set up realtime listener for user data
  void _setupRealtimeUserDataListener() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    setState(() => _isLoading = true);
    
    // Cancel any existing subscription
    _cancelUserDataSubscription();
    
    // Set up new subscription
    _userDataSubscription = _firestore
      .collection('users')
      .doc(userId)
      .snapshots()
      .listen(
        (DocumentSnapshot snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data() as Map<String, dynamic>;
            _username = data['username'] ?? '';
            _email = _auth.currentUser?.email ?? '';
            _photoUrl = data['photoUrl'];
            _userData = data;
          } else {
            // If user exists in Auth but not in Firestore, create the document
            _createInitialUserDocument(userId);
          }
          
          setState(() => _isLoading = false);
        },
        onError: (error) {
          if (kDebugMode) {
            print('Error in user data stream: $error');
          }
          setState(() {
            _isLoading = false;
          });
        }
      );
  }
  
  // Helper method to create initial user document
  Future<void> _createInitialUserDocument(String userId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      await _firestore.collection('users').doc(userId).set({
        'uid': userId,
        'email': user.email,
        'username': user.displayName ?? 'User',
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      
      _username = user.displayName ?? 'User';
      _email = user.email ?? '';
      _photoUrl = user.photoURL;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating initial user document: $e');
      }
    }
  }
  
  void setState(Function() update) {
    update();
    notifyListeners();
  }
  
  // Clear user data when logged out
  void _clearUserData() {
    _username = '';
    _email = '';
    _photoUrl = null;
    _userData = {};
    _isLoading = false;
    notifyListeners();
  }

  // Fetch user data from Firestore (manual fetch if needed)
  Future<void> fetchUserData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('fetchUserData: No user logged in');
        return;
      }

      setState(() => _isLoading = true);

      // Get user document
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        _username = data['username'] ?? '';
        _email = _auth.currentUser?.email ?? '';
        _photoUrl = data['photoUrl'];
        _userData = data;
        debugPrint('User data fetched successfully');
      } else {
        // If user exists in Auth but not in Firestore, create the document
        debugPrint('Creating new user document in Firestore');
        await _createInitialUserDocument(userId);
      }

      // Set up real-time listener after initial data fetch
      _setupRealtimeUserDataListener();

      // Update online status
      await _statusService.setUserOnline();
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      // Don't rethrow - allow app to continue even with an error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Set user as offline
  Future<void> setUserOffline() async {
    await _statusService.setUserOffline();
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
  
  // Update user profile
  Future<void> updateUserProfile({
    required String username,
    required String phoneNumber,
    required String location,
    String bio = '',
    String? photoUrl,
  }) async {
    if (_auth.currentUser == null) {
      throw Exception('User not authenticated');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final userDoc = _firestore.collection('users').doc(_auth.currentUser!.uid);

      Map<String, dynamic> updateData = {
        'username': username,
        'phoneNo': phoneNumber,
        'Location': location,
        'bio': bio,
        'profileCompleted': true,
      };
      
      // Add photoUrl if provided
      if (photoUrl != null) {
        updateData['photoUrl'] = photoUrl;
        _photoUrl = photoUrl;
      }

      // Update Firestore
      await userDoc.update(updateData);

      // Update local state
      _username = username;
      _userData['username'] = username;
      _userData['phoneNo'] = phoneNumber;
      _userData['Location'] = location;
      _userData['bio'] = bio;
      _userData['profileCompleted'] = true;

      // Optionally update Firebase Auth display name
      await _auth.currentUser!.updateDisplayName(username);

    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}