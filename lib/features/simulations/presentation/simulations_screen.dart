import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/widgets/media_reinforcement.dart';
import '../../../core/widgets/resolution_debrief.dart';
import '../../../core/widgets/training_basis_banner.dart';
import '../../../core/widgets/ui_kit.dart';

class SimulationsScreen extends ConsumerStatefulWidget {
  const SimulationsScreen({super.key});

  @override
  ConsumerState<SimulationsScreen> createState() => _SimulationsScreenState();
}

class _SimulationsScreenState extends ConsumerState<SimulationsScreen> {
  String mode = 'dia_prova';
  String? subject;
  int limit = 10;
  bool showOtherModes = false;
  List<dynamic> questions = [];
  final Map<String, int> answers = {};
  final Map<String, String> errorTypes = {};
  Map<String, dynamic>? report;
  Map<String, dynamic>? lastSimMeta;
  /// Ciclo AJ: corpos com quality/eixos para debrief pós-sim.
  final Map<String, Map<String, dynamic>> debriefById = {};
  final Set<String> debriefLoading = {};
  String defaultErrorType = 'conceito';
  final sw = Stopwatch();

  /// Tempo já corrido antes de retomar um checkpoint (Stopwatch sempre parte do zero).
  Duration resumeOffset = Duration.zero;
  Duration get elapsed => sw.elapsed + resumeOffset;
  Timer? ticker;
  bool examLocked = false;
  Duration? diaProvaHardCap;
  bool preflightDone = false;
  bool running = false;
  bool starting = false;
  bool grading = false;
  Map<String, dynamic>? pendingSimCheckpoint;
  String? startError;
  String? checkpointLoadError;
  String? checkpointSaveError;
  /// Erros ao carregar explicação pós-sim por questão.
  final Map<String, String> debriefErrors = {};
  /// Ciclo BS: teclado 1–5 / Enter na sessão em andamento.
  final FocusNode sessionFocus = FocusNode();
  int keyboardQi = 0;

  static const _modes = <(String, String, String, IconData)>[
    ('dia_prova', 'Dia de prova', 'Cronômetro e sem gabarito até terminar', Icons.timer_outlined),
    ('prova_completa', 'Prova completa', 'Treino com o recorte usual da prova', Icons.assignment_outlined),
    ('medicina', 'Medicina', 'Foco em Natureza e raciocínio biomédico', Icons.biotech_outlined),
    ('revisao', 'Revisão', 'O que já está na fila para revisar', Icons.replay_rounded),
    ('incidencia', 'Por incidência', 'Tópicos que mais caem (quando houver base)', Icons.insights_outlined),
    ('disciplina', 'Por disciplina', 'Escolha a matéria', Icons.menu_book_outlined),
  ];

  static const _errorLabels = {
    'conceito': 'Conceito',
    'interpretacao': 'Interpretação',
    'calculo': 'Cálculo',
    'distracao': 'Distração',
    'tempo': 'Tempo',
  };

  @override
  void initState() {
    super.initState();
    _loadSimCheckpoint();
    _requestSessionFocus();
  }

  @override
  void dispose() {
    ticker?.cancel();
    sessionFocus.dispose();
    super.dispose();
  }

  void _requestSessionFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) sessionFocus.requestFocus();
    });
  }

  KeyEventResult _onSessionKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;

    // Relatório: atalhos pós-grade (Ciclo DB)
    if (report != null) {
      if (isEnter) {
        context.go('/dashboard');
        return KeyEventResult.handled;
      }
      final gaps = (report!['gaps'] as List? ?? []);
      if (event.logicalKey == LogicalKeyboardKey.digit1 ||
          event.logicalKey == LogicalKeyboardKey.numpad1) {
        context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1');
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.digit2 ||
          event.logicalKey == LogicalKeyboardKey.numpad2) {
        if (gaps.isNotEmpty) {
          unawaited(_remediateGaps());
        } else {
          context.go('/fila');
        }
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.digit3 ||
          event.logicalKey == LogicalKeyboardKey.numpad3) {
        context.go('/redacao');
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyE) {
        unawaited(_exportReport());
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyN) {
        unawaited(_resetSim());
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Preflight: Enter inicia (mesmo do botão Começar / Iniciar)
    if (!running) {
      if (isEnter) {
        final canStart = !(mode == 'disciplina' && (subject == null || subject!.isEmpty));
        if (canStart) unawaited(_start());
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (questions.isEmpty) return KeyEventResult.ignored;

    final qi = keyboardQi.clamp(0, questions.length - 1);
    final q = Map<String, dynamic>.from(questions[qi] as Map);
    final id = q['id']?.toString() ?? '';
    final opts = (q['options'] as List? ?? []);
    final answered = id.isNotEmpty && answers.containsKey(id);

    // ← / Backspace: item anterior
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (keyboardQi > 0) {
        setState(() => keyboardQi = keyboardQi - 1);
      }
      return KeyEventResult.handled;
    }

    // → / Space: próximo item (sem revelar gabarito)
    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.space) {
      if (keyboardQi < questions.length - 1) {
        setState(() => keyboardQi = keyboardQi + 1);
      }
      return KeyEventResult.handled;
    }

    final keys = <LogicalKeyboardKey, int>{
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
    final opt = keys[event.logicalKey];
    if (opt != null && id.isNotEmpty) {
      // Sem resposta: 1–5 marca opção. Com resposta e !examLocked: 1–5 tipo de erro.
      if (!answered) {
        if (opt >= opts.length) return KeyEventResult.handled;
        setState(() {
          answers[id] = opt;
          if (!examLocked) errorTypes.putIfAbsent(id, () => defaultErrorType);
        });
        unawaited(_saveSimCheckpoint());
        return KeyEventResult.handled;
      }
      if (!examLocked) {
        const errKeys = ['conceito', 'interpretacao', 'calculo', 'distracao', 'tempo'];
        if (opt < errKeys.length) {
          setState(() => errorTypes[id] = errKeys[opt]);
          unawaited(_saveSimCheckpoint());
        }
        return KeyEventResult.handled;
      }
      return KeyEventResult.handled;
    }

    if (isEnter) {
      if (id.isNotEmpty && answers.containsKey(id)) {
        if (qi < questions.length - 1) {
          setState(() => keyboardQi = qi + 1);
        } else if (answers.length >= questions.length) {
          unawaited(_grade());
        }
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _loadSimCheckpoint() async {
    try {
      final raw = await apiClient.get('/api/sim/checkpoint');
      final cp = (raw as Map)['checkpoint'];
      if (cp is Map && cp['started'] == true) {
        final qs = cp['questions'] as List? ?? [];
        if (qs.isNotEmpty && mounted) {
          setState(() {
            pendingSimCheckpoint = Map<String, dynamic>.from(cp);
            checkpointLoadError = null;
          });
        }
      } else if (mounted) {
        setState(() => checkpointLoadError = null);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        pendingSimCheckpoint = null;
        checkpointLoadError = humanApiError(
          e,
          fallback: 'Não foi possível carregar simulado salvo.',
        );
      });
    }
  }

  Future<void> _saveSimCheckpoint() async {
    if (!running || report != null || questions.isEmpty) return;
    final ids = questions
        .map((q) => (q is Map ? q['id'] : null)?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    final qs = questions
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    try {
      await apiClient.post('/api/sim/checkpoint', {
        'mode': mode,
        'limit': limit,
        'subject': subject,
        'startedAt': DateTime.now().toIso8601String(),
        'answers': answers.map((k, v) => MapEntry(k, v)),
        'errorTypes': errorTypes,
        'questionIds': ids,
        'questions': qs,
        'currentIndex': keyboardQi,
        'elapsedSec': elapsed.inSeconds,
        'examLocked': examLocked,
        'preflightDone': preflightDone,
        'basis': lastSimMeta?['basis'],
        'warning': lastSimMeta?['warning'],
        'started': true,
      });
      if (mounted) setState(() => checkpointSaveError = null);
    } catch (e) {
      if (!mounted) return;
      setState(
        () => checkpointSaveError = humanApiError(
          e,
          fallback: 'Progresso do simulado não foi salvo.',
        ),
      );
    }
  }

  Future<void> _clearSimCheckpoint() async {
    try {
      await apiClient.delete('/api/sim/checkpoint');
      if (mounted) {
        setState(() => pendingSimCheckpoint = null);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            humanApiError(e, fallback: 'Não foi possível descartar o simulado salvo.'),
          ),
        ),
      );
    }
  }

  Future<void> _resetSim() async {
    await _clearSimCheckpoint();
    if (!mounted) return;
    setState(() {
      questions = [];
      report = null;
      lastSimMeta = null;
      debriefById.clear();
      debriefLoading.clear();
      running = false;
      answers.clear();
      errorTypes.clear();
      keyboardQi = 0;
      diaProvaHardCap = null;
    });
  }

  Future<void> _exportReport() async {
    final r = report;
    if (r == null) return;
    final buf = StringBuffer('# Relatório de simulado — PAES MED AI\n\n');
    buf.writeln('**Modo:** ${lastSimMeta?['mode'] ?? mode}');
    buf.writeln('**Cronômetro:** $_clock');
    buf.writeln('');
    buf.writeln('## Resultado (treino local)');
    final acc = ((r['accuracy'] as num?) ?? 0) * 100;
    buf.writeln('- Acerto: ${acc.toStringAsFixed(0)}% (${r['correct']}/${r['total']})');
    if (r['avgTimeMs'] != null) {
      buf.writeln(
        '- Média por item: ${((r['avgTimeMs'] as num) / 1000).toStringAsFixed(1)}s',
      );
    }
    if (r['warning'] != null) buf.writeln('- Aviso: ${r['warning']}');
    buf.writeln('');
    buf.writeln('## Por disciplina');
    for (final s in (r['subjectBreakdown'] as List? ?? []).take(12)) {
      if (s is! Map) continue;
      final a = ((s['accuracy'] as num?) ?? 0) * 100;
      buf.writeln('- ${s['subject']}: ${s['correct']}/${s['total']} · ${a.toStringAsFixed(0)}%');
    }
    buf.writeln('');
    buf.writeln('## Lacunas');
    final gaps = r['gaps'] as List? ?? [];
    if (gaps.isEmpty) {
      buf.writeln('- (nenhuma lacuna no relatório)');
    } else {
      for (final g in gaps.take(12)) {
        if (g is! Map) continue;
        buf.writeln('- ${g['subject']} · ${g['topic']} · erros=${g['wrong']}');
      }
    }
    buf.writeln('');
    buf.writeln('## Disclaimer');
    buf.writeln(
      'Treino local · estimativa ≠ garantia. Não inventa probabilidade de aprovação UEMA.',
    );
    try {
      final data = await apiClient.post('/api/study/export-day', {
        'markdown': buf.toString(),
        'filename': 'sim_${mode}_${DateTime.now().millisecondsSinceEpoch}.md',
      });
      final map = Map<String, dynamic>.from(data as Map);
      final path = map['path']?.toString() ?? '';
      final dir = map['dir']?.toString() ?? '';
      if (dir.isNotEmpty) {
        try {
          await apiClient.openPath(dir);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                humanApiError(e, fallback: 'Export OK, mas pasta não abriu.'),
              ),
            ),
          );
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(path.isNotEmpty ? 'Exportado: $path' : 'Exportado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para exportar o simulado.'))),
      );
    }
  }

  void _restoreSimCheckpoint() {
    final cp = pendingSimCheckpoint;
    if (cp == null) return;
    final qs = (cp['questions'] as List? ?? []).toList();
    if (qs.isEmpty) return;
    final ansRaw = cp['answers'];
    final errRaw = cp['errorTypes'];
    answers.clear();
    errorTypes.clear();
    if (ansRaw is Map) {
      for (final e in ansRaw.entries) {
        final v = e.value;
        answers[e.key.toString()] = v is int ? v : int.tryParse('$v') ?? 0;
      }
    }
    if (errRaw is Map) {
      for (final e in errRaw.entries) {
        errorTypes[e.key.toString()] = e.value.toString();
      }
    }
    final elapsedSec = (cp['elapsedSec'] as num?)?.toInt() ?? 0;
    ticker?.cancel();
    setState(() {
      resumeOffset = Duration(seconds: elapsedSec);
      mode = cp['mode']?.toString() ?? mode;
      limit = (cp['limit'] as num?)?.toInt() ?? limit;
      subject = cp['subject']?.toString();
      questions = qs;
      lastSimMeta = {
        'basis': cp['basis'],
        'warning': cp['warning'],
        'questions': qs,
      };
      report = null;
      running = true;
      keyboardQi = (cp['currentIndex'] as num?)?.toInt() ?? 0;
      if (keyboardQi < 0 || keyboardQi >= qs.length) keyboardQi = 0;
      examLocked = cp['examLocked'] == true || mode == 'dia_prova';
      preflightDone = cp['preflightDone'] == true || mode == 'dia_prova';
      pendingSimCheckpoint = null;
      debriefById.clear();
      debriefLoading.clear();
      sw
        ..reset()
        ..start();
    });
    _armDiaProvaTicker();
    _requestSessionFocus();
  }

  Future<bool> _preflightDiaProva() async {
    Map<String, dynamic> basis = {};
    String? healthNote;
    try {
      final h = await apiClient.get('/health');
      basis = Map<String, dynamic>.from(h as Map);
    } catch (e) {
      healthNote = humanApiError(
        e,
          fallback: 'Sem internet — contagem de oficiais indisponível.',
      );
    }
    final n = basis['officialCount'] as int? ?? 0;
    final mins = (limit * 1.5).ceil().clamp(15, 90);
    if (!mounted) return false;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pronto para o dia de prova?'),
        content: Text(
          '${healthNote != null ? '$healthNote\n\n' : ''}'
          '${n < 10
              ? 'Há poucas oficiais na base ($n). Este modo NÃO inventa prova UEMA — sem acervo sério, a base de treino fica rotulada como treino.\n\n'
                  'Tempo estimado: ~$mins min.\nResolução só ao finalizar.'
              : 'Base oficial: $n questões (contagem local).\nTempo estimado: ~$mins min.\nResolução oculta até finalizar · sem treino disfarçado nesta seleção.'}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(ctx, false);
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(ctx, true);
            },
            child: const Text('Começar'),
          ),
        ],
      ),
    );
    return go == true;
  }

  Future<void> _start() async {
    if (mode == 'dia_prova') {
      final ok = await _preflightDiaProva();
      if (!ok) return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      startError = null;
      starting = true;
    });
    try {
      final data = await apiClient.post('/api/simulations', {
        'mode': mode,
        'subject': subject,
        'limit': limit,
      });
      final map = Map<String, dynamic>.from(data as Map);
      final qs = map['questions'] as List<dynamic>? ?? [];
      if (qs.isEmpty) {
        setState(() {
          startError = 'Nenhuma questão neste modo — monte o acervo na Biblioteca.';
          running = false;
          starting = false;
        });
        return;
      }
      ticker?.cancel();
      setState(() {
        lastSimMeta = map;
        questions = qs;
        answers.clear();
        errorTypes.clear();
        debriefById.clear();
        debriefLoading.clear();
        report = null;
        running = true;
        starting = false;
        keyboardQi = 0;
        examLocked = mode == 'dia_prova';
        preflightDone = mode == 'dia_prova';
        resumeOffset = Duration.zero;
        sw
          ..reset()
          ..start();
      });
      _armDiaProvaTicker();
      unawaited(_saveSimCheckpoint());
      _requestSessionFocus();
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() {
        startError = humanApiError(e, fallback: 'Não deu para iniciar o simulado.');
        running = false;
        starting = false;
      });
    }
  }

  Future<void> _grade() async {
    HapticFeedback.mediumImpact();
    sw.stop();
    ticker?.cancel();
    setState(() => grading = true);
    final payload = answers.entries
        .map((e) => {
              'questionId': e.key,
              'selectedIndex': e.value,
              'timeMs': elapsed.inMilliseconds ~/ answers.length.clamp(1, 999),
              'errorType': errorTypes[e.key] ?? defaultErrorType,
            })
        .toList();
    try {
      final data = await apiClient.post('/api/simulations/grade', {'answers': payload});
      ref.read(refreshTickProvider.notifier).state++;
      await _clearSimCheckpoint();
      setState(() {
        report = Map<String, dynamic>.from(data as Map);
        running = false;
        examLocked = false;
        diaProvaHardCap = null;
        grading = false;
      });
      HapticFeedback.lightImpact();
      for (final raw in (report?['results'] as List? ?? [])) {
        final r = Map<String, dynamic>.from(raw as Map);
        if (r['correct'] == true) continue;
        final id = r['questionId']?.toString();
        if (id != null && id.isNotEmpty) unawaited(_ensureDebrief(id));
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() {
        startError = humanApiError(e, fallback: 'Não deu para corrigir o simulado.');
        grading = false;
      });
    }
  }

  Future<void> _ensureDebrief(String id) async {
    if (debriefById.containsKey(id) || debriefLoading.contains(id)) return;
    setState(() => debriefLoading.add(id));
    try {
      for (final raw in questions) {
        final q = Map<String, dynamic>.from(raw as Map);
        if (q['id']?.toString() == id &&
            (q['resolutionQuality'] != null ||
                q['resolutionAxes'] != null ||
                q['resolution'] != null)) {
          if (mounted) {
            setState(() {
              debriefById[id] = q;
              debriefLoading.remove(id);
            });
          }
          return;
        }
      }
      final data = await apiClient.get('/api/questions/$id');
      if (!mounted) return;
      setState(() {
        debriefById[id] = Map<String, dynamic>.from(data as Map);
        debriefLoading.remove(id);
        debriefErrors.remove(id);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        debriefLoading.remove(id);
        debriefErrors[id] = humanApiError(e, fallback: 'Explicação indisponível.');
      });
    }
  }

  Widget _debriefBlock(String questionId, String subject, String topic) {
    final q = debriefById[questionId];
    if (debriefLoading.contains(questionId) && q == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: LinearProgressIndicator(),
      );
    }
    if (q == null) {
      final err = debriefErrors[questionId];
      if (err != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(err, style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => debriefErrors.remove(questionId));
                _ensureDebrief(questionId);
              },
              child: const Text('Tentar'),
            ),
          ],
        );
      }
      return TextButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          _ensureDebrief(questionId);
        },
        child: const Text('Carregar explicação'),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: ResolutionDebrief(
        question: q,
        trailing: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                context.go(
                  '/adaptativo?subject=${Uri.encodeComponent(subject)}'
                  '&topic=${Uri.encodeComponent(topic)}',
                );
              },
              child: const Text('Remediar'),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                context.go('/fila');
              },
              child: const Text('Fila'),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                context.go(
                  '/sessao?examBoard=UEMA_PAES&preferNatureza=1',
                );
              },
              child: const Text('Sessão Natureza'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _remediateGaps() async {
    final gaps = (report!['gaps'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    try {
      final data = await apiClient.post('/api/simulations/schedule-gaps', {'gaps': gaps});
      final map = Map<String, dynamic>.from(data as Map);
      final cta = map['cta']?.toString() ?? '/fila';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lacunas na fila (${map['scheduled'] ?? 0}).')),
      );
      context.go(cta);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para agendar as lacunas.'))),
      );
    }
  }

  String get _clock {
    final e = elapsed;
    return '${e.inMinutes.toString().padLeft(2, '0')}:${(e.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  Duration _diaProvaHardCapForLimit(int n) =>
      Duration(minutes: (n * 1.5).ceil().clamp(15, 90));

  String get _timeRemainingLabel {
    final cap = diaProvaHardCap;
    if (cap == null) return '';
    final left = cap - elapsed;
    if (!left.isNegative && left.inSeconds <= 0) return '00:00';
    final safe = left.isNegative ? Duration.zero : left;
    return '${safe.inMinutes.toString().padLeft(2, '0')}:${(safe.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  void _armDiaProvaTicker() {
    ticker?.cancel();
    diaProvaHardCap = mode == 'dia_prova' ? _diaProvaHardCapForLimit(limit) : null;
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final cap = diaProvaHardCap;
      if (cap != null && elapsed >= cap && report == null) {
        _grade();
        return;
      }
      setState(() {});
      if (elapsed.inSeconds % 5 == 0) {
        unawaited(_saveSimCheckpoint());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inSession = running || report != null;
    final genInPack = lastSimMeta == null
        ? 0
        : (lastSimMeta!['generatedInPack'] as int? ??
            (lastSimMeta!['questions'] as List? ?? [])
                .where((q) => q is Map && q['generated'] == true)
                .length);
    final wrongResults = (report?['results'] as List? ?? [])
        .whereType<Map>()
        .where((r) => r['correct'] != true)
        .toList();

    final body = ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: 'Treino',
                title: 'Simulados',
                subtitle: inSession
                    ? (report != null
                        ? 'Enter Hoje · 1 Natureza · 2 Fila · 3 Redação · E export · N novo'
                        : examLocked
                            ? 'Dia de prova · restam $_timeRemainingLabel · 1–5 · Enter avança · gabarito no fim'
                            : '1–5 opção · Enter próxima · Space avança (sem gabarito)')
                    : 'Escolha um modo e faça um bloco como no dia da prova',
                trailing: inSession && report == null
                    ? SurfacePanel(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        color: examLocked ? cs.tertiaryContainer.f55 : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _clock,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            if (examLocked && diaProvaHardCap != null)
                              Text(
                                '−$_timeRemainingLabel',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface.f65,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                          ],
                        ),
                      )
                    : null,
              ),

              if (lastSimMeta != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TrainingBasisBanner(
                    basis: lastSimMeta!['basis']?.toString(),
                    message: lastSimMeta!['warning']?.toString() ??
                        (lastSimMeta!['basis'] == 'oficial'
                            ? (genInPack > 0
                                ? 'Seleção com $genInPack questão(ões) geradas — não confunda com oficiais.'
                                : null)
                            : 'Este bloco usou base de treino. Monte a Biblioteca para Dia de prova sério.'),
                    showLibraryCta: lastSimMeta!['basis'] != 'oficial',
                    areaKey: 'simulados',
                  ),
                )
              else if (!inSession && (mode == 'dia_prova' || mode == 'medicina'))
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: TrainingBasisBanner(
                    basis: 'treino',
                    message:
                        'Dia de prova e Medicina pedem oficiais. Sem acervo, o app rotula treino — não inventa incidência.',
                    areaKey: 'simulados',
                  ),
                ),

              if (!inSession) ...[
                if (checkpointLoadError != null)
                  QuietEmpty(
                    message: checkpointLoadError!,
                    action: TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _loadSimCheckpoint();
                      },
                      child: const Text('Tentar'),
                    ),
                  ),
                if (startError != null)
                  QuietEmpty(
                    message: startError!,
                    action: Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() => startError = null);
                          },
                          child: const Text('Ok'),
                        ),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            context.go('/biblioteca');
                          },
                          child: const Text('Biblioteca'),
                        ),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1');
                          },
                          child: const Text('Sessão'),
                        ),
                      ],
                    ),
                  ),
                if (pendingSimCheckpoint != null)
                  SurfacePanel(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: cs.tertiaryContainer.withOpacity(0.4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Simulado em andamento',
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: cs.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Modo ${pendingSimCheckpoint!['mode'] ?? '—'} · '
                          '${(pendingSimCheckpoint!['answers'] as Map? ?? {}).length} respondida(s)',
                          style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            FilledButton(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                _restoreSimCheckpoint();
                              },
                              child: const Text('Continuar'),
                            ),
                            OutlinedButton(
                              onPressed: () async {
                                HapticFeedback.selectionClick();
                                await _clearSimCheckpoint();
                              },
                              child: const Text('Descartar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                SectionLabel('Dia de prova', hint: 'Caminho principal · cronômetro · gabarito no fim'),
                _ModeCard(
                  selected: mode == 'dia_prova',
                  icon: Icons.timer_outlined,
                  title: 'Dia de prova',
                  subtitle: 'Cronômetro e sem gabarito até terminar',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => mode = 'dia_prova');
                  },
                ),
                const SizedBox(height: 4),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  initiallyExpanded: showOtherModes || mode != 'dia_prova',
                  onExpansionChanged: (v) => setState(() => showOtherModes = v),
                  title: Text('Outros modos', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  children: [
                    for (final m in _modes.where((e) => e.$1 != 'dia_prova'))
                      _ModeCard(
                        selected: mode == m.$1,
                        icon: m.$4,
                        title: m.$2,
                        subtitle: m.$3,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => mode = m.$1);
                        },
                      ),
                  ],
                ),
                if (mode == 'disciplina') ...[
                  const SizedBox(height: 8),
                  DropdownMenu<String>(
                    label: const Text('Disciplina'),
                    onSelected: (v) => setState(() => subject = v),
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: 'Biologia', label: 'Biologia'),
                      DropdownMenuEntry(value: 'Química', label: 'Química'),
                      DropdownMenuEntry(value: 'Física', label: 'Física'),
                      DropdownMenuEntry(value: 'Matemática', label: 'Matemática'),
                      DropdownMenuEntry(value: 'Língua Portuguesa e Literatura', label: 'Português'),
                    ],
                  ),
                ],
                if (mode == 'disciplina' && (subject == null || subject!.isEmpty))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Escolha a disciplina antes de iniciar.',
                      style: GoogleFonts.inter(fontSize: 13, color: cs.error),
                    ),
                  ),
                const SizedBox(height: 12),
                SectionLabel('Quantidade', hint: '$limit questões'),
                Slider(
                  value: limit.toDouble(),
                  min: 5,
                  max: 30,
                  divisions: 5,
                  label: '$limit',
                  onChanged: (v) => setState(() => limit = v.round()),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: starting ||
                          (mode == 'disciplina' && (subject == null || subject!.isEmpty))
                      ? null
                      : _start,
                  icon: starting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(starting
                      ? 'Carregando questões…'
                      : mode == 'dia_prova'
                          ? 'Começar dia de prova'
                          : 'Iniciar simulado'),
                ),
              ],

              if (running && checkpointSaveError != null) ...[
                QuietEmpty(
                  message: checkpointSaveError!,
                  action: TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _saveSimCheckpoint();
                    },
                    child: const Text('Tentar'),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              if (running && report == null && !examLocked) ...[
                SectionLabel('Se errar, marque o tipo', hint: 'Padrão para o bloco inteiro'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in _errorLabels.entries)
                      ChoiceChip(
                        label: Text(e.value),
                        selected: defaultErrorType == e.key,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => defaultErrorType = e.key);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              if (examLocked && report == null)
                SurfacePanel(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: cs.tertiaryContainer.f45,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dia de prova em andamento',
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: cs.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Respostas: ${answers.length}/${questions.length} · tempo $_clock'
                        '${diaProvaHardCap != null ? ' · restam $_timeRemainingLabel' : ''}',
                        style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sem gabarito até finalizar. Ao acabar o tempo ou responder tudo, o app corrige.',
                        style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.f65),
                      ),
                    ],
                  ),
                ),

              for (var qi = 0; qi < questions.length; qi++)
                Builder(
                  builder: (context) {
                    final q = Map<String, dynamic>.from(questions[qi] as Map);
                    final id = q['id'] as String;
                    final opts = (q['options'] as List).map((e) => e.toString()).toList();
                    final year = q['year'];
                    final kbActive = running && report == null && qi == keyboardQi;
                    return SurfacePanel(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: kbActive ? cs.primaryContainer.withOpacity(0.28) : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Questão ${qi + 1} de ${questions.length}'
                            '${year != null ? ' · $year' : ''}'
                            '${kbActive ? ' · teclado' : ''}',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: cs.primary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${q['subject'] ?? ''} · ${q['topic'] ?? ''}',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
                          ),
                          const SizedBox(height: 8),
                          StatementView(
                            key: ValueKey('sim_stmt_$id'),
                            text: q['statement']?.toString() ?? '',
                          ),
                          const SizedBox(height: 8),
                          for (var i = 0; i < opts.length; i++)
                            ChoiceOptionTile(
                              key: ValueKey('sim_opt_${id}_$i'),
                              index: i,
                              label: opts[i].toString(),
                              selected: answers[id] == i,
                              enabled: report == null,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  answers[id] = i;
                                  keyboardQi = qi;
                                });
                                unawaited(_saveSimCheckpoint());
                              },
                            ),
                          if (report == null && answers.containsKey(id) && !examLocked)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: DropdownButton<String>(
                                value: errorTypes[id] ?? defaultErrorType,
                                hint: const Text('Tipo de erro se miss'),
                                items: [
                                  for (final e in _errorLabels.entries)
                                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  HapticFeedback.selectionClick();
                                  setState(() => errorTypes[id] = v);
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

              if (questions.isNotEmpty && report == null) ...[
                const SizedBox(height: 4),
                FilledButton.tonal(
                  onPressed: (answers.length < questions.length || grading) ? null : _grade,
                  child: grading
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text('Corrigindo ${answers.length} questões…'),
                          ],
                        )
                      : Text(
                          answers.length < questions.length
                              ? 'Responda todas (${answers.length}/${questions.length})'
                              : 'Finalizar e corrigir',
                        ),
                ),
              ],

              if (report != null) ...[
                SectionLabel('Resultado'),
                SurfacePanel(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: cs.primaryContainer.f35,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Anima o número de 0 até a porcentagem final
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: ((report!['accuracy'] as num) * 100).toDouble()),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          final pct = value.toStringAsFixed(0);
                          // Cor muda conforme acerto: vermelho <40, laranja <70, verde >=70
                          final color = value >= 70
                              ? cs.primary
                              : value >= 40
                                  ? cs.tertiary
                                  : cs.error;
                          return Text(
                            '$pct% de acerto',
                            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: color),
                          );
                        },
                      ),
                      Text(
                        '${report!['correct']}/${report!['total']} corretas · tempo $_clock',
                        style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: cs.onSurface.withOpacity(0.85)),
                      ),
                      if (report!['avgTimeMs'] != null)
                        Text(
                          'Média ${((report!['avgTimeMs'] as num) / 1000).toStringAsFixed(1)}s por item',
                          style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
                        ),
                      if (report!['warning'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${report!['warning']}',
                          style: TextStyle(color: cs.error),
                        ),
                      ],
                    ],
                  ),
                ),

                if ((report!['subjectBreakdown'] as List? ?? []).isNotEmpty) ...[
                  SectionLabel('Por disciplina'),
                  for (final s in (report!['subjectBreakdown'] as List).take(8))
                    PlaylistTile(
                      title: (s as Map)['subject']?.toString() ?? '—',
                      subtitle:
                          '${s['correct']}/${s['total']} · ${(((s['accuracy'] as num?) ?? 0) * 100).toStringAsFixed(0)}%',
                      leadingIcon: Icons.school_outlined,
                    ),
                ],

                if ((report!['gaps'] as List? ?? []).isNotEmpty) ...[
                  SectionLabel('Lacunas para treinar'),
                  for (final g in (report!['gaps'] as List).take(6))
                    PlaylistTile(
                      title: '${(g as Map)['subject']} · ${g['topic']}',
                      subtitle: '${g['wrong']} erro(s)',
                      leadingIcon: Icons.flag_outlined,
                      onPlay: () => context.go(
                        '/adaptativo?subject=${Uri.encodeComponent(g['subject']?.toString() ?? '')}'
                        '&topic=${Uri.encodeComponent(g['topic']?.toString() ?? '')}',
                      ),
                    ),
                  Builder(
                    builder: (_) {
                      final gaps = (report!['gaps'] as List).whereType<Map>().toList();
                      if (gaps.isEmpty) return const SizedBox.shrink();
                      final g0 = Map<String, dynamic>.from(gaps.first);
                      final s = g0['subject']?.toString() ?? '';
                      final t = g0['topic']?.toString() ?? '';
                      if (s.isEmpty || t.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: MediaReinforcement(
                          subject: s,
                          topic: t,
                          compact: true,
                        ),
                      );
                    },
                  ),
                ],

                if (wrongResults.isNotEmpty) ...[
                  SectionLabel('Erros — debrief', hint: '4 eixos quando a resolução for real'),
                  for (final r in wrongResults.take(8))
                    SurfacePanel(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${r['subject'] ?? ''} · ${r['topic'] ?? ''}',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
                          ),
                          _debriefBlock(
                            r['questionId']?.toString() ?? '',
                            r['subject']?.toString() ?? '',
                            r['topic']?.toString() ?? '',
                          ),
                        ],
                      ),
                    ),
                ],

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: (report!['gaps'] as List? ?? []).isNotEmpty
                          ? () {
                              HapticFeedback.selectionClick();
                              _remediateGaps();
                            }
                          : () {
                              HapticFeedback.selectionClick();
                              context.go('/fila');
                            },
                      icon: const Icon(Icons.playlist_play_rounded),
                      label: Text(
                        (report!['gaps'] as List? ?? []).isNotEmpty
                            ? 'Mandar lacunas para a Fila'
                            : 'Continuar na Fila',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1');
                      },
                      child: const Text('Sessão Natureza'),
                    ),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.go('/redacao');
                      },
                      child: const Text('Redação'),
                    ),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.go('/dashboard');
                      },
                      child: const Text('Hoje'),
                    ),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _exportReport();
                      },
                      child: const Text('Exportar resumo'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _resetSim();
                      },
                      child: const Text('Novo simulado'),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('Detalhe das respostas', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  children: [
                    for (final r in (report!['results'] as List? ?? []))
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          (r as Map)['correct'] == true ? Icons.check_circle : Icons.cancel,
                          color: r['correct'] == true ? cs.primary : cs.error,
                        ),
                        title: Text('${r['subject']} · ${r['topic']}'),
                        trailing: TextButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            context.go('/questoes/${r['questionId']}');
                          },
                          child: const Text('Ver'),
                        ),
                      ),
                    if ((report!['professorHints'] as List? ?? []).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Macete dos erros', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
                      for (final h in (report!['professorHints'] as List).take(5))
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('${(h as Map)['topic']}'),
                          subtitle: Text(h['macete']?.toString() ?? ''),
                          trailing: TextButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              context.go('/questoes/${h['questionId']}');
                            },
                            child: const Text('Abrir'),
                          ),
                        ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return Focus(
      focusNode: sessionFocus,
      autofocus: true,
      onKeyEvent: _onSessionKey,
      child: body,
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? cs.primaryContainer.f55 : cs.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(kRadiusPanel),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadiusPanel),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kRadiusPanel),
              border: Border.all(
                color: selected ? cs.primary.f55 : cs.outlineVariant.f85,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: selected ? cs.primary : cs.onSurface.withOpacity(0.7)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.f72),
                      ),
                    ],
                  ),
                ),
                if (selected) Icon(Icons.check_circle_rounded, color: cs.primary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
