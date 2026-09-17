import 'package:flutter/material.dart';

/// Material 3 palette mapped from the Tailwind classes used throughout
/// `src/screens/*.tsx` — see the design doc's "Theming" section.
class AppColors {
  AppColors._();

  static const skyPrimary = Color(0xFF0369A1); // sky-700
  static const skyPrimaryDark = Color(0xFF075985); // sky-800

  static const slate50 = Color(0xFFF8FAFC);
  static const slate900 = Color(0xFF0F172A);

  static const statusPaid = Color(0xFF10B981); // emerald-500
  static const statusPending = Color(0xFFF59E0B); // amber-500
  static const statusOverdue = Color(0xFFE11D48); // rose-600
}

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.skyPrimary),
  scaffoldBackgroundColor: AppColors.slate50,
  cardTheme: const CardThemeData(
    elevation: 1,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: AppColors.slate900,
    elevation: 0,
    scrolledUnderElevation: 1,
    centerTitle: false,
    titleTextStyle: TextStyle(color: AppColors.slate900, fontSize: 16, fontWeight: FontWeight.bold),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: AppColors.skyPrimary.withValues(alpha: 0.12),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => TextStyle(
        fontSize: 11,
        fontWeight: states.contains(WidgetState.selected) ? FontWeight.bold : FontWeight.normal,
        color: states.contains(WidgetState.selected) ? AppColors.skyPrimaryDark : Colors.grey,
      ),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.skyPrimary,
    foregroundColor: Colors.white,
    extendedTextStyle: TextStyle(fontWeight: FontWeight.bold),
  ),
);
