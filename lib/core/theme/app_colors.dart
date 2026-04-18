import 'package:flutter/material.dart';

class AppColors {
  // Main palette
  static const Color background = Color(0xFF0E0E0E);
  static const Color surface = Color(0xFF131313);
  static const Color surfaceContainer = Color(0xFF191919);
  static const Color surfaceContainerLow = Color(0xFF131313);
  static const Color surfaceContainerHigh = Color(0xFF1F1F1F);
  static const Color surfaceContainerHighest = Color(0xFF262626);
  
  // Brand colors
  static const Color primary = Color(0xFFA2FFBF);
  static const Color primaryDim = Color(0xFF00FD93);
  static const Color secondary = Color(0xFF679CFF);
  static const Color tertiary = Color(0xFF7BE2FF);
  
  // Content colors
  static const Color onBackground = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFFABABAB);
  static const Color outlineVariant = Color(0xFF484848);

  // Gradients
  static const LinearGradient velocityGradient = LinearGradient(
    colors: [primary, primaryDim],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
