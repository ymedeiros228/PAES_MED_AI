import 'package:flutter/material.dart';

/// Identidade PAES MED AI: teal clínico + navy.
/// Light = ar limpo. Dark = foco noturno (ink).
class AppTheme {
  static const navy = Color(0xFF0A1628);
  static const navySoft = Color(0xFF132337);
  static const teal = Color(0xFF1FA887);
  static const tealDeep = Color(0xFF0C7A63);
  static const mint = Color(0xFFE6F6F1);
  static const sand = Color(0xFFF6F4F1);
  static const ink = Color(0xFF0E1726);
  static const alert = Color(0xFFE8A04B);
  static const warning = Color(0xFFE8A04B);
  static const danger = Color(0xFFD3544A);
  static const brandAccent = teal;

  /// Compat com código antigo que usava gradient fixo.
  static const scaffoldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFCFBFA), Color(0xFFF3F7F5), Color(0xFFEDF2F0)],
    stops: [0.0, 0.55, 1.0],
  );

  static LinearGradient scaffoldGradientFor(Brightness b) {
    if (b == Brightness.dark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF070E18), Color(0xFF0C1828), Color(0xFF0A141F)],
        stops: [0.0, 0.55, 1.0],
      );
    }
    return scaffoldGradient;
  }

  static LinearGradient heroGradient(Brightness b) {
    if (b == Brightness.dark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0B1A2C), Color(0xFF0C4A3E), Color(0xFF0A1628)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0B1F33), Color(0xFF0F6B5C), Color(0xFF148F78)],
    );
  }

  static LinearGradient railGradient(Brightness b) {
    if (b == Brightness.dark) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0A121C), Color(0xFF0B1522)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFFFF), Color(0xFFF5F8F7)],
    );
  }

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: dark ? const Color(0xFF3DC9A8) : tealDeep,
      onPrimary: dark ? navy : Colors.white,
      primaryContainer: dark ? const Color(0xFF163B33) : mint,
      onPrimaryContainer: dark ? const Color(0xFFB8F0DE) : const Color(0xFF053D34),
      secondary: dark ? const Color(0xFF8BA3B8) : navy,
      onSecondary: dark ? navy : Colors.white,
      secondaryContainer: dark ? const Color(0xFF1A2A3A) : const Color(0xFFE8EEF3),
      onSecondaryContainer: dark ? const Color(0xFFD5E2EE) : navy,
      tertiary: warning,
      onTertiary: navy,
      tertiaryContainer: dark ? const Color(0xFF3A2A12) : const Color(0xFFFFF1DB),
      onTertiaryContainer: dark ? const Color(0xFFFFE0B0) : const Color(0xFF5C3A0A),
      error: danger,
      onError: Colors.white,
      errorContainer: dark ? const Color(0xFF3B1715) : const Color(0xFFFFE8E6),
      onErrorContainer: dark ? const Color(0xFFFFC9C4) : const Color(0xFF5C1510),
      surface: dark ? const Color(0xFF0E1824) : Colors.white,
      onSurface: dark ? const Color(0xFFE8EEF3) : ink,
      surfaceContainerHighest: dark ? const Color(0xFF1A2838) : const Color(0xFFEAEFED),
      surfaceContainerHigh: dark ? const Color(0xFF162231) : const Color(0xFFF0F4F2),
      surfaceContainer: dark ? const Color(0xFF121D2A) : const Color(0xFFF6F8F7),
      surfaceContainerLow: dark ? const Color(0xFF101A26) : const Color(0xFFFAFBFA),
      surfaceContainerLowest: dark ? const Color(0xFF0A121C) : Colors.white,
      outline: dark ? const Color(0xFF334555) : const Color(0xFFC9D4CE),
      outlineVariant: dark ? const Color(0xFF243140) : const Color(0xFFE2E9E5),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: dark ? const Color(0xFFE8EEF3) : navy,
      onInverseSurface: dark ? navy : Colors.white,
      inversePrimary: dark ? tealDeep : const Color(0xFF3DC9A8),
    );

    // Display Georgia (editorial) + corpo Segoe Variable (UI limpa, HK)
    const displayFallback = <String>['Georgia', 'Times New Roman', 'serif'];
    const bodyFallback = <String>[
      'Segoe UI Variable',
      'Segoe UI',
      'Candara',
      'sans-serif',
    ];
    final display = TextStyle(
      fontFamily: 'Georgia',
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
      height: 1.12,
      letterSpacing: -0.6,
    );
    final body = TextStyle(
      fontFamily: 'Segoe UI Variable',
      fontFamilyFallback: bodyFallback,
      color: scheme.onSurface,
      height: 1.45,
      letterSpacing: 0.1,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: scheme.surface,
      dividerColor: scheme.outlineVariant,
      textTheme: TextTheme(
        displayLarge: display.copyWith(fontSize: 44),
        displayMedium: display.copyWith(fontSize: 36),
        displaySmall: display.copyWith(fontSize: 32),
        headlineLarge: display.copyWith(fontSize: 28),
        headlineMedium: display.copyWith(fontSize: 24),
        headlineSmall: display.copyWith(fontSize: 20),
        titleLarge: body.copyWith(fontWeight: FontWeight.w700, fontSize: 18),
        titleMedium: body.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
        titleSmall: body.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
        bodyLarge: body.copyWith(fontSize: 16),
        bodyMedium: body.copyWith(fontSize: 14, color: scheme.onSurface.withOpacity(0.88)),
        bodySmall: body.copyWith(fontSize: 12, color: scheme.onSurface.withOpacity(0.62)),
        labelLarge: body.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
        labelMedium: body.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
        labelSmall: body.copyWith(fontWeight: FontWeight.w500, fontSize: 11, letterSpacing: 0.4),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: display.copyWith(fontSize: 20, color: scheme.onSurface),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: scheme.surface.withOpacity(dark ? 0.92 : 0.96),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withOpacity(0.8)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          side: BorderSide(color: scheme.outline.withOpacity(0.7)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primaryContainer,
        labelStyle: body.copyWith(fontSize: 12),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return scheme.onPrimary;
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return scheme.primary;
          return scheme.surfaceContainerHighest;
        }),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface.withOpacity(0.96),
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          body.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        height: 68,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: scheme.onSurface.withOpacity(0.45)),
        selectedLabelTextStyle: body.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: scheme.primary,
        ),
        unselectedLabelTextStyle: body.copyWith(
          fontSize: 12,
          color: scheme.onSurface.withOpacity(0.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? scheme.surfaceContainerHigh : navy,
        contentTextStyle: body.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

extension AppThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
