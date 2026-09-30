import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette - Navy/Blue khas PapiKost
  static const Color primary = Color(0xFF1A3C6E); // Navy Blue
  static const Color primaryLight = Color(0xFF2A5BA8); // Medium Blue
  static const Color primaryDark = Color(0xFF0D2244); // Dark Navy

  // Secondary Palette - Cyan/Teal untuk aksen & AI
  static const Color secondary = Color(0xFF00BCD4); // Cyan
  static const Color secondaryLight = Color(0xFF4DD0E1); // Light Cyan
  static const Color secondaryDark = Color(0xFF0097A7); // Dark Teal

  // Accent untuk PapiBot
  static const Color papibotAccent = Color(0xFF00E5FF); // Electric Cyan
  static const Color papibotBg = Color(0xFFE0F7FA); // Very light cyan

  // Neutral
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);

  // Background
  static const Color scaffold = Color(0xFFF8F9FB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color inputBg = Color(0xFFF1F3F8);

  // Ticket Status Colors
  static const Color statusPending = Color(0xFFFFC107);
  static const Color statusPendingBg = Color(0xFFFFF8E1);
  static const Color statusInProgress = Color(0xFF2196F3);
  static const Color statusInProgressBg = Color(0xFFE3F2FD);
  static const Color statusDone = Color(0xFF4CAF50);
  static const Color statusDoneBg = Color(0xFFE8F5E9);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );

  static const LinearGradient papibotGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, papibotAccent],
  );
}
