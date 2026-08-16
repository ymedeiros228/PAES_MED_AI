import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
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
  List<String> _navPaths = const [];
  String _sessionPath = '/sessao?examBoard=UEMA_PAES&preferNatureza=1';
  bool gapsOnlyNoMaterial = false;
  // Futures cached para evitar recriar a cada rebuild
  late final Future<dynamic> _checkpointFuture;
  late final Future<dynamic> _essayProgressFuture;

  @override
  void initState() {
    super.initState();
    _checkpointFuture = apiClient.get('/api/session/checkpoint');
    _essayProgressFuture = apiClient.get('/api/essays/progress');
    _load();
  }

  @override
  void dispose() {
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
        const SnackBar(content: Text('Tópico revisado')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para marcar o tópico para revisar.'))),
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
    final cs = Theme.of(context).colorScheme;
    if (error != null) {
      return EmptyState(
        title: 'Fila indisponível',
        subtitle: error!,
        action: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TapScale(
              child: FilledButton(onPressed: _load, child: const Text('Tentar de novo')),
            ),
            TextButton(
              onPressed: () => context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1'),
              child: const Text('Sessão'),
            ),
          ],
        ),
      );
    }
    if (queue == null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SkeletonCard(lines: 2),
          SizedBox(height: 12),
          SkeletonCard(lines: 3),
          SizedBox(height: 12),
          SkeletonCard(lines: 2),
        ],
      );
    }

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

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
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

                SizedBox(
                  width: double.infinity,
                  child: TapScale(
                    child: FilledButton.icon(
                      onPressed: () => context.go(sessionPath),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Começar sessão'),
                    ),
                  ),
                ),
                FutureBuilder(
                  future: _checkpointFuture,
                  builder: (context, snap) {
                    final cp = snap.hasData ? (snap.data as Map)['checkpoint'] : null;
                    if (cp is! Map || cp['started'] != true) return const SizedBox.shrink();
                    final phase = cp['phaseName']?.toString() ?? '';
                    final phaseLabel = SessionResumeBanner.phaseLabel(phase);
                    final q = (cp['qIndex'] as num?)?.toInt();
                    final sub = phase == 'questions' && q != null
                        ? '$phaseLabel · questão ${q + 1} · prática'
                        : '$phaseLabel · retomamos de onde parou';
                    return SessionResumeBanner(
                      phaseName: phase,
                      subtitle: sub,
                      onContinue: () => context.go(sessionPath),
                    );
                  },
                ),

                SectionLabel(
                  'Outras ações',
                  hint: 'Complementos do dia, abaixo da sessão principal',
                ),
                // Card de missão de redação com gradiente sutil (tertiary → surface)
                Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.tertiaryContainer.withOpacity(0.35),
                        cs.surface.withOpacity(0.98),
                      ],
                      stops: const [0.0, 0.6],
                    ),
                    borderRadius: BorderRadius.circular(kRadiusPanelSoft),
                    border: Border.all(
                      color: cs.outlineVariant.withOpacity(0.5),
                    ),
                    boxShadow: Theme.of(context).brightness == Brightness.dark
                        ? null
                        : [
                            BoxShadow(
                              color: const Color(0xFF0A1628).withOpacity(0.03),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: const Color(0xFF0A1628).withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Missão de redação',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            Text(
                              'Prática · não banca',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: cs.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/redacao'),
                        child: const Text('Abrir'),
                      ),
                    ],
                  ),
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
                      HapticFeedback.selectionClick();
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
                          color: Theme.of(context).colorScheme.onSurface.f22,
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
                    'Tópicos para revisar',
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
                          onSelected: (v) {
                            HapticFeedback.selectionClick();
                            setState(() => gapsOnlyNoMaterial = v);
                          },
                        ),
                      ),
                    ),
                  StaggeredFadeIn(
                    children: [
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
                                    HapticFeedback.selectionClick();
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
                    ],
                  ),
                  if (gapItems.any((raw) {
                    if (raw is! Map) return false;
                    return raw['hasLocalMaterial'] == false;
                  }))
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: QuietEmpty(
                        message:
                            'Tópico(s) para revisar sem teoria local — o app não inventa edital. '
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
                  StaggeredFadeIn(
                    children: [
                      if ((((queue!['axisCardsDue'] as int?) ?? 0) > 0) ||
                          (((queue!['axisCardsCreatedToday'] as int?) ?? 0) > 0))
                        PlaylistTile(
                          title: 'Cartões da revisão',
                          subtitle: () {
                            final due = (queue!['axisCardsDue'] as int?) ?? 0;
                            final neu = (queue!['axisCardsCreatedToday'] as int?) ?? 0;
                            if (due > 0 && neu > 0) {
                              return '$due para revisar · $neu dos eixos sem revisão';
                            }
                            if (due > 0) return '$due cartões dos eixos para revisar';
                            return '$neu cartões dos eixos (ainda sem revisão)';
                          }(),
                          badge: 'eixos',
                          active: navIndexFor('/flashcards?due=1') == selected,
                          leadingIcon: Icons.style_outlined,
                          onPlay: () {
                            HapticFeedback.selectionClick();
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
                                HapticFeedback.selectionClick();
                                final i = navIndexFor(path);
                                if (i >= 0) setState(() => selected = i);
                                context.go(path);
                              },
                            );
                          },
                        ),
                      if (cards.isNotEmpty)
                        PlaylistTile(
                          title: '${cards.length} cartões de estudo',
                          subtitle: 'Revisão rápida',
                          badge: 'cartões',
                          active: navIndexFor('/flashcards?due=1') == selected,
                          leadingIcon: Icons.style_rounded,
                          onPlay: () {
                            HapticFeedback.selectionClick();
                            const path = '/flashcards?due=1';
                            final i = navIndexFor(path);
                            if (i >= 0) setState(() => selected = i);
                            context.go(path);
                          },
                        ),
                    ],
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
                          HapticFeedback.selectionClick();
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
                  future: _essayProgressFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const CompactStatus(
                        message: 'Carregando missão de redação…',
                        icon: Icons.hourglass_empty_rounded,
                      );
                    }
                    if (snap.hasError || snap.data is! Map) {
                      return const CompactStatus(
                        message: 'Missão de redação indisponível no momento.',
                        icon: Icons.sync_problem_outlined,
                      );
                    }
                    final prog = Map<String, dynamic>.from(snap.data as Map);
                    final count = prog['count'] as int? ?? 0;
                    final mission = prog['nextMission'];
                    if (count < 1 || mission is! Map) {
                      return const CompactStatus(
                        message: 'Nenhuma missão de redação disponível.',
                        icon: Icons.edit_note_outlined,
                      );
                    }
                    final label = mission['label']?.toString() ?? 'eixo';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionLabel('Missão de redação', hint: 'prática · não banca'),
                        PlaylistTile(
                          title: 'Subir $label',
                          subtitle: mission['prompt']?.toString() ?? 'Prática por eixos',
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
                  StaggeredFadeIn(
                    children: [
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
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Theme.of(ctx).colorScheme.onSurface.f72,
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
    // AnimatedScale: pulso sutil quando ativo — feedback visual moderno
    return AnimatedScale(
      scale: active ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? cs.primary : cs.surfaceContainerHighest,
          border: Border.all(
            color: active ? cs.primary : cs.outlineVariant,
            width: active ? 2 : 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: active ? cs.onPrimary : cs.onSurface.f72,
          ),
        ),
      ),
    );
  }
}
