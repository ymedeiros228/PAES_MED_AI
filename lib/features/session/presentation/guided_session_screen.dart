import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../../core/data/api_client.dart';
import '../../../core/data/providers.dart';
import '../../../core/widgets/resolution_debrief.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/training_basis_banner.dart';
import '../../../core/widgets/ui_kit.dart';

const _errorTypes = ['conceito', 'interpretacao', 'calculo', 'distracao', 'tempo'];

class GuidedSessionScreen extends ConsumerStatefulWidget {
  const GuidedSessionScreen({
    super.key,
    this.examBoard,
    this.year,
    this.preferNatureza,
    this.subject,
    this.topic,
  });

  final String? examBoard;
  final int? year;
  final bool? preferNatureza;
  final String? subject;
  final String? topic;

  @override
  ConsumerState<GuidedSessionScreen> createState() => _GuidedSessionScreenState();
}

class _GuidedSessionScreenState extends ConsumerState<GuidedSessionScreen> {
  Map<String, dynamic>? plan;
  String? error;
  int phaseIndex = 0;
  final sw = Stopwatch();
  final qSw = Stopwatch();
  Timer? ticker;
  bool started = false;
  bool paused = false;
  String? exportMsg;

  List<Map<String, dynamic>> sessionQuestions = [];
  int qIndex = 0;
  int? selected;
  bool revealed = false;
  String errorType = 'conceito';
  bool pendingErrorPick = false;
  final answeredIds = <String>[];
  final sessionErrors = <String>[];
  final missTopics = <Map<String, String>>[];
  int flashcardsCreated = 0;
  int correctCount = 0;
  final focusNode = FocusNode();
  Map<String, dynamic>? lastRemediation;

  // Revision phase: flashcards
  List<Map<String, dynamic>> sessionCards = [];
  int cardIndex = 0;
  bool cardFlipped = false;
  int cardsDone = 0;
  bool revisionUsingQuestions = false;
  bool restoring = false;
  Map<String, dynamic>? pendingCheckpoint;
  /// Ciclo AI: painel final da sessão (após último bloco).
  bool sessionComplete = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _planPath {
    final qs = <String>[];
    final board = widget.examBoard;
    if (board != null && board.isNotEmpty) {
      qs.add('examBoard=${Uri.encodeComponent(board)}');
    }
    if (widget.year != null) qs.add('year=${widget.year}');
    final subj = widget.subject?.trim();
    final top = widget.topic?.trim();
    if (subj != null && subj.isNotEmpty) {
      qs.add('subject=${Uri.encodeComponent(subj)}');
    }
    if (top != null && top.isNotEmpty) {
      qs.add('topic=${Uri.encodeComponent(top)}');
    }
    final natSubjects = {'Biologia', 'Química', 'Física'};
    if (widget.preferNatureza == true) {
      qs.add('preferNatureza=true');
    } else if (widget.preferNatureza == false) {
      qs.add('preferNatureza=false');
    } else if (subj != null && subj.isNotEmpty) {
      qs.add(natSubjects.contains(subj) ? 'preferNatureza=true' : 'preferNatureza=false');
    } else if (board != null && board.toUpperCase() == 'UEMA_PAES') {
      qs.add('preferNatureza=true');
    }
    return qs.isEmpty ? '/api/session/plan' : '/api/session/plan?${qs.join('&')}';
  }

  @override
  void dispose() {
    if (started) {
      // fire-and-forget save
      _saveCheckpoint();
    }
    ticker?.cancel();
    focusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await apiClient.get(_planPath);
      Map<String, dynamic>? cp;
      try {
        final raw = await apiClient.get('/api/session/checkpoint');
        cp = (raw as Map)['checkpoint'] as Map<String, dynamic>?;
        if (cp != null) cp = Map<String, dynamic>.from(cp);
      } catch (_) {}
      setState(() {
        plan = Map<String, dynamic>.from(data as Map);
        pendingCheckpoint = cp != null && cp['started'] == true ? cp : null;
      });
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  Future<void> _saveCheckpoint() async {
    if (!started || plan == null) return;
    final phases = (plan?['sessionPlan'] as List? ?? []);
    final phaseName = phases.isEmpty
        ? null
        : Map<String, dynamic>.from(phases[phaseIndex.clamp(0, phases.length - 1)] as Map)['phase']?.toString();
    final ids = sessionQuestions.map((q) => q['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
    try {
      await apiClient.post('/api/session/checkpoint', {
        'phaseIndex': phaseIndex,
        'qIndex': qIndex,
        'answeredIds': answeredIds.toList(),
        'elapsedMs': _resumeElapsedMs + sw.elapsedMilliseconds,
        'correctCount': correctCount,
        'sessionErrors': sessionErrors.toList(),
        'missTopics': missTopics,
        'flashcardsCreated': flashcardsCreated,
        'phaseName': phaseName,
        'questionIds': ids,
        'started': true,
      });
    } catch (_) {}
  }

  Future<void> _clearCheckpoint() async {
    try {
      await apiClient.delete('/api/session/checkpoint');
    } catch (_) {}
    setState(() => pendingCheckpoint = null);
  }

  Future<void> _restoreCheckpoint() async {
    final cp = pendingCheckpoint;
    if (cp == null || plan == null) return;
    setState(() => restoring = true);
    try {
      final elapsed = (cp['elapsedMs'] as num?)?.toInt() ?? 0;
      sw
        ..reset()
        ..start();
      // approximate elapsed by setting stopwatch via starting earlier isn't possible; store offset
      final ids = (cp['questionIds'] as List? ?? []).map((e) => e.toString()).toList();
      final phase = (cp['phaseIndex'] as num?)?.toInt() ?? 0;
      final qIdx = (cp['qIndex'] as num?)?.toInt() ?? 0;
      answeredIds
        ..clear()
        ..addAll((cp['answeredIds'] as List? ?? []).map((e) => e.toString()));
      sessionErrors
        ..clear()
        ..addAll((cp['sessionErrors'] as List? ?? []).map((e) => e.toString()));
      missTopics
        ..clear()
        ..addAll(
          (cp['missTopics'] as List? ?? []).whereType<Map>().map(
                (e) => {
                  'subject': e['subject']?.toString() ?? '',
                  'topic': e['topic']?.toString() ?? '',
                },
              ),
        );
      flashcardsCreated = (cp['flashcardsCreated'] as num?)?.toInt() ?? 0;
      correctCount = (cp['correctCount'] as num?)?.toInt() ?? 0;
      ticker?.cancel();
      ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && !paused) {
          setState(() {});
          if (sw.elapsed.inSeconds % 20 == 0) _saveCheckpoint();
        }
      });
      setState(() {
        started = true;
        paused = false;
        phaseIndex = phase;
        pendingCheckpoint = null;
        _resumeElapsedMs = elapsed;
      });
      final phases = (plan?['sessionPlan'] as List? ?? []);
      final name = phases.isEmpty
          ? ''
          : Map<String, dynamic>.from(phases[phase.clamp(0, phases.length - 1)] as Map)['phase']?.toString() ?? '';
      if (name == 'questions' || name == 'revisions' || name == 'review') {
        if (ids.isNotEmpty) {
          await _loadQuestionBodies(ids);
          setState(() => qIndex = qIdx.clamp(0, sessionQuestions.isEmpty ? 0 : sessionQuestions.length - 1));
        } else if (name == 'questions') {
          await _enterQuestionsPhase();
        } else {
          await _enterRevisionsPhase();
        }
      }
      // Adjust displayed clock: add resume offset in build via _resumeElapsedMs
    } finally {
      if (mounted) setState(() => restoring = false);
    }
  }

  int _resumeElapsedMs = 0;

  Future<void> _loadQuestionBodies(List ids) async {
    final out = <Map<String, dynamic>>[];
    for (final raw in ids.take(12)) {
      try {
        final q = await apiClient.get('/api/questions/${raw.toString()}');
        out.add(Map<String, dynamic>.from(q as Map));
      } catch (_) {}
    }
    setState(() {
      sessionQuestions = out;
      qIndex = 0;
      selected = null;
      revealed = false;
      pendingErrorPick = false;
      errorType = 'conceito';
    });
    qSw
      ..reset()
      ..start();
    WidgetsBinding.instance.addPostFrameCallback((_) => focusNode.requestFocus());
  }

  void _start() {
    sw
      ..reset()
      ..start();
    _resumeElapsedMs = 0;
    paused = false;
    ticker?.cancel();
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !paused) {
        setState(() {});
        if (sw.elapsed.inSeconds % 20 == 0) _saveCheckpoint();
      }
    });
    setState(() {
      started = true;
      sessionComplete = false;
      phaseIndex = 0;
      answeredIds.clear();
      sessionErrors.clear();
      missTopics.clear();
      flashcardsCreated = 0;
      correctCount = 0;
      cardsDone = 0;
      sessionCards = [];
      pendingCheckpoint = null;
    });
    _saveCheckpoint();
  }

  void _togglePause() {
    setState(() {
      paused = !paused;
      if (paused) {
        sw.stop();
        qSw.stop();
      } else {
        sw.start();
        if (!revealed) qSw.start();
      }
    });
  }

  Future<void> _enterQuestionsPhase() async {
    final ids = (plan?['phases'] as Map?)?['questions'] as List? ?? [];
    await _loadQuestionBodies(ids);
  }

  Future<void> _enterRevisionsPhase() async {
    final cards = (plan?['flashcards'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .take(10)
        .toList();
    if (cards.isNotEmpty) {
      setState(() {
        sessionCards = cards;
        cardIndex = 0;
        cardFlipped = false;
        cardsDone = 0;
        revisionUsingQuestions = false;
      });
      return;
    }
    // Sem flashcards: praticar questões dos tópicos em revisão
    final revs = (plan?['revisions'] as List? ?? plan?['phases']?['revisions'] as List? ?? []);
    final ids = <String>[];
    for (final raw in revs.take(4)) {
      final r = Map<String, dynamic>.from(raw as Map);
      final subject = r['subject']?.toString() ?? '';
      final topic = r['topic']?.toString() ?? '';
      if (subject.isEmpty) continue;
      try {
        final qs = await apiClient.get(
          '/api/questions?subject=${Uri.encodeComponent(subject)}'
          '&topic=${Uri.encodeComponent(topic)}&limit=3',
        );
        for (final q in (qs as List).take(2)) {
          final id = (q as Map)['id']?.toString();
          if (id != null && id.isNotEmpty && !ids.contains(id)) ids.add(id);
        }
      } catch (_) {}
    }
    if (ids.isEmpty) {
      final study = plan?['studyToday'] as Map?;
      if (study != null) {
        try {
          final qs = await apiClient.get(
            '/api/questions?subject=${Uri.encodeComponent(study['subject']?.toString() ?? '')}'
            '&topic=${Uri.encodeComponent(study['topic']?.toString() ?? '')}&limit=5',
          );
          for (final q in (qs as List).take(5)) {
            final id = (q as Map)['id']?.toString();
            if (id != null) ids.add(id);
          }
        } catch (_) {}
      }
    }
    setState(() {
      sessionCards = [];
      revisionUsingQuestions = true;
    });
    if (ids.isNotEmpty) await _loadQuestionBodies(ids);
  }

  Future<void> _nextPhase() async {
    final phases = (plan?['sessionPlan'] as List? ?? []);
    if (phaseIndex >= phases.length - 1) {
      sw.stop();
      ticker?.cancel();
      await _clearCheckpoint();
      await _prepareSessionEnd();
      return;
    }
    final next = phaseIndex + 1;
    setState(() => phaseIndex = next);
    final phase = Map<String, dynamic>.from(phases[next] as Map);
    final name = phase['phase']?.toString() ?? '';
    if (name == 'questions') await _enterQuestionsPhase();
    if (name == 'revisions' || name == 'review') await _enterRevisionsPhase();
    await _saveCheckpoint();
  }

  List<Map<String, String>> get _sessionGaps {
    final unique = <String>{};
    final gaps = <Map<String, String>>[];
    for (final m in missTopics) {
      final key = '${m['subject']}::${m['topic']}';
      if (unique.add(key) && (m['subject'] ?? '').isNotEmpty) gaps.add(m);
    }
    return gaps;
  }

  Future<void> _prepareSessionEnd() async {
    final gaps = _sessionGaps;
    if (gaps.isNotEmpty) {
      try {
        await apiClient.post('/api/simulations/schedule-gaps', {
          'gaps': [
            for (final g in gaps) {'subject': g['subject'], 'topic': g['topic']},
          ],
        });
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      started = false;
      sessionComplete = true;
    });
  }

  Future<void> _closeStudyDay() async {
    try {
      await apiClient.post('/api/study/day-close', {});
      ref.read(refreshTickProvider.notifier).state++;
    } catch (_) {}
    if (mounted) context.go('/dashboard');
  }

  Widget _sessionEndPanel(BuildContext context) {
    final gaps = _sessionGaps;
    final first = gaps.isNotEmpty ? gaps.first : null;
    final officialInPack = plan?['officialInPack'];
    final toppedOff = plan?['toppedOff'] == true;
    final yearWidened = plan?['yearWidened'] == true;
    final total = answeredIds.length;
    final cs = Theme.of(context).colorScheme;
    return SurfacePanel(
      margin: const EdgeInsets.only(bottom: 16),
      color: cs.primaryContainer.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bloco encerrado',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Acertos $correctCount/$total'
            '${flashcardsCreated > 0 ? ' · $flashcardsCreated card(s) criados' : ''}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (officialInPack != null) ...[
            const SizedBox(height: 4),
            Text(
              'Oficiais no pack: $officialInPack'
              '${toppedOff ? ' · pack completado com oficiais' : ''}'
              '${yearWidened ? ' · janela de anos ampliada' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          if (gaps.isEmpty)
            const Text('Sem misses neste bloco — siga a fila ou os cards due.')
          else ...[
            Text(
              'Tópicos fracos',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            for (final g in gaps.take(6)) Text('· ${g['subject']} / ${g['topic']}'),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () => context.go('/fila'),
                child: const Text('Fila'),
              ),
              if (first != null)
                FilledButton.tonal(
                  onPressed: () {
                    final s = Uri.encodeComponent(first['subject'] ?? '');
                    final t = Uri.encodeComponent(first['topic'] ?? '');
                    context.go('/adaptativo?subject=$s&topic=$t');
                  },
                  child: const Text('Treinar tópico fraco'),
                ),
              FilledButton.tonal(
                onPressed: () => context.go('/flashcards?due=1'),
                child: const Text('Cards due'),
              ),
              OutlinedButton(
                onPressed: _closeStudyDay,
                child: const Text('Encerrar dia'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitAnswer() async {
    if (sessionQuestions.isEmpty || selected == null || revealed) return;
    final q = sessionQuestions[qIndex];
    final correctIdx = (q['correctIndex'] as int?) ?? (q['correct_index'] as int?);
    final correct = selected == correctIdx;
    qSw.stop();
    if (!correct) {
      setState(() {
        revealed = true;
        pendingErrorPick = true;
      });
      return;
    }
    await _persistAnswer(q, correct: true, type: null);
  }

  Future<void> _persistAnswer(Map<String, dynamic> q, {required bool correct, String? type}) async {
    final res = await apiClient.post('/api/answers', {
      'questionId': q['id'],
      'correct': correct,
      'subject': q['subject'],
      'topic': q['topic'],
      'errorType': correct ? null : (type ?? errorType),
      'timeMs': qSw.elapsedMilliseconds,
    });
    ref.read(refreshTickProvider.notifier).state++;
    setState(() {
      revealed = true;
      pendingErrorPick = false;
      answeredIds.add(q['id'].toString());
      lastRemediation = correct
          ? null
          : Map<String, dynamic>.from((res as Map?)?['remediation'] as Map? ?? {});
      if (correct) {
        correctCount++;
      } else {
        sessionErrors.add(type ?? errorType);
        missTopics.add({
          'subject': q['subject']?.toString() ?? '',
          'topic': q['topic']?.toString() ?? '',
        });
      }
    });
    if (!correct && mounted && (res as Map?)?['flashcardCreated'] == true) {
      flashcardsCreated++;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flashcard criado para revisão (due amanhã).'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _confirmErrorAndSave() async {
    if (sessionQuestions.isEmpty) return;
    await _persistAnswer(sessionQuestions[qIndex], correct: false, type: errorType);
  }

  Future<void> _nextQuestion() async {
    if (qIndex >= sessionQuestions.length - 1) {
      await _nextPhase();
      return;
    }
    setState(() {
      qIndex++;
      selected = null;
      revealed = false;
      pendingErrorPick = false;
      errorType = 'conceito';
    });
    qSw
      ..reset()
      ..start();
    focusNode.requestFocus();
  }

  Future<void> _reviewCard({required bool remembered}) async {
    if (sessionCards.isEmpty) return;
    final card = sessionCards[cardIndex];
    final id = card['id'];
    if (id != null) {
      try {
        await apiClient.post('/api/flashcards/$id/review', {'remembered': remembered});
      } catch (_) {}
    }
    final last = cardIndex >= sessionCards.length - 1;
    setState(() {
      cardsDone++;
      cardFlipped = false;
      if (!last) cardIndex++;
    });
    // Ciclo G: último card avança sozinho para a próxima fase
    if (last) await _nextPhase();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !started) return KeyEventResult.ignored;
    final phases = plan?['sessionPlan'] as List? ?? [];
    final phase = Map<String, dynamic>.from(phases[phaseIndex.clamp(0, phases.length - 1)] as Map);
    if ((phase['phase']?.toString() ?? '') != 'questions') return KeyEventResult.ignored;
    if (pendingErrorPick) return KeyEventResult.ignored;
    if (revealed) {
      if (event.logicalKey == LogicalKeyboardKey.keyN || event.logicalKey == LogicalKeyboardKey.enter) {
        _nextQuestion();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    final keys = {
      LogicalKeyboardKey.digit1: 0,
      LogicalKeyboardKey.digit2: 1,
      LogicalKeyboardKey.digit3: 2,
      LogicalKeyboardKey.digit4: 3,
      LogicalKeyboardKey.digit5: 4,
    };
    if (keys.containsKey(event.logicalKey)) {
      setState(() => selected = keys[event.logicalKey]);
      return KeyEventResult.handled;
    }
      if (event.logicalKey == LogicalKeyboardKey.enter && selected != null) {
      _submitAnswer();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _exportDay() async {
    final study = plan?['studyToday'] as Map<String, dynamic>?;
    final buf = StringBuffer('# Pacote do dia — PAES MED AI\n\n');
    if (study != null) {
      buf.writeln('## Meta: ${study['subject']} — ${study['topic']}');
      buf.writeln('${study['reason']}\n');
    }
    buf.writeln('## Teoria (edital)');
    for (final s in (plan?['theorySnippets'] as List? ?? plan?['phases']?['theorySnippets'] as List? ?? [])) {
      buf.writeln('- $s');
    }
    buf.writeln('\n## Sessão');
    buf.writeln('Respondidas: ${answeredIds.length} · Acertos: $correctCount · Cards: $cardsDone');
    if (sessionErrors.isNotEmpty) {
      buf.writeln('Erros (tipos): ${sessionErrors.join(', ')}');
    }
    for (final id in answeredIds) {
      buf.writeln('- $id');
    }
    final file = File(p.join(Directory.current.path, 'data', 'pacote_dia.md'));
    await file.parent.create(recursive: true);
    await file.writeAsString(buf.toString());
    setState(() => exportMsg = file.path);
  }

  Map<String, dynamic>? get _professor {
    if (sessionQuestions.isEmpty) return null;
    final q = sessionQuestions[qIndex];
    final pm = q['professorMode'];
    if (pm is Map) {
      final map = Map<String, dynamic>.from(pm);
      map.putIfAbsent('resolution', () => q['resolution']);
      map.putIfAbsent('resolutionQuality', () => q['resolutionQuality']);
      map.putIfAbsent('resolutionAxes', () => q['resolutionAxes']);
      map.putIfAbsent('studentResolutionLabel', () => q['studentResolutionLabel']);
      map.putIfAbsent('macete', () => q['macete']);
      map.putIfAbsent('pegadinha', () => q['pegadinha']);
      map.putIfAbsent('bancaIntent', () => q['bancaIntent']);
      map.putIfAbsent('examBoard', () => q['examBoard']);
      return map;
    }
    return {
      'resolution': q['resolution'],
      'resolutionQuality': q['resolutionQuality'],
      'resolutionAxes': q['resolutionAxes'],
      'studentResolutionLabel': q['studentResolutionLabel'],
      'macete': q['macete'],
      'pegadinha': q['pegadinha'],
      'bancaIntent': q['bancaIntent'],
      'examBoard': q['examBoard'],
    };
  }

  Future<void> _createCardFromCurrent() async {
    if (sessionQuestions.isEmpty) return;
    final id = sessionQuestions[qIndex]['id']?.toString();
    if (id == null) return;
    try {
      final data = await apiClient.post('/api/flashcards/from-question', {
        'questionId': id,
        'count': 4,
      });
      if (!mounted) return;
      final n = (data as Map)['created'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(n == 0 ? 'Sem eixos para card' : 'Card(s) criados: $n')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Widget _debriefForCurrent() {
    final q = sessionQuestions[qIndex];
    final s = q['subject']?.toString() ?? '';
    final t = q['topic']?.toString() ?? '';
    return ResolutionDebrief(
      question: q,
      professor: _professor,
      trailing: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          TextButton(
            onPressed: () => context.go(
              '/adaptativo?subject=${Uri.encodeComponent(s)}&topic=${Uri.encodeComponent(t)}',
            ),
            child: const Text('Treinar este tópico'),
          ),
          TextButton(
            onPressed: _createCardFromCurrent,
            child: const Text('Criar card'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return EmptyState(
        title: 'Sessão indisponível',
        subtitle: 'API offline. Reabra o atalho PAES MED AI na Desktop.',
        action: FilledButton(onPressed: _load, child: const Text('Tentar de novo')),
      );
    }
    if (plan == null) return const Center(child: CircularProgressIndicator());

    final phases = (plan!['sessionPlan'] as List? ?? [
      {'phase': 'theory', 'minutes': 20, 'title': 'Teoria do dia'},
      {'phase': 'questions', 'minutes': 30, 'title': 'Questões'},
      {'phase': 'revisions', 'minutes': 10, 'title': 'Revisão spaced'},
    ]);
    final study = plan!['studyToday'] as Map<String, dynamic>?;
    final current = Map<String, dynamic>.from(phases[phaseIndex.clamp(0, phases.length - 1)] as Map);
    final phaseName = current['phase']?.toString() ?? '';
    final isQuestions = phaseName == 'questions';
    final isTheory = phaseName == 'theory';
    final isRevisions = phaseName == 'revisions' || phaseName == 'review';
    final snippets = (plan!['theorySnippets'] as List? ??
            (plan!['phases'] as Map?)?['theorySnippets'] as List? ??
            [])
        .map((e) => e.toString())
        .toList();
    final clockMs = sw.elapsedMilliseconds + _resumeElapsedMs;
    final clockElapsed = Duration(milliseconds: clockMs);
    final clock =
        '${clockElapsed.inMinutes.toString().padLeft(2, '0')}:${(clockElapsed.inSeconds % 60).toString().padLeft(2, '0')}';

    return Focus(
      focusNode: focusNode,
      onKeyEvent: _onKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
        children: [
          PageHeader(
            eyebrow: 'Foco',
            title: 'Sessão guiada',
            subtitle: sessionComplete
                ? 'Sessão completa — próximos passos'
                : study == null
                    ? 'Gere um plano para calibrar a meta.'
                    : 'Meta: ${study['subject']} · ${study['topic']}',
            trailing: started
                ? SurfacePanel(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      paused ? 'Pausado $clock' : clock,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  )
                : null,
          ),
          if (sessionComplete) ...[
            _sessionEndPanel(context),
            FilledButton.tonal(
              onPressed: () async {
                await _clearCheckpoint();
                setState(() {
                  sessionComplete = false;
                  phaseIndex = 0;
                  qIndex = 0;
                  answeredIds.clear();
                  sessionErrors.clear();
                  missTopics.clear();
                  correctCount = 0;
                  flashcardsCreated = 0;
                  sessionQuestions = [];
                });
              },
              child: const Text('Recomeçar (mesma meta)'),
            ),
          ] else if (pendingCheckpoint != null && !started) ...[
            SurfacePanel(
              margin: const EdgeInsets.only(bottom: 12),
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.45),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sessão em andamento encontrada'),
                subtitle: Text('Salva em ${pendingCheckpoint!['updatedAt'] ?? '—'}'),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    TextButton(onPressed: restoring ? null : _clearCheckpoint, child: const Text('Descartar')),
                    FilledButton(onPressed: restoring ? null : _restoreCheckpoint, child: const Text('Continuar')),
                  ],
                ),
              ),
            ),
          ],
          if (!sessionComplete) ...[
          TrainingBasisBanner(
            basis: (plan!['statsBasis'] as Map?)?['basis']?.toString() ??
                (plan!['preferOfficial'] == true ? 'oficial' : 'treino'),
            officialCount: (plan!['officialCount'] as int?) ??
                (plan!['statsBasis'] as Map?)?['officialCount'] as int?,
            message: plan!['warning']?.toString(),
            showLibraryCta: ((plan!['officialCount'] as int?) ?? 0) == 0,
            areaKey: 'sessao',
          ),
          const SizedBox(height: 8),
          PhaseProgressBar(
            phases: [
              for (final ph in phases)
                ((ph as Map)['title']?.toString() ?? 'Fase').split(' ').take(2).join(' '),
            ],
            currentIndex: phaseIndex.clamp(0, phases.length - 1),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 12),
            child: Text(
              started
                  ? (paused ? 'Pausado · ${current['title']}' : '${current['title']} · ${current['minutes'] ?? '?'} min')
                  : '20 teoria → 30 questões → 10 revisão',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                  ),
            ),
          ),
          if (!started)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Iniciar sessão'),
                ),
              ],
            )
          else ...[
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonal(onPressed: _togglePause, child: Text(paused ? 'Continuar' : 'Pausar')),
                if (!isQuestions || sessionQuestions.isEmpty)
                  FilledButton(
                    onPressed: () async {
                      if (isQuestions && sessionQuestions.isEmpty) {
                        await _enterQuestionsPhase();
                      } else if (isRevisions && sessionCards.isEmpty && !revisionUsingQuestions) {
                        await _enterRevisionsPhase();
                      } else if (isRevisions && revisionUsingQuestions && sessionQuestions.isEmpty) {
                        await _enterRevisionsPhase();
                      } else {
                        await _nextPhase();
                      }
                    },
                    child: Text(
                      isQuestions && sessionQuestions.isEmpty
                          ? 'Carregar questões'
                          : isRevisions && sessionCards.isEmpty && sessionQuestions.isEmpty
                              ? 'Carregar revisões'
                              : 'Próxima fase',
                    ),
                  ),
                FilledButton.tonal(onPressed: _exportDay, child: const Text('Exportar')),
              ],
            ),
            if (isTheory) ...[
              const Divider(height: 24),
              Text('Teoria do edital', style: Theme.of(context).textTheme.titleMedium),
              if (snippets.isEmpty)
                const Text('Sem tópicos de syllabus para o assunto do dia — rode Sync syllabus na Biblioteca.')
              else
                for (final s in snippets.take(10))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2, right: 8),
                          child: Icon(Icons.menu_book_outlined, size: 18),
                        ),
                        Expanded(child: SelectableText(s)),
                      ],
                    ),
                  ),
              const Text('Leia os trechos acima (~20 min) e avance para as questões.'),
              if (study != null)
                FutureBuilder(
                  future: apiClient.get(
                    '/api/media/articles',
                    {
                      'subject': study['subject']?.toString() ?? '',
                      'topic': study['topic']?.toString() ?? '',
                    },
                  ),
                  builder: (context, snap) {
                    if (!snap.hasData || snap.data is! Map) return const SizedBox.shrink();
                    final map = Map<String, dynamic>.from(snap.data as Map);
                    final items = (map['items'] as List? ?? []).whereType<Map>().toList();
                    if (items.isEmpty) return const SizedBox.shrink();
                    final first = Map<String, dynamic>.from(items.first);
                    final url = first['url']?.toString() ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: OutlinedButton.icon(
                        onPressed: url.isEmpty
                            ? null
                            : () async {
                                try {
                                  await apiClient.post(
                                    '/api/media/open',
                                    {'url': url, 'kind': 'article'},
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$e')),
                                  );
                                }
                              },
                        icon: const Icon(Icons.article_outlined),
                        label: Text(
                          'Leitura de reforço · ${first['title'] ?? 'abrir'} (não é banca)',
                        ),
                      ),
                    );
                  },
                ),
            ],
            if ((isQuestions || (isRevisions && revisionUsingQuestions)) && sessionQuestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              SurfacePanel(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              Text(
                'Questão ${qIndex + 1}/${sessionQuestions.length} · acertos $correctCount/${answeredIds.length}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: sessionQuestions.isEmpty ? 0 : (qIndex + 1) / sessionQuestions.length,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                sessionQuestions[qIndex]['statement']?.toString() ?? '',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < (sessionQuestions[qIndex]['options'] as List? ?? []).length; i++)
                RadioListTile<int>(
                  value: i,
                  groupValue: selected,
                  onChanged: revealed ? null : (v) => setState(() => selected = v),
                  title: Text('${'ABCDE'[i]}) ${(sessionQuestions[qIndex]['options'] as List)[i]}'),
                ),
              if (revealed) ...[
                Text(
                  selected == ((sessionQuestions[qIndex]['correctIndex'] as int?) ?? sessionQuestions[qIndex]['correct_index'])
                      ? 'Correto.'
                      : 'Incorreto. Gabarito: ${'ABCDE'[((sessionQuestions[qIndex]['correctIndex'] as int?) ?? 0).clamp(0, 4)]}',
                  style: TextStyle(
                    color: selected ==
                            ((sessionQuestions[qIndex]['correctIndex'] as int?) ?? sessionQuestions[qIndex]['correct_index'])
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.tertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (pendingErrorPick) ...[
                  const SizedBox(height: 8),
                  const Text('Tipo de erro:'),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final t in _errorTypes)
                        ChoiceChip(
                          label: Text(t),
                          selected: errorType == t,
                          onSelected: (_) => setState(() => errorType = t),
                        ),
                    ],
                  ),
                  FilledButton(onPressed: _confirmErrorAndSave, child: const Text('Salvar erro e ver explicação')),
                ],
                if (!pendingErrorPick &&
                    selected !=
                        ((sessionQuestions[qIndex]['correctIndex'] as int?) ??
                            sessionQuestions[qIndex]['correct_index']) &&
                    _professor != null) ...[
                  const SizedBox(height: 12),
                  _debriefForCurrent(),
                ],
                if (!pendingErrorPick &&
                    selected ==
                        ((sessionQuestions[qIndex]['correctIndex'] as int?) ??
                            sessionQuestions[qIndex]['correct_index']) &&
                    (sessionQuestions[qIndex]['resolutionQuality']?.toString() == 'real' ||
                        (_professor?['resolutionQuality']?.toString() == 'real'))) ...[
                  const SizedBox(height: 12),
                  _debriefForCurrent(),
                ],
                if (!pendingErrorPick && lastRemediation != null && lastRemediation!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(lastRemediation!['title']?.toString() ?? 'Remediação', style: const TextStyle(fontWeight: FontWeight.w700)),
                  for (final s in (lastRemediation!['steps'] as List? ?? []))
                    Text('• $s'),
                  Text(lastRemediation!['practiceHint']?.toString() ?? '', style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (!revealed)
                    FilledButton(onPressed: selected == null ? null : _submitAnswer, child: const Text('Responder (Enter)')),
                  if (revealed && !pendingErrorPick)
                    FilledButton(onPressed: _nextQuestion, child: const Text('Próxima (N)')),
                ],
              ),
                  ],
                ),
              ),
            ] else if (isQuestions && started)
              const Text('Toque em “Carregar questões” (1–5 + Enter).'),
            if (isRevisions && !revisionUsingQuestions) ...[
              const Divider(height: 24),
              Text('Revisão prática', style: Theme.of(context).textTheme.titleMedium),
              if (sessionCards.isEmpty)
                Text(
                  'Sem flashcards due. Revisões na fila: ${((plan?['revisions'] as List?) ?? []).length}. '
                  'Toque em “Carregar revisões” para praticar questões dos tópicos, ou avance a fase.',
                )
              else ...[
                Text('Card ${cardIndex + 1}/${sessionCards.length} · feitos $cardsDone'),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: Text(sessionCards[cardIndex]['front']?.toString() ?? ''),
                    subtitle: cardFlipped
                        ? Text(sessionCards[cardIndex]['back']?.toString() ?? '')
                        : const Text('Toque para revelar'),
                    onTap: () => setState(() => cardFlipped = !cardFlipped),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.tonal(onPressed: () => setState(() => cardFlipped = true), child: const Text('Revelar')),
                    FilledButton(onPressed: () => _reviewCard(remembered: true), child: const Text('Lembrei')),
                    OutlinedButton(onPressed: () => _reviewCard(remembered: false), child: const Text('Esqueci')),
                  ],
                ),
              ],
            ],
            if (isRevisions && revisionUsingQuestions && sessionQuestions.isEmpty)
              const Text('Toque em “Carregar revisões” para praticar questões dos tópicos due.'),
          ],
          ], // !sessionComplete
          if (exportMsg != null) ...[
            const SizedBox(height: 8),
            Text('Pacote: $exportMsg', style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
