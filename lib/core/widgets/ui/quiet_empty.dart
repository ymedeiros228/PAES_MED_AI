import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'surface_panel.dart';

class QuietEmpty extends StatefulWidget {
  const QuietEmpty({required this.message, this.action, this.icon, super.key});
  final String message;
  final Widget? action;
  final IconData? icon;

  @override
  State<QuietEmpty> createState() => _QuietEmptyState();
}

class _QuietEmptyState extends State<QuietEmpty>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: widget.message,
      button: widget.action != null,
      child: SurfacePanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) => Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.surfaceContainerHigh,
                      cs.surfaceContainerHigh.withOpacity(0.6 + _ctrl.value * 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.outlineVariant.withOpacity(0.3 + _ctrl.value * 0.15),
                    width: 1,
                  ),
                ),
                child: child,
              ),
              child: Icon(
                widget.icon ?? Icons.inbox_rounded,
                size: 20,
                color: cs.onSurface.f55,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.message,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface.f72,
                  height: 1.5,
                ),
              ),
            ),
            if (widget.action != null) ...[const SizedBox(width: 10), widget.action!],
          ],
        ),
      ),
    );
  }
}

/// Estado secundário compacto para não fazer uma seção desaparecer em silêncio.
class CompactStatus extends StatelessWidget {
  const CompactStatus({
    required this.message,
    this.icon = Icons.info_outline_rounded,
    super.key,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: message,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 17, color: cs.onSurface.withOpacity(0.58)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.f72,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formata enunciado de questão em parágrafos legíveis.
/// Detecta mudanças de parágrafo (ponto final + maiúscula) e adiciona
/// espaçamento vertical entre eles — melhora muito a leitura no desktop.
/// Animação de entrada fade-in em cascata para listas de widgets.
/// Cada item aparece com um pequeno atraso, criando um efeito visual suave.

