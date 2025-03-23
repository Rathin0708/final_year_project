import 'package:flutter/material.dart';
import '../Widgets/text_field_input.dart';

class Login_screen extends StatefulWidget {
  const Login_screen({super.key});

  @override
  State<Login_screen> createState() => _Login_screenState();
}

class _Login_screenState extends State<Login_screen> {
  final emailController=TextEditingController();
  final passController=TextEditingController();
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    emailController.dispose();
    passController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Container(),
                flex: 2,
              ),
              Text("Login_screen"),
              SizedBox(
                height: 64,
              ),
              TextFieldInput(
                textEditingController: emailController,
                hintText: "enter you email",
                textInputType: TextInputType.emailAddress,
              )
            ],
          ),
        ),
      ),
    );
  }
}