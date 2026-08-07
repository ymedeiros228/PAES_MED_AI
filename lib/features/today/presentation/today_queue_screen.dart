import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/study_prefs_providers.dart';
import '../../../core/widgets/media_reinforcement.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/theory_read_sheet.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../core/widgets/week_close_panel.dart';

/// Fila: só o que estudar a seguir — sem jargão de pipeline.
class TodayQueueScreen extends ConsumerStatefulWidget {
  const TodayQueueScreen({super.key});

  @override
  ConsumerState<TodayQueueScreen> createState() => _TodayQueueScreenState();
}

class _TodayQueueScreenState extends ConsumerState<TodayQueueScreen> {
  Map<String, dynamic>? queue;
  String? error;
  int selected = 0;
  int _readRefreshTick = 0;
  final _focusNode = FocusNode();
  List<String> _navPaths = const [];
  String _sessionPath = '/sessao?examBoard=UEMA_PAES&preferNatureza=1';
  bool gapsOnlyNoMaterial = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
    _load();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _syncNavPaths(Map<String, dynamic> q, String sessionPath) {
    _sessionPath = sessionPath;
    final paths = <String>[sessionPath];
    final openGaps = q['openGaps'] is Map ? q['openGaps'] as Map : null;
    for (final raw in (openGaps?['items'] as List? ?? const []).take(6)) {
      if (raw is! Map) continue;
      final s = raw['subject']?.toString() ?? '';
      final t = raw['topic']?.toString() ?? '';
      if (s.isNotEmpty || t.isNotEmpty) {
        paths.add(
          '/adaptativo?subject=${Uri.encodeComponent(s)}&topic=${Uri.encodeComponent(t)}',
        );
      }
    }
    if (((q['axisCardsDue'] as int?) ?? 0) > 0 ||
        ((q['axisCardsCreatedToday'] as int?) ?? 0) > 0) {
      paths.add('/flashcards?due=1');
    }
    for (final r in (q['revisions'] as List? ?? const []).take(8)) {
      if (r is! Map) continue;
      paths.add(
        '/adaptativo?subject=${Uri.encodeComponent(r['subject']?.toString() ?? '')}'
        '&topic=${Uri.encodeComponent(r['topic']?.toString() ?? '')}',
      );
    }
    if ((q['flashcards'] as List? ?? const []).isNotEmpty) {
      paths.add('/flashcards?due=1');
    }
    final study = q['studyToday'] as Map<String, dynamic>?;
    if (study != null) {
      final s = study['subject']?.toString() ?? '';
      final t = study['topic']?.toString() ?? '';
      if (s.isNotEmpty || t.isNotEmpty) paths.add(_sessionFor(s, t));
    }
    for (final raw in (q['medicineTop'] as List? ?? const []).take(5)) {
      if (raw is! Map) continue;
      final key = raw['key']?.toString() ?? '';
      final parts = key.split('::');
      final s = parts.isNotEmpty ? parts[0] : '';
      final t = parts.length > 1 ? parts[1] : '';
      if (s.isNotEmpty || t.isNotEmpty) paths.add(_sessionFor(s, t));
    }
    _navPaths = paths;
    if (selected >= _navPaths.length && _navPaths.isNotEmpty) {
      selected = _navPaths.length - 1;
    }
  }

  void _openSelected() {
    if (_navPaths.isEmpty) return;
    context.go(_navPaths[selected.clamp(0, _navPaths.length - 1)]);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyS) {
      context.go(_sessionPath);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyR || key == LogicalKeyboardKey.f5) {
      unawaited(_load());
      return KeyEventResult.handled;
    }
    if (_navPaths.isEmpty) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyJ) {
      setState(() => selected = (selected + 1).clamp(0, _navPaths.length - 1));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyK) {
      setState(() => selected = (selected - 1).clamp(0, _navPaths.length - 1));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      _openSelected();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _load() async {
    try {
      final data = await apiClient.get('/api/today');
      setState(() {
        queue = Map<String, dynamic>.from(data as Map);
        error = null;
      });
    } catch (e) {
      setState(() => error = humanApiError(e, fallback: 'Não deu para carregar a fila. Tente de novo.'));
    }
  }

  Future<void> _recoverGap(String subject, String topic) async {
    try {
      await apiClient.post('/api/gaps/recover', {
        'subject': subject,
        'topic': topic,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lacuna marcada como recuperada (treino local).')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para marcar a lacuna.'))),
      );
    }
  }

  Future<void> _closeWeek() async {
    try {
      final data = await apiClient.post('/api/study/week-close', {});
      final map = Map<String, dynamic>.from(data as Map);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(map['message']?.toString() ?? 'Semana encerrada.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanApiError(e, fallback: 'Não foi possível fechar a semana.'))),
      );
    }
  }

  Future<void> _openTheory(String subject, String topic) async {
    await openTheoryReadSheet(
      context,
      subject: subject,
      topic: topic,
      trainPath: '/adaptativo?subject=${Uri.encodeComponent(subject)}'
          '&topic=${Uri.encodeComponent(topic)}',
    );
    if (mounted) setState(() => _readRefreshTick++);
  }

  String _sessionFor(String s, String t) {
    final nat = const {'Biologia', 'Química', 'Física'}.contains(s);
    return '/sessao?examBoard=UEMA_PAES'
        '&subject=${Uri.encodeComponent(s)}'
        '&topic=${Uri.encodeComponent(t)}'
        '&preferNatureza=${nat ? '1' : '0'}';
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return EmptyState(
        title: 'Fila indisponível',
        subtitle: error!,
        action: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(onPressed: _load, child: const Text('Tentar de novo')),
            TextButton(
              onPressed: () => context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1'),
              child: const Text('Sessão'),
            ),
          ],
        ),
      );
    }
    if (queue == null) return const Center(child: CircularProgressIndicator());

    final revisions = (queue!['revisions'] as List? ?? []);
    final cards = (queue!['flashcards'] as List? ?? []);
    final study = queue!['studyToday'] as Map<String, dynamic>?;
    final minutes = queue!['suggestedMinutes'] ?? 60;
    final openGaps = queue!['openGaps'] is Map ? queue!['openGaps'] as Map : null;
    final gapItems = openGaps?['items'] as List? ?? const [];
    final gapN = openGaps?['openCount'] as int? ?? gapItems.length;
    final gapNoMaterialN = gapItems.where((raw) {
      if (raw is! Map) return false;
      return raw['hasLocalMaterial'] == false;
    }).length;
    final medicineTop = queue!['medicineTop'] as List? ?? const [];
    final routine = Map<String, dynamic>.from(queue!['dailyRoutine'] as Map? ?? {});
    final sessionPath = routine['sessionPath']?.toString() ??
        '/sessao?examBoard=UEMA_PAES&preferNatureza=1';
    final coach = routine['line']?.toString();
    final officialUnlocked = queue!['officialUnlocked'] == true;
    final coachYear = routine['year'];
    final coachSubject = routine['subject']?.toString();
    final coachTopic = routine['topic']?.toString();

    final hasAnything = gapN > 0 ||
        revisions.isNotEmpty ||
        cards.isNotEmpty ||
        study != null ||
        medicineTop.isNotEmpty ||
        ((queue!['axisCardsDue'] as int?) ?? 0) > 0 ||
        ((queue!['axisCardsCreatedToday'] as int?) ?? 0) > 0;

    _syncNavPaths(queue!, sessionPath);

    int navIndexFor(String path) => _navPaths.indexOf(path);

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      child: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          PageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  eyebrow: 'Estudar',
                  title: 'Fila',
                  subtitle: coach ?? 'Próximo passo do dia · cerca de $minutes min',
                  trailing: IconButton(
                    tooltip: 'Atualizar fila',
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    ),
                ),

                MissionQuestCard(
                  title: 'Missão de redação',
                  why: 'Treine o eixo fraco com persona e delta honesto — treino local, não banca.',
                  ctaLabel: 'Abrir redação',
                  status: MissionQuestStatus.open,
                  onCta: () => context.go('/redacao'),
                ),

                FilledButton.icon(
                  onPressed: () => context.go(sessionPath),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Começar sessão'),
                ),
                FutureBuilder(
                  future: apiClient.get('/api/session/checkpoint'),
                  builder: (context, snap) {
                    final cp = snap.hasData ? (snap.data as Map)['checkpoint'] : null;
                    if (cp is! Map || cp['started'] != true) return const SizedBox.shrink();
                    final phase = cp['phaseName']?.toString() ?? '';
                    final phaseLabel = SessionResumeBanner.phaseLabel(phase);
                    final q = (cp['qIndex'] as num?)?.toInt();
                    final sub = phase == 'questions' && q != null
                        ? '$phaseLabel · item ${q + 1} · treino local'
                        : '$phaseLabel · retomamos de onde parou';
                    return SessionResumeBanner(
                      phaseName: phase,
                      subtitle: sub,
                      onContinue: () => context.go(sessionPath),
                    );
                  },
                ),

                if (officialUnlocked && coachSubject != null && coachTopic != null) ...[
                  const SizedBox(height: 12),
                  SectionLabel(
                    'Oficial do dia',
                    hint: coachYear != null ? 'Ano $coachYear · base UEMA local' : 'Base UEMA local',
                  ),
                  PlaylistTile(
                    title: coachSubject,
                    subtitle: coachTopic,
                    badge: 'oficial',
                    active: navIndexFor(sessionPath) == selected,
                    leadingIcon: Icons.menu_book_rounded,
                    onPlay: () {
                      final i = navIndexFor(sessionPath);
                      if (i >= 0) setState(() => selected = i);
                      context.go(sessionPath);
                    },
                  ),
                ],

                if (!hasAnything) ...[
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.playlist_add_check_rounded,
                          size: 40,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.22),
                        ),
                        const SizedBox(height: 10),
                        QuietEmpty(
                          message:
                              'Nada pendente na fila. Toque em Começar sessão acima para montar o plano de hoje.',
                        ),
                      ],
                    ),
                  ),
                ],

                if (gapN > 0) ...[
                  SectionLabel(
                    'Lacunas',
                    hint: 'Erros recentes a retomar',
                    chip: gapNoMaterialN > 0 ? '$gapNoMaterialN sem teoria' : null,
                  ),
                  if (gapNoMaterialN > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FilterChip(
                          label: const Text('Só sem material'),
                          selected: gapsOnlyNoMaterial,
                          onSelected: (v) => setState(() => gapsOnlyNoMaterial = v),
                        ),
                      ),
                    ),
                  for (final raw in gapItems.where((raw) {
                    if (!gapsOnlyNoMaterial) return true;
                    if (raw is! Map) return false;
                    return raw['hasLocalMaterial'] == false;
                  }).take(6))
                    Builder(
                      builder: (_) {
                        final g = Map<String, dynamic>.from(raw as Map);
                        final s = g['subject']?.toString() ?? '';
                        final t = g['topic']?.toString() ?? '';
                        final hasMaterial = g['hasLocalMaterial'] != false;
                        final path =
                            '/adaptativo?subject=${Uri.encodeComponent(s)}'
                            '&topic=${Uri.encodeComponent(t)}';
                        return FutureBuilder(
                          key: ValueKey('gap-tile-$s-$t-$_readRefreshTick'),
                          future: apiClient.get(
                            '/api/study/reads',
                            {'subject': s, 'topic': t},
                          ),
                          builder: (context, snap) {
                            final read = snap.hasData &&
                                (snap.data is Map) &&
                                (snap.data as Map)['read'] == true;
                            final subtitle = !hasMaterial
                                ? '$t · sem material local'
                                : read
                                    ? '$t · li'
                                    : t;
                            final badge = !hasMaterial
                                ? 'sem teoria'
                                : read
                                    ? 'teoria lida'
                                    : 'retomar';
                            final badgeColor = !hasMaterial
                                ? Theme.of(context).colorScheme.tertiaryContainer
                                : read
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : Theme.of(context).colorScheme.surfaceContainerHighest;
                            return PlaylistTile(
                              title: s,
                              subtitle: subtitle,
                              badge: badge,
                              badgeColor: badgeColor,
                              active: navIndexFor(path) == selected,
                              leadingIcon: hasMaterial
                                  ? (read ? Icons.menu_book_rounded : Icons.flag_rounded)
                                  : Icons.folder_off_outlined,
                              onPlay: () {
                                final i = navIndexFor(path);
                                if (i >= 0) setState(() => selected = i);
                                context.go(path);
                              },
                              secondary: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // dots: 1 lido, 2 treinado (gap recuperada ≠, 2 = teórico + lido → pronto)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _GapDot(active: read, label: '1'),
                                        const SizedBox(width: 3),
                                        _GapDot(active: read && hasMaterial, label: '2'),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Biblioteca deste tópico',
                                    icon: Icon(
                                      Icons.library_books_outlined,
                                      size: 20,
                                      color: Theme.of(context).colorScheme.tertiary,
                                    ),
                                    onPressed: () {
                                      final qp = <String, String>{
                                        if (s.isNotEmpty) 'subject': s,
                                        if (t.isNotEmpty) 'topic': t,
                                      };
                                      final qs = qp.entries
                                          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
                                          .join('&');
                                      context.go(qs.isEmpty ? '/biblioteca' : '/biblioteca?$qs');
                                    },
                                  ),
                                  IconButton(
                                    tooltip: read ? 'Teoria lida' : 'Ler teoria',
                                    icon: Icon(
                                      read ? Icons.menu_book_rounded : Icons.menu_book_outlined,
                                      size: 20,
                                      color: read ? Theme.of(context).colorScheme.primary : null,
                                    ),
                                    onPressed: () => _openTheory(s, t),
                                  ),
                                  IconButton(
                                    tooltip: 'Sessão longa',
                                    icon: const Icon(Icons.timer_outlined, size: 20),
                                    onPressed: () => context.go(_sessionFor(s, t)),
                                  ),
                                  IconButton(
                                    tooltip: 'Marcar recuperada',
                                    icon: const Icon(Icons.check_circle_outline, size: 20),
                                    onPressed: s.isEmpty || t.isEmpty
                                        ? null
                                        : () => _recoverGap(s, t),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  if (gapItems.any((raw) {
                    if (raw is! Map) return false;
                    return raw['hasLocalMaterial'] == false;
                  }))
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: QuietEmpty(
                        message:
                            'Lacuna(s) sem teoria local — o app não inventa edital. '
                            'Atualize 2024–26 na Biblioteca ou treine direto no tópico.',
                        action: FilledButton.tonal(
                          onPressed: () => context.go('/biblioteca'),
                          child: const Text('Biblioteca'),
                        ),
                      ),
                    ),
                ],

                Builder(
                  builder: (_) {
                    final wc = Map<String, dynamic>.from(queue!['weekClose'] as Map? ?? const {});
                    if (wc.isEmpty) return const SizedBox.shrink();
                    return WeekClosePanel(weekClose: wc, onCloseWeek: _closeWeek);
                  },
                ),

                if (revisions.isNotEmpty ||
                    cards.isNotEmpty ||
                    ((queue!['axisCardsDue'] as int?) ?? 0) > 0 ||
                    ((queue!['axisCardsCreatedToday'] as int?) ?? 0) > 0) ...[
                  SectionLabel('Revisões', hint: 'O que está na hora'),
                  if ((((queue!['axisCardsDue'] as int?) ?? 0) > 0) ||
                      (((queue!['axisCardsCreatedToday'] as int?) ?? 0) > 0))
                    PlaylistTile(
                      title: 'Cards do debrief',
                      subtitle: () {
                        final due = (queue!['axisCardsDue'] as int?) ?? 0;
                        final neu = (queue!['axisCardsCreatedToday'] as int?) ?? 0;
                        if (due > 0 && neu > 0) {
                          return '$due para revisar · $neu dos eixos sem revisão';
                        }
                        if (due > 0) return '$due card(s) dos eixos para revisar';
                        return '$neu card(s) dos eixos (ainda sem revisão)';
                      }(),
                      badge: 'eixos',
                      active: navIndexFor('/flashcards?due=1') == selected,
                      leadingIcon: Icons.style_outlined,
                      onPlay: () {
                        const path = '/flashcards?due=1';
                        final i = navIndexFor(path);
                        if (i >= 0) setState(() => selected = i);
                        context.go(path);
                      },
                    ),
                  for (final r in revisions.take(8))
                    Builder(
                      builder: (_) {
                        final path =
                            '/adaptativo?subject=${Uri.encodeComponent(r['subject']?.toString() ?? '')}'
                            '&topic=${Uri.encodeComponent(r['topic']?.toString() ?? '')}';
                        return PlaylistTile(
                          title: '${(r as Map)['subject']}',
                          subtitle: '${r['topic']}',
                          badge: 'revisão',
                          active: navIndexFor(path) == selected,
                          leadingIcon: Icons.replay_rounded,
                          onPlay: () {
                            final i = navIndexFor(path);
                            if (i >= 0) setState(() => selected = i);
                            context.go(path);
                          },
                        );
                      },
                    ),
                  if (cards.isNotEmpty)
                    PlaylistTile(
                      title: '${cards.length} flashcards',
                      subtitle: 'Revisão rápida',
                      badge: 'cards',
                      active: navIndexFor('/flashcards?due=1') == selected,
                      leadingIcon: Icons.style_rounded,
                      onPlay: () {
                        const path = '/flashcards?due=1';
                        final i = navIndexFor(path);
                        if (i >= 0) setState(() => selected = i);
                        context.go(path);
                      },
                    ),
                ],

                if (study != null) ...[
                  SectionLabel('Meta de hoje'),
                  Builder(
                    builder: (_) {
                      final s = study['subject']?.toString() ?? '';
                      final t = study['topic']?.toString() ?? '';
                      final path = _sessionFor(s, t);
                      return PlaylistTile(
                        title: '${study['subject']}',
                        subtitle: '${study['topic']}',
                        badge: 'hoje',
                        active: navIndexFor(path) == selected,
                        leadingIcon: Icons.wb_sunny_outlined,
                        onPlay: () {
                          final i = navIndexFor(path);
                          if (i >= 0) setState(() => selected = i);
                          context.go(path);
                        },
                      );
                    },
                  ),
                ],

                Builder(
                  builder: (_) {
                    final s = study?['subject']?.toString() ??
                        coachSubject ??
                        routine['subject']?.toString();
                    final t = study?['topic']?.toString() ??
                        coachTopic ??
                        routine['topic']?.toString();
                    if (s == null || t == null || s.isEmpty || t.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return MediaReinforcement(subject: s, topic: t);
                  },
                ),

                FutureBuilder(
                  future: apiClient.get('/api/essays/progress'),
                  builder: (context, snap) {
                    if (!snap.hasData || snap.data is! Map) return const SizedBox.shrink();
                    final prog = Map<String, dynamic>.from(snap.data as Map);
                    final count = prog['count'] as int? ?? 0;
                    final mission = prog['nextMission'];
                    if (count < 1 || mission is! Map) return const SizedBox.shrink();
                    final label = mission['label']?.toString() ?? 'eixo';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionLabel('Missão de redação', hint: 'treino local · não banca'),
                        PlaylistTile(
                          title: 'Subir $label',
                          subtitle: mission['prompt']?.toString() ?? 'Treino local por eixos',
                          badge: 'missão',
                          leadingIcon: Icons.edit_note_rounded,
                          onPlay: () => context.go('/redacao'),
                        ),
                      ],
                    );
                  },
                ),

                if (medicineTop.isNotEmpty) ...[
                  SectionLabel('Sugestões de domínio'),
                  for (final raw in medicineTop.take(5))
                    Builder(
                      builder: (_) {
                        final c = Map<String, dynamic>.from(raw as Map);
                        final key = c['key']?.toString() ?? '';
                        final parts = key.split('::');
                        final s = parts.isNotEmpty ? parts[0] : '';
                        final t = parts.length > 1 ? parts[1] : '';
                        final path = _sessionFor(s, t);
                        return PlaylistTile(
                          title: s.isEmpty ? key : s,
                          subtitle: t,
                          active: navIndexFor(path) == selected,
                          leadingIcon: Icons.local_hospital_outlined,
                          onPlay: () {
                            final i = navIndexFor(path);
                            if (i >= 0) setState(() => selected = i);
                            context.go(path);
                          },
                        );
                      },
                    ),
                ],

                const SizedBox(height: 24),
                Builder(
                  builder: (ctx) {
                    final focus = ref.watch(focusModeProvider);
                    return Wrap(
                      spacing: 8,
                      children: [
                        if (!focus) ...[
                          TextButton(onPressed: () => context.go('/cronograma'), child: const Text('Plano')),
                          TextButton(onPressed: () => context.go('/medicina'), child: const Text('Domínio')),
                        ],
                        TextButton(onPressed: () => context.go('/adaptativo'), child: const Text('Treino livre')),
                        if (focus)
                          Text(
                            'Modo foco: Plano/Domínio escondidos (F desliga)',
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.55),
                                ),
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

class _GapDot extends StatelessWidget {
  const _GapDot({required this.active, required this.label});
  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? cs.primary : cs.surfaceContainerHighest,
        border: Border.all(color: active ? cs.primary : cs.outlineVariant),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: active ? cs.onPrimary : cs.onSurface.withOpacity(0.45),
        ),
      ),
    );
  }
}
