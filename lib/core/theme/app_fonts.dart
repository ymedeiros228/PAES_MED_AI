// app_fonts.dart - substitui GoogleFonts por fontes locais embutidas
// As fontes Poppins e Inter estao em assets/fonts/ e declaradas no pubspec.yaml
import 'package:flutter/material.dart';

class AppFonts {
  // Poppins - para titulos
  static TextStyle poppins({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double height = 1.0,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // Inter - para corpo/UI
  static TextStyle inter({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double height = 1.0,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
