import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/widgets/media_reinforcement.dart';
import '../../../core/widgets/resolution_debrief.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/training_basis_banner.dart';
import '../../../core/ux_copy.dart';
import '../../../core/widgets/theory_read_sheet.dart';
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
  String? checkpointLoadError;
  String? checkpointSaveError;
  String? questionsLoadError;
  String? questionsPartialLoadNote;
  List<String> _lastQuestionBodyIds = [];
  /// Ciclo AI: painel final da sessão (após último bloco).
  bool sessionComplete = false;
  String? scheduleGapsError;
  String? answerSaveError;
  String? cardReviewError;
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
      String? cpErr;
      try {
        final raw = await apiClient.get('/api/session/checkpoint');
        cp = (raw as Map)['checkpoint'] as Map<String, dynamic>?;
        if (cp != null) cp = Map<String, dynamic>.from(cp);
      } catch (e) {
        cpErr = humanApiError(e, fallback: 'Não deu para recuperar a sessão salva.');
      }
      setState(() {
        plan = Map<String, dynamic>.from(data as Map);
        pendingCheckpoint = cp != null && cp['started'] == true ? cp : null;
        checkpointLoadError = cpErr;
      });
    } catch (e) {
      setState(() => error = humanApiError(e, fallback: 'Não deu para montar a sessão. Tente de novo.'));
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
      if (mounted && checkpointSaveError != null) {
        setState(() => checkpointSaveError = null);
      }
    } catch (e) {
      if (!mounted) return;
      setState(
        () => checkpointSaveError = humanApiError(
          e,
          fallback: 'Não foi possível salvar progresso da sessão.',
        ),
      );
    }
  }

  String _checkpointLabel(Map cp) {
    final phase = cp['phaseName']?.toString() ?? '';
    final phaseLabel = switch (phase) {
      'theory' => 'Teoria',
      'questions' => 'Questões',
      'revisions' || 'review' || 'cards' => 'Revisão',
      _ => phase.isEmpty ? 'Sessão' : phase,
    };
    final q = (cp['qIndex'] as num?)?.toInt();
    final correct = (cp['correctCount'] as num?)?.toInt();
    final parts = <String>[phaseLabel];
    if (phase == 'questions' && q != null) {
      parts.add('item ${q + 1}');
    }
    if (correct != null && correct > 0) {
      parts.add('$correct acerto(s)');
    }
    final at = cp['updatedAt']?.toString();
    if (at != null && at.isNotEmpty) {
      parts.add('salva ${at.length > 16 ? at.substring(0, 16) : at}');
    }
    return parts.join(' · ');
  }

  Future<void> _clearCheckpoint() async {
    try {
      await apiClient.delete('/api/session/checkpoint');
      setState(() {
        pendingCheckpoint = null;
        checkpointLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            humanApiError(e, fallback: 'Não deu para descartar a sessão salva.'),
          ),
        ),
      );
    }
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
    var failed = 0;
    final batch = ids.take(12).toList();
    _lastQuestionBodyIds = batch.map((e) => e.toString()).toList();
    for (final raw in batch) {
      try {
        final q = await apiClient.get('/api/questions/${raw.toString()}');
        out.add(Map<String, dynamic>.from(q as Map));
      } catch (_) {
        failed++;
      }
    }
    setState(() {
      sessionQuestions = out;
      qIndex = 0;
      selected = null;
      revealed = false;
      pendingErrorPick = false;
      errorType = 'conceito';
      questionsLoadError = out.isEmpty && batch.isNotEmpty
          ? 'Não foi possível carregar as questões desta fase. Verifique se o app está rodando e tente de novo.'
          : null;
      questionsPartialLoadNote = failed > 0 && out.isNotEmpty
          ? '$failed de ${batch.length} questões não carregaram. Toque em Recarregar para tentar de novo.'
          : null;
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
      scheduleGapsError = null;
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
    var fetchFailures = 0;
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
      } catch (_) {
        fetchFailures++;
      }
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
        } catch (_) {
          fetchFailures++;
        }
      }
    }
    setState(() {
      sessionCards = [];
      revisionUsingQuestions = true;
      questionsLoadError = ids.isEmpty && fetchFailures > 0
          ? 'Não foi possível buscar questões das revisões. Tente de novo.'
          : null;
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
    String? gapsErr;
    if (gaps.isNotEmpty) {
      try {
        await apiClient.post('/api/simulations/schedule-gaps', {
          'gaps': [
            for (final g in gaps) {'subject': g['subject'], 'topic': g['topic']},
          ],
        });
      } catch (e) {
        gapsErr = humanApiError(e, fallback: 'Lacunas não agendadas na fila — abra a Fila para revisar.');
      }
    }
    if (!mounted) return;
    setState(() {
      started = false;
      sessionComplete = true;
      scheduleGapsError = gapsErr;
    });
  }

  Future<void> _closeStudyDay() async {
    try {
      await apiClient.post('/api/study/day-close', {});
      ref.read(refreshTickProvider.notifier).state++;
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            humanApiError(e, fallback: 'Não foi possível encerrar o dia a partir da sessão.'),
          ),
        ),
      );
    }
  }

  Widget _sessionEndPanel(BuildContext context) {
    final gaps = _sessionGaps;
    final first = gaps.isNotEmpty ? gaps.first : null;
    final officialInPack = plan?['officialInPack'];
    final toppedOff = plan?['toppedOff'] == true;
    final yearWidened = plan?['yearWidened'] == true;
    final total = answeredIds.length;
    final wrong = (total - correctCount).clamp(0, total);
    final cs = Theme.of(context).colorScheme;
    final study = plan?['studyToday'] as Map? ?? {};
    final subj = study['subject']?.toString() ?? '';
    final top = study['topic']?.toString() ?? '';
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
          const SizedBox(height: 4),
          Text(
            gaps.isEmpty
                ? 'Boa volta. O próximo passo natural é a Fila do dia.'
                : 'Houve erro neste bloco — a Fila e o treino do tópico fraco resolvem bem.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.f72,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(Icons.check_circle_rounded, size: 18, color: cs.primary),
                label: Text('$correctCount acerto${correctCount == 1 ? '' : 's'}'),
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                avatar: Icon(Icons.radio_button_unchecked, size: 18, color: cs.tertiary),
                label: Text('$wrong erro${wrong == 1 ? '' : 's'}'),
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                avatar: const Icon(Icons.quiz_outlined, size: 18),
                label: Text('$total respondida${total == 1 ? '' : 's'}'),
                visualDensity: VisualDensity.compact,
              ),
              if (flashcardsCreated > 0)
                Chip(
                  avatar: Icon(Icons.style_outlined, size: 18, color: cs.primary),
                  label: Text('$flashcardsCreated cartão${flashcardsCreated == 1 ? '' : 'ões'}'),
                  visualDensity: VisualDensity.compact,
                ),
              if (cardsDone > 0)
                Chip(
                  avatar: const Icon(Icons.replay_rounded, size: 18),
                  label: Text('$cardsDone revisão${cardsDone == 1 ? '' : 'ões'}'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (officialInPack != null || toppedOff || yearWidened)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  'Detalhe do bloco',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      [
                        if (officialInPack != null) 'Oficiais nesta seleção: $officialInPack',
                        if (toppedOff) 'Completamos com oficiais do acervo',
                        if (yearWidened) 'Janela de anos ampliada para achar itens',
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          if (scheduleGapsError != null) ...[
            QuietEmpty(
              message: scheduleGapsError!,
              action: TextButton(
                onPressed: () => context.go('/fila'),
                child: const Text('Abrir fila'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (gaps.isEmpty)
            const Text('Nenhum erro neste bloco — veja o que vem a seguir na Fila.')
          else ...[
            Text(
              'Tópicos fracos',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final g in gaps.take(6))
                  ActionChip(
                    label: Text('${g['subject']} · ${g['topic']}'),
                    onPressed: () {
                      final s = Uri.encodeComponent(g['subject'] ?? '');
                      final t = Uri.encodeComponent(g['topic'] ?? '');
                      context.go('/adaptativo?subject=$s&topic=$t');
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Divider(color: cs.outlineVariant.withOpacity(0.5)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => context.go('/fila'),
            icon: const Icon(Icons.playlist_play_rounded),
            label: const Text('Continuar na Fila'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (first != null)
                OutlinedButton(
                  onPressed: () {
                    final s = Uri.encodeComponent(first['subject'] ?? '');
                    final t = Uri.encodeComponent(first['topic'] ?? '');
                    context.go('/adaptativo?subject=$s&topic=$t');
                  },
                  child: const Text('Treinar tópico fraco'),
                ),
              if (subj.isNotEmpty && top.isNotEmpty)
                TextButton(
                  onPressed: () => openTheoryReadSheet(
                    context,
                    subject: subj,
                    topic: top,
                  ),
                  child: const Text('Ler teoria'),
                ),
              TextButton(
                onPressed: () => context.go('/flashcards?due=1'),
                child: const Text('Cartões'),
              ),
              TextButton(
                onPressed: () => context.go('/progresso'),
                child: const Text('Relevo'),
              ),
              TextButton(
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
      HapticFeedback.mediumImpact();
      setState(() {
        revealed = true;
        pendingErrorPick = true;
      });
      return;
    }
    HapticFeedback.lightImpact();
    await _persistAnswer(q, correct: true, type: null);
  }

  Future<void> _persistAnswer(Map<String, dynamic> q, {required bool correct, String? type}) async {
    try {
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
        answerSaveError = null;
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
            content: Text('Cartão criado para revisar amanhã.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(
        () => answerSaveError = humanApiError(
          e,
          fallback: 'Resposta não gravada — progresso local incompleto.',
        ),
      );
    }
  }

  Future<void> _confirmErrorAndSave() async {
    if (sessionQuestions.isEmpty) return;
    HapticFeedback.selectionClick();
    await _persistAnswer(sessionQuestions[qIndex], correct: false, type: errorType);
  }

  Future<void> _nextQuestion() async {
    HapticFeedback.selectionClick();
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
        if (mounted) setState(() => cardReviewError = null);
      } catch (e) {
        if (!mounted) return;
        setState(
          () => cardReviewError = humanApiError(
            e,
            fallback: 'Revisão do cartão não registrada.',
          ),
        );
      }
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
    final phaseName = phase['phase']?.toString() ?? '';

    // Fase theory: Enter avança (Ciclo CF)
    if (phaseName == 'theory') {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        unawaited(_nextPhase());
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Fase cards (revisão prática) — Space/L/E só em cards reais (Ciclo CA)
    final isRevPhase =
        phaseName == 'revisions' || phaseName == 'review' || phaseName == 'cards';
    if (isRevPhase && !revisionUsingQuestions) {
      if (sessionCards.isEmpty) return KeyEventResult.ignored;
      if (event.logicalKey == LogicalKeyboardKey.space) {
        setState(() => cardFlipped = !cardFlipped);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyL ||
          event.logicalKey == LogicalKeyboardKey.digit1 ||
          event.logicalKey == LogicalKeyboardKey.numpad1) {
        unawaited(_reviewCard(remembered: true));
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyE ||
          event.logicalKey == LogicalKeyboardKey.digit2 ||
          event.logicalKey == LogicalKeyboardKey.numpad2) {
        unawaited(_reviewCard(remembered: false));
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Ciclo CI: revisão com questões reusa teclado da fase questions
    final questionsKeyboard = phaseName == 'questions' ||
        (isRevPhase && revisionUsingQuestions && sessionQuestions.isNotEmpty);
    if (!questionsKeyboard) return KeyEventResult.ignored;

    // Tipo de erro após miss: 1–5 + Enter (Ciclo CA)
    if (pendingErrorPick) {
      final errKeys = <LogicalKeyboardKey, String>{
        LogicalKeyboardKey.digit1: _errorTypes[0],
        LogicalKeyboardKey.digit2: _errorTypes[1],
        LogicalKeyboardKey.digit3: _errorTypes[2],
        LogicalKeyboardKey.digit4: _errorTypes[3],
        LogicalKeyboardKey.digit5: _errorTypes[4],
        LogicalKeyboardKey.numpad1: _errorTypes[0],
        LogicalKeyboardKey.numpad2: _errorTypes[1],
        LogicalKeyboardKey.numpad3: _errorTypes[2],
        LogicalKeyboardKey.numpad4: _errorTypes[3],
        LogicalKeyboardKey.numpad5: _errorTypes[4],
      };
      final pick = errKeys[event.logicalKey];
      if (pick != null) {
        setState(() => errorType = pick);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        unawaited(_confirmErrorAndSave());
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (revealed) {
      if (event.logicalKey == LogicalKeyboardKey.keyN ||
          event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
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
      LogicalKeyboardKey.numpad1: 0,
      LogicalKeyboardKey.numpad2: 1,
      LogicalKeyboardKey.numpad3: 2,
      LogicalKeyboardKey.numpad4: 3,
      LogicalKeyboardKey.numpad5: 4,
    };
    if (keys.containsKey(event.logicalKey)) {
      setState(() => selected = keys[event.logicalKey]);
      return KeyEventResult.handled;
    }
    if ((event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) &&
        selected != null) {
      _submitAnswer();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String _keyboardHintForPhase(String phaseName) {
    if (!started || sessionComplete) return '';
    final isRevPhase =
        phaseName == 'revisions' || phaseName == 'review' || phaseName == 'cards';
    if (phaseName == 'theory') return ' · Enter avança';
    if (isRevPhase && !revisionUsingQuestions) {
      return ' · Espaço vira o cartão';
    }
    if (pendingErrorPick) return ' · Escolha o tipo de erro';
    if (revealed) return ' · Enter próxima';
    if (phaseName == 'questions' || (isRevPhase && revisionUsingQuestions)) {
      return ' · 1–5 escolhe · Enter confirma';
    }
    return '';
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
    buf.writeln('Respondidas: ${answeredIds.length} · Acertos: $correctCount · Cartões: $cardsDone');
    if (sessionErrors.isNotEmpty) {
      buf.writeln('Erros (tipos): ${sessionErrors.join(', ')}');
    }
    for (final id in answeredIds) {
      buf.writeln('- $id');
    }
    try {
      final data = await apiClient.post('/api/study/export-day', {
        'markdown': buf.toString(),
      });
      final map = Map<String, dynamic>.from(data as Map);
      final path = map['path']?.toString() ?? '';
      setState(() => exportMsg = path.isNotEmpty ? path : map['dir']?.toString() ?? 'exportado');
      if (path.isNotEmpty) {
        try {
          final parent = p.dirname(path);
          await apiClient.post('/api/library/open-path', {'path': parent});
        } catch (e) {
          setState(
            () => exportMsg =
                '${exportMsg ?? 'Exportado'} · ${humanApiError(e, fallback: 'Pasta de export não abriu.')}',
          );
        }
      }
    } catch (e) {
      setState(() => exportMsg = humanApiError(e, fallback: 'Não deu para exportar o dia.'));
    }
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
        SnackBar(content: Text(n == 0 ? 'Sem eixos para cartão' : 'Cartões criados: $n')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para criar o cartão.'))),
      );
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
          if (s.isNotEmpty && t.isNotEmpty)
            FilledButton.tonal(
              onPressed: () => openTheoryReadSheet(
                context,
                subject: s,
                topic: t,
                trainPath:
                    '/adaptativo?subject=${Uri.encodeComponent(s)}&topic=${Uri.encodeComponent(t)}',
              ),
              child: const Text('Ler teoria'),
            ),
          TextButton(
            onPressed: () => context.go(
              '/adaptativo?subject=${Uri.encodeComponent(s)}&topic=${Uri.encodeComponent(t)}',
            ),
            child: const Text('Treinar este tópico'),
          ),
          TextButton(
            onPressed: () => context.go('/progresso'),
            child: const Text('Este tópico no relevo'),
          ),
          TextButton(
            onPressed: _createCardFromCurrent,
            child: const Text('Criar cartão'),
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
        subtitle: error!,
        action: FilledButton(onPressed: _load, child: const Text('Tentar de novo')),
      );
    }
    if (plan == null) {
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

    final phases = (plan!['sessionPlan'] as List? ?? [
      {'phase': 'theory', 'minutes': 20, 'title': 'Teoria do dia'},
      {'phase': 'questions', 'minutes': 30, 'title': 'Questões'},
      {'phase': 'revisions', 'minutes': 10, 'title': 'Revisão'},
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
            eyebrow: 'Sessão',
            title: 'Sessão guiada',
            subtitle: sessionComplete
                ? 'Sessão completa — próximos passos'
                : study == null
                    ? 'Inicie a sessão para montar o plano de estudo de hoje.'
                    : 'Meta: ${study['subject']} · ${study['topic']}${started ? _keyboardHintForPhase(phaseName) : ''}',
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
          ] else if (checkpointLoadError != null && !started) ...[
            QuietEmpty(
              message: checkpointLoadError!,
              action: TextButton(onPressed: _load, child: const Text('Tentar')),
            ),
            const SizedBox(height: 8),
          ] else if (pendingCheckpoint != null && !started) ...[
            SessionResumeBanner(
              phaseName: pendingCheckpoint!['phaseName']?.toString() ?? '',
              subtitle: _checkpointLabel(pendingCheckpoint!),
              onContinue: restoring ? () {} : () => unawaited(_restoreCheckpoint()),
              onDiscard: restoring ? null : () => unawaited(_clearCheckpoint()),
            ),
          ],
          if (checkpointSaveError != null && started) ...[
            QuietEmpty(
              message: checkpointSaveError!,
              action: TextButton(
                onPressed: () => unawaited(_saveCheckpoint()),
                child: const Text('Tentar'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (questionsLoadError != null) ...[
            QuietEmpty(
              message: questionsLoadError!,
              action: FilledButton.tonal(
                onPressed: () => unawaited(
                  revisionUsingQuestions ? _enterRevisionsPhase() : _enterQuestionsPhase(),
                ),
                child: const Text('Tentar de novo'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => context.go('/biblioteca'),
                  child: const Text('Biblioteca'),
                ),
              ),
            ),
          ],
          if (questionsPartialLoadNote != null) ...[
            QuietEmpty(
              message: questionsPartialLoadNote!,
              action: TextButton(
                onPressed: _lastQuestionBodyIds.isEmpty
                    ? null
                    : () => unawaited(_loadQuestionBodies(_lastQuestionBodyIds)),
                child: const Text('Recarregar'),
              ),
            ),
            const SizedBox(height: 8),
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
                    color: Theme.of(context).colorScheme.onSurface.f72,
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
                FilledButton.tonal(onPressed: _exportDay, child: const Text('Exportar pacote do dia')),
              ],
            ),
            if (isTheory) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Text(
                    'Teoria do edital',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Text(
                    snippets.isEmpty ? 'Passo 1 de 2' : 'Passo 1 de 2 · ler',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.45,
                  minHeight: 4,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 12),
              if (snippets.isEmpty)
                QuietEmpty(
                  message:
                      'Sem teoria do edital para o assunto de hoje. Atualize o edital na Biblioteca.',
                  action: FilledButton.tonal(
                    onPressed: () => context.go('/biblioteca'),
                    child: const Text('Abrir Biblioteca'),
                  ),
                )
              else ...[
                for (var si = 0; si < (snippets.length > 10 ? 10 : snippets.length); si++)
                  SurfacePanel(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${si + 1} de ${snippets.length > 10 ? 10 : snippets.length}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: SelectableText(snippets[si].toString()),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const Text('Leia os trechos acima (~20 min) e avance para as questões.'),
              if (study != null)
                MediaReinforcement(
                  subject: study['subject']?.toString() ?? '',
                  topic: study['topic']?.toString() ?? '',
                  compact: true,
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
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0,
                    end: sessionQuestions.isEmpty ? 0 : (qIndex + 1) / sessionQuestions.length,
                  ),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: StatementView(
                    text: sessionQuestions[qIndex]['statement']?.toString() ?? '',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              StaggeredFadeIn(
                children: [
                  for (var i = 0; i < (sessionQuestions[qIndex]['options'] as List? ?? []).length; i++)
                    Builder(
                      builder: (_) {
                        final correctIdx = (sessionQuestions[qIndex]['correctIndex'] as int?) ??
                            (sessionQuestions[qIndex]['correct_index'] as int?);
                        bool? reveal;
                        if (revealed) {
                          if (i == correctIdx) {
                            reveal = true;
                          } else if (i == selected) {
                            reveal = false;
                          }
                        }
                        return ChoiceOptionTile(
                          index: i,
                          label: '${(sessionQuestions[qIndex]['options'] as List)[i]}',
                          selected: selected == i,
                          enabled: !revealed,
                          revealCorrect: reveal,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => selected = i);
                          },
                        );
                      },
                    ),
                ],
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
                          label: Text(errorTypeLabelPt(t)),
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
              if (answerSaveError != null) ...[
                const SizedBox(height: 8),
                QuietEmpty(
                  message: answerSaveError!,
                  action: TextButton(
                    onPressed: () {
                      final q = sessionQuestions[qIndex];
                      final correctIdx = (q['correctIndex'] as int?) ?? (q['correct_index'] as int?);
                      final correct = selected == correctIdx;
                      if (pendingErrorPick) {
                        unawaited(_confirmErrorAndSave());
                      } else if (revealed) {
                        unawaited(_persistAnswer(q, correct: correct, type: correct ? null : errorType));
                      } else {
                        unawaited(_submitAnswer());
                      }
                    },
                    child: const Text('Tentar'),
                  ),
                ),
              ],
                  ],
                ),
              ),
            ] else if (isQuestions && started)
              QuietEmpty(
                message: 'Questões ainda não carregadas. Toque no botão abaixo ou use 1–5 + Enter.',
                action: FilledButton.tonal(
                  onPressed: () => unawaited(_enterQuestionsPhase()),
                  child: const Text('Carregar questões'),
                ),
              ),
            if (isRevisions && !revisionUsingQuestions) ...[
              const Divider(height: 24),
              const SectionLabel('Revisão prática'),
              if (sessionCards.isEmpty)
                QuietEmpty(
                  message:
                      'Nenhum cartão para revisar agora (${((plan?['revisions'] as List?) ?? []).length} '
                      'assunto(s) na fila). Carregue revisões para praticar com questões.',
                  action: FilledButton.tonal(
                    onPressed: () => unawaited(_enterRevisionsPhase()),
                    child: const Text('Carregar revisões'),
                  ),
                )
              else ...[
                Text('Cartão ${cardIndex + 1}/${sessionCards.length} · feitos $cardsDone'),
                const SizedBox(height: 8),
                SurfacePanel(
                  padding: EdgeInsets.zero,
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
                    FilledButton.tonal(onPressed: () => setState(() => cardFlipped = true), child: const Text('Revelar (Space)')),
                    FilledButton(onPressed: () => _reviewCard(remembered: true), child: const Text('Lembrei (L)')),
                    OutlinedButton(onPressed: () => _reviewCard(remembered: false), child: const Text('Esqueci (E)')),
                  ],
                ),
                if (cardReviewError != null) ...[
                  const SizedBox(height: 8),
                  QuietEmpty(
                    message: cardReviewError!,
                    action: TextButton(
                      onPressed: () => setState(() => cardReviewError = null),
                      child: const Text('Tentar de novo'),
                    ),
                  ),
                ],
              ],
            ],
            if (isRevisions && revisionUsingQuestions && sessionQuestions.isEmpty)
              QuietEmpty(
                message: 'Sem questões carregadas para revisar. Toque para buscar questões dos tópicos.',
                action: FilledButton.tonal(
                  onPressed: () => unawaited(_enterRevisionsPhase()),
                  child: const Text('Carregar revisões'),
                ),
              ),
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
