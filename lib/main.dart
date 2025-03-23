import 'package:final_year_project_test/screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // if(kIsWeb) {
  //   await Firebase.initializeApp(
  //     options: const FirebaseOptions(
  //         apiKey: "AIzaSyBnrcudXOBD3TeWeCYF-dlPa-zv1dLUGh4",
  //         appId: "1:287751604152:web:ff6137c57c8d9e68c4314d",
  //         messagingSenderId: "287751604152",
  //         projectId: "finalyear-328b3",
  //         //addextra/
  //         authDomain: "finalyear-328b3.firebaseapp.com",
  //         storageBucket: "finalyear-328b3.firebasestorage.app",
  //         measurementId: "G-LCGPCQFP8Q"
  //     ),
  //   );
  // }
  // else {
  //   await Firebase.initializeApp();
  // }
  // if (await Firebase.initializeApp().then((value) => true).catchError((e) => false))
  // await Firebase.initializeApp();
  runApp(const MyApp()
  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home:Login_screen(),

      // Responsive_layout(mobileScreenLayout: Mobile_screen_layout(),
      // webScreenLayout: web_screen_layout(),),
    );
  }
}
