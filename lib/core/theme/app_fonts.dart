// Tipografia do app — Inter (corpo/UI) + Poppins (títulos), embutidas em
// assets/fonts e declaradas no pubspec.yaml. Fallback: Segoe UI → Arial.
//
// Histórico: em ago/2026 as fontes foram removidas porque o pacote
// google_fonts tentava baixá-las da internet e o fallback quebrava o texto.
// Agora não há google_fonts: os TTF são locais e empacotados no build.
import 'package:flutter/material.dart';

class AppFonts {
  AppFonts._();

  /// Família do corpo/UI.
  static const bodyFamily = 'Inter';

  /// Família de títulos/display.
  static const displayFamily = 'Poppins';

  /// Fallback do sistema (Windows) caso algum glifo falte.
  static const fallback = <String>['Segoe UI', 'Arial', 'sans-serif'];

  /// Títulos (Poppins).
  static TextStyle display({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double height = 1.2,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: displayFamily,
      fontFamilyFallback: fallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Corpo / UI (Inter).
  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double height = 1.5,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: bodyFamily,
      fontFamilyFallback: fallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Números tabulares (cronômetro, placares, estatísticas).
  static const tabular = [FontFeature.tabularFigures()];

  /// Alias de [display] (compat).
  static TextStyle poppins({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double height = 1.2,
    double letterSpacing = 0,
  }) =>
      display(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// Alias de [body] (compat).
  static TextStyle inter({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double height = 1.5,
    double letterSpacing = 0,
  }) =>
      body(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
}
