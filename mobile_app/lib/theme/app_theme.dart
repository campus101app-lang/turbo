// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class DayFiColors {
  // ── Light theme ─────────────────────────────────────────────────────────
  static const lightBackground    = Color(0xFFF9F7F4); // matches web --color-bg
  static const lightSurface       = Color(0xFFFFFFFF); // --color-bg-raised
  static const lightCard          = Color(0xFFFFFFFF); // --color-bg-raised
  static const lightBorder        = Color(0x14000000); // --color-border rgba(0,0,0,0.08)
  static const lightBorderBright  = Color(0x24000000); // --color-border-bright rgba(0,0,0,0.14)
  static const lightTextPrimary   = Color(0xFF111111); // --color-ink
  static const lightTextSecondary = Color(0xFF52504D); // --color-ink-muted
  static const lightTextMuted     = Color(0xFF8E8B85); // --color-ink-faint

  // ── Dark theme ──────────────────────────────────────────────────────────
  static const background    = Color(0xFF0D0D0D); // --color-bg dark
  static const surface       = Color(0xFF1A1A1A); // --color-bg-raised dark
  static const card          = Color(0xFF1A1A1A); // --color-bg-raised dark
  static const border        = Color(0x14FFFFFF); // --color-border rgba(255,255,255,0.08)
  static const borderBright  = Color(0x21FFFFFF); // --color-border-bright rgba(255,255,255,0.13)
  static const textPrimary   = Color(0xFFF0EFED); // --color-ink dark
  static const textSecondary = Color(0xFF9B9995); // --color-ink-muted dark
  static const textMuted     = Color(0xFF6B6966); // --color-ink-faint dark

  // ── PRIMARY: Green — web --color-teal / --color-success ─────────────────
  // Light: #0a9480  Dark: #2dc9b0  (direct from your web CSS)
  static const primary          = Color(0xFF0A9480); // --color-teal light
  static const primaryDark      = Color(0xFF2DC9B0); // --color-teal dark
  static const primaryDim       = Color(0xFF0A948014); // --color-teal-dim light (~8% alpha)
  static const primaryDimLight  = Color(0xFFE4F4F1); // --color-success-dim light
  static const primaryDimDark   = Color(0xFF0D3630); // --color-success-dim dark

  // Full green ramp (mirrors Tailwind green-800 family + web tokens)
  static const green50   = Color(0xFFE4F4F1); // success-dim light
  static const green100  = Color(0xFFB3E4DC);
  static const green200  = Color(0xFF7ECFC4);
  static const green400  = Color(0xFF0A9480); // primary / --color-teal
  static const green600  = Color(0xFF077A69);
  static const green800  = Color(0xFF166534); // Tailwind green-800
  static const green900  = Color(0xFF0D3630); // success-dim dark

  // ── Secondary: Brand blue ────────────────────────────────────────────────
  static const secondary          = Color(0xFF5B8EF0); // --color-brand light
  static const secondaryDark      = Color(0xFF7AA9F7); // --color-brand dark
  static const secondaryDim       = Color(0xFF5B8EF018); // --color-brand-dim
  static const secondaryDimLight  = Color(0xFFDDE9FB); // --color-brand-light
  static const secondaryDimDark   = Color(0xFF7AA9F720);

  // ── Accent: kept for success/confirmed states (alias of primary) ─────────
  static const accent         = primary;
  static const accentDim      = primaryDimDark;
  static const accentDimLight = primaryDimLight;

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const error          = Color(0xFFD32F2F); // --color-error light
  static const errorDark      = Color(0xFFF06060); // --color-error dark
  static const errorDim       = Color(0xFF991B1B);
  static const errorDimLight  = Color(0xFFFDE8E8); // --color-error-dim light
  static const errorDimDark   = Color(0xFF2D0E0E); // --color-error-dim dark

  static const warning        = Color(0xFFD08700); // --color-warning light
  static const warningDark    = Color(0xFFF5A623); // --color-warning dark
  static const warningDim     = Color(0xFF92400E);
  static const warningDimLight = Color(0xFFFFF3CD); // --color-warning-dim light
  static const warningDimDark  = Color(0xFF2E2000); // --color-warning-dim dark

  static const success          = primary;
  static const successDark      = primaryDark;
  static const successDim       = primaryDimDark;
  static const successDimLight  = primaryDimLight;

  // ── Legacy aliases ───────────────────────────────────────────────────────
  static const green         = primary;
  static const greenDim      = primaryDimDark;
  static const greenDimLight = primaryDimLight;

  static const blue          = secondary;
  static const blueDim       = secondaryDimDark;
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

  // ── LIGHT ────────────────────────────────────────────────────────────────
  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: DayFiColors.lightBackground,
      colorScheme: const ColorScheme.light(
        background: DayFiColors.lightBackground,
        surface: DayFiColors.lightSurface,
        primary: DayFiColors.primary,         // green
        onPrimary: Colors.white,
        secondary: DayFiColors.secondary,     // brand blue
        onSecondary: Colors.white,
        error: DayFiColors.error,
        onBackground: DayFiColors.lightTextPrimary,
        onSurface: DayFiColors.lightTextPrimary,
        onError: Colors.white,
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
            color: DayFiColors.primary, // green focus ring
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DayFiColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
          backgroundColor: DayFiColors.primary, // green CTA
          foregroundColor: Colors.white,
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
          foregroundColor: DayFiColors.primary, // green text + border
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: DayFiColors.primary, width: 1.5),
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
          foregroundColor: DayFiColors.primary, // green text buttons
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
        primary: DayFiColors.primaryDark,     // brighter green for dark mode
        onPrimary: Colors.black,
        secondary: DayFiColors.secondaryDark, // brighter blue for dark mode
        onSecondary: Colors.black,
        error: DayFiColors.errorDark,
        onBackground: DayFiColors.textPrimary,
        onSurface: DayFiColors.textPrimary,
        onError: Colors.black,
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
            color: DayFiColors.primaryDark, // bright green focus ring
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DayFiColors.errorDark),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
          backgroundColor: DayFiColors.primaryDark, // bright green CTA
          foregroundColor: Colors.black,
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
          foregroundColor: DayFiColors.primaryDark,
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: DayFiColors.primaryDark, width: 1.5),
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
          foregroundColor: DayFiColors.primaryDark,
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

  static AppThemeExtension get light => const AppThemeExtension(
        surfaceBackground:  DayFiColors.lightBackground,
        cardSurface:        DayFiColors.lightCard,
        sheetSurface:       DayFiColors.lightSurface,
        cardBorder:         DayFiColors.lightBorder,
        primaryText:        DayFiColors.lightTextPrimary,
        secondaryText:      DayFiColors.lightTextSecondary,
        sectionHeader:      Color(0xFF0A4A3F), // deep green tint
        hintText:           DayFiColors.lightTextMuted,
        chartUnfilled:      Color(0xFFD4EDE9), // green-tinted unfilled
        gradientOverlay:    DayFiColors.lightBackground,
        monthlyCardSurface: DayFiColors.lightCard,
        contentBackground:  DayFiColors.lightSurface,
        headerIconColor:    DayFiColors.lightTextSecondary,
        tabIndicatorColor:  DayFiColors.primary,     // green tab indicator
        tabSelectedColor:   DayFiColors.primary,     // green selected tab
        tabUnselectedColor: DayFiColors.lightTextSecondary,
        errorColor:         DayFiColors.error,
        accentBlue:         DayFiColors.secondary,
        accentBlueDim:      DayFiColors.secondaryDimLight,
      );

  static AppThemeExtension get dark => const AppThemeExtension(
        surfaceBackground:  DayFiColors.background,
        cardSurface:        DayFiColors.card,
        sheetSurface:       DayFiColors.surface,
        cardBorder:         DayFiColors.border,
        primaryText:        DayFiColors.textPrimary,
        secondaryText:      DayFiColors.textSecondary,
        sectionHeader:      Color(0xFF7ECFC4), // bright green-teal tint
        hintText:           DayFiColors.textMuted,
        chartUnfilled:      Color(0xFF0D3630), // dark green unfilled
        gradientOverlay:    DayFiColors.background,
        monthlyCardSurface: DayFiColors.card,
        contentBackground:  DayFiColors.surface,
        headerIconColor:    DayFiColors.textSecondary,
        tabIndicatorColor:  DayFiColors.primaryDark, // bright green tab
        tabSelectedColor:   DayFiColors.primaryDark,
        tabUnselectedColor: DayFiColors.textSecondary,
        errorColor:         DayFiColors.errorDark,
        accentBlue:         DayFiColors.secondaryDark,
        accentBlueDim:      DayFiColors.secondaryDimDark,
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