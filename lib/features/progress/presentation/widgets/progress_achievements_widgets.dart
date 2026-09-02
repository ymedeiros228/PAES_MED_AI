import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/ui_kit.dart';

/// Botão de aba interno (Desempenho / Conquistas).
class ProgressTabButton extends StatelessWidget {
  const ProgressTabButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? cs.onPrimary : cs.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? cs.onPrimary : cs.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Destaca a próxima conquista não desbloqueada com progresso > 0.
class ProgressNextAchievementPanel extends StatelessWidget {
  const ProgressNextAchievementPanel({super.key, required this.gamification});

  final Map<String, dynamic> gamification;

  @override
  Widget build(BuildContext context) {
    final achievements = (gamification['achievements'] as List? ?? []);
    Map<String, dynamic>? next;
    for (final raw in achievements) {
      final a = Map<String, dynamic>.from(raw as Map);
      if (a['unlocked'] != true && (a['progress'] ?? 0.0) > 0) {
        next = a;
        break;
      }
    }
    if (next == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final progress = (next['progress'] ?? 0.0) as double;
    final pct = (progress * 100).clamp(0, 100).round();

    return SurfacePanel(
      margin: const EdgeInsets.only(bottom: 16),
      color: cs.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_rounded, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Próxima conquista',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              next['title']?.toString() ?? '',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              next['description']?.toString() ?? '',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(cs.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Resumo visual de progresso das conquistas — 3 métricas em linha.
class ProgressAchievementSummary extends StatelessWidget {
  const ProgressAchievementSummary({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unlocked = data['unlockedCount'] as int? ?? 0;
    final total = data['totalAchievements'] as int? ?? 0;
    final xp = data['xp'] as int? ?? 0;
    final streak = data['streakDays'] as int? ?? 0;

    final items = [
      _ProgressSummaryItem(
        icon: Icons.emoji_events_outlined,
        value: '$unlocked/$total',
        label: 'medalhas',
        color: cs.primary,
      ),
      _ProgressSummaryItem(
        icon: Icons.bolt_rounded,
        value: '$xp',
        label: 'XP total',
        color: cs.tertiary,
      ),
      _ProgressSummaryItem(
        icon: Icons.local_fire_department_rounded,
        value: '$streak',
        label: 'dias seguidos',
        color: cs.error,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: _buildItem(context, items[i], cs)),
        ],
      ],
    );
  }

  Widget _buildItem(BuildContext context, _ProgressSummaryItem item, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(item.icon, color: item.color, size: 22),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSummaryItem {
  const _ProgressSummaryItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
}

/// Card de nível/XP na aba Conquistas.
class ProgressLevelCard extends StatelessWidget {
  const ProgressLevelCard({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final level = data['level'] ?? 1;
    final levelTitle = data['levelTitle'] ?? 'Iniciante';
    final xp = data['xp'] ?? 0;
    final xpInLevel = data['xpInLevel'] ?? 0;
    final xpForNext = data['xpForNext'] ?? 500;
    final progress = (data['levelProgress'] ?? 0.0) as double;

    return SurfacePanel(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.primaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '$level',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nível $level · $levelTitle',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$xp XP totais',
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(cs.primary),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$xpInLevel / $xpForNext XP',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de medalha na aba Conquistas.
class ProgressAchievementCard extends StatelessWidget {
  const ProgressAchievementCard({super.key, required this.achievement});

  final Map<String, dynamic> achievement;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unlocked = achievement['unlocked'] == true;
    final progress = (achievement['progress'] ?? 0.0) as double;
    final tier = achievement['tier'] ?? 'bronze';
    final icon = _iconFor(achievement['icon'] ?? 'emoji_events');

    final tierColors = {
      'bronze': const Color(0xFFCD7F32),
      'silver': const Color(0xFFC0C0C0),
      'gold': const Color(0xFFFFD700),
    };
    final tierColor = tierColors[tier] ?? cs.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SurfacePanel(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: unlocked
                      ? tierColor.withOpacity(0.15)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: unlocked ? Border.all(color: tierColor, width: 2) : null,
                ),
                child: Icon(
                  icon,
                  color: unlocked ? tierColor : cs.onSurface.withOpacity(0.3),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            achievement['title'] ?? '',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: unlocked
                                  ? cs.onSurface
                                  : cs.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ),
                        if (unlocked)
                          Icon(Icons.check_circle, color: tierColor, size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement['description'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ),
                    if (!unlocked && progress > 0) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: cs.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(tierColor.withOpacity(0.6)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String name) {
    const map = {
      'play_circle': Icons.play_circle_outline,
      'looks_one': Icons.looks_one_outlined,
      'looks_two': Icons.looks_two_outlined,
      'looks_3': Icons.looks_3_outlined,
      'directions_run': Icons.directions_run,
      'local_fire_department': Icons.local_fire_department_outlined,
      'whatshot': Icons.whatshot,
      'shield': Icons.shield_outlined,
      'edit_note': Icons.edit_note,
      'rate_review': Icons.rate_review,
      'psychology': Icons.psychology,
      'lightbulb': Icons.lightbulb_outline,
      'gps_fixed': Icons.gps_fixed,
      'schedule': Icons.schedule,
      'hourglass_full': Icons.hourglass_full,
      'emoji_events': Icons.emoji_events_outlined,
    };
    return map[name] ?? Icons.emoji_events_outlined;
  }
}
