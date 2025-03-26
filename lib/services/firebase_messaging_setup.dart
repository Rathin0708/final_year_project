import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> setupFirebaseMessaging() async {
  try {
    await Firebase.initializeApp();
    final fcmToken = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $fcmToken'); // For debugging
  } catch (e) {
    print('Firebase Messaging initialization error: $e');
    // Consider implementing a fallback to still allow the app to function
  }
}