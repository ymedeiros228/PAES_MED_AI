import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'layout_tokens.dart';

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
  final Color? color;
  final EdgeInsets margin;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? (isDark ? cs.surface.f90 : cs.surface.withOpacity(0.98)),
        borderRadius: BorderRadius.circular(soft ? kRadiusPanelSoft : kRadiusPanel),
        border: Border.all(color: soft ? cs.outlineVariant.f50 : cs.outlineVariant.f85),
        boxShadow: soft && !isDark
            ? [
                BoxShadow(
                  color: const Color(0xFF0A1628).f10,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
