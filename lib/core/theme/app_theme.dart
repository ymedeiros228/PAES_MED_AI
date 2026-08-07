import 'package:flutter/material.dart';

/// Identidade PAES MED AI — studio de estudos (teal clínico + ink).
/// Referência visual: apps desktop densos (rail escura, lista viva, tipo editorial).
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

  /// Rail sempre escura (chrome tipo player).
  static const railInk = Color(0xFF0B1220);
  static const railInkDeep = Color(0xFF070D17);
  static const railInkHover = Color(0xFF141E2E);
  static const railText = Color(0xFFE8EEF4);
  static const railMuted = Color(0xFF8B9BB0);

  /// Compat com código antigo que usava gradient fixo.
  static const scaffoldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF9FBFA), Color(0xFFF0F5F3), Color(0xFFE8F0EC)],
    stops: [0.0, 0.48, 1.0],
  );

  static LinearGradient scaffoldGradientFor(Brightness b) {
    if (b == Brightness.dark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF070E18), Color(0xFF0A1522), Color(0xFF0C1A1A)],
        stops: [0.0, 0.55, 1.0],
      );
    }
    return scaffoldGradient;
  }

  /// Mesa de estudo: glow sutil no canto (não “dashboard genérico”).
  static List<BoxShadow> softElevation(Brightness b) {
    if (b == Brightness.dark) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.35),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ];
    }
    return [
      BoxShadow(
        color: const Color(0xFF0A1628).withOpacity(0.06),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: tealDeep.withOpacity(0.04),
        blurRadius: 40,
        offset: const Offset(0, 16),
      ),
    ];
  }

  static LinearGradient heroGradient(Brightness b) {
    if (b == Brightness.dark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0A1830), Color(0xFF0A4A40), Color(0xFF081420)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0A1E32), Color(0xFF0E6B5C), Color(0xFF12967C)],
    );
  }

  static LinearGradient railGradient(Brightness b) {
    // Sempre ink — legibilidade e “produto” (claro ou escuro do conteúdo).
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [railInk, railInkDeep],
    );
  }

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: dark ? const Color(0xFF3ED4B0) : tealDeep,
      onPrimary: dark ? navy : Colors.white,
      primaryContainer: dark ? const Color(0xFF124038) : mint,
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
      surface: dark ? const Color(0xFF0E1824) : const Color(0xFFFAFCFA),
      onSurface: dark ? const Color(0xFFE8EEF3) : ink,
      surfaceContainerHighest: dark ? const Color(0xFF1A2838) : const Color(0xFFE4ECE8),
      surfaceContainerHigh: dark ? const Color(0xFF162231) : const Color(0xFFEEF3F0),
      surfaceContainer: dark ? const Color(0xFF121D2A) : const Color(0xFFF4F8F6),
      surfaceContainerLow: dark ? const Color(0xFF101A26) : const Color(0xFFF8FBFA),
      surfaceContainerLowest: dark ? const Color(0xFF0A121C) : Colors.white,
      outline: dark ? const Color(0xFF334555) : const Color(0xFFC2CFC8),
      outlineVariant: dark ? const Color(0xFF243140) : const Color(0xFFDCE6E1),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: dark ? const Color(0xFFE8EEF3) : navy,
      onInverseSurface: dark ? navy : Colors.white,
      inversePrimary: dark ? tealDeep : const Color(0xFF3DC9A8),
    );

    // Display serif editorial + corpo UI limpa (Windows Segoe).
    final display = TextStyle(
      fontFamily: 'Georgia',
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
      height: 1.08,
      letterSpacing: -0.8,
    );
    final body = TextStyle(
      fontFamily: 'Segoe UI',
      color: scheme.onSurface,
      height: 1.45,
      letterSpacing: 0.05,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: scheme.surface,
      dividerColor: scheme.outlineVariant,
      textTheme: TextTheme(
        displayLarge: display.copyWith(fontSize: 48),
        displayMedium: display.copyWith(fontSize: 38),
        displaySmall: display.copyWith(fontSize: 32),
        headlineLarge: display.copyWith(fontSize: 30),
        headlineMedium: display.copyWith(fontSize: 26),
        headlineSmall: display.copyWith(fontSize: 22),
        titleLarge: body.copyWith(fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.2),
        titleMedium: body.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
        titleSmall: body.copyWith(fontWeight: FontWeight.w600, fontSize: 13.5),
        bodyLarge: body.copyWith(fontSize: 16),
        bodyMedium: body.copyWith(fontSize: 14.5, color: scheme.onSurface.withOpacity(0.88)),
        bodySmall: body.copyWith(fontSize: 12.5, color: scheme.onSurface.withOpacity(0.58)),
        labelLarge: body.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
        labelMedium: body.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
        labelSmall: body.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.6,
          color: scheme.onSurface.withOpacity(0.55),
        ),
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
        color: scheme.surface.withOpacity(dark ? 0.92 : 0.98),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant.withOpacity(0.75)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: body.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: BorderSide(color: scheme.outline.withOpacity(0.55)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.primary,
        labelStyle: body.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
        selectedIconTheme: const IconThemeData(color: Color(0xFF3ED4B0)),
        unselectedIconTheme: IconThemeData(color: railMuted.withOpacity(0.85)),
        selectedLabelTextStyle: body.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF3ED4B0),
        ),
        unselectedLabelTextStyle: body.copyWith(
          fontSize: 12,
          color: railMuted,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? scheme.surfaceContainerHigh : navy,
        contentTextStyle: body.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer.withOpacity(0.55),
        circularTrackColor: scheme.primaryContainer.withOpacity(0.55),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 0,
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
