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
                  AnimatedBuilder(
                    animation: _morph,
                    builder: (context, _) {
                      return SizedBox(
                        height: 200,
                        child: CustomPaint(
                          painter: RelevoPainter(
                            peaks: peaks,
                            t: Curves.easeOut.transform(_morph.value),
                            teal: AppTheme.teal,
                            navy: AppTheme.navy,
                            sand: AppTheme.sand,
                            isDark: Theme.of(context).brightness == Brightness.dark,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      );
                    },
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
                  else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in peaks.take(8))
                        Chip(
                          label: Text(
                            '${p['label']}: ${(p['value'] as num?)?.toStringAsFixed(1) ?? '—'}',
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
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

class RelevoPainter extends CustomPainter {
  RelevoPainter({
    required this.peaks,
    required this.t,
    required this.teal,
    required this.navy,
    required this.sand,
    required this.isDark,
  });

  final List<Map<String, dynamic>> peaks;
  final double t;
  final Color teal;
  final Color navy;
  final Color sand;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [navy.withOpacity(0.95), const Color(0xFF0E1726)]
            : [const Color(0xFF0B1F33), const Color(0xFF0F4A42)],
      ).createShader(Offset.zero & size);
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    canvas.drawRRect(rrect, bg);

    if (peaks.isEmpty) return;
    final n = peaks.length;
    final path = Path();
    final midY = size.height * 0.72;
    path.moveTo(0, size.height);
    path.lineTo(0, midY);
    for (var i = 0; i < n; i++) {
      final x = size.width * (i + 0.5) / n;
      final raw = (peaks[i]['value'] as num?)?.toDouble() ?? 2.0;
      final maxV = (peaks[i]['max'] as num?)?.toDouble() ?? 10.0;
      final h = (raw / maxV).clamp(0.08, 1.0) * size.height * 0.55 * t;
      final y = midY - h;
      final prevX = i == 0 ? 0.0 : size.width * (i - 0.5) / n;
      final cx = (prevX + x) / 2;
      if (i == 0) {
        path.lineTo(x, y);
      } else {
        path.quadraticBezierTo(cx, midY - h * 0.2, x, y);
      }
    }
    path.lineTo(size.width, midY);
    path.lineTo(size.width, size.height);
    path.close();

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          teal.withOpacity(0.75),
          teal.withOpacity(0.15),
          sand.withOpacity(0.05),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, fill);

    final stroke = Paint()
      ..color = teal.withOpacity(0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawPath(path, stroke);

    // valley soft markers
    final valleyPaint = Paint()..color = sand.withOpacity(0.35);
    for (var i = 0; i < n; i++) {
      final raw = (peaks[i]['value'] as num?)?.toDouble() ?? 2.0;
      if (raw >= 5.5) continue;
      final x = size.width * (i + 0.5) / n;
      canvas.drawCircle(Offset(x, midY + 8), 3.5, valleyPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RelevoPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.peaks != peaks;
}
