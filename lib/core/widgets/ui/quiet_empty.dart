import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'layout_tokens.dart';
import 'surface_panel.dart';

/// Aviso discreto dentro da página (seção vazia, info, falha leve) com ação
/// opcional à direita. Estático — sem animação contínua (economiza CPU).
///
/// ```dart
/// QuietEmpty(message: 'Nenhuma revisão para hoje.', icon: Icons.check_circle_outline)
/// QuietEmpty(message: erro, action: TextButton(onPressed: _retry, child: Text('Tentar')))
/// ```
class QuietEmpty extends StatelessWidget {
  const QuietEmpty({required this.message, this.action, this.icon, super.key});
  final String message;
  final Widget? action;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: message,
      child: SurfacePanel(
        padding: const EdgeInsets.symmetric(horizontal: kGap16, vertical: kGap12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(kRadiusControl),
              ),
              child: Icon(
                icon ?? Icons.inbox_rounded,
                size: 18,
                color: cs.onSurface.f72,
              ),
            ),
            const SizedBox(width: kGap12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface.f72,
                  height: 1.5,
                ),
              ),
            ),
            if (action != null) ...[const SizedBox(width: kGap12), action!],
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
