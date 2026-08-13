import 'package:flutter/material.dart';

class _Palette {
  const _Palette({
    required this.background,
    required this.surface,
    required this.card,
    required this.glassBg,
    required this.glassBorder,
    required this.foreground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.muted,
    required this.border,
    required this.divider,
    required this.correctLight,
    required this.incorrectLight,
    required this.warningLight,
    required this.goldLight,
    required this.xpLight,
    required this.streakLight,
    required this.coinsLight,
    required this.sky,
    required this.peach,
    required this.mint,
    required this.lavender,
    required this.darkGradient,
    required this.glassGradient,
  });

  final Color background;
  final Color surface;
  final Color card;
  final Color glassBg;
  final Color glassBorder;
  final Color foreground;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color muted;
  final Color border;
  final Color divider;
  final Color correctLight;
  final Color incorrectLight;
  final Color warningLight;
  final Color goldLight;
  final Color xpLight;
  final Color streakLight;
  final Color coinsLight;
  final Color sky;
  final Color peach;
  final Color mint;
  final Color lavender;
  final LinearGradient darkGradient;
  final LinearGradient glassGradient;
}

class AppColors {
  // ── Runtime mode flag (swapped by the app root) ──
  static bool isDark = true;

  static const _Palette _darkPalette = _Palette(
    background: Color(0xFF0A1628),
    surface: Color(0xFF111D35),
    card: Color(0xFF162040),
    glassBg: Color(0x331A2A50),
    glassBorder: Color(0x3300D4FF),
    foreground: Color(0xFFFFFFFF),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF8899BB),
    textMuted: Color(0xFF556688),
    muted: Color(0xFF1A2A50),
    border: Color(0xFF1E3060),
    divider: Color(0xFF1A2A50),
    correctLight: Color(0x3300E676),
    incorrectLight: Color(0x33FF5252),
    warningLight: Color(0x33FFAB40),
    goldLight: Color(0x33FFD700),
    xpLight: Color(0x33BB86FC),
    streakLight: Color(0x33FF6B9D),
    coinsLight: Color(0x33FFD700),
    sky: Color(0x3300D4FF),
    peach: Color(0x33FF6B9D),
    mint: Color(0x3300E676),
    lavender: Color(0x33BB86FC),
    darkGradient: LinearGradient(
      colors: [Color(0xFF0A1628), Color(0xFF111D35)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    glassGradient: LinearGradient(
      colors: [Color(0x1A00D4FF), Color(0x0DFFFFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const _Palette _lightPalette = _Palette(
    background: Color(0xFFF3F6FB),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFE8EEF7),
    glassBg: Color(0xFFEAF0FA),
    glassBorder: Color(0x5900D4FF),
    foreground: Color(0xFF0F1B33),
    textPrimary: Color(0xFF0F1B33),
    textSecondary: Color(0xFF516171),
    textMuted: Color(0xFF8B98AE),
    muted: Color(0xFFE2E9F4),
    border: Color(0xFFD9E2F0),
    divider: Color(0xFFE6ECF5),
    correctLight: Color(0xFFE2F8EC),
    incorrectLight: Color(0xFFFFE9EA),
    warningLight: Color(0xFFFFF3E1),
    goldLight: Color(0xFFFFF4D8),
    xpLight: Color(0xFFF2E9FF),
    streakLight: Color(0xFFFFE9F2),
    coinsLight: Color(0xFFFFF4D8),
    sky: Color(0xFFE0F6FF),
    peach: Color(0xFFFFEAF2),
    mint: Color(0xFFE2F8EC),
    lavender: Color(0xFFF2E9FF),
    darkGradient: LinearGradient(
      colors: [Color(0xFFF6F9FE), Color(0xFFEDF2FA)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    glassGradient: LinearGradient(
      colors: [Color(0x1400D4FF), Color(0x0DFFFFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static _Palette get _c => isDark ? _darkPalette : _lightPalette;

  // ── Primary (Cyan) ──
  static const Color primary = Color(0xFF00D4FF);
  static const Color primaryLight = Color(0xFF5CE1FF);
  static const Color primaryDark = Color(0xFF0091B3);
  static const Color onPrimary = Color(0xFF0A1628);

  // ── Secondary (Pink) ──
  static const Color secondary = Color(0xFFFF6B9D);
  static const Color secondaryLight = Color(0xFFFF9DC2);

  // ── Accent (Gold) ──
  static const Color accent = Color(0xFFFFD700);
  static const Color accentLight = Color(0xFFFFE566);

  // ── Backgrounds ──
  static Color get background => _c.background;
  static Color get surface => _c.surface;
  static Color get card => _c.card;

  // ── Glass ──
  static Color get glassBg => _c.glassBg;
  static Color get glassBorder => _c.glassBorder;

  // ── Text ──
  static Color get foreground => _c.foreground;
  static Color get textPrimary => _c.textPrimary;
  static Color get textSecondary => _c.textSecondary;
  static Color get textMuted => _c.textMuted;

  // ── Muted / Borders ──
  static Color get muted => _c.muted;
  static Color get border => _c.border;
  static Color get divider => _c.divider;

  // ── Semantic States ──
  static const Color correct = Color(0xFF00E676);
  static Color get correctLight => _c.correctLight;
  static const Color incorrect = Color(0xFFFF5252);
  static Color get incorrectLight => _c.incorrectLight;
  static const Color warning = Color(0xFFFFAB40);
  static Color get warningLight => _c.warningLight;
  static const Color destructive = Color(0xFFFF5252);

  // ── Gamification ──
  static const Color gold = Color(0xFFFFD700);
  static Color get goldLight => _c.goldLight;
  static const Color xp = Color(0xFFBB86FC);
  static Color get xpLight => _c.xpLight;
  static const Color streak = Color(0xFFFF6B9D);
  static Color get streakLight => _c.streakLight;
  static const Color coins = Color(0xFFFFD700);
  static Color get coinsLight => _c.coinsLight;

  // ── Legacy aliases ──
  static Color get navy => _c.background;
  static const Color orange = accent;
  static Color get cream => _c.background;
  static Color get inkSoft => _c.textSecondary;
  static Color get white => _c.textPrimary;
  static Color get peach => _c.peach;
  static Color get sky => _c.sky;
  static Color get mint => _c.mint;
  static Color get lavender => _c.lavender;
  static const Color cardShadow = Color(0x1A00D4FF);

  // ── Shadows ──
  static final List<BoxShadow> clayShadow = [
    BoxShadow(
      offset: const Offset(0, 4),
      blurRadius: 20,
      color: Colors.black.withOpacity(0.3),
    ),
    BoxShadow(
      offset: const Offset(0, 0),
      blurRadius: 1,
      color: AppColors.primary.withOpacity(0.05),
    ),
  ];

  static final List<BoxShadow> clayShadowSmall = [
    BoxShadow(
      offset: const Offset(0, 2),
      blurRadius: 12,
      color: Colors.black.withOpacity(0.2),
    ),
  ];

  static final List<BoxShadow> clayShadowLarge = [
    BoxShadow(
      offset: const Offset(0, 8),
      blurRadius: 30,
      color: Colors.black.withOpacity(0.4),
    ),
  ];

  static final List<BoxShadow> glowShadow = [
    BoxShadow(
      offset: const Offset(0, 0),
      blurRadius: 20,
      color: AppColors.primary.withOpacity(0.3),
    ),
  ];

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF0091B3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFAB40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient correctGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00C853)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incorrectGradient = LinearGradient(
    colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFAB40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient xpGradient = LinearGradient(
    colors: [Color(0xFFBB86FC), Color(0xFF9C64FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get darkGradient => _c.darkGradient;
  static LinearGradient get glassGradient => _c.glassGradient;
}

class AppTheme {
  static final ThemeData darkTheme = _buildTheme(dark: true);
  static final ThemeData lightTheme = _buildTheme(dark: false);

  static ThemeData _buildTheme({required bool dark}) {
    final previous = AppColors.isDark;
    AppColors.isDark = dark;
    final theme = _compose();
    AppColors.isDark = previous;
    return theme;
  }

  static ThemeData _compose() {
    return ThemeData(
      useMaterial3: true,
      brightness: AppColors.isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: AppColors.isDark
          ? ColorScheme.dark(
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              tertiary: AppColors.accent,
              surface: AppColors.surface,
              error: AppColors.destructive,
              onPrimary: AppColors.onPrimary,
              onSurface: AppColors.textPrimary,
            )
          : ColorScheme.light(
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              tertiary: AppColors.accent,
              surface: AppColors.surface,
              error: AppColors.destructive,
              onPrimary: AppColors.onPrimary,
              onSurface: AppColors.textPrimary,
            ),
      fontFamily: 'Nunito',
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 48.0,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
          letterSpacing: -1.5,
          height: 1.1,
        ),
        headlineLarge: TextStyle(
          fontSize: 32.0,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.3,
        ),
        labelMedium: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 20.0,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16.0,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16.0,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
      ),
    );
  }
}

/// Inherited scope exposing the current light/dark mode so that any widget
/// tree can subscribe to palette changes simply by reading [AppThemeScope.isDark].
class AppThemeScope extends InheritedWidget {
  const AppThemeScope({
    super.key,
    required this.isDark,
    required super.child,
  });

  final bool isDark;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppThemeScope>()?.isDark ?? AppColors.isDark;

  @override
  bool updateShouldNotify(AppThemeScope oldWidget) => oldWidget.isDark != isDark;
}