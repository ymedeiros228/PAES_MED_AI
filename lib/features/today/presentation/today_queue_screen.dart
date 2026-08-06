import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/study_prefs_providers.dart';
import '../../../core/widgets/media_reinforcement.dart';
import '../../../core/widgets/status_widgets.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
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
    try {
      final matFuture = apiClient.get(
        '/api/library/materials',
        {'subject': subject, 'topic': topic},
      );
      final readFuture = apiClient.get(
        '/api/study/reads',
        {'subject': subject, 'topic': topic},
      );
      final artFuture = apiClient.get(
        '/api/media/articles',
        {'subject': subject, 'topic': topic},
      );
      final matRaw = await matFuture;
      final readRaw = await readFuture;
      final artRaw = await artFuture;
      if (!mounted) return;
      final map = Map<String, dynamic>.from(matRaw as Map);
      final readMap = Map<String, dynamic>.from(readRaw as Map);
      final artMap = Map<String, dynamic>.from(artRaw as Map);
      final items = (map['items'] as List? ?? []).whereType<Map>().toList();
      final articles = (artMap['items'] as List? ?? []).whereType<Map>().toList();
      final note = map['note']?.toString();
      final artDisclaimer = artMap['disclaimer']?.toString();
      var isRead = readMap['read'] == true;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setModal) {
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.55,
                minChildSize: 0.35,
                maxChildSize: 0.9,
                builder: (_, scroll) {
                  return ListView(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      Text(
                        'Teoria · $subject · $topic',
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                      if (isRead)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Marcado como li${readMap['at'] != null ? ' · ${readMap['at']}' : ''}',
                            style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(ctx).colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      if (note != null && note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(note, style: Theme.of(ctx).textTheme.bodySmall),
                      ],
                      if (items.isEmpty) ...[
                        const SizedBox(height: 16),
                        QuietEmpty(
                          message: note ?? 'Sem material local para este tópico.',
                          action: TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.go('/biblioteca');
                            },
                            child: const Text('Biblioteca'),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        for (final raw in items.take(8))
                          Builder(
                            builder: (_) {
                              final it = Map<String, dynamic>.from(raw);
                              final path = it['path']?.toString() ?? '';
                              final snippet = it['snippet']?.toString() ?? '';
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(it['label']?.toString() ?? it['kind']?.toString() ?? 'item'),
                                subtitle: snippet.isNotEmpty
                                    ? Text(
                                        snippet.length > 200 ? '${snippet.substring(0, 200)}…' : snippet,
                                      )
                                    : Text(path.isNotEmpty ? path : (it['kind']?.toString() ?? '')),
                                trailing: path.isNotEmpty
                                    ? IconButton(
                                        tooltip: 'Abrir',
                                        icon: const Icon(Icons.open_in_new_rounded),
                                        onPressed: () async {
                                          try {
                                            await apiClient.post('/api/library/open-path', {'path': path});
                                          } catch (_) {
                                            await apiClient.post(
                                              '/api/library/open-folder',
                                              {'folder': it['folder'] ?? 'edital'},
                                            );
                                          }
                                        },
                                      )
                                    : null,
                              );
                            },
                          ),
                      ],
                      if (articles.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('Leituras de reforço', style: Theme.of(ctx).textTheme.titleSmall),
                        if (artDisclaimer != null)
                          Text(artDisclaimer, style: Theme.of(ctx).textTheme.bodySmall),
                        for (final raw in articles.take(5))
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text((raw as Map)['title']?.toString() ?? 'Leitura'),
                            subtitle: Text(raw['source']?.toString() ?? raw['channel']?.toString() ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Marquei como lido',
                                  icon: const Icon(Icons.check_circle_outline, size: 20),
                                  onPressed: () async {
                                    final u = raw['url']?.toString() ?? '';
                                    if (u.isEmpty) return;
                                    try {
                                      await apiClient.post('/api/media/mark-read', {
                                        'url': u,
                                        'subject': subject,
                                        'topic': topic,
                                        'title': raw['title']?.toString(),
                                      });
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Marcado como lido (local).')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              humanApiError(e, fallback: 'Não deu para marcar como lido.'),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                const Icon(Icons.open_in_new_rounded, size: 18),
                              ],
                            ),
                            onTap: () async {
                              final u = raw['url']?.toString() ?? '';
                              if (u.isEmpty) return;
                              try {
                                await apiClient.post('/api/media/open', {
                                  'url': u,
                                  'kind': 'article',
                                  'subject': subject,
                                  'topic': topic,
                                  'title': raw['title']?.toString(),
                                });
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        humanApiError(e, fallback: 'Não deu para abrir o material.'),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () async {
                              try {
                                final r = await apiClient.post('/api/study/mark-read', {
                                  'subject': subject,
                                  'topic': topic,
                                });
                                final m = Map<String, dynamic>.from(r as Map);
                                setModal(() {
                                  isRead = true;
                                  readMap['at'] = m['at'];
                                  readMap['read'] = true;
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Marcado como li (local).')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        humanApiError(e, fallback: 'Não deu para marcar como lido.'),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(isRead ? 'Li de novo' : 'Marquei como li'),
                          ),
                          FilledButton.tonal(
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.go(_sessionFor(subject, topic));
                            },
                            child: const Text('Treinar tópico'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.go('/biblioteca');
                            },
                            child: const Text('Biblioteca'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para abrir a leitura.'))),
      );
    }
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
        subtitle: 'Reabra o app pelo atalho da área de trabalho.',
        action: FilledButton(onPressed: _load, child: const Text('Tentar de novo')),
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

    return RefreshIndicator(
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
                  subtitle: coach ?? 'O que fazer a seguir · cerca de $minutes min',
                  trailing: IconButton(
                    tooltip: 'Atualizar',
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    ),
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
                    final phaseLabel = switch (phase) {
                      'theory' => 'Teoria',
                      'questions' => 'Questões',
                      'revisions' || 'review' || 'cards' => 'Revisão',
                      _ => phase.isEmpty ? 'Sessão' : phase,
                    };
                    final q = (cp['qIndex'] as num?)?.toInt();
                    final sub = phase == 'questions' && q != null
                        ? '$phaseLabel · item ${q + 1}'
                        : phaseLabel;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: OutlinedButton.icon(
                        onPressed: () => context.go(sessionPath),
                        icon: const Icon(Icons.history_rounded),
                        label: Text('Continuar · $sub'),
                      ),
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
                    active: true,
                    leadingIcon: Icons.menu_book_rounded,
                    onPlay: () => context.go(sessionPath),
                  ),
                ],

                if (!hasAnything) ...[
                  const SizedBox(height: 20),
                  QuietEmpty(
                    message: 'Fila leve — sessão guiada é o caminho.',
                    action: TextButton(
                      onPressed: () => context.go('/sessao'),
                      child: const Text('Sessão'),
                    ),
                  ),
                ],

                if (gapN > 0) ...[
                  SectionLabel('Lacunas', hint: 'Erros recentes a retomar'),
                  for (final raw in gapItems.take(6))
                    Builder(
                      builder: (_) {
                        final g = Map<String, dynamic>.from(raw as Map);
                        final s = g['subject']?.toString() ?? '';
                        final t = g['topic']?.toString() ?? '';
                        return PlaylistTile(
                          title: s,
                          subtitle: t,
                          badge: 'retomar',
                          leadingIcon: Icons.flag_rounded,
                          onPlay: () => context.go(
                            '/adaptativo?subject=${Uri.encodeComponent(s)}'
                            '&topic=${Uri.encodeComponent(t)}',
                          ),
                          secondary: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FutureBuilder(
                                future: apiClient.get(
                                  '/api/study/reads',
                                  {'subject': s, 'topic': t},
                                ),
                                builder: (context, snap) {
                                  final read = snap.hasData &&
                                      (snap.data is Map) &&
                                      (snap.data as Map)['read'] == true;
                                  return IconButton(
                                    tooltip: read ? 'Teoria (li)' : 'Ler teoria',
                                    icon: Icon(
                                      read ? Icons.menu_book_rounded : Icons.menu_book_outlined,
                                      size: 20,
                                      color: read ? Theme.of(context).colorScheme.primary : null,
                                    ),
                                    onPressed: () => _openTheory(s, t),
                                  );
                                },
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
                          return '$due due · $neu dos eixos sem revisão';
                        }
                        if (due > 0) return '$due card(s) dos eixos due';
                        return '$neu card(s) dos eixos (ainda sem revisão)';
                      }(),
                      badge: 'eixos',
                      leadingIcon: Icons.style_outlined,
                      onPlay: () => context.go('/flashcards?due=1'),
                    ),
                  for (final r in revisions.take(8))
                    PlaylistTile(
                      title: '${(r as Map)['subject']}',
                      subtitle: '${r['topic']}',
                      badge: 'revisão',
                      leadingIcon: Icons.replay_rounded,
                      onPlay: () => context.go(
                        '/adaptativo?subject=${Uri.encodeComponent(r['subject']?.toString() ?? '')}'
                        '&topic=${Uri.encodeComponent(r['topic']?.toString() ?? '')}',
                      ),
                    ),
                  if (cards.isNotEmpty)
                    PlaylistTile(
                      title: '${cards.length} flashcards',
                      subtitle: 'Revisão rápida',
                      badge: 'cards',
                      leadingIcon: Icons.style_rounded,
                      onPlay: () => context.go('/flashcards?due=1'),
                    ),
                ],

                if (study != null) ...[
                  SectionLabel('Meta de hoje'),
                  PlaylistTile(
                    title: '${study['subject']}',
                    subtitle: '${study['topic']}',
                    badge: 'hoje',
                    active: true,
                    leadingIcon: Icons.wb_sunny_outlined,
                    onPlay: () {
                      final s = study['subject']?.toString() ?? '';
                      final t = study['topic']?.toString() ?? '';
                      context.go(_sessionFor(s, t));
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
                        return PlaylistTile(
                          title: s.isEmpty ? key : s,
                          subtitle: t,
                          leadingIcon: Icons.local_hospital_outlined,
                          onPlay: () => context.go(_sessionFor(s, t)),
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
    );
  }
}
