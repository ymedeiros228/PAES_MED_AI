import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/widgets/essay_rose_chart.dart';
import '../../../core/widgets/ui_kit.dart';
import '../essay_draft.dart';

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
  Timer? _draftDebounce;
  bool _draftRestored = false;
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
    _restoreDraft();
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    textCtrl.dispose();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    final draft = await loadEssayDraft();
    if (!mounted || draft == null) return;
    // Não sobrescreve texto já digitado ou vindo de "Reescrever".
    if (textCtrl.text.trim().isNotEmpty) return;
    setState(() {
      textCtrl.text = draft.text;
      if (draft.theme.isNotEmpty) {
        if (!themes.contains(draft.theme)) themes = [...themes, draft.theme];
        theme = draft.theme;
      }
      _draftRestored = true;
    });
  }

  void _scheduleDraftSave() {
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 600), () {
      unawaited(saveEssayDraft(EssayDraft(theme: theme ?? '', text: textCtrl.text)));
    });
  }

  Future<void> _clearDraft({bool clearEditor = false}) async {
    _draftDebounce?.cancel();
    await clearEssayDraft();
    if (!mounted) return;
    setState(() {
      _draftRestored = false;
      if (clearEditor) textCtrl.clear();
    });
  }

  Future<void> _loadThemes() async {
    try {
      final data = await apiClient.get('/api/essay/themes');
      if (!mounted) return;
      setState(() {
        themes = (data as List).map((e) => e.toString()).toList();
        // Preserva tema do rascunho/seleção se ainda existir na lista.
        if (theme != null && themes.contains(theme)) {
          // keep
        } else if (theme != null && theme!.isNotEmpty && _draftRestored) {
          if (!themes.contains(theme)) themes = [...themes, theme!];
        } else {
          theme = themes.isNotEmpty ? themes.first : null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        themes = [];
        if (!_draftRestored) theme = null;
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
      final data = await apiClient.get('/api/essays/progress');
      if (!mounted) return;
      final map = Map<String, dynamic>.from(data as Map);
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
      // Redação corrigida: o rascunho local já cumpriu seu papel.
      unawaited(_clearDraft());
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

  String _axisPt(String key) {
    return switch (key) {
      'grammar' => 'gramática',
      'cohesion' => 'coesão',
      'coherence' => 'coerência',
      'argumentation' => 'argumentação',
      'intervention' => 'intervenção',
      _ => key,
    };
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
        const SnackBar(content: Text('Texto da última redação no editor · treino local')),
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
                subtitle: 'Escreva com calma, corrija por eixos e feche missões — treino local, não banca',
              ),
              HeroStudyStrip(
                eyebrow: 'Loop de treino',
                title: count > 0
                    ? 'Nível ${progress?['levelLabel'] ?? 'treino'} · média ${progress?['meanScore'] ?? '—'}'
                    : 'Primeira correção desbloqueia o relevo',
                subtitle: 'Ctrl+Enter corrige · missões sobem o eixo mais fraco',
                trailing: const HonestBadge(),
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
                  MissionQuestCard(
                    title: 'Missão · ${(progress!['nextMission'] as Map)['label'] ?? 'eixo'}',
                    why: (progress!['nextMission'] as Map)['prompt']?.toString() ??
                        'Treine o eixo mais fraco.',
                    ctaLabel:
                        (progress!['nextMission'] as Map)['status']?.toString() == 'cleared'
                            ? 'Nova redação'
                            : 'Aceitar missão',
                    status: switch ((progress!['nextMission'] as Map)['status']?.toString()) {
                      'cleared' => MissionQuestStatus.cleared,
                      'active' => MissionQuestStatus.active,
                      _ => MissionQuestStatus.open,
                    },
                    onCta: () => _startMissionRewrite(history),
                  ),
                ],
                SurfacePanel(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HonestBadge(),
                      const SizedBox(height: 4),
                      Text(
                        '${progress!['count']} redação(ões) · média ${progress!['meanScore'] ?? '—'}'
                        '${streak > 0 ? ' · sequência $streak dia(s)' : ''}'
                        '${progress!['levelLabel'] != null ? ' · ${progress!['levelLabel']}' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      EssayRoseChart(
                        axes: axes,
                        averages: avg,
                        labels: labels,
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
                SectionLabel('Mentores por eixo', hint: '5 eixos · o que cada um olha'),
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
                      Tooltip(
                        message: p['hint']?.toString() ?? 'Mentor de treino local',
                        child: FilterChip(
                          label: Text(p['label']?.toString() ?? p['id']?.toString() ?? 'persona'),
                          selected: personaId == p['id']?.toString(),
                          onSelected: (_) => setState(() => personaId = p['id']?.toString()),
                        ),
                      ),
                  ],
                ),
                if (personaId != null) ...[
                  const SizedBox(height: 6),
                  Builder(
                    builder: (_) {
                      final p = personas.cast<Map?>().firstWhere(
                            (e) => e?['id']?.toString() == personaId,
                            orElse: () => null,
                          );
                      final hint = p?['hint']?.toString();
                      if (hint == null || hint.isEmpty) return const SizedBox.shrink();
                      return Text(
                        'O que olho: $hint',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.72),
                            ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 12),
              ],
              if (themes.isNotEmpty)
                DropdownMenu<String>(
                  initialSelection: theme,
                  label: const Text('Tema'),
                  width: double.infinity,
                  onSelected: (v) {
                    setState(() => theme = v);
                    _scheduleDraftSave();
                  },
                  dropdownMenuEntries: [
                    for (final t in themes) DropdownMenuEntry(value: t, label: t),
                  ],
                ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                minLines: 12,
                maxLines: 20,
                onChanged: (_) {
                  setState(() {});
                  _scheduleDraftSave();
                },
                decoration: const InputDecoration(
                  labelText: 'Sua redação',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: Text(
                  '${RegExp(r"\S+").allMatches(textCtrl.text.trim()).length} palavras · treino local',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.72),
                      ),
                ),
              ),
              const SizedBox(height: 8),
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
                          color: cs.onSurface.withOpacity(0.72),
                        ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(
                      _draftRestored ? Icons.history_rounded : Icons.save_outlined,
                      size: 14,
                      color: cs.onSurface.withOpacity(0.55),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _draftRestored
                            ? 'Rascunho restaurado · salvo automaticamente no seu PC'
                            : 'Rascunho salvo automaticamente no seu PC',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.55),
                            ),
                      ),
                    ),
                    if (textCtrl.text.trim().isNotEmpty)
                      TextButton(
                        onPressed: () => _clearDraft(clearEditor: true),
                        child: const Text('Limpar rascunho'),
                      ),
                  ],
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
                        QuietEmpty(
                          message: '${last!['error']}',
                          action: TextButton(
                            onPressed: () => unawaited(_grade()),
                            child: const Text('Tentar de novo'),
                          ),
                        )
                      else ...[
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: (last!['score'] as num?)?.toDouble() ?? 0),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          builder: (context, v, _) => Text(
                            'Nota ${v.toStringAsFixed(1)}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const HonestBadge(),
                        if (last!['deltas'] is Map) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final e in (last!['deltas'] as Map).entries)
                                if (e.value is num)
                                  DeltaChip(
                                    label: {
                                          'grammar': 'Gramática',
                                          'cohesion': 'Coesão',
                                          'coherence': 'Coerência',
                                          'argumentation': 'Argumentação',
                                          'intervention': 'Intervenção',
                                        }[e.key.toString()] ??
                                        e.key.toString(),
                                    delta: (e.value as num).toDouble(),
                                  ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        Builder(
                          builder: (_) {
                            final fb = last!['feedback'];
                            if (fb is! Map) return Text('$fb');
                            final axisRows = [
                              ('grammar', 'Gramática', fb['grammar']),
                              ('cohesion', 'Coesão', fb['cohesion']),
                              ('coherence', 'Coerência', fb['coherence']),
                              ('argumentation', 'Argumentação', fb['argumentation']),
                              ('intervention', 'Intervenção', fb['intervention']),
                            ];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (fb['personaLabel'] != null || fb['persona'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      'Mentor: ${fb['personaLabel'] ?? fb['persona']}'
                                      '${fb['focusAxis'] != null ? ' · eixo ${_axisPt(fb['focusAxis'].toString())}' : ''}',
                                      style: Theme.of(context).textTheme.labelLarge,
                                    ),
                                  ),
                                for (final a in axisRows)
                                  if (a.$3 != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        a.$3 is num
                                            ? '${a.$2}: ${(a.$3 as num).toStringAsFixed(1)}'
                                            : '${a.$2}: ${a.$3}',
                                      ),
                                    ),
                                if (fb['tips'] is Map) ...[
                                  const SizedBox(height: 8),
                                  Text('O que treinar', style: Theme.of(context).textTheme.titleSmall),
                                  for (final tip in (fb['tips'] as Map).values)
                                    Text('· $tip', style: Theme.of(context).textTheme.bodySmall),
                                ],
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
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    FilledButton.tonal(
                                      onPressed: () => _startMissionRewrite(history),
                                      child: const Text('Reescrever no tema'),
                                    ),
                                    OutlinedButton(
                                      onPressed: () => context.go('/progresso'),
                                      child: const Text('Ver relevo'),
                                    ),
                                  ],
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
                      SoftTimeline(
                        items: [
                          for (final raw in items)
                            SoftTimelineItem(
                              title: (raw as Map)['theme']?.toString() ?? 'Tema',
                              subtitle: 'Nota ${raw['score']} · ${raw['createdAt'] ?? ''}',
                              onTap: () => _openEssayDetail(Map<String, dynamic>.from(raw)),
                            ),
                        ],
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
