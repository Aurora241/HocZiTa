import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Màu chủ đạo theo spec
  static const Color primary = Color(0xFF0077BB);
  static const Color primaryDark = Color(0xFF005588);
  static const Color primaryLight = Color(0xFF3399CC);

  // Accent
  static const Color accent = Color(0xFFFF8800);

  // Neutral
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE0E0E0);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFB0B8C1);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Game - màu cho từng sao
  static const Color star = Color(0xFFFFD700);
  static const Color starEmpty = Color(0xFFD1D5DB);

  // Level
  static const Color levelA = Color(0xFF22C55E);  // Xanh lá - dễ
  static const Color levelB = Color(0xFFF59E0B);  // Vàng - trung bình
  static const Color levelC = Color(0xFFEF4444);  // Đỏ - khó
}
