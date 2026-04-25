// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class DayFiColors {
  // ── Light theme (default) ── Claude AI Web Theme Inspired ──────────────
  static const lightBackground    = Color(0xFFFAFAFA); // clean white background
  static const lightSurface       = Color(0xFFFFFFFF); // pure white surface
  static const lightCard          = Color(0xFFFFFFFF); // pure white cards
  static const lightBorder        = Color(0xFFE5E7EB); // subtle gray border
  static const lightTextPrimary   = Color(0xFF111827); // dark gray text
  static const lightTextSecondary = Color(0xFF6B7280); // medium gray text
  static const lightTextMuted     = Color(0xFF9CA3AF); // muted gray text

  // ── Dark theme ── Claude AI Dark Mode ─────────────────────────────────────
  static const background    = Color(0xFF0F0F0F); // deep black
  static const surface       = Color(0xFF1A1A1A); // dark surface
  static const card          = Color(0xFF262626); // dark card
  static const border        = Color(0xFF404040); // dark border
  static const textPrimary   = Color(0xFFFAFAFA); // light primary text
  static const textSecondary = Color(0xFFA1A1AA); // light secondary text
  static const textMuted     = Color(0xFF71717A); // light muted text

  // ── Claude AI Brand Colors ───────────────────────────────────────────────────
  static const primary        = Color(0xFFD97706); // warm amber (Claude orange)
  static const primaryDim     = Color(0xFF92400E); // dark: dim primary bg
  static const primaryDimLight = Color(0xFFFEF3C7); // light: dim primary bg

  static const secondary      = Color(0xFF0EA5E9); // bright blue (Claude blue)
  static const secondaryDim   = Color(0xFF075985); // dark: dim secondary bg
  static const secondaryDimLight = Color(0xFFE0F2FE); // light: dim secondary bg

  static const accent         = Color(0xFF10B981); // emerald green
  static const accentDim      = Color(0xFF047857); // dark: dim accent bg
  static const accentDimLight = Color(0xFFD1FAE5); // light: dim accent bg

  static const error          = Color(0xFFEF4444); // red
  static const errorDim       = Color(0xFF991B1B); // dark: dim error bg
  static const errorDimLight  = Color(0xFFFEE2E2); // light: dim error bg

  static const warning        = Color(0xFFF59E0B); // amber
  static const warningDim     = Color(0xFF92400E); // dark: dim warning bg
  static const warningDimLight = Color(0xFFFEF3C7); // light: dim warning bg

  static const success        = Color(0xFF10B981); // emerald
  static const successDim     = Color(0xFF047857); // dark: dim success bg
  static const successDimLight = Color(0xFFD1FAE5); // light: dim success bg

  // Legacy color names for compatibility
  static const green         = success;
  static const greenDim      = successDim;
  static const greenDimLight = successDimLight;

  static const blue          = secondary;
  static const blueDim       = secondaryDim;
  static const blueDimLight  = secondaryDimLight;

  static const red           = error;
  static const redDim        = errorDim;
  static const redDimLight   = errorDimLight;
}

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

  // ── LIGHT (default) ──────────────────────────────────────────────────────
  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: DayFiColors.lightBackground,
      colorScheme: const ColorScheme.light(
        background: DayFiColors.lightBackground,
        surface: DayFiColors.lightSurface,
        primary: DayFiColors.primary,
        secondary: DayFiColors.secondary,
        error: DayFiColors.error,
        onBackground: DayFiColors.lightTextPrimary,
        onSurface: DayFiColors.lightTextPrimary,
        onError: DayFiColors.lightTextPrimary,
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
          fontWeight: FontWeight.w600,
          color: DayFiColors.lightTextPrimary,
        ),
        iconTheme: const IconThemeData(color: DayFiColors.lightTextPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DayFiColors.lightCard,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DayFiColors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        hintStyle: GoogleFonts.bricolageGrotesque(
          color: DayFiColors.lightTextMuted,
          fontSize: 16,
        ),
        labelStyle: GoogleFonts.bricolageGrotesque(
          color: DayFiColors.lightTextSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DayFiColors.lightTextPrimary,
          foregroundColor: DayFiColors.lightBackground,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100), // Ko-fi pill buttons
          ),
          textStyle: GoogleFonts.bricolageGrotesque(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DayFiColors.lightTextPrimary,
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: DayFiColors.lightBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          textStyle: GoogleFonts.bricolageGrotesque(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DayFiColors.lightTextSecondary,
          textStyle: GoogleFonts.bricolageGrotesque(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: DayFiColors.lightBorder,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: DayFiColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: DayFiColors.lightBorder),
        ),
      ),
    );
  }

  // ── DARK ─────────────────────────────────────────────────────────────────
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: DayFiColors.background,
      colorScheme: const ColorScheme.dark(
        background: DayFiColors.background,
        surface: DayFiColors.surface,
        primary: DayFiColors.primary,
        secondary: DayFiColors.secondary,
        error: DayFiColors.error,
        onBackground: DayFiColors.textPrimary,
        onSurface: DayFiColors.textPrimary,
        onError: DayFiColors.textPrimary,
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
          fontWeight: FontWeight.w600,
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
        labelStyle: GoogleFonts.bricolageGrotesque(
          color: DayFiColors.textSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DayFiColors.textPrimary,
          foregroundColor: DayFiColors.background,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          textStyle: GoogleFonts.bricolageGrotesque(
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
            borderRadius: BorderRadius.circular(100),
          ),
          textStyle: GoogleFonts.bricolageGrotesque(
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
}

/// App-specific semantic theme colors used across categories, recurring items,
/// transactions, charts, tabs, etc.
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
    required this.accentBlue,
    required this.accentBlueDim,
  });

  final Color surfaceBackground;
  final Color cardSurface;
  final Color sheetSurface;
  final Color cardBorder;
  final Color primaryText;
  final Color secondaryText;
  final Color sectionHeader;
  final Color hintText;
  final Color chartUnfilled;
  final Color gradientOverlay;
  final Color monthlyCardSurface;
  final Color contentBackground;
  final Color headerIconColor;
  final Color tabIndicatorColor;
  final Color tabSelectedColor;
  final Color tabUnselectedColor;
  final Color errorColor;
  final Color accentBlue;
  final Color accentBlueDim;

  static AppThemeExtension get light => AppThemeExtension(
        surfaceBackground:  DayFiColors.lightBackground,
        cardSurface:        DayFiColors.lightCard,
        sheetSurface:       DayFiColors.lightSurface,
        cardBorder:         DayFiColors.lightBorder,
        primaryText:        DayFiColors.lightTextPrimary,
        secondaryText:      DayFiColors.lightTextSecondary,
        sectionHeader:      const Color(0xFF3D3026),
        hintText:           DayFiColors.lightTextMuted,
        chartUnfilled:      const Color(0xFFE4DDD5),
        gradientOverlay:    DayFiColors.lightBackground,
        monthlyCardSurface: DayFiColors.lightCard,
        contentBackground:  DayFiColors.lightSurface,
        headerIconColor:    DayFiColors.lightTextSecondary,
        tabIndicatorColor:  DayFiColors.blue,
        tabSelectedColor:   DayFiColors.lightTextPrimary,
        tabUnselectedColor: DayFiColors.lightTextSecondary,
        errorColor:         DayFiColors.error,
        accentBlue:         DayFiColors.secondary,
        accentBlueDim:      DayFiColors.secondaryDimLight,
      );

  static AppThemeExtension get dark => AppThemeExtension(
        surfaceBackground:  DayFiColors.background,
        cardSurface:        DayFiColors.card,
        sheetSurface:       DayFiColors.surface,
        cardBorder:         DayFiColors.border,
        primaryText:        DayFiColors.textPrimary,
        secondaryText:      DayFiColors.textSecondary,
        sectionHeader:      const Color(0xFFB8AFA6),
        hintText:           DayFiColors.textMuted,
        chartUnfilled:      const Color(0xFF2A2218),
        gradientOverlay:    DayFiColors.background,
        monthlyCardSurface: DayFiColors.card,
        contentBackground:  DayFiColors.surface,
        headerIconColor:    DayFiColors.textSecondary,
        tabIndicatorColor:  DayFiColors.blue,
        tabSelectedColor:   DayFiColors.textPrimary,
        tabUnselectedColor: DayFiColors.textSecondary,
        errorColor:         DayFiColors.error,
        accentBlue:         DayFiColors.secondary,
        accentBlueDim:      DayFiColors.secondaryDim,
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
    Color? accentBlue,
    Color? accentBlueDim,
  }) {
    return AppThemeExtension(
      surfaceBackground:  surfaceBackground  ?? this.surfaceBackground,
      cardSurface:        cardSurface        ?? this.cardSurface,
      sheetSurface:       sheetSurface       ?? this.sheetSurface,
      cardBorder:         cardBorder         ?? this.cardBorder,
      primaryText:        primaryText        ?? this.primaryText,
      secondaryText:      secondaryText      ?? this.secondaryText,
      sectionHeader:      sectionHeader      ?? this.sectionHeader,
      hintText:           hintText           ?? this.hintText,
      chartUnfilled:      chartUnfilled      ?? this.chartUnfilled,
      gradientOverlay:    gradientOverlay    ?? this.gradientOverlay,
      monthlyCardSurface: monthlyCardSurface ?? this.monthlyCardSurface,
      contentBackground:  contentBackground  ?? this.contentBackground,
      headerIconColor:    headerIconColor    ?? this.headerIconColor,
      tabIndicatorColor:  tabIndicatorColor  ?? this.tabIndicatorColor,
      tabSelectedColor:   tabSelectedColor   ?? this.tabSelectedColor,
      tabUnselectedColor: tabUnselectedColor ?? this.tabUnselectedColor,
      errorColor:         errorColor         ?? this.errorColor,
      accentBlue:         accentBlue         ?? this.accentBlue,
      accentBlueDim:      accentBlueDim      ?? this.accentBlueDim,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      surfaceBackground:  Color.lerp(surfaceBackground,  other.surfaceBackground,  t)!,
      cardSurface:        Color.lerp(cardSurface,        other.cardSurface,        t)!,
      sheetSurface:       Color.lerp(sheetSurface,       other.sheetSurface,       t)!,
      cardBorder:         Color.lerp(cardBorder,         other.cardBorder,         t)!,
      primaryText:        Color.lerp(primaryText,        other.primaryText,        t)!,
      secondaryText:      Color.lerp(secondaryText,      other.secondaryText,      t)!,
      sectionHeader:      Color.lerp(sectionHeader,      other.sectionHeader,      t)!,
      hintText:           Color.lerp(hintText,           other.hintText,           t)!,
      chartUnfilled:      Color.lerp(chartUnfilled,      other.chartUnfilled,      t)!,
      gradientOverlay:    Color.lerp(gradientOverlay,    other.gradientOverlay,    t)!,
      monthlyCardSurface: Color.lerp(monthlyCardSurface, other.monthlyCardSurface, t)!,
      contentBackground:  Color.lerp(contentBackground,  other.contentBackground,  t)!,
      headerIconColor:    Color.lerp(headerIconColor,    other.headerIconColor,    t)!,
      tabIndicatorColor:  Color.lerp(tabIndicatorColor,  other.tabIndicatorColor,  t)!,
      tabSelectedColor:   Color.lerp(tabSelectedColor,   other.tabSelectedColor,   t)!,
      tabUnselectedColor: Color.lerp(tabUnselectedColor, other.tabUnselectedColor, t)!,
      errorColor:         Color.lerp(errorColor,         other.errorColor,         t)!,
      accentBlue:         Color.lerp(accentBlue,         other.accentBlue,         t)!,
      accentBlueDim:      Color.lerp(accentBlueDim,      other.accentBlueDim,      t)!,
    );
  }

  static AppThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<AppThemeExtension>() ?? light;
  }
}