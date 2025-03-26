import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_data_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/user_status_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  final UserStatusService _userStatusService = UserStatusService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required String location,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Add user details to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'username': username,
          'phoneNumber': phoneNumber,
          'location': location,
          'profileCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
          'photoUrl': null,
        });

        // Update profile in Firebase Auth
        await user.updateDisplayName(username);

        // Subscribe to user-specific notifications
        await _notificationService.subscribeToUserTopics(user.uid);

        // Save FCM token
        await _notificationService.saveTokenToDatabase(user.uid);

        // Show registration notification
        await _notificationService.showRegistrationSuccessNotification(username);

        return result;
      }
      return Future.error('User not found');
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Registration error: ${e.message}');
      }
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Get user data from Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          String username = userData['username'] ?? 'User';

          // Update last login timestamp first
          await _firestore.collection('users').doc(user.uid).update({
            'lastLogin': FieldValue.serverTimestamp(),
          });

          // These operations can fail on iOS due to APNS token, but we'll handle it gracefully
          try {
            // Subscribe to user-specific notifications
            await _notificationService.subscribeToUserTopics(user.uid);
            
            // Update token
            await _notificationService.saveTokenToDatabase(user.uid);
            
            // Show login notification
            await _notificationService.showLoginSuccessNotification(username);
          } catch (e) {
            debugPrint('Non-critical notification error during login: $e');
            // Ignore notification errors - they shouldn't prevent login
          }
        }

        return result;
      }
      return Future.error('User not found');
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Login error: ${e.message}');
      }
      throw _handleAuthException(e);
    }
  }

  // Sign in with credential (for social logins)
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    try {
      UserCredential result = await _auth.signInWithCredential(credential);
      
      User? user = result.user;
      
      if (user != null) {
        // Check if user exists in Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (!userDoc.exists) {
          // Create user document if it doesn't exist
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'username': user.displayName ?? 'User',
            'photoUrl': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'profileCompleted': false,
          });
        } else {
          // Update last login timestamp
          await _firestore.collection('users').doc(user.uid).update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }
        
        // Handle notification operations separately to prevent login failures
        try {
          // Subscribe to user-specific notifications
          await _notificationService.subscribeToUserTopics(user.uid);
          
          // Update token
          await _notificationService.saveTokenToDatabase(user.uid);
          
          // Show login notification
          await _notificationService.showLoginSuccessNotification(user.displayName ?? 'User');
        } catch (e) {
          debugPrint('Non-critical notification error during social login: $e');
          // Ignore notification errors - they shouldn't prevent login
        }
      }
      
      return result;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Social login error: ${e.message}');
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) {
        print('Social login error: $e');
      }
      throw Exception('Social login failed. Please try again.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Get current user ID before signing out
      final user = _auth.currentUser;
      final String? userId = user?.uid;
      
      if (userId == null) {
        // No user is logged in, just perform the sign out
        await _auth.signOut();
        return;
      }
      
      // Update last seen timestamp before other operations
      try {
        await _firestore.collection('users').doc(userId).update({
          'lastSeen': FieldValue.serverTimestamp(),
          'isOnline': false,
        });
      } catch (e) {
        debugPrint('Non-critical error updating user status: $e');
      }
      
      // Perform all the cleanup operations that shouldn't block sign out
      List<Future> cleanupOperations = [];
      
      // Set user as offline
      cleanupOperations.add(
        _userStatusService.setUserOffline().catchError((e) {
          debugPrint('Error setting user offline: $e');
        })
      );
      
      // Clear FCM token
      cleanupOperations.add(
        _firestore.collection('users').doc(userId).update({'fcmToken': null}).catchError((e) {
          debugPrint('Error clearing FCM token: $e');
        })
      );
      
      // Unsubscribe from user-specific notifications
      cleanupOperations.add(
        _notificationService.unsubscribeFromUserTopics(userId).catchError((e) {
          debugPrint('Error unsubscribing from topics: $e');
        })
      );
      
      // Wait for all operations to complete or fail
      // Using Future.wait with eagerError: false to allow all futures to complete
      await Future.wait(cleanupOperations, eagerError: false).catchError((e) {
        debugPrint('Some cleanup operations failed: $e');
      });

      // Finally sign out - this should never fail
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      throw Exception('Error signing out. Please try again.');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'null-user', 
          message: 'No user is currently signed in'
        );
      }
      
      // Set user as offline before deletion
      await _userStatusService.setUserOffline();
      
      // Delete user data from Firestore and any other cleanup needed
      try {
        // Unsubscribe from FCM topics
        await _notificationService.unsubscribeFromUserTopics(user.uid);
        
        // Delete user data from Firestore first
        await _firestore.collection('users').doc(user.uid).delete();

        // Delete the user authentication
        await user.delete();

        // Show notification
        await _notificationService.showAccountDeletionNotification();
      } catch (e) {
        throw Exception('Failed to delete user data: $e');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'For security reasons, please log in again before deleting your account.'
        );
      } else {
        if (kDebugMode) {
          print('Delete account error: ${e.message}');
        }
        throw _handleAuthException(e);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Delete account error: $e');
      }
      throw Exception('Failed to delete account. Please try again.');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Password reset error: ${e.message}');
      }
      throw _handleAuthException(e);
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
    String? username,
    String? phoneNo,
    String? location,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      User? user = _auth.currentUser;

      if (user == null) {
        throw Exception('No user is currently logged in.');
      }

      // Update Auth profile if needed
      if (displayName != null || photoURL != null) {
        await user.updateDisplayName(displayName);
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }
      }

      // Prefer username over displayName if both are provided
      String? actualUsername = username ?? displayName;

      // Prepare Firestore update data
      Map<String, dynamic> updateData = {
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (actualUsername != null) {
        updateData['username'] = actualUsername;
      }

      if (photoURL != null) {
        updateData['photoUrl'] = photoURL;
      }

      if (phoneNo != null) {
        updateData['phoneNo'] = phoneNo;
      }

      if (location != null) {
        updateData['Location'] = location;
      }

      if (additionalData != null) {
        updateData.addAll(additionalData);
      }

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update(updateData);

      // Show notification
      await _notificationService.showProfileUpdateNotification();
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Update profile error: ${e.message}');
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) {
        print('Update profile error: $e');
      }
      throw Exception('Failed to update profile. Please try again.');
    }
  }

  // Helper method to handle Firebase Auth exceptions
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email.');
      case 'wrong-password':
        return Exception('Incorrect password. Please try again.');
      case 'email-already-in-use':
        return Exception('This email is already registered.');
      case 'weak-password':
        return Exception('Password is too weak. Please use a stronger password.');
      case 'invalid-email':
        return Exception('Invalid email address.');
      case 'operation-not-allowed':
        return Exception('This operation is not allowed.');
      case 'user-disabled':
        return Exception('This account has been disabled.');
      case 'requires-recent-login':
        return Exception('Please log in again before performing this operation.');
      case 'network-request-failed':
        return Exception('Network error. Please check your connection.');
      default:
        return Exception(e.message ?? 'Authentication error occurred.');
    }
  }
}