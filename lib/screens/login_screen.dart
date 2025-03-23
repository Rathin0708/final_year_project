import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Widgets/text_field_input.dart';
import '../utils/app_dimensions.dart';
import '../utils/app_typography.dart';
import 'Dashboard.dart';
import 'Register_screen.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';

class Login_screen extends StatefulWidget {
  const Login_screen({super.key});

  @override
  State<Login_screen> createState() => _Login_screenState();
}

class _Login_screenState extends State<Login_screen> {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

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
              SizedBox(
                height: AppDimensions.paddingXXL,
              ),
              Text("Welcome Back", style: AppTypography.h3),
              const SizedBox(
                height: 64,
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(AppDimensions.paddingM),
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
                      padding: EdgeInsets.all(AppDimensions.paddingM),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isLoading = true;
                          });
                          
                          try {
                            await _authService.signInWithEmailAndPassword(
                              email: emailController.text,
                              password: passController.text,
                            );
                            
                            if (context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const Dashboard()),
                              );
                            }
                          } catch (error) {
                            if (error is FirebaseAuthException) {
                              if (error.code == 'user-not-found') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No user found for that email.')),
                                );
                              } else if (error.code == 'wrong-password') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Wrong password provided for that user.')),
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
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        }
                      },
                      child: _isLoading 
                        ? SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            )
                          )
                        : Text('Login', style: TextStyle(fontSize: 16, color: AppColors.primary)),
                    ),
                    TextButton(
                      onPressed: () {
                        // Add your forgot password logic here
                      },
                      child: Text('Forgot Password?', style: AppTypography.bodyMedium),
                    ),
                    Container(
                      padding: EdgeInsets.all(AppDimensions.paddingM),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Don\'t have an account?', style: AppTypography.bodyMedium),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegisterScreen()),
                              );
                              // Add your sign up logic here
                            },
                            child: Text('Register', style: TextStyle(fontSize: 16, color: AppColors.primary)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}