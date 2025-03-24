import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_data_model.dart';
import '../services/api_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiService _apiService = ApiService();

  // Get current user
  User? get currentUser => _auth.currentUser;

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
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user in MockAPI
      final apiUser = await _apiService.createUser(
        UserDataModel(
          username: username,
          gmailid: email,
          phoneNo: phoneNumber,
          location: location,
          password: password,
          dob: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      );

      // Save user data in Firestore with API ID reference
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'username': username,
        'email': email,
        'phoneNumber': phoneNumber,
        'location': location,
        'apiUserId': apiUser.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with credential (for Google, Apple signin)
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    try {
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Delete user account from Firebase and API
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      
      if (user != null) {
        // Get API user ID from Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          String apiUserId = userData['apiUserId'] ?? '';
          
          // Delete user from API if ID exists
          if (apiUserId.isNotEmpty) {
            await _apiService.deleteUser(apiUserId);
          }
          
          // Delete user document from Firestore
          await _firestore.collection('users').doc(user.uid).delete();
          
          // Delete Firebase Auth user
          await user.delete();
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile (in both Firebase and API)
  Future<void> updateUserProfile({
    required String username,
    required String phoneNumber,
    required String location,
    String? photoUrl,
  }) async {
    try {
      User? user = _auth.currentUser;
      
      if (user != null) {
        // Get user data from Firestore to check if API ID exists
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          String apiUserId = userData['apiUserId'] ?? '';
          
          // Update Firebase data
          Map<String, dynamic> updateData = {
            'username': username,
            'phoneNumber': phoneNumber,
            'location': location,
          };
          
          if (photoUrl != null) {
            updateData['photoUrl'] = photoUrl;
          }
          
          await _firestore.collection('users').doc(user.uid).update(updateData);
          
          // Update API data if API ID exists
          if (apiUserId.isNotEmpty) {
            await _apiService.updateUser(
              apiUserId,
              UserDataModel(
                username: username,
                gmailid: user.email ?? '',
                phoneNo: phoneNumber,
                location: location,
                password: '', // We don't send password when updating
              ),
            );
          } else {
            // Create new API user if no API ID exists
            final apiUser = await _apiService.createUser(
              UserDataModel(
                username: username,
                gmailid: user.email ?? '',
                phoneNo: phoneNumber,
                location: location,
                password: 'securePassword', // Use a secure default
              ),
            );
            
            // Save API ID to Firestore
            await _firestore.collection('users').doc(user.uid).update({
              'apiUserId': apiUser.id,
            });
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get user data from both Firebase and API
  Future<Map<String, dynamic>> getUserData() async {
    try {
      User? user = _auth.currentUser;
      Map<String, dynamic> userData = {};
      
      if (user != null) {
        // Get Firebase data
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (userDoc.exists) {
          userData = userDoc.data() as Map<String, dynamic>;
          String apiUserId = userData['apiUserId'] ?? '';
          
          // If API ID exists, get data from API as well
          if (apiUserId.isNotEmpty) {
            try {
              final apiUser = await _apiService.getUserById(apiUserId);
              
              // Merge data, prioritizing API data
              userData['username'] = apiUser.username;
              userData['phoneNumber'] = apiUser.phoneNo;
              userData['location'] = apiUser.location;
              
              // Sync Firebase with API data
              await _firestore.collection('users').doc(user.uid).update({
                'username': apiUser.username,
                'phoneNumber': apiUser.phoneNo,
                'location': apiUser.location,
              });
            } catch (e) {
              print('Error fetching API data: $e');
              // Continue with Firebase data if API fetch fails
            }
          }
        }
      }
      
      return userData;
    } catch (e) {
      rethrow;
    }
  }
}