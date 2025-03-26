import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// This function needs to be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background handlers
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  // Singleton pattern implementation
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();
  
  Future<void> initialize() async {
    // Set background message handler first
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Local notifications setup
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        if (kDebugMode) {
          print('Notification tapped: ${response.payload}');
        }
      },
    );
    
    // Create notification channels for Android
    await _createNotificationChannels();
    
    // Request permission for iOS and Android 13+
    await _requestPermissions();
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleMessage);
    
    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // Get FCM token for this device
    try {
      String? token = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }
    } catch (e) {
      print('Failed to get FCM token: $e');
      // Continue with app initialization despite FCM error
    }
  }
  
  Future<void> _createNotificationChannels() async {
    // For Android 8.0+
    const AndroidNotificationChannel accountChannel = AndroidNotificationChannel(
      'account_channel',
      'Account Notifications',
      description: 'Notifications related to your account activities',
      importance: Importance.high,
    );

    const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
      'general_channel',
      'General Notifications',
      description: 'General app notifications',
      importance: Importance.defaultImportance,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(accountChannel);
    
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
  }
  
  Future<void> _requestPermissions() async {
    // Firebase messaging permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
    
    if (kDebugMode) {
      print('Firebase notification permission status: ${settings.authorizationStatus}');
    }
    
    // Local notification permission for iOS
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    
    // For Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
  
  Future<void> _handleMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('Got a message whilst in the foreground!');
    }
    if (kDebugMode) {
      print('Message data: ${message.data}');
    }
    
    // Extract notification type from data if available
    String notificationType = message.data['type'] ?? 'general';
    
    if (message.notification != null) {
      await showNotification(
        id: message.hashCode,
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        channelId: _getChannelIdForType(notificationType),
        payload: message.data,
      );
    }
  }
  
  String _getChannelIdForType(String type) {
    switch (type) {
      case 'account':
      case 'login':
      case 'registration':
      case 'profile':
        return 'account_channel';
      default:
        return 'general_channel';
    }
  }
  
  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      print('Message opened app: ${message.data}');
    }
    // Can be used to navigate based on notification data
  }

  // Show local notification with more options
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String channelId = 'general_channel',
    Map<String, dynamic>? payload,
  }) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'account_channel' ? 'Account Notifications' : 'General Notifications',
      channelDescription: channelId == 'account_channel' 
          ? 'Notifications related to your account' 
          : 'General notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableLights: true,
      color: Colors.blue,
      ledColor: Colors.blue,
      ledOnMs: 1000,
      ledOffMs: 500,
    );
    
    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    
    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload?.toString(),
    );
  }
  
  // Specific notification methods
  Future<void> showAccountDeletionNotification() async {
    await showNotification(
      id: 1,
      title: 'Account Deleted',
      body: 'Your account has been successfully deleted from our system.',
      channelId: 'account_channel',
      payload: {'type': 'account_deletion'},
    );
  }
  
  Future<void> showRegistrationSuccessNotification(String username) async {
    await showNotification(
      id: 2,
      title: 'Welcome to the App!',
      body: 'Hi $username, your account has been successfully created.',
      channelId: 'account_channel',
      payload: {'type': 'registration'},
    );
  }
  
  Future<void> showLoginSuccessNotification(String username) async {
    await showNotification(
      id: 3,
      title: 'Login Successful',
      body: 'Welcome back, $username!',
      channelId: 'account_channel',
      payload: {'type': 'login'},
    );
  }
  
  Future<void> showProfileUpdateNotification() async {
    await showNotification(
      id: 4,
      title: 'Profile Updated',
      body: 'Your profile information has been successfully updated.',
      channelId: 'account_channel',
      payload: {'type': 'profile_update'},
    );
  }
  
  // FCM topic management
  Future<void> subscribeToUserTopics(String userId) async {
    try {
      // For iOS, check if APNS token is available first
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          debugPrint('Cannot subscribe to topics: APNS token not available yet');
          return; // Skip subscribing if APNS token is not available
        }
      }
      
      await _firebaseMessaging.subscribeToTopic('user_$userId');
      await _firebaseMessaging.subscribeToTopic('all_users');
      debugPrint('Successfully subscribed to user topics');
    } catch (e) {
      debugPrint('Error subscribing to topics: $e');
      // Don't rethrow, allow app to continue even with subscription error
    }
  }
  
  Future<void> unsubscribeFromUserTopics(String userId) async {
    try {
      // For iOS, check if APNS token is available first
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          debugPrint('Cannot unsubscribe from topics: APNS token not available yet');
          return; // Skip unsubscribing if APNS token is not available
        }
      }
      
      await _firebaseMessaging.unsubscribeFromTopic('user_$userId');
      debugPrint('Successfully unsubscribed from user topics');
    } catch (e) {
      debugPrint('Error unsubscribing from topics: $e');
      // Don't rethrow, allow app to continue even with unsubscription error
    }
  }
  
  // Save FCM token to user document in Firestore
  Future<void> saveTokenToDatabase(dynamic user) async {
    try {
      String userId = user is String ? user : user.uid;
      
      // For iOS, check if APNS token is available
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        // If no APNS token yet, skip saving the token for now
        if (apnsToken == null) {
          debugPrint('APNS token not available yet, skipping FCM token save');
          return;
        }
      }
      
      String? token = await _firebaseMessaging.getToken();
      if (token == null) return;
      
      // Here you should implement saving the token to Firebase Firestore
      // For example:
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'tokens': FieldValue.arrayUnion([token]),
        'lastSeen': DateTime.now(),
      });
      if (kDebugMode) {
        print('FCM token saved to user document: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving FCM token: $e');
      }
    }
  }
}