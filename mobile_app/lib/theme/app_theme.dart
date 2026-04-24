// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class DayFiColors {
  // Dark theme (default)
  static const background = Color(0xFF000000);
  static const surface = Color(0xFF0A0A0A);
  static const card = Color(0xFF111111);
  static const border = Color(0xFF1E1E1E);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF888888);
  static const textMuted = Color(0xFF444444);

  // Accent
  static const green = Color(0xFF00E676);
  static const greenDim = Color(0xFF1A3326);
  static const red = Color(0xFFFF4444);
  static const redDim = Color(0xFF3D1515);

  // Light theme
  static const lightBackground = Color(0xFFF5F5F5);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFF0F0F0);
  static const lightBorder = Color(0xFFE0E0E0);
  static const lightTextPrimary = Color(0xFF000000);
  static const lightTextSecondary = Color(0xFF666666);
}

// schibstedGrotesk
// medievalSharp

class AppTheme {
  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    final base = GoogleFonts.bricolageGrotesqueTextTheme();
    return base.copyWith(
      displayLarge: GoogleFonts.bricolageGrotesque(
        fontSize: 44,
        fontWeight: FontWeight.w400,
        color: primary,
        letterSpacing: -2,
      ),
      displayMedium: GoogleFonts.bricolageGrotesque(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: primary,
        letterSpacing: -1.5,
      ),
      displaySmall: GoogleFonts.bricolageGrotesque(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: primary,
        letterSpacing: -1,
      ),
      headlineMedium: GoogleFonts.bricolageGrotesque(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.bricolageGrotesque(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleMedium: GoogleFonts.bricolageGrotesque(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: GoogleFonts.bricolageGrotesque(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyMedium: GoogleFonts.bricolageGrotesque(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      bodySmall: GoogleFonts.bricolageGrotesque(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      labelLarge: GoogleFonts.bricolageGrotesque(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: DayFiColors.background,
      colorScheme: const ColorScheme.dark(
        background: DayFiColors.background,
        surface: DayFiColors.surface,
        primary: DayFiColors.textPrimary,
        secondary: DayFiColors.green,
        error: DayFiColors.red,
        onBackground: DayFiColors.textPrimary,
        onSurface: DayFiColors.textPrimary,
      ),
      textTheme: _buildTextTheme(
        DayFiColors.textPrimary,
        DayFiColors.textSecondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: DayFiColors.background,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.bricolageGrotesque(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: DayFiColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: DayFiColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DayFiColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DayFiColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DayFiColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: DayFiColors.textPrimary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DayFiColors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        hintStyle: GoogleFonts.bricolageGrotesque(
          color: DayFiColors.textMuted,
          fontSize: 16,
        ),
        labelStyle: GoogleFonts.bricolageGrotesque(color: DayFiColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DayFiColors.textPrimary,
          foregroundColor: DayFiColors.background,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.bricolageGrotesque(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DayFiColors.textPrimary,
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: DayFiColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.bricolageGrotesque(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DayFiColors.textSecondary,
          textStyle: GoogleFonts.bricolageGrotesque(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: DayFiColors.border,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: DayFiColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: DayFiColors.border),
        ),
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: DayFiColors.lightBackground,
      colorScheme: const ColorScheme.light(
        background: DayFiColors.lightBackground,
        surface: DayFiColors.lightSurface,
        primary: DayFiColors.lightTextPrimary,
        secondary: Color(0xFF00B459),
        error: DayFiColors.red,
      ),
      textTheme: _buildTextTheme(
        DayFiColors.lightTextPrimary,
        DayFiColors.lightTextSecondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: DayFiColors.lightBackground,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.bricolageGrotesque(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: DayFiColors.lightTextPrimary,
        ),
        iconTheme: const IconThemeData(color: DayFiColors.lightTextPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DayFiColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DayFiColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DayFiColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: DayFiColors.lightTextPrimary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        hintStyle: GoogleFonts.bricolageGrotesque(
          color: DayFiColors.lightTextSecondary,
          fontSize: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DayFiColors.lightTextPrimary,
          foregroundColor: DayFiColors.lightBackground,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.bricolageGrotesque(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: DayFiColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: DayFiColors.lightBorder),
        ),
      ),
    );
  }
}

/// App-specific semantic theme colors used across categories, recurring items,
/// transactions, charts, tabs, etc.
///
/// This extension works together with the main AppTheme (DayFiColors).
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.surfaceBackground,
    required this.cardSurface,
    required this.sheetSurface,
    required this.cardBorder,
    required this.primaryText,
    required this.secondaryText,
    required this.sectionHeader,
    required this.hintText,
    required this.chartUnfilled,
    required this.gradientOverlay,
    required this.monthlyCardSurface,
    required this.contentBackground,
    required this.headerIconColor,
    required this.tabIndicatorColor,
    required this.tabSelectedColor,
    required this.tabUnselectedColor,
    required this.errorColor,
  });

  // Main background (scaffold, list views)
  final Color surfaceBackground;

  // Card/container background
  final Color cardSurface;

  // Bottom sheet / modal surface
  final Color sheetSurface;

  // Card borders
  final Color cardBorder;

  // Primary text (amounts, titles, important content)
  final Color primaryText;

  // Secondary text (labels, subtitles)
  final Color secondaryText;

  // Section headers
  final Color sectionHeader;

  // Hint / placeholder text
  final Color hintText;

  // Chart unfilled / background segments
  final Color chartUnfilled;

  // Gradient overlays (e.g. search bar fade)
  final Color gradientOverlay;

  // Monthly review / summary card
  final Color monthlyCardSurface;

  // Main content area background (inside tabs)
  final Color contentBackground;

  // Header icons (settings, refresh, etc.)
  final Color headerIconColor;

  // Tab bar indicator
  final Color tabIndicatorColor;

  // Selected tab label / active state
  final Color tabSelectedColor;

  // Unselected tab label
  final Color tabUnselectedColor;

  // Error / negative values (debt, negative balance)
  final Color errorColor;

  static AppThemeExtension get dark => AppThemeExtension(
        surfaceBackground: DayFiColors.background,           // 0xFF000000
        cardSurface: DayFiColors.card,                       // 0xFF111111
        sheetSurface: DayFiColors.surface,                   // 0xFF0A0A0A
        cardBorder: DayFiColors.border,                      // 0xFF1E1E1E
        primaryText: DayFiColors.textPrimary,                // 0xFFFFFFFF
        secondaryText: DayFiColors.textSecondary,            // 0xFF888888
        sectionHeader: const Color(0xFFAAAAAA),              // slightly brighter for headers
        hintText: DayFiColors.textMuted,                     // 0xFF444444
        chartUnfilled: const Color(0xFF1E1E1E),              // subtle unfilled chart bg
        gradientOverlay: DayFiColors.background,             // fade to black
        monthlyCardSurface: DayFiColors.card,                // same as cards for consistency
        contentBackground: DayFiColors.surface,              // 0xFF0A0A0A
        headerIconColor: const Color(0xFFAAAAAA),
        tabIndicatorColor: DayFiColors.green,                // accent green for active tab
        tabSelectedColor: DayFiColors.textPrimary,
        tabUnselectedColor: DayFiColors.textSecondary,
        errorColor: DayFiColors.red,                         // 0xFFFF4444
      );

  static AppThemeExtension get light => AppThemeExtension(
        surfaceBackground: DayFiColors.lightBackground,      // 0xFFF5F5F5
        cardSurface: DayFiColors.lightCard,                  // 0xFFF0F0F0
        sheetSurface: DayFiColors.lightSurface,              // 0xFFFFFFFF
        cardBorder: DayFiColors.lightBorder,                 // 0xFFE0E0E0
        primaryText: DayFiColors.lightTextPrimary,           // 0xFF000000
        secondaryText: DayFiColors.lightTextSecondary,       // 0xFF666666
        sectionHeader: const Color(0xFF2C2C2C),
        hintText: const Color(0xFF999999),
        chartUnfilled: const Color(0xFFEEEEEE),
        gradientOverlay: const Color(0xFFF8F8F8),
        monthlyCardSurface: DayFiColors.lightCard,
        contentBackground: DayFiColors.lightBackground,
        headerIconColor: const Color(0xFF555555),
        tabIndicatorColor: const Color(0xFF00B459),          // matches light secondary
        tabSelectedColor: DayFiColors.lightTextPrimary,
        tabUnselectedColor: DayFiColors.lightTextSecondary,
        errorColor: DayFiColors.red,
      );

  @override
  AppThemeExtension copyWith({
    Color? surfaceBackground,
    Color? cardSurface,
    Color? sheetSurface,
    Color? cardBorder,
    Color? primaryText,
    Color? secondaryText,
    Color? sectionHeader,
    Color? hintText,
    Color? chartUnfilled,
    Color? gradientOverlay,
    Color? monthlyCardSurface,
    Color? contentBackground,
    Color? headerIconColor,
    Color? tabIndicatorColor,
    Color? tabSelectedColor,
    Color? tabUnselectedColor,
    Color? errorColor,
  }) {
    return AppThemeExtension(
      surfaceBackground: surfaceBackground ?? this.surfaceBackground,
      cardSurface: cardSurface ?? this.cardSurface,
      sheetSurface: sheetSurface ?? this.sheetSurface,
      cardBorder: cardBorder ?? this.cardBorder,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      sectionHeader: sectionHeader ?? this.sectionHeader,
      hintText: hintText ?? this.hintText,
      chartUnfilled: chartUnfilled ?? this.chartUnfilled,
      gradientOverlay: gradientOverlay ?? this.gradientOverlay,
      monthlyCardSurface: monthlyCardSurface ?? this.monthlyCardSurface,
      contentBackground: contentBackground ?? this.contentBackground,
      headerIconColor: headerIconColor ?? this.headerIconColor,
      tabIndicatorColor: tabIndicatorColor ?? this.tabIndicatorColor,
      tabSelectedColor: tabSelectedColor ?? this.tabSelectedColor,
      tabUnselectedColor: tabUnselectedColor ?? this.tabUnselectedColor,
      errorColor: errorColor ?? this.errorColor,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      surfaceBackground: Color.lerp(surfaceBackground, other.surfaceBackground, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      sheetSurface: Color.lerp(sheetSurface, other.sheetSurface, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      sectionHeader: Color.lerp(sectionHeader, other.sectionHeader, t)!,
      hintText: Color.lerp(hintText, other.hintText, t)!,
      chartUnfilled: Color.lerp(chartUnfilled, other.chartUnfilled, t)!,
      gradientOverlay: Color.lerp(gradientOverlay, other.gradientOverlay, t)!,
      monthlyCardSurface: Color.lerp(monthlyCardSurface, other.monthlyCardSurface, t)!,
      contentBackground: Color.lerp(contentBackground, other.contentBackground, t)!,
      headerIconColor: Color.lerp(headerIconColor, other.headerIconColor, t)!,
      tabIndicatorColor: Color.lerp(tabIndicatorColor, other.tabIndicatorColor, t)!,
      tabSelectedColor: Color.lerp(tabSelectedColor, other.tabSelectedColor, t)!,
      tabUnselectedColor: Color.lerp(tabUnselectedColor, other.tabUnselectedColor, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
    );
  }

  /// Convenient getter
  static AppThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<AppThemeExtension>() ?? dark;
  }
}