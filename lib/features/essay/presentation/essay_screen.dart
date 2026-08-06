import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/widgets/ui_kit.dart';
import '../essay_progress_view.dart';

class EssayScreen extends ConsumerStatefulWidget {
  const EssayScreen({super.key});

  @override
  ConsumerState<EssayScreen> createState() => _EssayScreenState();
}

class _EssayScreenState extends ConsumerState<EssayScreen> {
  final textCtrl = TextEditingController();
  List<String> themes = [];
  String? theme;
  Map<String, dynamic>? last;
  Map<String, dynamic>? progress;
  List<Map<String, dynamic>> personas = [];
  String? personaId;
  bool busy = false;
  String? setupError;

  Future<void> _reloadSetup() async {
    setState(() => setupError = null);
    await Future.wait([_loadThemes(), _loadProgress(), _loadPersonas()]);
  }

  @override
  void initState() {
    super.initState();
    _loadThemes();
    _loadProgress();
    _loadPersonas();
  }

  @override
  void dispose() {
    textCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadThemes() async {
    try {
      final data = await apiClient.get('/api/essay/themes');
      if (!mounted) return;
      setState(() {
        themes = (data as List).map((e) => e.toString()).toList();
        theme = themes.isNotEmpty ? themes.first : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        themes = [];
        theme = null;
        setupError = humanApiError(e, fallback: 'Temas indisponíveis — API offline?');
      });
    }
  }

  Future<void> _loadPersonas() async {
    try {
      final data = await apiClient.get('/api/essays/personas');
      final map = Map<String, dynamic>.from(data as Map);
      final items = (map['items'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (!mounted) return;
      setState(() => personas = items);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        personas = [];
        setupError ??= humanApiError(e, fallback: 'Personas indisponíveis.');
      });
    }
  }

  Future<void> _loadProgress() async {
    try {
      // Passa pelo provider central (dedupe com Hoje/Dashboard).
      final data = await ref.read(essayProgressProvider.future);
      if (!mounted) return;
      final map = Map<String, dynamic>.from(data);
      final mission = map['nextMission'];
      String? suggested;
      if (mission is Map) {
        suggested = mission['suggestedPersona']?.toString();
      }
      setState(() {
        progress = map;
        if (personaId == null && suggested != null && suggested.isNotEmpty) {
          personaId = suggested;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        progress = null;
        setupError ??= humanApiError(e, fallback: 'Progresso indisponível.');
      });
    }
  }

  Future<void> _grade() async {
    if (theme == null || textCtrl.text.trim().length < 50) return;
    setState(() => busy = true);
    try {
      final body = <String, dynamic>{
        'theme': theme,
        'text': textCtrl.text.trim(),
      };
      if (personaId != null && personaId!.isNotEmpty) {
        body['persona'] = personaId;
        Map<String, dynamic>? p;
        for (final e in personas) {
          if (e['id']?.toString() == personaId) {
            p = e;
            break;
          }
        }
        if (p != null && p['focusAxis'] != null) {
          body['focusAxis'] = p['focusAxis'];
        }
      }
      final mission = progress?['nextMission'];
      if (mission is Map && body['focusAxis'] == null) {
        body['focusAxis'] = mission['axis'];
      }
      final data = await apiClient.post('/api/essay/grade', body);
      ref.read(refreshTickProvider.notifier).state++;
      setState(() => last = Map<String, dynamic>.from(data as Map));
      await _loadProgress();
    } catch (e) {
      setState(() => last = {
            'error': humanApiError(e, fallback: 'Não deu para corrigir a redação. Tente de novo.'),
          });
    } finally {
      setState(() => busy = false);
    }
  }

  void _applyEssayToEditor(Map<String, dynamic> item) {
    final t = item['theme']?.toString();
    final text = item['text']?.toString() ?? '';
    setState(() {
      if (t != null && t.isNotEmpty) {
        if (!themes.contains(t)) themes = [...themes, t];
        theme = t;
      }
      textCtrl.text = text;
      last = {
        'score': item['score'],
        'feedback': item['feedback'],
        'theme': item['theme'],
      };
      final mission = progress?['nextMission'];
      if (mission is Map) {
        final suggested = mission['suggestedPersona']?.toString();
        if (suggested != null && suggested.isNotEmpty) {
          personaId = suggested;
        }
      }
    });
  }

  void _openEssayDetail(Map<String, dynamic> item) {
    final fb = item['feedback'];
    final fbMap = fb is Map ? Map<String, dynamic>.from(fb) : <String, dynamic>{};
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (_, scroll) {
            return ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Text(
                  item['theme']?.toString() ?? 'Redação',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nota ${item['score'] ?? '—'} · ${item['createdAt'] ?? ''} · treino local · não banca',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text('Texto', style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 6),
                SelectableText(item['text']?.toString() ?? '(vazio)'),
                if (fbMap.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Feedback', style: Theme.of(ctx).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  for (final a in [
                    ('Gramática', fbMap['grammar']),
                    ('Coesão', fbMap['cohesion']),
                    ('Coerência', fbMap['coherence']),
                    ('Argumentação', fbMap['argumentation']),
                    ('Intervenção', fbMap['intervention']),
                  ])
                    if (a.$2 != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('${a.$1}: ${a.$2}'),
                      ),
                  if (fbMap['strengths'] != null) Text('Fortes: ${fbMap['strengths']}'),
                  if (fbMap['improvements'] != null) Text('Melhorar: ${fbMap['improvements']}'),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _applyEssayToEditor(item);
                  },
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Reescrever este texto'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _startMissionRewrite(AsyncValue<List<dynamic>> history) {
    final mission = progress?['nextMission'];
    final suggested = mission is Map ? mission['suggestedPersona']?.toString() : null;
    if (suggested != null && suggested.isNotEmpty) {
      setState(() => personaId = suggested);
    }
    final items = history.asData?.value ?? const [];
    if (items.isNotEmpty) {
      final first = Map<String, dynamic>.from(items.first as Map);
      _applyEssayToEditor(first);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Texto da última redação no editor · treino local · não banca')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Corrija 1 redação antes e use a missão para reescrever.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(essaysProvider);
    final cs = Theme.of(context).colorScheme;
    final avg = Map<String, dynamic>.from(progress?['averages'] as Map? ?? {});
    final labels = Map<String, dynamic>.from(progress?['labels'] as Map? ?? {});
    final axes = (progress?['axes'] as List? ?? const [
      'grammar',
      'cohesion',
      'coherence',
      'argumentation',
      'intervention',
    ])
        .map((e) => e.toString())
        .toList();
    final count = progress?['count'] as int? ?? 0;
    final streak = progress?['streakDays'] as int? ?? 0;
    final lastScores = Map<String, dynamic>.from(progress?['lastAxisScores'] as Map? ?? {});
    final radarAvg = essayRadarValues(avg, axes);
    final radarLast = essayRadarLastValues(lastScores, axes);
    final weakKey = progress == null ? null : weakestAxisKey(progress!);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
          if (!busy && textCtrl.text.trim().length >= 50) {
            unawaited(_grade());
          }
        },
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): () {
          if (!busy && textCtrl.text.trim().length >= 50) {
            unawaited(_grade());
          }
        },
        const SingleActivator(LogicalKeyboardKey.numpadEnter, control: true): () {
          if (!busy && textCtrl.text.trim().length >= 50) {
            unawaited(_grade());
          }
        },
      },
      child: Focus(
        autofocus: false,
        child: ListView(
      children: [
        PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(
                eyebrow: 'Conteúdo',
                title: 'Redação',
                subtitle: 'Escreva e corrija com Ctrl+Enter — feedback local por eixos, rascunho offline',
              ),
              if (setupError != null) ...[
                QuietEmpty(
                  message: setupError!,
                  action: Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => unawaited(_reloadSetup()),
                        child: const Text('Tentar'),
                      ),
                      TextButton(
                        onPressed: () => context.go('/sessao'),
                        child: const Text('Sessão'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (progress != null && count > 0) ...[
                SectionLabel(
                  'Progresso local',
                  hint: progress!['disclaimer']?.toString() ?? 'treino local · não banca',
                ),
                if (progress!['nextMission'] is Map) ...[
                  SurfacePanel(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: cs.tertiaryContainer.withOpacity(0.35),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Missão · ${(progress!['nextMission'] as Map)['label'] ?? 'eixo'}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (progress!['nextMission'] as Map)['prompt']?.toString() ??
                              'Treine o eixo mais fraco.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'treino local · não banca',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.primary),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => _startMissionRewrite(history),
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: const Text('Reescrever missão'),
                        ),
                      ],
                    ),
                  ),
                ],
                SurfacePanel(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'treino local · não banca',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 10),
                      StatsStrip(
                        items: [
                          ('Redações', '$count'),
                          ('Média', '${progress!['meanScore'] ?? '—'}'),
                          ('Sequência', streak > 0 ? '$streak d' : '—'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            streak > 0 ? Icons.local_fire_department_rounded : Icons.bolt_rounded,
                            size: 16,
                            color: streak > 0 ? cs.tertiary : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              streakLabel(streak),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: streak > 0 ? FontWeight.w700 : FontWeight.w500,
                                    color: streak > 0 ? cs.tertiary : cs.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: RadarChart(
                          RadarChartData(
                            dataSets: [
                              RadarDataSet(
                                dataEntries: [
                                  for (final v in radarAvg) RadarEntry(value: v),
                                ],
                                fillColor: cs.primary.withOpacity(0.18),
                                borderColor: cs.primary,
                                entryRadius: 2.5,
                                borderWidth: 2,
                              ),
                              if (radarLast != null)
                                RadarDataSet(
                                  dataEntries: [
                                    for (final v in radarLast) RadarEntry(value: v),
                                  ],
                                  fillColor: cs.tertiary.withOpacity(0.10),
                                  borderColor: cs.tertiary,
                                  entryRadius: 2,
                                  borderWidth: 2,
                                ),
                            ],
                            radarBackgroundColor: Colors.transparent,
                            borderData: FlBorderData(show: false),
                            radarBorderData: BorderSide(color: cs.outlineVariant),
                            tickBorderData: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
                            gridBorderData: BorderSide(color: cs.outlineVariant.withOpacity(0.6)),
                            ticksTextStyle: Theme.of(context).textTheme.labelSmall,
                            tickCount: 5,
                            titleTextStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ) ??
                                const TextStyle(fontSize: 11),
                            getTitle: (index, angle) {
                              if (index < 0 || index >= axes.length) {
                                return const RadarChartTitle(text: '');
                              }
                              final key = axes[index];
                              final short = labels[key]?.toString() ?? key;
                              return RadarChartTitle(
                                text: short.length > 12 ? '${short.substring(0, 10)}…' : short,
                              );
                            },
                            titlePositionPercentageOffset: 0.18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (radarLast != null)
                        Row(
                          children: [
                            _LegendDot(color: cs.primary),
                            const SizedBox(width: 4),
                            Text('média', style: Theme.of(context).textTheme.labelSmall),
                            const SizedBox(width: 12),
                            _LegendDot(color: cs.tertiary),
                            const SizedBox(width: 4),
                            Text('última', style: Theme.of(context).textTheme.labelSmall),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '· eixos 0–10 · treino local',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Radar dos eixos (0–10) · treino local',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      const SizedBox(height: 12),
                      for (final key in axes)
                        Builder(
                          builder: (_) {
                            final raw = avg[key];
                            final value = raw is num ? raw.toDouble() : null;
                            final label = labels[key]?.toString() ?? key;
                            final t = value == null ? 0.0 : (value / 10.0).clamp(0.0, 1.0);
                            final isWeak = key == weakKey;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          label,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: isWeak ? FontWeight.w800 : FontWeight.w400,
                                              ),
                                        ),
                                      ),
                                      if (isWeak) ...[
                                        Icon(Icons.trending_up_rounded, size: 14, color: cs.tertiary),
                                        const SizedBox(width: 4),
                                        Text(
                                          'focar',
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: cs.tertiary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Text(
                                        value == null ? '—' : value.toStringAsFixed(1),
                                        style: Theme.of(context).textTheme.labelLarge,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: t,
                                      minHeight: 8,
                                      backgroundColor: cs.surfaceContainerHighest,
                                      color: isWeak ? cs.tertiary : null,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ] else if (progress != null) ...[
                SurfacePanel(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    progress!['disclaimer']?.toString() ??
                        'Corrija ao menos 1 redação para ver o progresso por eixos (treino local · não banca).',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
              if (personas.isNotEmpty) ...[
                SectionLabel('Persona de correção', hint: 'prompts locais · treino'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Geral'),
                      selected: personaId == null,
                      onSelected: (_) => setState(() => personaId = null),
                    ),
                    for (final p in personas)
                      FilterChip(
                        label: Text(p['label']?.toString() ?? p['id']?.toString() ?? 'persona'),
                        selected: personaId == p['id']?.toString(),
                        onSelected: (_) => setState(() => personaId = p['id']?.toString()),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (themes.isNotEmpty)
                DropdownMenu<String>(
                  initialSelection: theme,
                  label: const Text('Tema'),
                  width: double.infinity,
                  onSelected: (v) => setState(() => theme = v),
                  dropdownMenuEntries: [
                    for (final t in themes) DropdownMenuEntry(value: t, label: t),
                  ],
                ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                minLines: 12,
                maxLines: 20,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Sua redação',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: busy || textCtrl.text.trim().length < 50 ? null : _grade,
                icon: const Icon(Icons.rate_review_outlined),
                label: Text(busy ? 'Corrigindo…' : 'Corrigir (Ctrl+Enter)'),
              ),
              if (textCtrl.text.trim().isNotEmpty && textCtrl.text.trim().length < 50)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Escreva pelo menos ~50 caracteres para corrigir.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.55),
                        ),
                  ),
                ),
              if (last != null) ...[
                SectionLabel('Resultado'),
                SurfacePanel(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: cs.primaryContainer.withOpacity(0.35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (last!['error'] != null)
                        Text('${last!['error']}', style: TextStyle(color: cs.error))
                      else ...[
                        Text(
                          'Nota ${last!['score'] ?? '—'}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        Builder(
                          builder: (_) {
                            final fb = last!['feedback'];
                            if (fb is! Map) return Text('$fb');
                            final axisRows = [
                              ('Gramática', fb['grammar']),
                              ('Coesão', fb['cohesion']),
                              ('Coerência', fb['coherence']),
                              ('Argumentação', fb['argumentation']),
                              ('Intervenção', fb['intervention']),
                            ];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (fb['personaLabel'] != null || fb['persona'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      'Persona: ${fb['personaLabel'] ?? fb['persona']}'
                                      '${fb['focusAxis'] != null ? ' · eixo ${fb['focusAxis']}' : ''}',
                                      style: Theme.of(context).textTheme.labelLarge,
                                    ),
                                  ),
                                for (final a in axisRows)
                                  if (a.$2 != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text('${a.$1}: ${a.$2}'),
                                    ),
                                if (fb['strengths'] != null) ...[
                                  const SizedBox(height: 6),
                                  Text('Fortes: ${fb['strengths']}'),
                                ],
                                if (fb['improvements'] != null) Text('Melhorar: ${fb['improvements']}'),
                                if (fb['note'] != null)
                                  Text(
                                    '${fb['note']}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              SectionLabel('Histórico'),
              history.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => QuietEmpty(
                  message: humanApiError(e, fallback: 'Histórico indisponível.'),
                  action: TextButton(
                    onPressed: () => ref.read(refreshTickProvider.notifier).state++,
                    child: const Text('Tentar'),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return QuietEmpty(
                      message: 'Ainda sem redações corrigidas.',
                      action: TextButton(
                        onPressed: () {
                          final c = PrimaryScrollController.maybeOf(context);
                          c?.animateTo(
                            0,
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOut,
                          );
                        },
                        child: const Text('Escrever agora'),
                      ),
                    );
                  }
                  final scores = items
                      .map((raw) => ((raw as Map)['score'] as num?)?.toDouble())
                      .whereType<double>()
                      .toList()
                      .reversed
                      .toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (scores.length >= 2)
                        SurfacePanel(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            height: 120,
                            child: LineChart(
                              LineChartData(
                                titlesData: const FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                gridData: const FlGridData(show: false),
                                minY: 0,
                                maxY: 10,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: [
                                      for (var i = 0; i < scores.length; i++)
                                        FlSpot(i.toDouble(), scores[i]),
                                    ],
                                    isCurved: true,
                                    color: cs.primary,
                                    barWidth: 3,
                                    dotData: const FlDotData(show: true),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      for (final raw in items)
                        PlaylistTile(
                          title: (raw as Map)['theme']?.toString() ?? 'Tema',
                          subtitle: 'Nota ${raw['score']} · ${raw['createdAt'] ?? ''} · toque para abrir',
                          leadingIcon: Icons.edit_note_rounded,
                          onPlay: () => _openEssayDetail(Map<String, dynamic>.from(raw)),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
        ),
      ),
    );
  }
}

/// Ponto colorido de legenda para o radar (média vs última).
class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
