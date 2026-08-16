import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/widgets/media_reinforcement.dart';
import '../../../core/widgets/resolution_debrief.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/tour_overlay.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        TourOverlay.maybeShow(
          context,
          key: 'tour_estudar_v1',
          title: 'Estudar',
          body: 'Aperte "Estudar agora" e o sistema escolhe tudo pra voce: '
              'topico, questoes e revisao. Quer escolher? Toque em '
              '"Personalizar sessao" abaixo.',
          icon: Icons.school_rounded,
        );
      }
    });
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
        gapsErr = humanApiError(e, fallback: 'Tópicos para revisar não agendados na fila — abra a Fila para revisar.');
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
    final total = answeredIds.length;
    final wrong = (total - correctCount).clamp(0, total);
    final cs = Theme.of(context).colorScheme;
    final study = plan?['studyToday'] as Map? ?? {};
    final subj = study['subject']?.toString() ?? '';
    final top = study['topic']?.toString() ?? '';
    final pct = total > 0 ? (correctCount / total * 100).round() : 0;
    return SurfacePanel(
      margin: const EdgeInsets.only(bottom: 16),
      color: cs.primaryContainer.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pct >= 70 ? 'Bom trabalho!' : 'Bloco encerrado',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              if (total > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pct%',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            total > 0
                ? '$correctCount acerto${correctCount == 1 ? '' : 's'} · $wrong erro${wrong == 1 ? '' : 's'} · $total questão${total == 1 ? '' : 'ês'}'
                : 'Sessão encerrada.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: cs.onPrimaryContainer.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 14),
          _SessionInsightBanner(
            correctCount: correctCount,
            wrongCount: wrong,
            total: total,
            subject: subj,
            topic: top,
          ),
          if (gaps.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Revisar agora',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in gaps.take(3))
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
          const SizedBox(height: 20),
          TapScale(
            child: FilledButton.icon(
              onPressed: () => context.go('/fila'),
              icon: const Icon(Icons.playlist_play_rounded),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              label: const Text('Continuar na Fila', style: TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _closeStudyDay,
                child: const Text('Encerrar dia'),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () => context.go('/inicio'),
                child: const Text('Voltar ao Início'),
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
          await apiClient.openPath(parent);
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
    final cs = Theme.of(context).colorScheme;
    if (error != null) {
      return EmptyState(
        icon: Icons.school_outlined,
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
      {'phase': 'questions', 'minutes': 40, 'title': 'Estudar'},
      {'phase': 'revisions', 'minutes': 10, 'title': 'Debrief'},
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
    // Pulse no último minuto da fase atual (quando faltam ≤ 60s e > 0s)
    final phaseMinutes = (current['minutes'] as num?)?.toInt() ?? 0;
    final remainingSec = phaseMinutes * 60 - clockElapsed.inSeconds;
    final lastMinute = started && !paused && phaseMinutes > 0 && remainingSec > 0 && remainingSec <= 60;

    return ListView(
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
                ? _BreathingClock(
                    paused: paused,
                    clock: clock,
                    pulse: lastMinute,
                  )
                : null,
          ),
          if (started)
            LinearProgressIndicator(
              value: (qIndex + (answeredIds.isNotEmpty ? 1 : 0)) /
                  (sessionQuestions.isEmpty ? 1 : sessionQuestions.length),
              minHeight: 4,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(cs.primary),
              borderRadius: BorderRadius.circular(2),
            )
          else
            const SizedBox.shrink(),
          const SizedBox(height: 16),
          if (sessionComplete) ...[
            _sessionEndPanel(context),
            TapScale(
              child: FilledButton.tonal(
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
          if (started)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(
                    paused ? 'Pausado' : '${current['title']}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(qIndex + cardsDone)}/${(sessionQuestions.length + sessionCards.length)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            )
          else
            _SessionStartCard(
              plan: plan,
              onStart: _start,
            ),
          if (started) ...[
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonal(onPressed: _togglePause, child: Text(paused ? 'Continuar' : 'Pausar')),
                if (!isQuestions || sessionQuestions.isEmpty)
                  TapScale(
                    child: FilledButton(
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
                  ),
                FilledButton.tonal(onPressed: _exportDay, child: const Text('Exportar pacote do dia')),
              ],
            ),
            // AnimatedSwitcher: transição suave (FadeTransition) entre fases
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: KeyedSubtree(
                key: ValueKey(phaseName),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isTheory) ...[
                      const Divider(height: 24),
                      Row(
                        children: [
                          Text(
                            'Teoria do edital',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    snippets.isEmpty ? 'Passo 1 de 2' : 'Passo 1 de 2 · ler',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 0.45),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 4,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
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
                StaggeredFadeIn(
                  key: const ValueKey('theory_snippets'),
                  children: [
                    for (var si = 0; si < (snippets.length > 10 ? 10 : snippets.length); si++)
                      SurfacePanel(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${si + 1} de ${snippets.length > 10 ? 10 : snippets.length}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
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
                key: ValueKey('question_panel_$qIndex'),
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
                    key: ValueKey('statement_$qIndex'),
                    text: sessionQuestions[qIndex]['statement']?.toString() ?? '',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              StaggeredFadeIn(
                key: ValueKey('options_$qIndex'),
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
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() => errorType = t);
                          },
                        ),
                    ],
                  ),
                  TapScale(
                    child: FilledButton(onPressed: _confirmErrorAndSave, child: const Text('Salvar erro e ver explicação')),
                  ),
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
                  Text(lastRemediation!['title']?.toString() ?? 'Reforço', style: const TextStyle(fontWeight: FontWeight.w700)),
                  for (final s in (lastRemediation!['steps'] as List? ?? []))
                    Text('• $s'),
                  SelectableText(
                    lastRemediation!['practiceHint']?.toString() ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.5,
                      color: cs.onSurface.withOpacity(0.75),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (!revealed)
                    TapScale(
                      child: FilledButton(onPressed: selected == null ? null : _submitAnswer, child: const Text('Responder (Enter)')),
                    ),
                  if (revealed && !pendingErrorPick)
                    TapScale(
                      child: FilledButton(onPressed: _nextQuestion, child: const Text('Próxima (N)')),
                    ),
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
                    TapScale(
                      child: FilledButton(onPressed: () => _reviewCard(remembered: true), child: const Text('Lembrei (L)')),
                    ),
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
                ),
              ),
            ),
          ],
          ], // !sessionComplete
          if (exportMsg != null) ...[
            const SizedBox(height: 8),
            Text(
              'Pacote: $exportMsg',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ],
    );
  }
}

/// Relógio da sessão com efeito de "breathing" quando pausado.
/// Pulsar suave (opacity 0.6 ↔ 1.0) indica que está pausado mas ativo.
/// Pulse (AnimatedScale) no último minuto da fase avisa que o tempo está acabando.
class _BreathingClock extends StatefulWidget {
  const _BreathingClock({required this.paused, required this.clock, this.pulse = false});
  final bool paused;
  final String clock;
  /// Pulse sutil quando faltam ≤ 60s na fase atual.
  final bool pulse;

  @override
  State<_BreathingClock> createState() => _BreathingClockState();
}

class _BreathingClockState extends State<_BreathingClock>
    with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.paused) _breath.repeat(reverse: true);
    if (widget.pulse && !widget.paused) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_BreathingClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paused != widget.paused) {
      if (widget.paused) {
        _breath.repeat(reverse: true);
      } else {
        _breath.stop();
        _breath.value = 1.0;
      }
    }
    if (oldWidget.pulse != widget.pulse) {
      if (widget.pulse && !widget.paused) {
        _pulse.repeat(reverse: true);
      } else {
        _pulse.stop();
        _pulse.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = widget.paused ? 'Pausado ${widget.clock}' : widget.clock;
    final color = widget.paused ? cs.tertiary : (widget.pulse ? cs.tertiary : cs.primary);
    final icon = widget.paused
        ? Icons.pause_circle_outline_rounded
        : (widget.pulse ? Icons.timer_3_outlined : Icons.timer_outlined);

    Widget content(Color c) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: c),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c,
                fontFeatures: const [FontFeature.tabularFigures()],
                letterSpacing: 0.2,
              ),
            ),
          ],
        );

    if (!widget.paused && !widget.pulse) {
      return SurfacePanel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: content(color),
      );
    }

    if (widget.pulse && !widget.paused) {
      // Pulse sutil (scale 1.0 ↔ 1.06) no último minuto da fase
      return AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_pulse.value);
          return SurfacePanel(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: AnimatedScale(
              scale: 1.0 + t * 0.06,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOut,
              child: content(color.withOpacity(0.7 + t * 0.3)),
            ),
          );
        },
      );
    }

    return AnimatedBuilder(
      animation: _breath,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_breath.value);
        return SurfacePanel(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: content(color.withOpacity(0.6 + t * 0.4)),
        );
      },
    );
  }
}

class _SessionInsightBanner extends StatelessWidget {
  const _SessionInsightBanner({
    required this.correctCount,
    required this.wrongCount,
    required this.total,
    required this.subject,
    required this.topic,
  });

  final int correctCount;
  final int wrongCount;
  final int total;
  final String subject;
  final String topic;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final acc = total > 0 ? correctCount / total : 0.0;

    String message;
    IconData icon;
    Color color;

    if (total == 0) {
      return const SizedBox.shrink();
    } else if (acc >= 0.8) {
      message = 'Excelente! Voce dominou $topic em $subject. '
          'Hora de tentar um topico novo ou um simulado completo.';
      icon = Icons.celebration_rounded;
      color = const Color(0xFF4CAF50);
    } else if (acc >= 0.6) {
      message = 'Bom ritmo em $topic! Revise os $wrongCount erro(s) e '
          'tente novamente amanha para consolidar.';
      icon = Icons.trending_up_rounded;
      color = cs.primary;
    } else if (acc >= 0.4) {
      message = 'Voce acertou $correctCount de $total em $topic. '
          'Leia a teoria antes de tentar de novo - vai fazer diferenca.';
      icon = Icons.menu_book_rounded;
      color = const Color(0xFFE8A04B);
    } else {
      message = 'Topico dificil: $topic em $subject. Nao desanime! '
          'Comece pela teoria e volte com calma.';
      icon = Icons.school_rounded;
      color = cs.error;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/// Cartao de inicio da sessao: resumo, 1 botao, personalizacao escondida.
class _SessionStartCard extends StatelessWidget {
  const _SessionStartCard({required this.plan, required this.onStart});
  final Map<String, dynamic>? plan;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final study = plan?['studyToday'] as Map? ?? {};
    final subj = study['subject']?.toString() ?? 'do seu plano';
    final top = study['topic']?.toString() ?? 'Tema do dia';
    final phases = (plan?['sessionPlan'] as List? ?? [
      {'phase': 'questions', 'minutes': 40, 'title': 'Estudar'},
      {'phase': 'revisions', 'minutes': 10, 'title': 'Debrief'},
    ]);
    final totalMin = phases.fold<int>(0, (s, p) => s + ((p as Map)['minutes'] as num? ?? 0).toInt());
    final questionCount = (plan?['questionCount'] as int?) ?? (phases.firstWhere(
          (p) => (p as Map)['phase'] == 'questions',
      orElse: () => {'count': 8},
    ) as Map)['count'] ?? 8;

    return SurfacePanel(
      color: cs.primaryContainer.withOpacity(0.25),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Pronto para estudar',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$subj · $top',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Metric(icon: Icons.quiz_outlined, value: '$questionCount', label: 'questões'),
                      const SizedBox(width: 24),
                      _Metric(icon: Icons.timer_outlined, value: '$totalMin', label: 'minutos'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TapScale(
                    child: FilledButton.icon(
                      onPressed: onStart,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 24),
                      label: Text(
                        'Começar agora',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => _showCustomizeSheet(context),
                child: Text(
                  'Personalizar sessão',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomizeSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Outras formas de estudar',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Escolha uma opção ou volte e aperte Começar.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ShortcutChip(label: 'Questões', icon: Icons.quiz_outlined, path: '/questoes'),
                _ShortcutChip(label: 'Flashcards', icon: Icons.style_outlined, path: '/flashcards'),
                _ShortcutChip(label: 'Tutor IA', icon: Icons.auto_awesome_outlined, path: '/tutor'),
                _ShortcutChip(label: 'Simulado', icon: Icons.bolt_outlined, path: '/simulados'),
                _ShortcutChip(label: 'Redação', icon: Icons.edit_note_outlined, path: '/redacao'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: cs.primary, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: cs.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}


class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({required this.label, required this.icon, required this.path});
  final String label;
  final IconData icon;
  final String path;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () {
        HapticFeedback.selectionClick();
        context.go(path);
      },
    );
  }
}
