import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (details) {
    return Material(
      color: AppTheme.sand,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PAES MED AI — erro de UI', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 8),
              Text(details.exceptionAsString(), style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
              const Text('Feche e reabra o atalho Desktop, ou continue a sessão salva no Hoje.'),
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
