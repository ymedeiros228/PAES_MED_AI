import 'package:flutter/material.dart';

/// Layout padding padrão das telas âncora.
const kPagePadding = EdgeInsets.fromLTRB(28, 20, 28, 40);
const kPageMaxWidth = 1080.0;

/// Centraliza o conteúdo e aplica padding — ar como apps desktop modernos.
class PageBody extends StatelessWidget {
  const PageBody({
    required this.child,
    this.padding = kPagePadding,
    this.maxWidth = kPageMaxWidth,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(0.62),
                          height: 1.4,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {this.hint, super.key});
  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (hint != null)
            Text(
              hint!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.55),
                  ),
            ),
        ],
      ),
    );
  }
}

class SurfacePanel extends StatelessWidget {
  const SurfacePanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.margin = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? cs.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.85)),
      ),
      child: child,
    );
  }
}

/// Linha tipo playlist (Fila / Domínio / Plano).
class PlaylistTile extends StatefulWidget {
  const PlaylistTile({
    required this.title,
    this.subtitle,
    this.badge,
    this.leadingIcon = Icons.play_circle_outline_rounded,
    this.onPlay,
    this.secondary,
    this.active = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? badge;
  final IconData leadingIcon;
  final VoidCallback? onPlay;
  final Widget? secondary;
  final bool active;

  @override
  State<PlaylistTile> createState() => _PlaylistTileState();
}

class _PlaylistTileState extends State<PlaylistTile> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = widget.active
        ? cs.primaryContainer.withOpacity(0.55)
        : hover
            ? cs.surfaceContainerHigh.withOpacity(0.55)
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onPlay,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    widget.leadingIcon,
                    color: widget.active ? cs.primary : cs.onSurface.withOpacity(0.45),
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        if (widget.subtitle != null)
                          Text(
                            widget.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (widget.badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.badge!,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                  if (widget.secondary != null) ...[
                    const SizedBox(width: 8),
                    widget.secondary!,
                  ] else if (widget.onPlay != null) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: cs.onSurface.withOpacity(0.35)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StatsStrip extends StatelessWidget {
  const StatsStrip({required this.items, super.key});
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SurfacePanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(width: 1, height: 36, color: cs.outlineVariant),
            Expanded(
              child: Column(
                children: [
                  Text(
                    items[i].$1,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    items[i].$2,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Barra de fases da sessão (mínima, tipo player).
class PhaseProgressBar extends StatelessWidget {
  const PhaseProgressBar({
    required this.phases,
    required this.currentIndex,
    this.onSelect,
    super.key,
  });

  final List<String> phases;
  final int currentIndex;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SurfacePanel(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          for (var i = 0; i < phases.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: i <= currentIndex ? cs.primary : cs.outlineVariant,
                ),
              ),
            InkWell(
              onTap: onSelect == null ? null : () => onSelect!(i),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: i == currentIndex ? cs.primary : cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  phases[i],
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: i == currentIndex ? cs.onPrimary : cs.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class QuietEmpty extends StatelessWidget {
  const QuietEmpty({required this.message, this.action, super.key});
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SurfacePanel(
      child: Row(
        children: [
          Icon(Icons.horizontal_rule_rounded, color: cs.onSurface.withOpacity(0.3)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.6),
                  ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
