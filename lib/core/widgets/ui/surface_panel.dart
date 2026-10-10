import 'package:flutter/material.dart';

import 'layout_tokens.dart';

/// Painel base (superfície com borda sutil). Não é clicável — para cards
/// clicáveis com hover/foco use `AppCard(onTap: ...)`.
///
/// ```dart
/// SurfacePanel(child: Text('Conteúdo'))
/// SurfacePanel(color: cs.primaryContainer.f45, margin: EdgeInsets.only(bottom: 16), child: ...)
/// ```
class SurfacePanel extends StatelessWidget {
  const SurfacePanel({
    required this.child,
    this.padding = const EdgeInsets.all(kGap16),
    this.color,
    this.margin = EdgeInsets.zero,
    this.soft = true,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;

  /// Cor de fundo. Padrão: `surface` (um degrau acima do fundo da tela).
  final Color? color;
  final EdgeInsets margin;

  /// `true` = borda leve + sombra difusa no claro; `false` = borda mais marcada, sem sombra.
  final bool soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: panelDecoration(context, color: color, soft: soft),
      child: child,
    );
  }

  /// Decoração padrão de painel — reutilizável em Containers/AnimatedContainers.
  static BoxDecoration panelDecoration(
    BuildContext context, {
    Color? color,
    bool soft = true,
    double radius = kRadiusPanel,
    Color? borderColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: color ?? cs.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ??
            (soft ? cs.outlineVariant : cs.outline.withOpacity(isDark ? 0.7 : 0.6)),
      ),
      boxShadow: soft && !isDark
          ? const [
              BoxShadow(
                color: Color(0x0D0A1628),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ]
          : null,
    );
  }
}
