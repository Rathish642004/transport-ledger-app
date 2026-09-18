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
  // Every screen's `TextField`s are built with a local `_decoration()`-style
  // helper that sets padding/border but never a `style:` — so with no
  // override here, the actual typed/hint text fell back to Material 3's
  // default `textTheme.bodyLarge` (16px), visibly larger than the 11-12px
  // labels and hints surrounding it everywhere in the app (and, since field
  // height follows text height, made every field noticeably taller too).
  // Overriding just this one slot fixes every such field app-wide; explicit
  // per-field `style:` overrides (e.g. the bold 18px amount fields) are
  // untouched since they always take precedence over the theme default.
  //
  // `DropdownButton`/`DropdownButtonFormField` (every "select" field —
  // company/customer/driver/payment method/etc.) don't read `bodyLarge` at
  // all; they default to `titleMedium`, which was still at Material 3's
  // ~16px default, so selected values/menu items stayed visibly larger than
  // every plain text field around them. No `ListTile` (the other common
  // implicit consumer of `titleMedium`) exists anywhere in this app, so this
  // is safe to override the same way.
  textTheme: const TextTheme(bodyLarge: TextStyle(fontSize: 13), titleMedium: TextStyle(fontSize: 13)),
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
