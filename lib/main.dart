import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';

String _shortUiError(String raw) {
  final s = raw.trim();
  if (s.length <= 320) return s;
  return '${s.substring(0, 320)}…';
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (details) {
    final err = _shortUiError(details.exceptionAsString());
    return Material(
      color: AppTheme.sand,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'PAES MED AI — erro de UI',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                err,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 1.35,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'O que fazer:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '· Feche e reabra o atalho PAES MED AI na área de trabalho',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
              ),
              Text(
                '· Hoje → Continuar sessão (se havia checkpoint)',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
              ),
              Text(
                '· Atalhos: F foco · Ctrl+T tema',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  };
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  runApp(const ProviderScope(child: PaesMedAiApp()));
}
