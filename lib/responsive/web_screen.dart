import 'package:flutter/material.dart';

class web_screen_layout extends StatefulWidget {
  const web_screen_layout({super.key});

  @override
  State<web_screen_layout> createState() => _web_screen_layoutState();
}

class _web_screen_layoutState extends State<web_screen_layout> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:Text("web_screen"),
      ),
    );
  }
}
