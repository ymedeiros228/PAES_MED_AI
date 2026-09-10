import 'dart:async';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../data/api_client.dart';

/// Tela de inicializacao que espera o backend ficar pronto.
///
/// Comportamento:
/// - Tenta /health a cada 1s, ate 30s (30 tentativas).
/// - A partir de 8s mostra um botao "Continuar mesmo assim" para o usuario
///   nao ficar preso se o backend travar/lentidao.
/// - Se esgotar as tentativas, mostra tela de erro com botoes:
///     "Tentar novamente"  -> reinicia o ciclo
///     "Abrir mesmo assim"  -> chama onReady (app abre em modo degradado)
/// - Nunca fica girando infinitamente sem saida.
class StartupSplash extends StatefulWidget {
  const StartupSplash({super.key, required this.onReady});

  final VoidCallback onReady;

  @override
  State<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<StartupSplash>
    with SingleTickerProviderStateMixin {
  static const _maxAttempts = 90; // 90s — primeira exec com banco fresh e lenta
  static const _showContinueAfter = 5; // 5s -> botao Continuar aparece

  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  int _attempts = 0;
  String _status = 'Iniciando...';
  String _substatus = '';
  bool _failed = false;
  Timer? _timer;
  bool _continueVisible = false;

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
    _startWaiting();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _startWaiting() {
    if (!mounted) return;
    setState(() {
      _failed = false;
      _continueVisible = false;
      _status = 'Iniciando backend...';
      _substatus = '';
    });
    _attempts = 0;
    _tick();
  }

  Future<void> _tick() async {
    while (mounted && _attempts < _maxAttempts && !_failed) {
      _attempts++;
      try {
        await apiClient.get('/health');
        if (!mounted) return;
        setState(() {
          _status = 'Pronto!';
          _substatus = '';
        });
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        widget.onReady();
        return;
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _status = _attempts < 5
              ? 'Iniciando backend...'
              : _attempts < 15
                  ? 'Carregando dados...'
                  : _attempts < 30
                      ? 'Preparando acervo...'
                      : 'Quase pronto...';
          _substatus = 'Tentativa $_attempts de $_maxAttempts';
          if (_attempts >= _showContinueAfter) {
            _continueVisible = true;
          }
        });
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    // Esgotou as tentativas sem sucesso.
    if (mounted && !_failed) {
      setState(() {
        _failed = true;
        _status = 'Não foi possível iniciar o backend.';
        _substatus = 'O app pode abrir, mas alguns recursos podem não funcionar.';
      });
    }
  }

  void _retry() {
    _timer?.cancel();
    _startWaiting();
  }

  void _forceOpen() {
    if (!mounted) return;
    widget.onReady();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bright = Theme.of(context).brightness;
    return Material(
      color: bright == Brightness.dark ? AppTheme.ink : AppTheme.sand,
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
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
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withOpacity(0.8),
                    ),
                  ),
                  if (_substatus.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _substatus,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.45),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (!_failed) ...[
                    // Barra de progresso mostra tentativas visualmente
                    FractionallySizedBox(
                      widthFactor: 0.6,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_attempts / _maxAttempts).clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: cs.surfaceContainerHighest,
                          color: cs.primary.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: cs.primary.withOpacity(0.5),
                      ),
                    ),
                  ],
                  if (_continueVisible && !_failed) ...[
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _forceOpen,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Continuar mesmo assim'),
                    ),
                  ],
                  if (_failed) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: cs.errorContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.error.withOpacity(0.2)),
                      ),
                      child: Text(
                        'O app pode abrir, mas alguns recursos (questões, '
                        'redação, IA) podem não funcionar até o backend '
                        'estar disponível.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onErrorContainer,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: _retry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Tentar novamente'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _forceOpen,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Abrir mesmo assim'),
                        ),
                      ],
                    ),
                  ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
