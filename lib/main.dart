import 'dart:io';

import 'package:final_year_project_test/screens/splash_screen.dart';
import 'package:final_year_project_test/services/firebase_options.dart';
import 'package:final_year_project_test/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/employee_provider.dart';
import 'providers/professional_development_provider.dart';
import 'services/notification_service.dart';
import 'providers/chat_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Request permission first
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  // On iOS, register for background notifications
  if (Platform.isIOS) {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => ProfessionalDevelopmentProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const MyAppWrapper(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Debug App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// AppLifecycleObserver to handle user status changes
class AppLifecycleObserver with WidgetsBindingObserver {
  final UserProvider _userProvider;
  
  AppLifecycleObserver(this._userProvider) {
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kDebugMode) {
      print('App lifecycle state changed to: $state');
    }
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App is visible and in the foreground
        _userProvider.fetchUserData(); // This will set user as online
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // App is not visible or being terminated
        _userProvider.setUserOffline();
        break;
      default:
        break;
    }
  }
  
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

class MyAppWrapper extends StatefulWidget {
  const MyAppWrapper({super.key});

  @override
  State<MyAppWrapper> createState() => _MyAppWrapperState();
}

class _MyAppWrapperState extends State<MyAppWrapper> {
  AppLifecycleObserver? _appLifecycleObserver;

  @override
  void initState() {
    super.initState();
    // Schedule this for after the first frame to ensure Provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appLifecycleObserver = AppLifecycleObserver(
        Provider.of<UserProvider>(context, listen: false)
      );
    });
  }

  @override
  void dispose() {
    _appLifecycleObserver?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const MyApp();
  }
}