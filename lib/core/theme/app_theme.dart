import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_fonts.dart';

/// Identidade PAES MED AI: teal clínico + navy.
/// Dark = foco noturno (modo principal). Light = ar limpo.
///
/// Tipografia: Inter (corpo/UI) + Poppins (títulos/display), embutidas em
/// `assets/fonts` e declaradas no pubspec. Fallback: Segoe UI → Arial.
///
/// Regras do sistema visual (use nas telas):
/// - Espaçamento em escala 4/8 (`kGap4..kGap48` em layout_tokens.dart).
/// - Cantos: controles 10, botões 12, painéis 16, hero 20.
/// - Superfícies: fundo (scaffold) < surface (cards) < surfaceContainerHigh (destaques).
/// - Texto secundário = `onSurface.f72` (AA); terciário = `onSurface.f55` só para ícones/legendas.
class AppTheme {
  static const navy = Color(0xFF0A1628);
  static const navySoft = Color(0xFF132337);
  static const teal = Color(0xFF1FA887);
  static const tealDeep = Color(0xFF0C7A63);
  static const mint = Color(0xFFE6F6F1);
  static const sand = Color(0xFFF4F7F6);
  static const ink = Color(0xFF0A121B);
  static const alert = Color(0xFFE8A04B);
  static const warning = Color(0xFFE8A04B);
  static const danger = Color(0xFFD3544A);
  static const brandAccent = teal;

  // Cores semânticas fixas (compat). Prefira `context.palette` (adapta ao tema).
  static const success = Color(0xFF2E9B6B);
  static const successBg = Color(0xFFE4F5EE);
  static const error = Color(0xFFD3544A);
  static const errorBg = Color(0xFFFDEAE8);
  static const info = Color(0xFF3B82F6);
  static const infoBg = Color(0xFFE8F0FE);

  /// Compat com código antigo que usava gradient fixo (modo claro).
  static const scaffoldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF6F8F7), Color(0xFFEFF4F2)],
  );

  /// Fundo das telas — gradiente quase imperceptível (calmo, sem faixas).
  static LinearGradient scaffoldGradientFor(Brightness b) {
    if (b == Brightness.dark) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0B141E), Color(0xFF0A121B)],
      );
    }
    return scaffoldGradient;
  }

  /// Gradiente do hero (Início, cabeçalhos de destaque). Texto por cima: branco.
  static LinearGradient heroGradient(Brightness b) {
    if (b == Brightness.dark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F3A34), Color(0xFF0E2F2F), Color(0xFF0E1E2B)],
        stops: [0.0, 0.5, 1.0],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0B5A4B), Color(0xFF0B6553), Color(0xFF0C4A47)],
      stops: [0.0, 0.55, 1.0],
    );
  }

  /// Fundo da barra lateral.
  static LinearGradient railGradient(Brightness b) {
    if (b == Brightness.dark) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0D1722), Color(0xFF0C1520)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFFFF), Color(0xFFFAFCFB)],
    );
  }

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: dark ? const Color(0xFF3DC9A8) : tealDeep,
      onPrimary: dark ? const Color(0xFF03241C) : Colors.white,
      primaryContainer: dark ? const Color(0xFF123A31) : const Color(0xFFD5F1E7),
      onPrimaryContainer: dark ? const Color(0xFFBFF3E3) : const Color(0xFF00382B),
      secondary: dark ? const Color(0xFF9FB4C7) : const Color(0xFF34495E),
      onSecondary: dark ? navy : Colors.white,
      // Usado pelo FilledButton.tonal: teal acinzentado (secundário calmo).
      secondaryContainer: dark ? const Color(0xFF183330) : const Color(0xFFDDEFEA),
      onSecondaryContainer: dark ? const Color(0xFFCDEFE6) : const Color(0xFF0B3B31),
      tertiary: dark ? const Color(0xFFF0B163) : const Color(0xFFA35F0C),
      onTertiary: navy,
      tertiaryContainer: dark ? const Color(0xFF3A2A12) : const Color(0xFFFFF1DB),
      onTertiaryContainer: dark ? const Color(0xFFFFE0B0) : const Color(0xFF5C3A0A),
      error: dark ? const Color(0xFFF07A70) : const Color(0xFFC0392B),
      onError: Colors.white,
      errorContainer: dark ? const Color(0xFF3B1715) : const Color(0xFFFDE7E4),
      onErrorContainer: dark ? const Color(0xFFFFC9C4) : const Color(0xFF5C1510),
      surface: dark ? const Color(0xFF101A26) : Colors.white,
      onSurface: dark ? const Color(0xFFE6EDF3) : const Color(0xFF0E1726),
      onSurfaceVariant: dark ? const Color(0xFFA9B7C4) : const Color(0xFF4A5A66),
      surfaceContainerLowest: dark ? const Color(0xFF0B141E) : Colors.white,
      surfaceContainerLow: dark ? const Color(0xFF0E1823) : const Color(0xFFF8FAF9),
      surfaceContainer: dark ? const Color(0xFF121D2A) : const Color(0xFFF1F5F3),
      surfaceContainerHigh: dark ? const Color(0xFF172433) : const Color(0xFFEAF0ED),
      surfaceContainerHighest: dark ? const Color(0xFF1D2B3C) : const Color(0xFFE2E9E6),
      outline: dark ? const Color(0xFF3A4C5F) : const Color(0xFFB8C5BF),
      outlineVariant: dark ? const Color(0xFF223042) : const Color(0xFFDCE4E0),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: dark ? const Color(0xFFE6EDF3) : navy,
      onInverseSurface: dark ? navy : Colors.white,
      inversePrimary: dark ? tealDeep : const Color(0xFF3DC9A8),
      surfaceTint: Colors.transparent,
    );

    final palette = dark ? AppPalette.dark : AppPalette.light;

    final display = TextStyle(
      fontFamily: AppFonts.displayFamily,
      fontFamilyFallback: AppFonts.fallback,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
      height: 1.2,
      letterSpacing: -0.3,
    );
    final body = TextStyle(
      fontFamily: AppFonts.bodyFamily,
      fontFamilyFallback: AppFonts.fallback,
      color: scheme.onSurface,
      height: 1.5,
    );
    final secondaryText = scheme.onSurface.withOpacity(0.72);

    // Anel de foco de teclado (2px) — visível em botões e controles.
    final focusRing = BorderSide(color: scheme.primary, width: 2);
    WidgetStateProperty<BorderSide?> sideWithFocus(BorderSide? normal) {
      return WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) return focusRing;
        return normal;
      });
    }

    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    );
    final buttonText = TextStyle(
      fontFamily: AppFonts.bodyFamily,
      fontFamilyFallback: AppFonts.fallback,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      height: 1.2,
    );

    return ThemeData(
      fontFamily: AppFonts.bodyFamily,
      fontFamilyFallback: AppFonts.fallback,
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [palette],
      scaffoldBackgroundColor: dark ? ink : sand,
      canvasColor: scheme.surface,
      dividerColor: scheme.outlineVariant,
      focusColor: scheme.primary.withOpacity(0.14),
      hoverColor: scheme.onSurface.withOpacity(0.05),
      highlightColor: scheme.onSurface.withOpacity(0.06),
      splashColor: scheme.primary.withOpacity(0.10),
      textTheme: TextTheme(
        // Display — Poppins: números grandes e hero.
        displayLarge: display.copyWith(fontSize: 44, fontWeight: FontWeight.w700, height: 1.1, letterSpacing: -1),
        displayMedium: display.copyWith(fontSize: 36, fontWeight: FontWeight.w700, height: 1.1, letterSpacing: -0.8),
        displaySmall: display.copyWith(fontSize: 30, fontWeight: FontWeight.w600, height: 1.15, letterSpacing: -0.6),
        // Headline — Poppins: título de página e seções grandes.
        headlineLarge: display.copyWith(fontSize: 28, fontWeight: FontWeight.w600),
        headlineMedium: display.copyWith(fontSize: 24, fontWeight: FontWeight.w600),
        headlineSmall: display.copyWith(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        // Title — Inter: títulos de cards/painéis.
        titleLarge: body.copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.35, letterSpacing: -0.2),
        titleMedium: body.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: -0.1),
        titleSmall: body.copyWith(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
        // Body — Inter: texto corrido.
        bodyLarge: body.copyWith(fontSize: 16, height: 1.6),
        bodyMedium: body.copyWith(fontSize: 14, height: 1.55, color: scheme.onSurface.withOpacity(0.9)),
        bodySmall: body.copyWith(fontSize: 12.5, height: 1.5, color: secondaryText),
        // Label — Inter: botões, chips, legendas.
        labelLarge: body.copyWith(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3, letterSpacing: 0.1),
        labelMedium: body.copyWith(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3, letterSpacing: 0.2),
        labelSmall: body.copyWith(fontSize: 11, fontWeight: FontWeight.w600, height: 1.3, letterSpacing: 0.6),
      ),
      iconTheme: IconThemeData(color: scheme.onSurface.withOpacity(0.8), size: 22),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: dark ? const Color(0xFF0D1722) : Colors.white,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        titleTextStyle: display.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: body.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        subtitleTextStyle: body.copyWith(fontSize: 12.5, color: secondaryText, height: 1.45),
      ),
      filledButtonTheme: FilledButtonThemeData(
        // Sem backgroundColor fixo: FilledButton = primary; FilledButton.tonal =
        // secondaryContainer (teal calmo). Tamanho normal — não estica sozinho.
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
          minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
          shape: const WidgetStatePropertyAll(buttonShape),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: WidgetStatePropertyAll(buttonText),
          side: sideWithFocus(null),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
          minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
          shape: const WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(buttonText),
          side: sideWithFocus(null),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) return scheme.onSurface.withOpacity(0.38);
            return scheme.onSurface;
          }),
          overlayColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.pressed)) return scheme.onSurface.withOpacity(0.10);
            if (s.contains(WidgetState.hovered)) return scheme.onSurface.withOpacity(0.05);
            if (s.contains(WidgetState.focused)) return scheme.primary.withOpacity(0.08);
            return null;
          }),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
          minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
          shape: const WidgetStatePropertyAll(buttonShape),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: WidgetStatePropertyAll(buttonText),
          side: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.focused)) return focusRing;
            if (s.contains(WidgetState.disabled)) {
              return BorderSide(color: scheme.outlineVariant);
            }
            if (s.contains(WidgetState.hovered)) return BorderSide(color: scheme.onSurface.withOpacity(0.45));
            return BorderSide(color: scheme.outline);
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) return scheme.onSurface.withOpacity(0.38);
            return scheme.primary;
          }),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
          minimumSize: const WidgetStatePropertyAll(Size(48, 40)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
          textStyle: WidgetStatePropertyAll(buttonText),
          side: sideWithFocus(null),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          side: sideWithFocus(null),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(buttonText.copyWith(fontSize: 13)),
          side: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.focused)) return focusRing;
            return BorderSide(color: scheme.outline);
          }),
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.selected)) return scheme.primaryContainer;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.selected)) return scheme.onPrimaryContainer;
            return scheme.onSurface.withOpacity(0.85);
          }),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primaryContainer,
        secondarySelectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.onPrimaryContainer,
        labelStyle: body.copyWith(fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.2),
        secondaryLabelStyle: body.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: scheme.onPrimaryContainer,
        ),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        trackOutlineColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.focused)) return scheme.primary;
          if (s.contains(WidgetState.selected)) return Colors.transparent;
          return scheme.outline;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: BorderSide(color: scheme.outline, width: 1.5),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? const Color(0xFF0D1722) : Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((s) {
          return IconThemeData(
            color: s.contains(WidgetState.selected) ? scheme.primary : scheme.onSurface.withOpacity(0.72),
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          return body.copyWith(
            fontSize: 11.5,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? scheme.primary : scheme.onSurface.withOpacity(0.78),
          );
        }),
        height: 64,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: scheme.onSurface.withOpacity(0.72)),
        selectedLabelTextStyle: body.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.primary),
        unselectedLabelTextStyle: body.copyWith(fontSize: 12, color: scheme.onSurface.withOpacity(0.78)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xFF1D2B3C) : navy,
        contentTextStyle: body.copyWith(color: Colors.white, fontSize: 14),
        actionTextColor: const Color(0xFF7FE3C8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? scheme.surfaceContainerLow : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(1), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        hintStyle: body.copyWith(fontSize: 14, color: scheme.onSurface.withOpacity(0.5)),
        labelStyle: body.copyWith(fontSize: 14, color: scheme.onSurface.withOpacity(0.72)),
        helperStyle: body.copyWith(fontSize: 12, color: secondaryText),
        floatingLabelStyle: body.copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF26364A) : navy,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: body.copyWith(fontSize: 12, color: Colors.white, height: 1.3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        waitDuration: const Duration(milliseconds: 450),
        showDuration: const Duration(milliseconds: 2000),
        preferBelow: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? scheme.surfaceContainer : scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        titleTextStyle: display.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
        contentTextStyle: body.copyWith(fontSize: 14, color: scheme.onSurface.withOpacity(0.9), height: 1.55),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: dark ? scheme.surfaceContainer : scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        constraints: const BoxConstraints(maxWidth: 760),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: dark ? scheme.surfaceContainerHigh : scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        textStyle: body.copyWith(fontSize: 14),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(dark ? scheme.surfaceContainerHigh : scheme.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(3),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant)),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(8),
        radius: const Radius.circular(8),
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.dragged)) return scheme.onSurface.withOpacity(0.45);
          if (s.contains(WidgetState.hovered)) return scheme.onSurface.withOpacity(0.32);
          return scheme.onSurface.withOpacity(0.18);
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withOpacity(0.12),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: scheme.primary,
        collapsedIconColor: scheme.onSurface.withOpacity(0.6),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.windows: _FadeThroughTransitionBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: _FadeThroughTransitionBuilder(),
          TargetPlatform.linux: _FadeThroughTransitionBuilder(),
        },
      ),
    );
  }
}

/// Transição desktop: fade curto + deslize de 8px (rotas empilhadas/dialogs de
/// página). As abas do shell usam `_fadePage` em app.dart.
class _FadeThroughTransitionBuilder extends PageTransitionsBuilder {
  const _FadeThroughTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.012, 0),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }
}

/// Cores semânticas que se adaptam ao tema claro/escuro.
/// Uso: `context.palette.success`, `context.palette.warningContainer`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.heroForeground,
    required this.heroMuted,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color infoContainer;
  final Color onInfoContainer;

  /// Texto principal sobre o hero (gradiente teal).
  final Color heroForeground;

  /// Texto secundário sobre o hero (AA sobre o gradiente).
  final Color heroMuted;

  static const dark = AppPalette(
    success: Color(0xFF4FCB8E),
    onSuccess: Color(0xFF052615),
    successContainer: Color(0xFF123526),
    onSuccessContainer: Color(0xFFBDF0D4),
    warning: Color(0xFFF0B163),
    warningContainer: Color(0xFF3A2A12),
    onWarningContainer: Color(0xFFFFE0B0),
    info: Color(0xFF7DB3FF),
    infoContainer: Color(0xFF15263F),
    onInfoContainer: Color(0xFFCFE1FF),
    heroForeground: Colors.white,
    heroMuted: Color(0xFFC9E6DE),
  );

  static const light = AppPalette(
    success: Color(0xFF1E7F52),
    onSuccess: Colors.white,
    successContainer: Color(0xFFE1F4EA),
    onSuccessContainer: Color(0xFF0B3D24),
    warning: Color(0xFFA35F0C),
    warningContainer: Color(0xFFFFF1DB),
    onWarningContainer: Color(0xFF5C3A0A),
    info: Color(0xFF2563EB),
    infoContainer: Color(0xFFE6EEFD),
    onInfoContainer: Color(0xFF0E2A5C),
    heroForeground: Colors.white,
    heroMuted: Color(0xFFD5EEE7),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      success: l(success, other.success),
      onSuccess: l(onSuccess, other.onSuccess),
      successContainer: l(successContainer, other.successContainer),
      onSuccessContainer: l(onSuccessContainer, other.onSuccessContainer),
      warning: l(warning, other.warning),
      warningContainer: l(warningContainer, other.warningContainer),
      onWarningContainer: l(onWarningContainer, other.onWarningContainer),
      info: l(info, other.info),
      infoContainer: l(infoContainer, other.infoContainer),
      onInfoContainer: l(onInfoContainer, other.onInfoContainer),
      heroForeground: l(heroForeground, other.heroForeground),
      heroMuted: l(heroMuted, other.heroMuted),
    );
  }
}

extension AppThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ??
      (isDark ? AppPalette.dark : AppPalette.light);
}

/// Cor e ícone por disciplina — para identidade visual rápida nas listas.
/// Cada disciplina tem uma cor de destaque (não interfere no tema, só no badge/ícone).
class SubjectStyle {
  final Color color;
  final IconData icon;
  const SubjectStyle(this.color, this.icon);
}

SubjectStyle subjectStyle(String? subject) {
  final s = (subject ?? '').toLowerCase();
  if (s.contains('biolog')) return const SubjectStyle(Color(0xFF4CAF50), Icons.biotech_rounded);
  if (s.contains('química') || s.contains('quimica')) return const SubjectStyle(Color(0xFFAB47BC), Icons.science_rounded);
  if (s.contains('física') || s.contains('fisica')) return const SubjectStyle(Color(0xFFEF6C00), Icons.bolt_rounded);
  if (s.contains('matem')) return const SubjectStyle(Color(0xFF42A5F5), Icons.calculate_rounded);
  if (s.contains('portugu') || s.contains('linguag')) return const SubjectStyle(Color(0xFFEC407A), Icons.menu_book_rounded);
  if (s.contains('hist')) return const SubjectStyle(Color(0xFF8D6E63), Icons.account_balance_rounded);
  if (s.contains('geog')) return const SubjectStyle(Color(0xFF66BB6A), Icons.public_rounded);
  if (s.contains('filo')) return const SubjectStyle(Color(0xFF78909C), Icons.psychology_rounded);
  if (s.contains('soc')) return const SubjectStyle(Color(0xFF5C6BC0), Icons.groups_rounded);
  return const SubjectStyle(Color(0xFF1FA887), Icons.quiz_outlined); // default = teal
}

/// Tokens de opacidade pré-computados — evita criar novo Color a cada build.
/// Uso: `cs.onSurface.f72` em vez de `cs.onSurface.withOpacity(0.72)`.
extension FadeColor on Color {
  static final _cache = <int, Color>{};
  Color _f(int alpha255) {
    final key = (value << 8) | alpha255;
    return _cache[key] ??= Color.fromARGB(alpha255, red.toInt(), green.toInt(), blue.toInt());
  }

  Color get f88 => _f(224); // 0.88
  Color get f72 => _f(184); // 0.72
  Color get f55 => _f(140); // 0.55
  Color get f45 => _f(115); // 0.45
  Color get f38 => _f(97);  // 0.38
  Color get f35 => _f(89);  // 0.35
  Color get f22 => _f(56);  // 0.22
  Color get f85 => _f(217); // 0.85
  Color get f90 => _f(230); // 0.90
  Color get f65 => _f(166); // 0.65
  Color get f60 => _f(153); // 0.60
  Color get f50 => _f(128); // 0.50
  Color get f40 => _f(102); // 0.40
  Color get f30 => _f(77);  // 0.30
  Color get f20 => _f(51);  // 0.20
  Color get f10 => _f(26);  // 0.10
  Color get f98 => _f(250); // 0.98
}
