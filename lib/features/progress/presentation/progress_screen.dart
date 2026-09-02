import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/confetti_overlay.dart';
import '../../../core/widgets/essay_rose_chart.dart';
import '../../../core/widgets/ui_kit.dart';
import 'widgets/progress_achievements_widgets.dart';
import 'widgets/progress_charts_widgets.dart';

/// Progresso · Desempenho + Conquistas unificados (2 abas).
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? data;
  Map<String, dynamic>? _gamification;
  String? error;
  bool loading = true;
  bool _gamiLoading = true;
  int _tabIndex = 0; // 0 = Desempenho, 1 = Conquistas
  late final AnimationController _morph;
  int? _lastStreakLevel;

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
      final results = await Future.wait([
        apiClient.get('/api/progress/overview'),
        apiClient.get('/api/gamification'),
      ]);
      if (!mounted) return;
      setState(() {
        data = Map<String, dynamic>.from(results[0] as Map);
        loading = false;
        _gamification = results[1] is Map<String, dynamic>
            ? results[1] as Map<String, dynamic>
            : (results[1] is Map ? Map<String, dynamic>.from(results[1] as Map) : null);
        _gamiLoading = false;
      });
      _morph.forward(from: 0);
      _checkLevelUp();
      // Confete se tem conquistas desbloqueadas
      if (_gamification != null) {
        final unlocked = _gamification!['unlockedCount'] ?? 0;
        if (unlocked is int && unlocked > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) ConfettiOverlay.show(context);
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = humanApiError(e, fallback: 'Não deu para carregar seu desempenho.');
        loading = false;
      });
    }
  }

  /// Verifica se o streak subiu de nível desde a última carga.
  /// Se sim, mostra uma notificação gamificada de conquista.
  void _checkLevelUp() {
    final streak = (data?['streakDays'] as num?)?.toInt() ?? 0;
    final level = _streakLevel(streak);
    if (_lastStreakLevel != null && level > _lastStreakLevel!) {
      final (title, subtitle, icon, color) = _levelAchievement(level);
      AchievementToast.show(
        context,
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
      );
    }
    _lastStreakLevel = level;
  }

  /// Converte streak em nível (0-4).
  int _streakLevel(int streak) {
    if (streak >= 30) return 4;
    if (streak >= 14) return 3;
    if (streak >= 7) return 2;
    if (streak >= 3) return 1;
    return 0;
  }

  /// Retorna (título, subtítulo, ícone, cor) para o nível desbloqueado.
  (String, String, IconData, Color) _levelAchievement(int level) {
    return switch (level) {
      1 => ('Observador!', '3 dias seguidos — padrões surgindo', Icons.visibility_outlined, const Color(0xFF80CBC4)),
      2 => ('Astrônomo!', '7 dias seguidos — constelação visível', Icons.auto_awesome, const Color(0xFF4FC3F7)),
      3 => ('Cartógrafo Celeste!', '14 dias seguidos — mapeando o céu', Icons.map_outlined, const Color(0xFFB39DDB)),
      4 => ('Mestre das Estrelas!', '30 dias seguidos — domínio total', Icons.emoji_events_rounded, const Color(0xFFFFD700)),
      _ => ('Explorador!', 'Começou a jornada', Icons.explore, const Color(0xFF90A4AE)),
    };
  }

  /// Extrai a lista de dias ativos (true/false) do activity28 retornado pela API.
  List<bool> _extractActiveDays(Map<String, dynamic>? data) {
    final activity = data?['activity28'];
    if (activity is Map) {
      final items = activity['items'];
      if (items is List) {
        return items
            .whereType<Map>()
            .map((item) => item['active'] == true || item['closed'] == true)
            .toList();
      }
    }
    if (activity is List) {
      return activity
          .whereType<Map>()
          .map((item) => item['active'] == true || item['closed'] == true)
          .toList();
    }
    // Fallback: se não há dados, retorna 28 dias vazios
    return List.filled(28, false);
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
    final subjectScores = <String, double>{
      for (final p in peaks)
        (p['label']?.toString() ?? 'Eixo'):
            ((progressRelevoValue(p) / progressRelevoMax(p)) * 100).clamp(0, 100).toDouble(),
    };

    // Novos dados para graficos (Mega Plan 3)
    final evolutionCurve = (data?['evolutionCurve'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final errorTypesMap = Map<String, dynamic>.from(
      (data?['errorTypes'] as Map?) ?? {},
    );
    final errorHotTopics = (data?['errorHotTopics'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    // subjectAccuracy do backend (mais preciso que peaks)
    final subjectAccuracy = Map<String, double>.from(
      (data?['subjectAccuracy'] as Map?) ?? {},
    );
    final subjectAccScores = subjectAccuracy.isNotEmpty ? subjectAccuracy : subjectScores;

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
                  subtitle: 'Evolução, pontos fracos e medalhas — prática, não nota de corte',
                ),
                // Abas: Desempenho | Conquistas
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: ProgressTabButton(
                            label: 'Desempenho',
                            icon: Icons.trending_up_rounded,
                            selected: _tabIndex == 0,
                            onTap: () => setState(() => _tabIndex = 0),
                          ),
                        ),
                        Expanded(
                          child: ProgressTabButton(
                            label: 'Conquistas',
                            icon: Icons.emoji_events_outlined,
                            selected: _tabIndex == 1,
                            onTap: () => setState(() => _tabIndex = 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (loading) ...[
                  // Skeleton placeholders em vez de spinner
                  const SkeletonCard(lines: 2),
                  const SizedBox(height: 16),
                  const SkeletonCard(lines: 3),
                  const SizedBox(height: 16),
                  const SkeletonCard(lines: 2),
                ]
                else if (error != null)
                  QuietEmpty(
                    message: error!,
                    action: Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            _load();
                          },
                          child: const Text('Tentar'),
                        ),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            context.go('/fila');
                          },
                          child: const Text('Fila'),
                        ),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1');
                          },
                          child: const Text('Sessão'),
                        ),
                      ],
                    ),
                  )
                else if (_tabIndex == 0) ...[
                  HeroStudyStrip(
                    eyebrow: 'Seu desempenho',
                    title: 'Onde você vai bem e onde pode melhorar',
                    subtitle: data?['disclaimer']?.toString() ??
                        'Faça sessões e redações para ver onde você vai bem',
                    trailing: HonestBadge(
                      label: essay['levelLabel']?.toString() ?? 'prática',
                    ),
                  ),
                  // Heatmap de estudo + insights do coach
                  FutureBuilder(
                    future: apiClient.get('/api/coach/insights'),
                    builder: (context, snap) {
                      if (!snap.hasData || snap.data is! Map) return const SizedBox.shrink();
                      final insights = Map<String, dynamic>.from(snap.data as Map);
                      return ProgressStudyHeatmapCard(insights: insights);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (peaks.isNotEmpty && !(peaks.length == 1 && peaks.first['kind'] == 'hint'))
                    RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _morph,
                        builder: (context, _) => ProgressReadableRelief(
                          peaks: peaks,
                          progress: Curves.easeOut.transform(_morph.value),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (peaks.isEmpty || (peaks.length == 1 && peaks.first['kind'] == 'hint'))
                    QuietEmpty(
                      message:
                          'Seu desempenho ainda está plano. Faça uma sessão ou uma redação para ver pontos fortes e pontos a melhorar.',
                      action: Wrap(
                        spacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1');
                            },
                            child: const Text('Sessão'),
                          ),
                          TextButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              context.go('/redacao');
                            },
                            child: const Text('Redação'),
                          ),
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
                    const SectionLabel('Missão de redação', hint: 'prática · não banca'),
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
                  // === SECOES PRINCIPAIS (5) ===
                  StaggeredFadeIn(
                    children: [
                      // 1. Evolucao temporal
                      if (evolutionCurve.length >= 2) ...[
                        const SectionLabel('Evolução temporal', hint: 'acerto acumulado ao longo do tempo'),
                        SurfacePanel(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Curva de acerto',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 180,
                                child: ProgressEvolutionLineChart(points: evolutionCurve),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // 2. Mapa de pontos fracos
                      if (errorHotTopics.isNotEmpty) ...[
                        const SectionLabel('Mapa de pontos fracos', hint: 'tópicos com menor acerto'),
                        SurfacePanel(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ProgressWeakTopicsHeatmap(topics: errorHotTopics),
                        ),
                      ],
                    ],
                  ),
                  // === ANALISE DETALHADA (colapsada) ===
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    initiallyExpanded: false,
                    title: Text('Análise detalhada', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
                    subtitle: const Text('Redação, constelação, ritmo, áreas e tipos de erro'),
                    children: [
                      const SizedBox(height: 8),
                      if ((essay['count'] as int? ?? 0) > 0) ...[
                        SectionLabel(
                          'Quinteto da redação',
                          hint: essay['disclaimer']?.toString() ?? 'eixos 0–10',
                        ),
                        SurfacePanel(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: EssayRoseChart(
                            key: const ValueKey('progress_radar'),
                            axes: axes,
                            averages: avg,
                            labels: labels,
                          ),
                        ),
                      ],
                      // Constelação de Conhecimento
                      const SectionLabel('Sua constelação', hint: 'cada estrela = um dia de estudo'),
                      RepaintBoundary(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ConstellationMap(
                            activeDays: _extractActiveDays(data),
                            streakDays: (data?['streakDays'] as num?)?.toInt() ?? 0,
                            totalDays: 28,
                            accuracy: ((data?['accuracy'] as num?) ?? 0).toDouble(),
                          ),
                        ),
                      ),
                      // Ritmo de treino
                      SurfacePanel(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ritmo ${data?['readiness'] ?? '—'}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: () {
                                  final r = data?['readiness'];
                                  if (r is! num) return 0.0;
                                  final v = r.toDouble();
                                  return (v > 1 ? v / 100.0 : v).clamp(0.0, 1.0);
                                }()),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) => LinearProgressIndicator(
                                  value: value,
                                  minHeight: 6,
                                  backgroundColor: cs.surfaceContainerHighest,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Consistência de prática — não é % de aprovação.',
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurface.f72,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Desempenho por área
                      if (subjectAccScores.isNotEmpty)
                        SurfacePanel(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Desempenho por área',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 220,
                                child: ProgressSubjectBarChart(scores: subjectAccScores),
                              ),
                            ],
                          ),
                        ),
                      // Tipos de erro
                      if (errorTypesMap.isNotEmpty) ...[
                        const SectionLabel('Tipos de erro', hint: 'onde você mais erra'),
                        SurfacePanel(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ProgressErrorTypeDonut(errorTypes: errorTypesMap),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                  if (gaps.isNotEmpty) ...[
                    const SectionLabel('Pontos a melhorar', hint: 'próximo passo concreto'),
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
                            title: subj.isEmpty ? 'Tópico para revisar' : subj,
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
                  const SizedBox(height: 16),
                  // CTA unico — continuar estudando
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.go(
                          data?['sessionPath']?.toString() ??
                              '/sessao?examBoard=UEMA_PAES&preferNatureza=1',
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text('Continuar estudando'),
                    ),
                  ),
                ]
                else if (_tabIndex == 1) ...[
                  // ABA CONQUISTAS — unificada, sem tela separada
                  if (_gamiLoading)
                    const SkeletonCard(lines: 3)
                  else if (_gamification != null) ...[
                    ProgressLevelCard(data: _gamification!),
                    const SizedBox(height: 16),
                    // Resumo de progresso — barras visuais
                    ProgressAchievementSummary(data: _gamification!),
                    const SizedBox(height: 20),
                    // Próxima conquista destacada
                    ProgressNextAchievementPanel(gamification: _gamification!),
                    SectionLabel(
                      'Medalhas',
                      hint: '${_gamification!['unlockedCount'] ?? 0} desbloqueadas de ${_gamification!['totalAchievements'] ?? 0}',
                    ),
                    for (final a in (_gamification!['achievements'] as List? ?? []))
                      ProgressAchievementCard(
                        achievement: Map<String, dynamic>.from(a as Map),
                      ),
                    const SizedBox(height: 24),
                  ]
                  else
                    QuietEmpty(
                      message: 'Conquistas indisponíveis agora.',
                      action: TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _load();
                        },
                        child: const Text('Tentar'),
                      ),
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
