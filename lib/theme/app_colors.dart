import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF667EEA);
  static const secondary = Color(0xFF764BA2);
  static const accent = Color(0xFFF093FB);
  static const accentOrange = Color(0xFFFF6B6B);
  
  static const background = Color(0xFF0A0E27);
  static const surface = Color(0xFF1A1F3A);
  
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB8B8D1);
  
  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get backgroundGradient => const LinearGradient(
    colors: [Color(0xFF0F1729), Color(0xFF1A1F3A), Color(0xFF2D1B4E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
