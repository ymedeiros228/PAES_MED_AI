import 'dart:async';
import 'package:flutter/material.dart';

import '../data/api_client.dart';

/// Tela de inicialização que espera o backend ficar pronto.
/// Mostra um loading elegante em vez da tela vermelha de erro.
/// So mostra o app quando o backend responde /health com sucesso.
class StartupSplash extends StatefulWidget {
  const StartupSplash({super.key, required this.onReady});

  final VoidCallback onReady;

  @override
  State<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<StartupSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  int _attempts = 0;
  String _status = 'Iniciando...';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
    _waitForBackend();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _waitForBackend() async {
    const maxAttempts = 60; // ate 60 tentativas = 60 segundos
    while (_attempts < maxAttempts) {
      _attempts++;
      try {
        await apiClient.get('/health');
        if (mounted) {
          setState(() => _status = 'Pronto!');
          // Pequeno delay para o usuario ver "Pronto!"
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) widget.onReady();
        }
        return;
      } catch (_) {
        if (mounted) {
          setState(() => _status = _attempts < 5
              ? 'Iniciando backend...'
              : _attempts < 15
                  ? 'Carregando dados...'
                  : 'Quase pronto...');
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    // Se chegou aqui, o backend nao respondeu em 60s.
    // Mesmo assim, abre o app - o banner de erro vai aparecer.
    if (mounted) widget.onReady();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primaryContainer.withOpacity(0.3),
              cs.surface,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.primaryContainer],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.local_hospital_rounded,
                      size: 40,
                      color: cs.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'PAES MED AI',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _status,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: cs.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
