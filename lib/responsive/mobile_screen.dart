import 'package:flutter/material.dart';

class Mobile_screen_layout extends StatefulWidget {
  const Mobile_screen_layout({super.key});

  @override
  State<Mobile_screen_layout> createState() => _Mobile_screen_layoutState();
}

class _Mobile_screen_layoutState extends State<Mobile_screen_layout> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:Text("mobile_screen"),
      ),
    );
  }
}
