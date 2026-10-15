import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// JusticeNow Design System
/// Primary: Justice Blue (#1D4ED8)
/// Secondary: Sky Blue (#0284C7)
/// Accent: Action Blue (#2563EB)
/// Background: Slate-50 (#F8FAFC)
/// Surface: Pure White (#FFFFFF)

class AppColors {
  AppColors._();

  // Core Palette - Matching Blue
  static const primaryDark = Color(0xFF1E3A8A);    // Deep Royal Navy Blue (Tailwind Blue-900)
  static const primary = Color(0xFF1D4ED8);        // Justice Blue (Tailwind Blue-700)
  static const primaryLight = Color(0xFF3B82F6);   // Vibrant Blue (Tailwind Blue-500)

  static const secondary = Color(0xFF0284C7);      // Sky Blue (Tailwind Sky-600)
  static const secondaryLight = Color(0xFFE0F2FE); // Soft Ice Blue (Tailwind Sky-100)

  static const accent = Color(0xFF2563EB);         // Interactive Action Blue (Tailwind Blue-600)
  static const accentLight = Color(0xFFDBEAFE);    // Soft Blue Container (Tailwind Blue-100)

  // White-related backgrounds & surface palettes (distinct visual hierarchy, not all flat white)
  static const background = Color(0xFFF8FAFC);     // Slate-50 (Crisp clean off-white canvas)
  static const surface = Color(0xFFFFFFFF);        // Pure White (Cards, elevated panels, modal sheets)
  static const surfaceVariant = Color(0xFFF1F5F9); // Slate-100 (Chips, secondary buttons, dividers)
  static const surfaceSubtle = Color(0xFFF8FAFC);  // Slate-50 (Text areas, form inputs, grouped blocks)
  static const surfaceBlue = Color(0xFFEFF6FF);    // Blue-50 (Hero cards, featured banners, info callouts)
  static const surfaceBlueMuted = Color(0xFFDBEAFE);// Blue-100 (Active pills, badge containers)
  static const surfaceGreen = Color(0xFFF0FDF4);   // Green-50 (Approved/Verified status containers)
  static const surfaceAmber = Color(0xFFFFFBEB);   // Amber-50 (Pending/Review status containers)
  static const surfacePurple = Color(0xFFFAF5FF);  // Purple-50 (Counsel & Legal aid accents)
  static const surfaceRed = Color(0xFFFEF2F2);     // Red-50 (Urgent & Alert blocks)

  // Subtle Border Tints matching the Palettes
  static const borderBlue = Color(0xFFBFDBFE);     // Blue-200 (Matches surfaceBlue)
  static const borderGreen = Color(0xFFBBF7D0);    // Green-200 (Matches surfaceGreen)
  static const borderAmber = Color(0xFFFDE68A);    // Amber-200 (Matches surfaceAmber)

  // Typography for Light/White UI
  static const textPrimary = Color(0xFF0F172A);    // Slate-900 (High-contrast dark slate)
  static const textSecondary = Color(0xFF475569);  // Slate-600 (Clear subtitles & labels)
  static const textMuted = Color(0xFF94A3B8);      // Slate-400 (Hints & placeholders)
  static const textOnPrimary = Color(0xFFFFFFFF);  // Pure White on primary/accent

  // Feedback & Status
  static const success = Color(0xFF16A34A);        // Green-600
  static const warning = Color(0xFFD97706);        // Amber-600
  static const error = Color(0xFFDC2626);          // Red-600
  static const info = Color(0xFF2563EB);           // Blue-600

  // Status Colors (cases)
  static const statusSubmitted = Color(0xFF64748B);
  static const statusUnderReview = Color(0xFF2563EB);
  static const statusInvestigating = Color(0xFFD97706);
  static const statusResolved = Color(0xFF16A34A);
  static const statusClosed = Color(0xFF64748B);
  static const statusRejected = Color(0xFFDC2626);

  // Borders, Dividers & Shadows
  static const divider = Color(0xFFE2E8F0);        // Slate-200
  static const border = Color(0xFFE2E8F0);         // Slate-200
  static const shadow = Color(0x0D0F172A);         // Subtle Slate-900 shadow
  static const cardShadow = BoxShadow(
    color: Color(0x0D0F172A),
    blurRadius: 10,
    offset: Offset(0, 4),
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textOnPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.primary),
        actionsIconTheme: const IconThemeData(color: AppColors.primary),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(64, 48),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSubtle,
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: AppColors.border),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 6,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Consistent clean light theme everywhere ("not dark")
  static ThemeData get darkTheme => lightTheme;
}
