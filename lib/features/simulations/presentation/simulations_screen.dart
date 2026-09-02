import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/widgets/resolution_debrief.dart';
import '../../../core/widgets/training_basis_banner.dart';
import '../../../core/widgets/ui_kit.dart';
import 'widgets/simulation_report_panel.dart';
import 'widgets/simulation_setup_panel.dart';
import 'widgets/simulation_widgets.dart';

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
  int keyboardQi = 0;

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
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
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
    buf.writeln('## Resultado (prática)');
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
    buf.writeln('## Tópicos para revisar');
    final gaps = r['gaps'] as List? ?? [];
    if (gaps.isEmpty) {
      buf.writeln('- (nenhum tópico para revisar no relatório)');
    } else {
      for (final g in gaps.take(12)) {
        if (g is! Map) continue;
        buf.writeln('- ${g['subject']} · ${g['topic']} · erros=${g['wrong']}');
      }
    }
    buf.writeln('');
    buf.writeln('## Disclaimer');
    buf.writeln(
      'Prática · estimativa ≠ garantia. Não inventa probabilidade de aprovação UEMA.',
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
    final isPaes = mode == 'paes_realista';
    final mins = isPaes ? 240 : (limit * 1.5).ceil().clamp(15, 90);
    if (!mounted) return false;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isPaes ? 'Simulado PAES — 60 questões' : 'Pronto para o simulado do dia?'),
        content: Text(
          '${healthNote != null ? '$healthNote\n\n' : ''}'
          '${isPaes
              ? 'Simulado no estilo UEMA com 60 questões distribuídas por matéria.\nTempo: 4 horas.\nGabarito só ao finalizar.\n\n'
              : ''}'
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
    if (mode == 'dia_prova' || mode == 'paes_realista') {
      final ok = await _preflightDiaProva();
      if (!ok) return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      startError = null;
      starting = true;
    });
    try {
      final body = <String, dynamic>{
        'mode': mode,
        'subject': subject,
        'limit': limit,
      };
      if (mode == 'paes_realista') {
        body['exam_minutes'] = 240;
        body['limit'] = 60;
      }
      final data = await apiClient.post('/api/simulations', body);
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
      // Hard cap dinamico: backend pode retornar examMinutes (modo PAES = 240min)
      final examMin = (map['examMinutes'] as num?)?.toInt();
      final dynamicCap = examMin != null && examMin > 0
          ? Duration(minutes: examMin)
          : null;
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
        examLocked = (map['examLocked'] as bool?) ??
            (mode == 'dia_prova' || mode == 'paes_realista');
        preflightDone = mode == 'dia_prova' || mode == 'paes_realista';
        diaProvaHardCap = dynamicCap;
        resumeOffset = Duration.zero;
        sw
          ..reset()
          ..start();
      });
      _armDiaProvaTicker();
      unawaited(_saveSimCheckpoint());
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
            Text(err, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
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
        SnackBar(content: Text('Tópicos para revisar na fila (${map['scheduled'] ?? 0}).')),
      );
      context.go(cta);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para agendar os tópicos para revisar.'))),
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
    // PAES realista: mantem o hard cap de 4h vindo do backend (ja setado em _start)
    // Dia de prova: calcula pelo limite
    if (mode == 'paes_realista') {
      // diaProvaHardCap ja foi setado em _start a partir do examMinutes do backend
      // nao sobrescrever
    } else if (mode == 'dia_prova') {
      diaProvaHardCap = _diaProvaHardCapForLimit(limit);
    } else {
      diaProvaHardCap = null;
    }
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
                        ? 'Veja o resultado e escolha o próximo passo'
                        : examLocked
                            ? 'Simulado do dia · tempo restante $_timeRemainingLabel'
                            : 'Responda questão a questão · gabarito só no final')
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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            if (examLocked && diaProvaHardCap != null)
                              Text(
                                '−$_timeRemainingLabel',
                                style: TextStyle(
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
                            : 'Este bloco usou base de treino. Monte a Biblioteca para Simulado do dia sério.'),
                    showLibraryCta: lastSimMeta!['basis'] != 'oficial',
                    areaKey: 'simulados',
                  ),
                )
              else if (!inSession && mode == 'dia_prova')
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: TrainingBasisBanner(
                    basis: 'treino',
                    message:
                        'Simulado do dia e Medicina pedem oficiais. Sem acervo, o app rotula treino — não inventa frequência na prova.',
                    areaKey: 'simulados',
                  ),
                ),

              if (!inSession)
                SimulationSetupPanel(
                  mode: mode,
                  subject: subject,
                  limit: limit,
                  starting: starting,
                  showOtherModes: showOtherModes,
                  checkpointLoadError: checkpointLoadError,
                  startError: startError,
                  pendingCheckpoint: pendingSimCheckpoint,
                  onModeChanged: (m) => setState(() => mode = m),
                  onSubjectChanged: (v) => setState(() => subject = v),
                  onLimitChanged: (v) => setState(() => limit = v),
                  onShowOtherModesChanged: (v) => setState(() => showOtherModes = v),
                  onStart: _start,
                  onReloadCheckpoint: _loadSimCheckpoint,
                  onDismissStartError: () => setState(() => startError = null),
                  onRestoreCheckpoint: _restoreSimCheckpoint,
                  onClearCheckpoint: _clearSimCheckpoint,
                ),

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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SimulationCircularTimer(
                        remainingSeconds: diaProvaHardCap != null
                            ? (diaProvaHardCap!.inSeconds - elapsed.inSeconds).clamp(0, diaProvaHardCap!.inSeconds)
                            : 0,
                        totalSeconds: diaProvaHardCap?.inSeconds ?? 0,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Simulado do dia em andamento',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: cs.onSurface),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Respostas: ${answers.length}/${questions.length} · tempo $_clock'
                              '${diaProvaHardCap != null ? ' · restam $_timeRemainingLabel' : ''}',
                              style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sem gabarito até finalizar. Ao acabar o tempo ou responder tudo, o app corrige.',
                              style: TextStyle(fontSize: 13, color: cs.onSurface.f65),
                            ),
                          ],
                        ),
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
                            '${year != null ? ' · $year' : ''}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.primary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${q['subject'] ?? ''} · ${q['topic'] ?? ''}',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kbActive ? cs.onPrimaryContainer : cs.onSurface),
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

              if (report != null)
                SimulationReportPanel(
                  report: report!,
                  clock: _clock,
                  wrongResults: wrongResults.cast<Map<String, dynamic>>(),
                  debriefBuilder: _debriefBlock,
                  onRemediateGaps: _remediateGaps,
                  onExportReport: _exportReport,
                  onResetSim: _resetSim,
                ),
            ],
          ),
        ),
      ],
    );

    return body;
  }
}
