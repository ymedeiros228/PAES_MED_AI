import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/data/auth.dart';
import 'core/data/backend_launcher.dart';

String _shortUiError(String raw) {
  final s = raw.trim();
  if (s.length <= 320) return s;
  return '${s.substring(0, 320)}…';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lê a flag de onboarding uma vez (o redirect do router usa o cache).
  try {
    await preloadOnboardingFlag();
  } catch (_) {
    // Sem prefs: o redirect lê na 1ª navegação.
  }
  // Versão web: confere o login antes de abrir (sem piscar a tela de entrada).
  // No desktop o backend local não exige login.
  if (kIsWeb) await auth.verificar();
  // App de PC: inicia o backend Python local (até 3 tentativas, 2 s entre elas —
  // ex.: porta ocupada). Na web o backend é o do servidor.
  if (!kIsWeb) {
    () async {
      for (int i = 0; i < 3; i++) {
        final ok = await launchLocalBackend();
        if (ok) break;
        await Future.delayed(const Duration(seconds: 2));
      }
    }();
  }
  ErrorWidget.builder = (details) {
    final err = _shortUiError(details.exceptionAsString());
    const fundo = Color(0xFF0B141E);
    const texto = Color(0xFFE6EDF3);
    const textoSuave = Color(0xFFA9B7C4);
    return Material(
      color: fundo,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 28, color: Color(0xFFF0B163)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Esta parte da tela não abriu',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: texto),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                kIsWeb
                    ? 'Recarregue a página (F5). Seu progresso fica salvo no servidor.'
                    : 'Feche e abra de novo o PAES MED AI. Seu progresso fica salvo.',
                style: TextStyle(fontSize: 14, height: 1.5, color: texto),
              ),
              const SizedBox(height: 16),
              Text(
                'Detalhe técnico: $err',
                style: const TextStyle(fontSize: 12, height: 1.4, color: textoSuave),
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
