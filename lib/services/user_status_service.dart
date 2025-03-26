import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserStatusService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Set user as online
  Future<void> setUserOnline() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      await _firestore.collection('users').doc(userId).update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        print('User $userId set as online');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting user online: $e');
      }
    }
  }
  
  // Set user as offline
  Future<void> setUserOffline() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      await _firestore.collection('users').doc(userId).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        print('User $userId set as offline');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting user offline: $e');
      }
    }
  }
  
  // Get user online status
  Stream<Map<String, dynamic>?> getUserStatus(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          
          final data = snapshot.data() as Map<String, dynamic>;
          final isOnline = data['isOnline'] as bool?;
          final lastSeen = data['lastSeen'] as Timestamp?;
          
          return {
            'isOnline': isOnline ?? false,
            'lastSeen': lastSeen?.toDate(),
          };
        });
  }
}