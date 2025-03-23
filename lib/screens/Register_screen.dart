import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Widgets/text_field_input.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'login_screen.dart';
import 'Dashboard.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final passController = TextEditingController();
  final usernameController = TextEditingController();
  final locationController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passController.dispose();
    usernameController.dispose();
    phoneNumberController.dispose();
    locationController.dispose();
    confirmPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 64,
                ),
                const Text("Register Screen",
                    style: TextStyle(fontSize: 24,
                        fontWeight: FontWeight.bold
                    )
                ),
                const SizedBox(
                  height: 24,
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: TextFieldInput(
                          textEditingController: usernameController,
                          hintText: "Enter your username",
                          textInputType: TextInputType.text,
                          labelText: "Username",
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter a username';
                            }
                            return null;
                          },
                        ),
                      ),
          
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
                          textEditingController: phoneNumberController,
                          hintText: "Enter your phone number",
                          textInputType: TextInputType.phone,
                          labelText: "Phone Number",
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter a phone number';
                            } else if (!RegExp(r"^[0-9+]{0,1}[-\s.]?[0-9]{3}[-\s.]?[0-9]{3}[-\s.]?[ 0-9]{4}$").hasMatch(value)) {
                              return 'Please enter a valid phone number format';
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: TextFieldInput(
                          textEditingController: locationController,
                          hintText: "Location",
                          textInputType: TextInputType.text,
                          labelText: "Location",
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter a location';
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
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: TextFieldInput(
                          textEditingController: confirmPasswordController,
                          hintText: "Confirm Password",
                          isPass: true,
                          textInputType: TextInputType.visiblePassword,
                          labelText: "Confirm Password",
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter a confirm password';
                            } else if (value != passController.text) {
                              return 'Password and confirm password do not match';
                            }
                            return null;
                          },
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // Form is valid, proceed with login
                            final email = emailController.text;
                            final password = passController.text;
                            final username = usernameController.text;
                            final phoneNumber = phoneNumberController.text;
                            final location = locationController.text;

                            setState(() {
                              _isLoading = true;
                            });

                            try {
                              // Create user with AuthService
                              await _authService.signUpWithEmailAndPassword(
                                email: email,
                                password: password,
                                username: username,
                                phoneNumber: phoneNumber,
                                location: location,
                              );

                              setState(() {
                                _isLoading = false;
                              });
                              
                              // Navigate to Home screen
                              if (context.mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const Dashboard()),
                                );
                              }
                            } catch (error) {
                              setState(() {
                                _isLoading = false;
                              });
                              
                              if (error is FirebaseAuthException) {
                                if (error.code == 'weak-password') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('The password provided is too weak.')),
                                  );
                                } else if (error.code == 'email-already-in-use') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('The account already exists for that email.')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('An error occurred: ${error.message}')),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('An unexpected error occurred: $error')),
                                );
                              }
                            }
                          }
                        },
                        child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.secondary,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Register'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Login_screen()),
                          );
                        },
                        child: const Text('Already have an account? Login'),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}