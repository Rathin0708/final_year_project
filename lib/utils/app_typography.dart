import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

/// App Typography
/// Defines standardized text styles for the entire application.
/// Following clean architecture principles for maintainability.
class AppTypography {
  // Private constructor to prevent instantiation
  const AppTypography._();
  
  // Base font families
  static const String _fontFamily = 'Roboto';
  
  // Font weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  
  // Headings
  static TextStyle get h1 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppDimensions.fontHeadlineL,
    fontWeight: bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get h2 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppDimensions.fontHeadlineM,
    fontWeight: bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get h3 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppDimensions.fontHeadlineS,
    fontWeight: bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get h4 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppDimensions.fontXXL,
    fontWeight: semiBold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get h5 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppDimensions.fontTitle,
    fontWeight: semiBold,
    color: AppColors.textPrimary,
  );
  
  // Body text
  static TextStyle get bodyLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppDimensions.fontL,
    fontWeight: regular,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get bodyMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppDimensions.fontM,
    fontWeight: regular,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get bodySmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppDimensions.fontS,
    fontWeight: regular,
    color: AppColors.textSecondary,
  );
  
  // Specialized text styles
  static TextStyle get caption => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppDimensions.fontXS,
    fontWeight: regular,
    color: AppColors.textSecondary,
  );
  
  static TextStyle get button => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppDimensions.fontM,
    fontWeight: medium,
    color: AppColors.textLight,
  );
  
  static TextStyle get subtitle => TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppDimensions.fontL,
    fontWeight: medium,
    color: AppColors.textSecondary,
  );
  
  // Helper methods for quick style modifications
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
  
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }
  
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }
}