import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/widgets/confetti_overlay.dart';
import '../../../core/widgets/ui_kit.dart';

class GamificationScreen extends ConsumerStatefulWidget {
  const GamificationScreen({super.key});

  @override
  ConsumerState<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends ConsumerState<GamificationScreen> {
  Map<String, dynamic>? data;
  String? error;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final raw = await apiClient.get('/api/gamification');
      if (!mounted) return;
      setState(() {
        data = raw is Map<String, dynamic> ? raw : null;
        loading = false;
      });
      // Confete se tem conquistas desbloqueadas
      if (mounted && data != null) {
        final unlocked = data!['unlockedCount'] ?? 0;
        if (unlocked is int && unlocked > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) ConfettiOverlay.show(context);
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = humanApiError(e, fallback: 'Nao foi possivel carregar conquistas.');
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      child: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(
              child: PageHeader(
                eyebrow: 'Seu progresso',
                title: 'Conquistas',
                subtitle: loading
                    ? 'Carregando...'
                    : '${data?['unlockedCount'] ?? 0} de ${data?['totalAchievements'] ?? 0} medalhas desbloqueadas',
              ),
            ),
            if (loading) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: SkeletonList(count: 4, lines: 2)),
              ),
            ] else if (error != null) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: QuietEmpty(message: error!),
                ),
              ),
            ] else if (data != null) ...[
              SliverToBoxAdapter(
                child: _LevelCard(data: data!),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: SectionLabel(
                  'Medalhas',
                  hint: '${data!['unlockedCount']} desbloqueadas de ${data!['totalAchievements']}',
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final achievements =
                        (data!['achievements'] as List?) ?? [];
                    if (index >= achievements.length) return null;
                    final a = achievements[index] as Map<String, dynamic>;
                    return _AchievementCard(
                      achievement: a,
                      index: index,
                    );
                  },
                  childCount: ((data!['achievements'] as List?) ?? []).length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.data});
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
                      style: GoogleFonts.poppins(
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
                        'Nivel $level - $levelTitle',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$xp XP totais',
                        style: GoogleFonts.inter(
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
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: GoogleFonts.inter(
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

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement, required this.index});
  final Map<String, dynamic> achievement;
  final int index;

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
      child: StaggeredFadeIn(
        itemDelay: const Duration(milliseconds: 50),
        children: [
          SurfacePanel(
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
                      border: unlocked
                          ? Border.all(color: tierColor, width: 2)
                          : null,
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
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: unlocked
                                      ? cs.onSurface
                                      : cs.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ),
                            if (unlocked)
                              Icon(
                                Icons.check_circle,
                                color: tierColor,
                                size: 18,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          achievement['description'] ?? '',
                          style: GoogleFonts.inter(
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
                              valueColor:
                                  AlwaysStoppedAnimation(tierColor.withOpacity(0.6)),
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
        ],
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
