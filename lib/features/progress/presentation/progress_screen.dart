import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/essay_rose_chart.dart';
import '../../../core/widgets/ui_kit.dart';

/// Progresso · Relevo do aluno (mapa de forças).
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? data;
  String? error;
  bool loading = true;
  late final AnimationController _morph;

  @override
  void initState() {
    super.initState();
    _morph = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _load();
  }

  @override
  void dispose() {
    _morph.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final raw = await apiClient.get('/api/progress/overview');
      if (!mounted) return;
      setState(() {
        data = Map<String, dynamic>.from(raw as Map);
        loading = false;
      });
      _morph.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = humanApiError(e, fallback: 'Não deu para carregar o relevo.');
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(refreshTickProvider);
    final cs = Theme.of(context).colorScheme;
    final essay = Map<String, dynamic>.from(data?['essay'] as Map? ?? {});
    final peaks = (data?['peaks'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final gaps = (data?['gaps'] as List? ?? []);
    final avg = Map<String, dynamic>.from(essay['averages'] as Map? ?? {});
    final labels = Map<String, dynamic>.from(essay['labels'] as Map? ?? {});
    final axes = (essay['axes'] as List? ?? const [])
        .map((e) => e.toString())
        .toList();
    final mission = essay['nextMission'];
    final missionStatus = (mission is Map ? mission['status'] : essay['missionStatus'])
            ?.toString() ??
        'open';
    final questStatus = switch (missionStatus) {
      'cleared' => MissionQuestStatus.cleared,
      'active' => MissionQuestStatus.active,
      _ => MissionQuestStatus.open,
    };

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          PageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageHeader(
                  eyebrow: 'Analisar',
                  title: 'Progresso',
                  subtitle: 'Seu relevo: picos firmes e vales a treinar — treino local, não % de aprovação',
                ),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: SoftLoader(label: 'Carregando progresso…'),
                  )
                else if (error != null)
                  QuietEmpty(
                    message: error!,
                    action: Wrap(
                      spacing: 8,
                      children: [
                        TextButton(onPressed: _load, child: const Text('Tentar')),
                        TextButton(onPressed: () => context.go('/fila'), child: const Text('Fila')),
                        TextButton(
                          onPressed: () => context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1'),
                          child: const Text('Sessão'),
                        ),
                      ],
                    ),
                  )
                else ...[
                  HeroStudyStrip(
                    eyebrow: 'Relevo do aluno',
                    title: 'Onde você sobe e onde ainda vale treinar',
                    subtitle: data?['disclaimer']?.toString() ??
                        'Mapa local · não é banca nem garantia de aprovação',
                    trailing: HonestBadge(
                      label: essay['levelLabel']?.toString() ?? 'treino local',
                    ),
                  ),
                  if (peaks.isNotEmpty && !(peaks.length == 1 && peaks.first['kind'] == 'hint'))
                    AnimatedBuilder(
                      animation: _morph,
                      builder: (context, _) => _ReadableRelief(
                        peaks: peaks,
                        progress: Curves.easeOut.transform(_morph.value),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (peaks.isEmpty || (peaks.length == 1 && peaks.first['kind'] == 'hint'))
                    QuietEmpty(
                      message:
                          'Seu relevo ainda está plano. Faça uma sessão ou uma redação para ver picos e vales.',
                      action: Wrap(
                        spacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () => context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1'),
                            child: const Text('Sessão'),
                          ),
                          TextButton(onPressed: () => context.go('/redacao'), child: const Text('Redação')),
                        ],
                      ),
                    )
                  else const SizedBox.shrink(),
                  const SizedBox(height: 16),
                  StatsStrip(
                    items: [
                      ('${data?['streakDays'] ?? essay['streakDays'] ?? 0}', 'dias seguidos'),
                      ('${data?['studyMinutesToday'] ?? 0}', 'min hoje'),
                      (
                        '${((data?['accuracy'] as num?) != null ? ((data!['accuracy'] as num) * 100).toStringAsFixed(0) : '—')}%',
                        'acerto'
                      ),
                    ],
                  ),
                  if (mission is Map) ...[
                    const SectionLabel('Missão de redação', hint: 'treino local · não banca'),
                    MissionQuestCard(
                      title: 'Missão · ${mission['label'] ?? 'eixo'}',
                      why: mission['prompt']?.toString() ?? 'Treine o eixo mais fraco.',
                      ctaLabel: questStatus == MissionQuestStatus.cleared
                          ? 'Ver redação'
                          : 'Aceitar missão',
                      status: questStatus,
                      onCta: () => context.go('/redacao'),
                    ),
                  ],
                  if ((essay['count'] as int? ?? 0) > 0) ...[
                    SectionLabel(
                      'Quinteto da redação',
                      hint: essay['disclaimer']?.toString() ?? 'eixos 0–10',
                    ),
                    SurfacePanel(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: EssayRoseChart(
                        axes: axes,
                        averages: avg,
                        labels: labels,
                      ),
                    ),
                  ],
                  SectionLabel('Ritmo de treino', hint: 'instrumento local · não % de aprovação'),
                  SurfacePanel(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ritmo ${data?['readiness'] ?? '—'}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: () {
                              final r = data?['readiness'];
                              if (r is! num) return 0.0;
                              final v = r.toDouble();
                              return (v > 1 ? v / 100.0 : v).clamp(0.0, 1.0);
                            }(),
                            minHeight: 10,
                            backgroundColor: cs.surfaceContainerHighest,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Só mostra consistência de treino local — zero previsões de aprovação.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withOpacity(0.72),
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (gaps.isNotEmpty) ...[
                    const SectionLabel('Vales a treinar', hint: 'próximo passo concreto'),
                    for (final raw in gaps.take(3))
                      Builder(
                        builder: (_) {
                          final g = Map<String, dynamic>.from(raw as Map);
                          final key = g['key']?.toString() ?? '';
                          final parts = key.split('::');
                          final subj = parts.isNotEmpty ? parts[0] : (g['subject']?.toString() ?? '');
                          final top = parts.length > 1
                              ? parts.sublist(1).join('::')
                              : (g['topic']?.toString() ?? '');
                          return PlaylistTile(
                            title: subj.isEmpty ? 'Lacuna' : subj,
                            subtitle: top.isEmpty ? 'Abrir sessão Natureza' : top,
                            badge: 'vale',
                            leadingIcon: Icons.terrain_rounded,
                            onPlay: () {
                              if (subj.isNotEmpty) {
                                context.go(
                                  '/sessao?examBoard=UEMA_PAES&preferNatureza=1'
                                  '&subject=${Uri.encodeComponent(subj)}'
                                  '${top.isNotEmpty ? '&topic=${Uri.encodeComponent(top)}' : ''}',
                                );
                              } else {
                                context.go(
                                  data?['sessionPath']?.toString() ??
                                      '/sessao?examBoard=UEMA_PAES&preferNatureza=1',
                                );
                              }
                            },
                          );
                        },
                      ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () => context.go(
                          data?['sessionPath']?.toString() ??
                              '/sessao?examBoard=UEMA_PAES&preferNatureza=1',
                        ),
                        child: const Text('Sessão UEMA'),
                      ),
                      OutlinedButton(
                        onPressed: () => context.go(data?['essayPath']?.toString() ?? '/redacao'),
                        child: const Text('Redação'),
                      ),
                      TextButton(
                        onPressed: () => context.go(data?['queuePath']?.toString() ?? '/fila'),
                        child: const Text('Fila'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _relevoValleyThreshold = 5.5;

class _ReadableRelief extends StatelessWidget {
  const _ReadableRelief({
    required this.peaks,
    required this.progress,
  });

  final List<Map<String, dynamic>> peaks;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final ordered = [...peaks]
      ..sort(
        (a, b) => _relevoValue(b).compareTo(_relevoValue(a)),
      );
    final maxScale = ordered
        .map(_relevoMax)
        .fold<double>(0, (highest, value) => value > highest ? value : highest);
    final rowHeight = 42.0;
    final panelHeight = 88 + ordered.length * rowHeight;
    final cs = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(minHeight: panelHeight),
      padding: const EdgeInsets.all(kGap16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.navy,
            Color.alphaBlend(AppTheme.teal.withOpacity(0.45), AppTheme.navy),
          ],
        ),
        borderRadius: BorderRadius.circular(kRadiusPanel),
        border: Border.all(color: AppTheme.teal.withOpacity(0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Escala: 0–${maxScale.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withOpacity(0.92),
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: kGap8),
              Wrap(
                spacing: kGap12,
                runSpacing: kGap4,
                children: [
                  _ReliefLegend(
                    color: AppTheme.teal,
                    label: 'Pico firme',
                  ),
                  _ReliefLegend(
                    color: AppTheme.sand,
                    label: 'Vale a treinar (< 5.5)',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: kGap12),
          for (final peak in ordered)
            _ReliefRow(
              label: peak['label']?.toString() ?? 'Eixo',
              value: _relevoValue(peak),
              max: _relevoMax(peak),
              progress: progress,
              textTheme: Theme.of(context).textTheme,
              trackColor: cs.onSurface.withOpacity(0.18),
            ),
        ],
      ),
    );
  }
}

class _ReliefLegend extends StatelessWidget {
  const _ReliefLegend({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(kRadiusMicro),
          ),
        ),
        const SizedBox(width: kGap4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white.withOpacity(0.78),
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ],
    );
  }
}

class _ReliefRow extends StatelessWidget {
  const _ReliefRow({
    required this.label,
    required this.value,
    required this.max,
    required this.progress,
    required this.textTheme,
    required this.trackColor,
  });

  final String label;
  final double value;
  final double max;
  final double progress;
  final TextTheme textTheme;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final isValley = value < _relevoValleyThreshold;
    final barColor = isValley ? AppTheme.sand : AppTheme.teal;
    final ratio = (value / max).clamp(0.0, 1.0);
    final thresholdRatio = (_relevoValleyThreshold / max).clamp(0.0, 1.0);
    final note = '${value.toStringAsFixed(1)} de ${max.toStringAsFixed(0)}';

    return Semantics(
      label: 'Eixo $label, nota $note${isValley ? ', vale a treinar' : ', pico firme'}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: kGap8),
        child: Row(
          children: [
            SizedBox(
              width: 108,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: kGap8),
            Expanded(
              child: SizedBox(
                height: 18,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: trackColor,
                            borderRadius: BorderRadius.circular(kRadiusControl),
                          ),
                        ),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: ratio * progress,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(kRadiusControl),
                            ),
                          ),
                        ),
                        Positioned(
                          left: constraints.maxWidth * thresholdRatio,
                          top: 0,
                          bottom: 0,
                          child: Container(width: 2, color: AppTheme.sand.withOpacity(0.9)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: kGap8),
            SizedBox(
              width: 42,
              child: Text(
                value.toStringAsFixed(1),
                textAlign: TextAlign.right,
                style: textTheme.labelLarge?.copyWith(
                  color: Colors.white.withOpacity(0.92),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _relevoValue(Map<String, dynamic> peak) =>
    (peak['value'] as num?)?.toDouble() ?? 2.0;

double _relevoMax(Map<String, dynamic> peak) {
  final max = (peak['max'] as num?)?.toDouble();
  return max != null && max > 0 ? max : 10.0;
}
