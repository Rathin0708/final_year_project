# App Style System

This directory contains a clean architecture-based style system for the application.

## Key Components

### AppColors (`app_colors.dart`)
- Centralized color definitions for the entire app
- Organized by functional categories (primary, background, text, etc.)
- Includes semantic colors for status indicators (success, error, etc.)

### AppDimensions (`app_dimensions.dart`) 
- Standardized spacing, sizing, and layout measurements
- Follows a consistent naming convention (XS, S, M, L, XL, etc.)
- Includes specialized dimensions for common UI components

### AppTypography (`app_typography.dart`)
- Defines text styles with consistent sizing and weights
- Provides helper methods for style modifications
- Maintains readable and accessible type scales

### AppTheme (`app_theme.dart`)
- Combines colors, dimensions, and typography into cohesive themes
- Supports both light and dark mode
- Configures Material theme components with consistent styling

## Usage

Import the style barrel file to access all style utilities:

```dart
import 'package:your_app/utils/style.dart';
```

Then apply styles in your widgets:

```dart
// Using colors
Container(color: AppColors.primary);

// Using dimensions
Padding(padding: EdgeInsets.all(AppDimensions.paddingM));

// Using typography
Text('Heading', style: AppTypography.h3);

// Using theme (automatic through MaterialApp)
// The app theme is applied in main.dart
```

## Benefits

- **Consistency**: Unified visual language across the app
- **Maintainability**: Single source of truth for UI styling
- **Scalability**: Easy to extend with new styles
- **Performance**: Reduced widget rebuilds due to const values
- **Accessibility**: Standardized sizes and contrasts