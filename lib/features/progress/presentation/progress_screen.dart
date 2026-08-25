import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/confetti_overlay.dart';
import '../../../core/widgets/essay_rose_chart.dart';
import '../../../core/widgets/ui_kit.dart';

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
            ((_relevoValue(p) / _relevoMax(p)) * 100).clamp(0, 100).toDouble(),
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
                  subtitle: 'Desempenho e conquistas — prática, não % de aprovação',
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
                          child: _TabButton(
                            label: 'Desempenho',
                            icon: Icons.trending_up_rounded,
                            selected: _tabIndex == 0,
                            onTap: () => setState(() => _tabIndex = 0),
                          ),
                        ),
                        Expanded(
                          child: _TabButton(
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
                        'Seu progresso de estudo',
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
                      return _StudyHeatmapCard(insights: insights);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (peaks.isNotEmpty && !(peaks.length == 1 && peaks.first['kind'] == 'hint'))
                    RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _morph,
                        builder: (context, _) => _ReadableRelief(
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
                  // Constelação de Conhecimento — gamificação do progresso
                  const SectionLabel('Sua constelação', hint: 'cada estrela = um dia de estudo'),
                  // RepaintBoundary isola as animações da constelação do resto da tela
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
                  // Ritmo de treino (mantido abaixo, mais compacto)
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
                  StaggeredFadeIn(
                    children: [
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
                                child: _EvolutionLineChart(points: evolutionCurve),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                                child: _SubjectBarChart(scores: subjectAccScores),
                              ),
                            ],
                          ),
                        ),
                      if (errorHotTopics.isNotEmpty) ...[
                        const SectionLabel('Mapa de pontos fracos', hint: 'tópicos com menor acerto'),
                        SurfacePanel(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: _WeakTopicsHeatmap(topics: errorHotTopics),
                        ),
                      ],
                      if (errorTypesMap.isNotEmpty) ...[
                        const SectionLabel('Tipos de erro', hint: 'onde você mais erra'),
                        SurfacePanel(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: _ErrorTypeDonut(errorTypes: errorTypesMap),
                        ),
                      ],
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
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.go(
                            data?['sessionPath']?.toString() ??
                                '/sessao?examBoard=UEMA_PAES&preferNatureza=1',
                          );
                        },
                        child: const Text('Sessão UEMA'),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.go(data?['essayPath']?.toString() ?? '/redacao');
                        },
                        child: const Text('Redação'),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.go(data?['queuePath']?.toString() ?? '/fila');
                        },
                        child: const Text('Fila'),
                      ),
                    ],
                  ),
                ]
                else if (_tabIndex == 1) ...[
                  // ABA CONQUISTAS — unificada, sem tela separada
                  if (_gamiLoading)
                    const SkeletonCard(lines: 3)
                  else if (_gamification != null) ...[
                    _LevelCard(data: _gamification!),
                    const SizedBox(height: 16),
                    // Resumo de progresso — barras visuais
                    _AchievementSummary(data: _gamification!),
                    const SizedBox(height: 20),
                    // Próxima conquista destacada
                    ..._buildNextAchievement(_gamification!),
                    SectionLabel(
                      'Medalhas',
                      hint: '${_gamification!['unlockedCount'] ?? 0} desbloqueadas de ${_gamification!['totalAchievements'] ?? 0}',
                    ),
                    for (final a in (_gamification!['achievements'] as List? ?? []))
                      _AchievementCard(
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

  /// Destaca a próxima conquista não desbloqueada com progresso > 0.
  List<Widget> _buildNextAchievement(Map<String, dynamic> gami) {
    final achievements = (gami['achievements'] as List? ?? []);
    Map<String, dynamic>? next;
    for (final raw in achievements) {
      final a = Map<String, dynamic>.from(raw as Map);
      if (a['unlocked'] != true && (a['progress'] ?? 0.0) > 0) {
        next = a;
        break;
      }
    }
    if (next == null) return [const SizedBox.shrink()];
    final cs = Theme.of(context).colorScheme;
    final progress = (next['progress'] ?? 0.0) as double;
    final pct = (progress * 100).clamp(0, 100).round();
    return [
      SurfacePanel(
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
      ),
    ];
  }
}

/// Botão de aba interno (Desempenho / Conquistas).
class _TabButton extends StatelessWidget {
  const _TabButton({
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

/// Card de nível/XP — movido de gamification_screen.
/// Resumo visual de progresso das conquistas — 3 métricas em linha.
class _AchievementSummary extends StatelessWidget {
  const _AchievementSummary({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unlocked = data['unlockedCount'] as int? ?? 0;
    final total = data['totalAchievements'] as int? ?? 0;
    final xp = data['xp'] as int? ?? 0;
    final streak = data['streakDays'] as int? ?? 0;

    final items = [
      _SummaryItem(
        icon: Icons.emoji_events_outlined,
        value: '$unlocked/$total',
        label: 'medalhas',
        color: cs.primary,
      ),
      _SummaryItem(
        icon: Icons.bolt_rounded,
        value: '$xp',
        label: 'XP total',
        color: cs.tertiary,
      ),
      _SummaryItem(
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

  Widget _buildItem(BuildContext context, _SummaryItem item, ColorScheme cs) {
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

class _SummaryItem {
  const _SummaryItem({
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

/// Card de medalha — movido de gamification_screen.
class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});
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

const _relevoValleyThreshold = 5.5;
const _relevoRowHeight = 42.0;
const _relevoStackBreakpoint = 420.0;

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
    final panelHeight = 88 + ordered.length * _relevoRowHeight;

    return Container(
      constraints: BoxConstraints(minHeight: panelHeight),
      padding: const EdgeInsets.all(kGap16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.navy,
            Color.alphaBlend(AppTheme.teal.f45, AppTheme.navy),
          ],
        ),
        borderRadius: BorderRadius.circular(kRadiusPanel),
        border: Border.all(color: AppTheme.teal.f55),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Escala: 0–${maxScale.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: kGap8),
              Wrap(
                spacing: kGap12,
                runSpacing: kGap4,
                children: [
                  _ReliefLegend(
                    color: AppTheme.teal,
                    label: 'Ponto forte',
                  ),
                  _ReliefLegend(
                    color: AppTheme.sand,
                    label: 'Ponto a melhorar (< 5.5)',
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
              trackColor: Colors.white.withOpacity(0.20),
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
          style: TextStyle(
            fontSize: 11,
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
    required this.trackColor,
  });

  final String label;
  final double value;
  final double max;
  final double progress;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final isValley = value < _relevoValleyThreshold;
    final barColor = isValley ? AppTheme.sand : AppTheme.teal;
    final ratio = (value / max).clamp(0.0, 1.0);
    final thresholdRatio = (_relevoValleyThreshold / max).clamp(0.0, 1.0);
    final note = '${value.toStringAsFixed(1)} de ${max.toStringAsFixed(0)}';

    return Semantics(
      label: 'Eixo $label, nota $note${isValley ? ', ponto a melhorar' : ', ponto forte'}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: kGap8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < _relevoStackBreakpoint;
            final labelWidget = Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.92),
                fontWeight: FontWeight.w700,
              ),
            );
            final bar = _ReliefBar(
              ratio: ratio,
              progress: progress,
              thresholdRatio: thresholdRatio,
              barColor: barColor,
              trackColor: trackColor,
            );
            final valueWidget = SizedBox(
              width: 42,
              child: Text(
                value.toStringAsFixed(1),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.92),
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            );

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  labelWidget,
                  const SizedBox(height: kGap4),
                  Row(
                    children: [
                      Expanded(child: bar),
                      const SizedBox(width: kGap8),
                      valueWidget,
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                SizedBox(width: 108, child: labelWidget),
                const SizedBox(width: kGap8),
                Expanded(child: bar),
                const SizedBox(width: kGap8),
                valueWidget,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReliefBar extends StatelessWidget {
  const _ReliefBar({
    required this.ratio,
    required this.progress,
    required this.thresholdRatio,
    required this.barColor,
    required this.trackColor,
  });

  final double ratio;
  final double progress;
  final double thresholdRatio;
  final Color barColor;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final thresholdOffset =
              (constraints.maxWidth * thresholdRatio).clamp(0.0, constraints.maxWidth - 2).toDouble();
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
                left: thresholdOffset,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  color: Colors.white.withOpacity(0.78),
                ),
              ),
            ],
          );
        },
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

class _SubjectBarChart extends StatelessWidget {
  const _SubjectBarChart({required this.scores});

  final Map<String, double> scores;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomPaint(
      size: Size.infinite,
      painter: _BarChartPainter(scores: scores, cs: cs),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({required this.scores, required this.cs});

  final Map<String, double> scores;
  final ColorScheme cs;

  @override
  void paint(Canvas canvas, Size size) {
    final entries = scores.entries.toList();
    if (entries.isEmpty) return;

    const labelArea = 48.0;
    const valueArea = 20.0;
    final chartTop = valueArea;
    final chartBottom = size.height - labelArea;
    final chartHeight = chartBottom - chartTop;
    final chartWidth = size.width;
    final barCount = entries.length;
    final slotWidth = chartWidth / barCount;
    final barWidth = (slotWidth * 0.5).clamp(10.0, 52.0);

    // Grid horizontal tracejado
    final gridPaint = Paint()
      ..color = cs.onSurface.withOpacity(0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var p = 25; p < 100; p += 25) {
      final y = chartBottom - (p / 100) * chartHeight;
      final path = Path()
        ..moveTo(0, y)
        ..lineTo(chartWidth, y);
      canvas.drawPath(path, gridPaint);
    }

    final axisPaint = Paint()
      ..color = cs.onSurface.withOpacity(0.2)
      ..strokeWidth = 1.5;
    canvas.drawLine(
        Offset(0, chartBottom), Offset(chartWidth, chartBottom), axisPaint);

    final valueStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: cs.onSurface,
    );
    final labelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: cs.onSurface.withOpacity(0.7),
    );

    for (var i = 0; i < barCount; i++) {
      final entry = entries[i];
      final value = entry.value.clamp(0.0, 100.0);
      // Cor baseada no valor
      final baseColor = value > 70
          ? cs.primary
          : value >= 50
              ? cs.tertiary
              : cs.error;
      final barHeight = (value / 100) * chartHeight;
      final cx = slotWidth * i + slotWidth / 2;
      final left = cx - barWidth / 2;
      final top = chartBottom - barHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        const Radius.circular(8),
      );

      // Sombra suave
      final shadowPaint = Paint()
        ..color = baseColor.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left + 1, top + 2, barWidth, barHeight),
          const Radius.circular(8),
        ),
        shadowPaint,
      );

      // Barra com gradiente vertical
      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            baseColor,
            baseColor.withOpacity(0.7),
          ],
        ).createShader(Rect.fromLTWH(left, top, barWidth, barHeight));
      canvas.drawRRect(rect, gradientPaint);

      // Brilho no topo
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..style = PaintingStyle.fill;
      final highlightRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left + 2, top + 2, barWidth - 4, (barHeight * 0.3).clamp(4, 20)),
        const Radius.circular(6),
      );
      canvas.drawRRect(highlightRect, highlightPaint);

      final tpValue = TextPainter(
        text: TextSpan(text: '${value.toStringAsFixed(0)}%', style: valueStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tpValue.paint(
        canvas,
        Offset(cx - tpValue.width / 2, top - tpValue.height - 3),
      );

      canvas.save();
      canvas.translate(cx, chartBottom + 8);
      canvas.rotate(-0.785);
      final tpLabel = TextPainter(
        text: TextSpan(text: entry.key, style: labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: labelArea);
      tpLabel.paint(canvas, Offset(0, 0));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) =>
      old.scores != scores || old.cs != cs;
}

// ============================================================
// Mega Plan 3 — Graficos de Progresso com fl_chart
// ============================================================

/// Grafico de linha: evolucao do acerto acumulado ao longo do tempo.
class _EvolutionLineChart extends StatelessWidget {
  const _EvolutionLineChart({required this.points});

  final List<Map<String, dynamic>> points;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (points.length < 2) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    for (final p in points) {
      final n = (p['n'] as num?)?.toDouble() ?? 0;
      final acc = ((p['accuracy'] as num?)?.toDouble() ?? 0) * 100;
      spots.add(FlSpot(n, acc.clamp(0, 100)));
    }
    final maxX = spots.last.x;
    final lineColor = cs.primary;

    return LineChart(
      LineChartData(
        minX: 1,
        maxX: maxX,
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: cs.onSurface.withOpacity(0.08),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (maxX / 5).ceilToDouble().clamp(1, double.infinity),
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 25,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => cs.primary,
            tooltipRoundedRadius: 10,
            getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
              '${s.x.toInt()} questões\n${s.y.toStringAsFixed(1)}% acerto',
              TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            )).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: lineColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 5,
                color: lineColor,
                strokeWidth: 2.5,
                strokeColor: cs.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withOpacity(0.25),
                  lineColor.withOpacity(0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Donut chart: distribuicao dos tipos de erro.
class _ErrorTypeDonut extends StatelessWidget {
  const _ErrorTypeDonut({required this.errorTypes});

  final Map<String, dynamic> errorTypes;

  static const _labels = {
    'conceito': 'Conceito',
    'interpretacao': 'Interpretação',
    'calculo': 'Cálculo',
    'distracao': 'Distração',
    'tempo': 'Tempo',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final entries = errorTypes.entries.where((e) => (e.value as num).toInt() > 0).toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    final total = entries.fold(0, (sum, e) => sum + (e.value as num).toInt());
    final colors = <Color>[
      cs.error,
      cs.tertiary,
      cs.primary,
      cs.secondary,
      cs.outline,
    ];

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final value = (e.value as num).toDouble();
      final pct = (value / total * 100);
      final baseColor = colors[i % colors.length];
      sections.add(PieChartSectionData(
        value: value,
        color: baseColor,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            baseColor,
            baseColor.withOpacity(0.7),
          ],
        ),
        radius: 48,
        title: '${pct.toStringAsFixed(0)}%',
        titleStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          shadows: [
            Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 2),
          ],
        ),
        titlePositionPercentageOffset: 0.55,
        borderSide: BorderSide(
          color: cs.surface,
          width: 3,
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 38,
                    centerSpaceColor: cs.surface,
                    sectionsSpace: 4,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {},
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < entries.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    colors[i % colors.length],
                                    colors[i % colors.length].withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors[i % colors.length].withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _labels[entries[i].key] ?? entries[i].key,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            Text(
                              '${entries[i].value}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: colors[i % colors.length],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Total: $total erros registrados',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Mapa de calor: tópicos com menor acerto destacados por cor.
class _WeakTopicsHeatmap extends StatelessWidget {
  const _WeakTopicsHeatmap({required this.topics});

  final List<Map<String, dynamic>> topics;

  Color _colorFor(double acc, ColorScheme cs) {
    if (acc < 0.4) return cs.error.withOpacity(0.85);
    if (acc < 0.6) return cs.error.withOpacity(0.55);
    if (acc < 0.8) return cs.tertiary.withOpacity(0.65);
    return cs.primary.withOpacity(0.7);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sorted = List<Map<String, dynamic>>.from(topics)
      ..sort((a, b) {
        final aa = (a['accuracy'] as num?)?.toDouble() ?? 1.0;
        final bb = (b['accuracy'] as num?)?.toDouble() ?? 1.0;
        return aa.compareTo(bb);
      });
    final display = sorted.take(12).toList();
    if (display.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: display.map((t) {
        final key = t['key']?.toString() ?? '';
        final parts = key.split('::');
        final subj = parts.isNotEmpty ? parts[0] : (t['subject']?.toString() ?? '');
        final topic = parts.length > 1 ? parts.sublist(1).join('::') : (t['topic']?.toString() ?? '');
        final acc = (t['accuracy'] as num?)?.toDouble() ?? 0;
        final n = (t['n'] as num?)?.toInt() ?? 0;
        final color = _colorFor(acc, cs);
        final isWeak = acc < 0.5;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.75),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          constraints: const BoxConstraints(maxWidth: 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    isWeak ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      subj,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                topic,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.9),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${(acc * 100).toStringAsFixed(0)}% · $n resp.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}


class _StudyHeatmapCard extends StatelessWidget {
  const _StudyHeatmapCard({required this.insights});
  final Map<String, dynamic> insights;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final studyDays = (insights['studyDays'] as List?) ?? [];
    final trend = Map<String, dynamic>.from(insights['weeklyTrend'] as Map? ?? {});
    final streakInfo = Map<String, dynamic>.from(insights['streakInsight'] as Map? ?? {});
    final streak = streakInfo['streak'] ?? 0;

    return SurfacePanel(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: cs.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Sua semana',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                if (streak is int && streak > 0) ...[
                  Icon(Icons.local_fire_department_rounded, color: const Color(0xFFE8A04B), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$streak dias',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE8A04B),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Heatmap: 14 dias em grid
            if (studyDays.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final day in studyDays)
                    _HeatmapCell(
                      dayLabel: day['dayLabel']?.toString() ?? '',
                      studied: day['studied'] == true,
                      minutes: (day['minutes'] ?? 0) as int,
                    ),
                ],
              ),

            const SizedBox(height: 16),

            // Tendencia
            if (trend.isNotEmpty) ...[
              _ProgressTrendChip(trend: trend),
            ],
          ],
        ),
      ),
    );
  }
}


class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({required this.dayLabel, required this.studied, required this.minutes});
  final String dayLabel;
  final bool studied;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final intensity = studied ? (minutes / 30).clamp(0.3, 1.0) : 0.0;

    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            gradient: studied
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cs.primary.withOpacity(intensity),
                      cs.primary.withOpacity(intensity * 0.7),
                    ],
                  )
                : null,
            color: studied ? null : cs.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(6),
            boxShadow: studied
                ? [
                    BoxShadow(
                      color: cs.primary.withOpacity(intensity * 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dayLabel,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: studied ? cs.onSurface.withOpacity(0.7) : cs.onSurface.withOpacity(0.35),
          ),
        ),
      ],
    );
  }
}


class _ProgressTrendChip extends StatelessWidget {
  const _ProgressTrendChip({required this.trend});
  final Map<String, dynamic> trend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = trend['trend']?.toString() ?? 'sem_dados';
    final msg = trend['message']?.toString() ?? '';

    final (icon, color) = switch (t) {
      'melhorou' => (Icons.trending_up_rounded, const Color(0xFF4CAF50)),
      'piorou' => (Icons.trending_down_rounded, cs.error),
      'estavel' => (Icons.trending_flat_rounded, cs.onSurface.withOpacity(0.5)),
      'novo' => (Icons.auto_awesome_rounded, cs.primary),
      _ => (Icons.info_outline_rounded, cs.onSurface.withOpacity(0.4)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
