import 'package:flutter/material.dart';

/// App Color Scheme
/// This class provides consistent color definitions for the entire application
/// following a clean architecture approach.
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2196F3);        // Main brand color
  static const Color primaryLight = Color(0xFF64B5F6);   // Light variant
  static const Color primaryDark = Color(0xFF1976D2);    // Dark variant
  
  // Secondary Colors
  static const Color secondary = Color(0xFFFFA726);      // Accent color
  static const Color secondaryLight = Color(0xFFFFCC80); // Light variant
  static const Color secondaryDark = Color(0xFFF57C00);  // Dark variant
  
  // Background Colors
  static const Color background = Colors.white;          // App background
  static const Color backgroundVariant = Color(0xFFF5F5F5); // Secondary background
  static const Color backgroundDark = Color(0xFF121212); // Dark mode background
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);    // Primary text
  static const Color textSecondary = Color(0xFF757575);  // Secondary text
  static const Color textLight = Colors.white;           // Light text
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);        // Success/Confirmation
  static const Color error = Color(0xFFF44336);          // Error/Alert
  static const Color warning = Color(0xFFFF9800);        // Warning
  static const Color info = Color(0xFF2196F3);           // Information
  
  // Interface Colors
  static const Color divider = Color(0xFFE0E0E0);        // Dividers
  static const Color disabled = Color(0xFFBDBDBD);       // Disabled elements
  static const Color shadow = Color(0x40000000);         // Shadows
  
  // Platform Specific
  static const Color mobileBackgroundColor = backgroundVariant;
  static const Color webBackgroundColor = background;
}