import 'package:flutter/material.dart';
import '../Widgets/text_field_input.dart';

class Login_screen extends StatefulWidget {
  const Login_screen({super.key});

  @override
  State<Login_screen> createState() => _Login_screenState();
}

class _Login_screenState extends State<Login_screen> {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 64,
              ),
              const Text("Login Screen", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(
                height: 64,
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: TextFieldInput(
                        textEditingController: emailController,
                        hintText: "Enter your email",
                        textInputType: TextInputType.emailAddress,
                        labelText: "Email",
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter a valid email address';
                          } else if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) {
                            return 'Please enter a valid email format';
                          }
                          return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: TextFieldInput(
                        textEditingController: passController,
                        hintText: "Enter your password",
                        isPass: true,
                        textInputType: TextInputType.visiblePassword,
                        labelText: "Password",
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter a password';
                          } else if (value.length < 6) {
                            return 'Password should be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Form is valid, proceed with login
                          final email = emailController.text;
                          final password = passController.text;
                          print('Valid login attempt - Email: $email, Password: $password');
                          // Add your authentication logic here
                        } else {
                          // Form is invalid, show a message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fix the errors in the form')),
                          );
                        }
                      },
                      child: const Text('Login'),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}