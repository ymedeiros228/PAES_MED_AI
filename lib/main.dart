import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'PAES MED AI — erro de UI',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(err, style: const TextStyle(fontSize: 12, height: 1.35)),
              const SizedBox(height: 16),
              const Text(
                'O que fazer:',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text('· Feche e reabra o atalho PAES MED AI na área de trabalho'),
              const Text('· Hoje → Continuar sessão (se havia checkpoint)'),
              const Text('· Atalhos: F foco · Ctrl+T tema'),
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
