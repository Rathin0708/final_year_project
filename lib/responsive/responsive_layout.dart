import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/global_variables.dart';

class Responsive_layout extends StatefulWidget {
  final Widget mobileScreenLayout;
  final Widget webScreenLayout;
  const Responsive_layout({super.key, required this.mobileScreenLayout, required this.webScreenLayout});

  @override
  State<Responsive_layout> createState() => _Responsive_layoutState();
}

class _Responsive_layoutState extends State<Responsive_layout> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth>webscreenSize) {
        return widget.webScreenLayout;
      }
      return widget.mobileScreenLayout;
    }
    );
  }
}
