import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import 'ui_kit.dart';

/// Trilha gamificada (Q&A + redação) — horizontal, nodes clicáveis.
class StudyPathTrail extends StatelessWidget {
  const StudyPathTrail({
    required this.path,
    this.compact = false,
    this.showNextBar = true,
    super.key,
  });

  final Map<String, dynamic> path;
  final bool compact;
  /// Barra “próximo nó” com CTA (recomendado em listas e no Hoje).
  final bool showNextBar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nodes = (path['nodes'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (nodes.isEmpty) return const SizedBox.shrink();

    final level = path['level']?.toString() ?? '—';
    final levelLabel = path['levelLabel']?.toString() ?? 'treino';
    final xp = path['xp'];
    final done = path['doneCount'];
    final total = path['totalCount'];
    final current = path['current'] is Map
        ? Map<String, dynamic>.from(path['current'] as Map)
        : null;

    return SurfacePanel(
      margin: const EdgeInsets.only(bottom: 16),
      soft: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      cs.primary.withOpacity(0.9),
                      cs.primary.withOpacity(0.55),
                    ],
                  ),
                ),
                child: Text(
                  'Nv.$level · $levelLabel',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      xp != null
                          ? '$xp XP de treino · $done/$total nós'
                          : 'Caminho de treino · não banca',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      'Pontos locais · não é nota UEMA',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withOpacity(0.48),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (path['disclaimer'] != null) ...[
            const SizedBox(height: 6),
            Text(
              path['disclaimer']!.toString(),
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.48),
                  ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            height: compact ? 108 : 124,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: nodes.length,
              separatorBuilder: (_, __) => _Connector(),
              itemBuilder: (context, i) {
                final n = nodes[i];
                final status = n['status']?.toString() ?? 'locked';
                final canOpen = status == 'done' || status == 'active';
                return _PathNodeChip(
                  node: n,
                  onTap: !canOpen
                      ? null
                      : () {
                          final route = n['route']?.toString();
                          if (route != null && route.isNotEmpty) {
                            context.go(route);
                          }
                        },
                );
              },
            ),
          ),
          if (showNextBar && current != null) ...[
            const SizedBox(height: 12),
            _NextNodeBar(current: current),
          ],
        ],
      ),
    );
  }
}

/// Faixa compacta só com o próximo nó (útil no Hoje sem a trilha inteira).
class StudyPathNextStrip extends StatelessWidget {
  const StudyPathNextStrip({required this.path, super.key});

  final Map<String, dynamic> path;

  @override
  Widget build(BuildContext context) {
    final current = path['current'] is Map
        ? Map<String, dynamic>.from(path['current'] as Map)
        : null;
    if (current == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final level = path['level']?.toString() ?? '—';
    final xp = path['xp'];
    return SurfacePanel(
      margin: const EdgeInsets.only(bottom: 16),
      soft: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.route_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Caminho · Nv.$level${xp != null ? ' · $xp XP local' : ''}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/progresso'),
                child: const Text('Trilha'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _NextNodeBar(current: current),
        ],
      ),
    );
  }
}

class _NextNodeBar extends StatelessWidget {
  const _NextNodeBar({required this.current});

  final Map<String, dynamic> current;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final route = current['route']?.toString() ?? '/dashboard';
    final cta = current['cta']?.toString() ?? 'Seguir';
    return Material(
      color: cs.primaryContainer.withOpacity(0.55),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withOpacity(0.14),
              ),
              child: Icon(Icons.flag_rounded, size: 18, color: cs.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agora: ${current['title'] ?? '—'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if ((current['detail']?.toString() ?? '').isNotEmpty)
                    Text(
                      current['detail'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            FilledButton(
              onPressed: () => context.go(route),
              child: Text(cta),
            ),
          ],
        ),
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Container(
        width: 18,
        height: 3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: LinearGradient(
            colors: [
              cs.primary.withOpacity(0.45),
              cs.outlineVariant,
            ],
          ),
        ),
      ),
    );
  }
}

class _PathNodeChip extends StatefulWidget {
  const _PathNodeChip({required this.node, this.onTap});

  final Map<String, dynamic> node;
  final VoidCallback? onTap;

  @override
  State<_PathNodeChip> createState() => _PathNodeChipState();
}

class _PathNodeChipState extends State<_PathNodeChip> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = widget.node['status']?.toString() ?? 'locked';
    final kind = widget.node['kind']?.toString() ?? 'mix';
    final progress = (widget.node['progress'] is num)
        ? (widget.node['progress'] as num).toDouble()
        : null;

    final Color fill;
    final Color ring;
    final IconData icon;
    switch (status) {
      case 'done':
        fill = cs.primary;
        ring = cs.primary;
        icon = Icons.check_rounded;
        break;
      case 'active':
        fill = cs.primaryContainer;
        ring = cs.primary;
        icon = switch (kind) {
          'qa' => Icons.quiz_rounded,
          'essay' => Icons.edit_note_rounded,
          _ => Icons.flag_rounded,
        };
        break;
      default:
        fill = cs.surfaceContainerHighest.withOpacity(0.55);
        ring = cs.outlineVariant;
        icon = Icons.lock_outline_rounded;
    }

    final opacity = status == 'locked' ? 0.72 : 1.0;

    return Opacity(
      opacity: opacity,
      child: MouseRegion(
        onEnter: (_) => setState(() => hover = true),
        onExit: (_) => setState(() => hover = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 108,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            transform: hover && status != 'locked'
                ? (Matrix4.identity()..translate(0.0, -2.0))
                : Matrix4.identity(),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (progress != null && status == 'active')
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          strokeWidth: 3,
                          color: cs.primary,
                          backgroundColor: cs.primaryContainer.withOpacity(0.5),
                        ),
                      )
                    else
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: ring, width: 2.5),
                          color: fill.withOpacity(status == 'done' ? 1 : 0.95),
                          boxShadow: status == 'active'
                              ? [
                                  BoxShadow(
                                    color: AppTheme.teal.withOpacity(0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    if (status != 'active' || progress == null)
                      Icon(
                        icon,
                        color: status == 'done' ? cs.onPrimary : cs.onSurface.withOpacity(0.75),
                        size: 22,
                      )
                    else
                      Icon(icon, color: cs.primary, size: 22),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.node['title']?.toString() ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: status == 'active' ? FontWeight.w800 : FontWeight.w600,
                        height: 1.15,
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
