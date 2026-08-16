import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
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
        setupError = humanApiError(e, fallback: 'Temas indisponíveis — verifique a conexão com o aplicativo.');
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
        setupError ??= humanApiError(e, fallback: 'Temas indisponíveis.');
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
    HapticFeedback.mediumImpact();
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
      // Redação corrigida: o rascunho local já cumpriu seu propósito.
      unawaited(_clearDraft());
      await _loadProgress();
      HapticFeedback.lightImpact();
    } catch (e) {
      HapticFeedback.heavyImpact();
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
        final cs = Theme.of(context).colorScheme;
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
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: cs.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nota ${item['score'] ?? '—'} · ${item['createdAt'] ?? ''} · prática de redação',
                  style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
                ),
                const SizedBox(height: 12),
                Text('Texto', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 8),
                SelectableText(
                  item['text']?.toString() ?? '(vazio)',
                  style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: cs.onSurface.withOpacity(0.85)),
                ),
                if (fbMap.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Comentários', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  const SizedBox(height: 8),
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
                        child: SelectableText(
                          '${a.$1}: ${a.$2}',
                          style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: cs.onSurface.withOpacity(0.85)),
                        ),
                      ),
                  if (fbMap['strengths'] != null)
                    SelectableText(
                      'Fortes: ${fbMap['strengths']}',
                      style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: cs.onSurface.withOpacity(0.85)),
                    ),
                  if (fbMap['improvements'] != null)
                    SelectableText(
                      'Melhorar: ${fbMap['improvements']}',
                      style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: cs.onSurface.withOpacity(0.85)),
                    ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
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
        const SnackBar(content: Text('Texto da última redação no editor · prática de redação')),
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

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(
                eyebrow: 'Conteúdo',
                title: 'Redação',
                subtitle: 'Escreva com calma, corrija por eixos e feche missões — prática de redação',
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
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          unawaited(_reloadSetup());
                        },
                        child: const Text('Tentar'),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.go('/sessao');
                        },
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
                  hint: progress!['disclaimer']?.toString() ?? 'prática de redação',
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
                        style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 12),
                      EssayRoseChart(
                        key: const ValueKey('essay_radar'),
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
                  child: SelectableText(
                    progress!['disclaimer']?.toString() ??
                        'Corrija ao menos 1 redação para ver o progresso por eixos (prática de redação).',
                    style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: cs.onSurface.withOpacity(0.85)),
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
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => personaId = null);
                      },
                    ),
                    for (final p in personas)
                      Tooltip(
                        message: p['hint']?.toString() ?? 'Mentor de redação',
                        child: FilterChip(
                          label: Text(p['label']?.toString() ?? p['id']?.toString() ?? 'tema'),
                          selected: personaId == p['id']?.toString(),
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() => personaId = p['id']?.toString());
                          },
                        ),
                      ),
                  ],
                ),
                if (personaId != null) ...[
                  const SizedBox(height: 8),
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
                        style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.f72),
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
                    HapticFeedback.selectionClick();
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
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Row(
                  children: [
                    Text(
                      '${RegExp(r"\S+").allMatches(textCtrl.text.trim()).length} palavras',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.f72),
                    ),
                    const SizedBox(width: 8),
                    // Barra de progresso visual para mínimo de caracteres
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: (textCtrl.text.trim().length / 50).clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: cs.surfaceContainerHigh,
                          color: textCtrl.text.trim().length >= 50
                              ? cs.primary
                              : cs.tertiary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      textCtrl.text.trim().length >= 50
                          ? 'pronto para corrigir'
                          : '${50 - textCtrl.text.trim().length} chars',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textCtrl.text.trim().length >= 50
                            ? cs.primary
                            : cs.onSurface.f55,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TapScale(
                child: FilledButton.icon(
                  onPressed: busy || textCtrl.text.trim().length < 50 ? null : _grade,
                  icon: busy
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary),
                        )
                      : const Icon(Icons.rate_review_outlined),
                  label: Text(busy ? 'Corrigindo…' : 'Corrigir (Ctrl+Enter)'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      _draftRestored ? Icons.history_rounded : Icons.save_outlined,
                      size: 14,
                      color: cs.onSurface.f55,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        _draftRestored
                            ? 'Rascunho restaurado · salvo automaticamente no seu PC'
                            : 'Rascunho salvo automaticamente no seu PC',
                        style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.f55),
                      ),
                    ),
                    if (textCtrl.text.trim().isNotEmpty)
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _clearDraft(clearEditor: true);
                        },
                        child: const Text('Limpar rascunho'),
                      ),
                  ],
                ),
              ),
              if (last != null) ...[
                SectionLabel('Resultado'),
                SurfacePanel(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: cs.primaryContainer.f35,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (last!['error'] != null)
                        QuietEmpty(
                          message: '${last!['error']}',
                          action: TextButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              unawaited(_grade());
                            },
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
                            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: cs.onPrimaryContainer),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const HonestBadge(),
                        if (last!['deltas'] is Map) ...[
                          const SizedBox(height: 8),
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
                        const SizedBox(height: 8),
                        Builder(
                          builder: (_) {
                            final fb = last!['feedback'];
                            if (fb is! Map) return SelectableText('$fb', style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: cs.onSurface));
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
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      'Mentor: ${fb['personaLabel'] ?? fb['persona']}'
                                      '${fb['focusAxis'] != null ? ' · eixo ${_axisPt(fb['focusAxis'].toString())}' : ''}',
                                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                                    ),
                                  ),
                                for (final a in axisRows)
                                  if (a.$3 != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: SelectableText(
                                        a.$3 is num
                                            ? '${a.$2}: ${(a.$3 as num).toStringAsFixed(1)}'
                                            : '${a.$2}: ${a.$3}',
                                        style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: cs.onSurface.withOpacity(0.85)),
                                      ),
                                    ),
                                if (fb['tips'] is Map) ...[
                                  const SizedBox(height: 8),
                                  Text('O que treinar', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
                                  for (final tip in (fb['tips'] as Map).values)
                                    SelectableText('· $tip', style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withOpacity(0.7))),
                                ],
                                if (fb['strengths'] != null) ...[
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    'Fortes: ${fb['strengths']}',
                                    style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: cs.onSurface.withOpacity(0.85)),
                                  ),
                                ],
                                if (fb['improvements'] != null)
                                  SelectableText(
                                    'Melhorar: ${fb['improvements']}',
                                    style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: cs.onSurface.withOpacity(0.85)),
                                  ),
                                if (fb['rewriteExample'] != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: cs.primaryContainer.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Exemplo de reescrita',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: cs.onPrimaryContainer.withOpacity(0.85),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        SelectableText(
                                          '${fb['rewriteExample']}',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            height: 1.5,
                                            color: cs.onPrimaryContainer,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (fb['note'] != null)
                                  SelectableText(
                                    '${fb['note']}',
                                    style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
                                  ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    FilledButton.tonal(
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        _startMissionRewrite(history);
                                      },
                                      child: const Text('Reescrever no tema'),
                                    ),
                                    OutlinedButton(
                                      onPressed: () {
                                        HapticFeedback.selectionClick();
                                        context.go('/progresso');
                                      },
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
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      ref.read(refreshTickProvider.notifier).state++;
                    },
                    child: const Text('Tentar'),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return QuietEmpty(
                      message: 'Ainda sem redações corrigidas.',
                      action: TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
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
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _openEssayDetail(Map<String, dynamic>.from(raw));
                              },
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
    );
  }
}
