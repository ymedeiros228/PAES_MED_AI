// Tipografia do app — Segoe UI no desktop (via app_theme.dart).
// Fontes embutidas (Inter/Poppins) ficam desativadas até QA estável no Windows.
import 'package:flutter/material.dart';

class AppFonts {
  /// Títulos — herda Segoe UI / Arial do tema.
  static TextStyle display({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double height = 1.2,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Corpo / UI — herda Segoe UI / Arial do tema.
  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double height = 1.4,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  @Deprecated('Use AppFonts.display — poppins não está embutida')
  static TextStyle poppins({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double height = 1.0,
    double letterSpacing = 0,
  }) =>
      display(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  @Deprecated('Use AppFonts.body — inter não está embutida')
  static TextStyle inter({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double height = 1.0,
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
