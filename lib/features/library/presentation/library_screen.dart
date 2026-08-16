import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/data/study_prefs_providers.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/ui_kit.dart';
import 'ingest_review_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  Map<String, dynamic>? library;
  Map<String, dynamic>? coverage;
  Map<String, dynamic>? curation;
  String? error;
  String? msg;
  String? partialLoadNote;
  bool busy = false;
  String? resolutionStats;
  String? lessonStats;
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> searchHits = [];
  String? searchNote;
  String? searchHistoryNote;
  bool searching = false;
  String searchSourceKind = 'todos'; // todos | oficial | estudo
  List<Map<String, dynamic>> searchHistory = [];
  int _hitSelected = 0;
  final _semana1PanelKey = GlobalKey();
  bool showFirstRunCoach = false;
  bool _wantSemana1Scroll = false;
  bool _didSemana1Scroll = false;
  Timer? _searchDebounce;
  List<Map<String, dynamic>> _studyPdfs = [];
  bool _pdfsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_wantSemana1Scroll) {
      final q = GoRouterState.of(context).uri.queryParameters;
      _wantSemana1Scroll = q['semana1'] == '1';
    }
    _scheduleSemana1Scroll();
  }

  void _scheduleSemana1Scroll() {
    if (!_wantSemana1Scroll || _didSemana1Scroll || library == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didSemana1Scroll) return;
      final ctx = _semana1PanelKey.currentContext;
      if (ctx == null) return;
      _didSemana1Scroll = true;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.06,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
    _loadSearchHistory();
    _loadFirstRunCoach();
  }

  Future<void> _loadFirstRunCoach() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => showFirstRunCoach = prefs.getBool('first_run_coach_pending') ?? false);
  }

  Future<void> _dismissFirstRunCoach() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_run_coach_pending', false);
    if (mounted) setState(() => showFirstRunCoach = false);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      busy = true;
      error = null;
      partialLoadNote = null;
    });
    try {
      final data = await apiClient.get('/api/library');
      Map<String, dynamic>? cov;
      Map<String, dynamic>? cur;
      String? partialNote;
      try {
        final c = await apiClient.get('/api/edital/coverage');
        cov = Map<String, dynamic>.from(c as Map);
      } catch (e) {
        partialNote = humanApiError(e, fallback: 'Cobertura do edital indisponível.');
      }
      try {
        final inv = await apiClient.get('/api/curation/inventory');
        cur = Map<String, dynamic>.from(inv as Map);
      } catch (e) {
        partialNote ??= humanApiError(e, fallback: 'Inventário de curadoria indisponível.');
      }
      setState(() {
        library = Map<String, dynamic>.from(data as Map);
        coverage = cov;
        curation = cur;
        partialLoadNote = partialNote;
      });
      _scheduleSemana1Scroll();
      unawaited(_loadResolutionStats());
      unawaited(_loadLessonStats());
      unawaited(_loadStudyPdfs());
    } catch (e) {
      setState(() => error = humanApiError(e, fallback: 'Não deu para carregar a Biblioteca. Tente de novo.'));
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _bootstrapFirstYear() async {
    setState(() {
      busy = true;
      msg = 'Baixando…';
    });
    try {
      final data = await apiClient.post('/api/acervo/bootstrap-year', {
        'dryRun': false,
        'overwrite': false,
      });
      final map = Map<String, dynamic>.from(data as Map);
      final skipped = map['skippedFetch'] == true;
      final count = map['count'] ?? (map['questions'] as List?)?.length ?? 0;
      if (map['ok'] == false) {
        final portal = map['portal']?.toString();
        setState(() {
          msg = [
            map['message']?.toString() ?? map['error']?.toString() ?? 'A preparação do acervo falhou.',
            if (portal != null && portal.isNotEmpty) 'Portal: $portal',
            'Use a Biblioteca para abrir as provas.',
          ].join(' ');
        });
        return;
      }
      setState(() {
        msg = skipped
            ? 'PDFs no disco — Extraindo… Abrindo revisão ($count questões).'
            : 'Extraindo… Abrindo revisão ($count questões).';
      });
      final year = map['year'] as int? ?? 0;
      final previewId = map['previewId']?.toString();
      if (previewId != null && year > 0 && mounted) {
        final questions = List<Map<String, dynamic>>.from(
          (map['questions'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
        );
        context.push(
          '/biblioteca/revisao',
          extra: IngestReviewArgs(
            year: year,
            previewId: previewId,
            questions: questions,
            meta: {
              ...map,
              'fromBootstrap': true,
            },
          ),
        );
      }
      ref.read(refreshTickProvider.notifier).state++;
      await _load();
    } catch (e) {
      setState(() {
        msg = humanApiError(
          e,
          fallback:
              'Falha de rede/download — confira o portal na lista de materiais ou use Biblioteca → Manual / Abrir provas.',
        );
      });
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _professorBatchUema() async {
    setState(() {
      busy = true;
      msg = 'Gerando rascunhos professor (oficiais)…';
    });
    try {
      final data = await apiClient.post('/api/professor/batch-fill', {
        'limit': 30,
        'preferUema': true,
      });
      final map = Map<String, dynamic>.from(data as Map);
      setState(() {
        msg =
            'Professor: ${map['updated'] ?? 0} rascunhos. ${map['note'] ?? 'Revise — não é oficial da banca.'}';
      });
      ref.read(refreshTickProvider.notifier).state++;
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Não deu para concluir. Tente de novo.'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _healthLine(Map<String, dynamic> map, {Object? inserted}) {
    final health = Map<String, dynamic>.from(map['yearHealth'] as Map? ?? {});
    if (health.isEmpty && map['years'] is List) {
      // lote: soma natureza dos yearHealth
      var bio = 0, qui = 0, fis = 0, total = 0;
      for (final raw in (map['years'] as List)) {
        final y = Map<String, dynamic>.from(raw as Map);
        final h = Map<String, dynamic>.from(y['yearHealth'] as Map? ?? {});
        final nat = Map<String, dynamic>.from(h['natureza'] as Map? ?? {});
        bio += (nat['Biologia'] as int?) ?? 0;
        qui += (nat['Química'] as int?) ?? 0;
        fis += (nat['Física'] as int?) ?? 0;
        total += (h['total'] as int?) ?? (y['inserted'] as int?) ?? 0;
      }
      if (total == 0 && inserted != null) total = int.tryParse('$inserted') ?? 0;
      return total > 0 ? ' · lote: $total questões · Bio $bio/Qui $qui/Fis $fis' : '';
    }
    final nat = Map<String, dynamic>.from(health['natureza'] as Map? ?? {});
    if (health.isEmpty) return '';
    return ' · lote: ${health['total'] ?? inserted ?? '—'} questões · gabarito ${health['gabaritoPct'] ?? '—'}%'
        ' · Bio ${nat['Biologia'] ?? 0}/Qui ${nat['Química'] ?? 0}/Fis ${nat['Física'] ?? 0}'
        '${(health['suspectsRemaining'] as int? ?? 0) > 0 ? ' · ${health['suspectsRemaining']} suspeitas' : ''}';
  }

  Future<void> _showPostCommitCta({
    required String title,
    required String body,
    required String sessaoPath,
    Map<String, dynamic>? professor,
    Map<String, dynamic>? yearHealth,
    Map<String, dynamic>? naturezaPack,
  }) async {
    if (!mounted) return;
    final packLine = _naturezaPackLine(naturezaPack);
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text('$body$packLine'),
        actions: [
          TextButton(
            onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(ctx, 'professor'); },
            child: const Text('Rascunhos professor'),
          ),
          TextButton(onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(ctx, 'later'); }, child: const Text('Depois')),
          FilledButton(onPressed: () { HapticFeedback.mediumImpact(); Navigator.pop(ctx, 'study'); }, child: const Text('Estudar agora')),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'study') {
      await _goStudy(sessaoPath, yearHealth: yearHealth);
    } else if (choice == 'professor') {
      if (professor != null && (professor['updated'] as int? ?? 0) > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Já gerados: ${professor['updated']} rascunhos (não oficiais da banca).')),
        );
      } else {
        await _professorBatchUema();
      }
      if (mounted) {
        final focus = ref.read(focusModeProvider);
        context.go(focus ? '/sessao' : '/medicina');
      }
    }
  }

  Future<void> _showFetchPlaybook({
    required String title,
    required String body,
    String? portal,
    int? year,
    bool canCommitDisk = false,
  }) async {
    if (!mounted) return;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          if (canCommitDisk)
            FilledButton(
              onPressed: () { HapticFeedback.mediumImpact(); Navigator.pop(ctx, 'disk'); },
              child: const Text('Gravar PDFs do PC'),
            )
          else
            FilledButton(
              onPressed: () { HapticFeedback.mediumImpact(); Navigator.pop(ctx, 'provas'); },
              child: const Text('Abrir provas'),
            ),
          if (portal != null && portal.isNotEmpty)
            TextButton(onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(ctx, 'portal'); }, child: const Text('Portal')),
          TextButton(onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(ctx, 'gabaritos'); }, child: const Text('Abrir gabaritos')),
          if (year != null)
            TextButton(onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(ctx, 'retry'); }, child: const Text('Tentar de novo')),
          TextButton(onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(ctx, 'ok'); }, child: const Text('Fechar')),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'provas') await _openFolder('provas');
    if (choice == 'gabaritos') await _openFolder('gabaritos');
    if (choice == 'disk') await _commitOnDisk();
    if (choice == 'retry' && year != null) await _fetchYear(year);
    if (choice == 'portal' && portal != null) {
      await _openPortal(portal);
    }
  }

  Future<void> _openPortal(String portal) async {
    try {
      final data = await apiClient.post('/api/library/open-url', {'url': portal});
      setState(() => msg = 'Portal aberto no navegador: ${(data as Map)['url'] ?? portal}');
    } catch (e) {
      setState(() => msg = humanApiError(
            e,
            fallback:
                'Portal: $portal — abra no navegador e drope paes_YYYY.pdf / gabarito_YYYY.pdf.',
          ));
    }
  }

  String _semana1HealthBody(Map<String, dynamic> map) {
    final buf = StringBuffer();
    buf.writeln(map['message']?.toString() ?? '');
    final years = map['years'] as List? ?? const [];
    for (final raw in years) {
      final y = Map<String, dynamic>.from(raw as Map);
      final h = Map<String, dynamic>.from(y['yearHealth'] as Map? ?? {});
      final nat = Map<String, dynamic>.from(h['natureza'] as Map? ?? {});
      final suspects = h['suspectsRemaining'] ?? 0;
      buf.writeln(
        '· ${y['year']}: +${y['inserted'] ?? 0}'
        '${y['skipped'] == true ? ' (já commitado)' : ''}'
        '${h.isNotEmpty ? ' · Bio ${nat['Biologia'] ?? 0}/Qui ${nat['Química'] ?? 0}/Fis ${nat['Física'] ?? 0}' : ''}'
        '${suspects is int && suspects > 0 ? ' · $suspects suspeitas' : ''}',
      );
    }
    buf.write(_naturezaPackLine(
      map['naturezaPack'] is Map ? Map<String, dynamic>.from(map['naturezaPack'] as Map) : null,
    ));
    return buf.toString().trim();
  }

  Future<void> _semana1Real() async {
    setState(() {
      busy = true;
      msg = 'Semana 1: atualizando 2024–26…';
    });
    try {
      final data = await apiClient.post('/api/acervo/bootstrap-and-commit-available', {
        'dryRun': false,
        'overwrite': false,
        'minConfidence': 0.55,
        'skipCommitted': true,
        'autoProfessor': true,
      });
      final map = Map<String, dynamic>.from(data as Map);
      final inserted = map['insertedTotal'] as int? ?? 0;
      final empty = map['emptyDisk'] == true || inserted == 0;
      final pack = map['naturezaPack'] is Map ? Map<String, dynamic>.from(map['naturezaPack'] as Map) : null;
      final sessao = map['sessionPath']?.toString() ?? '/sessao?examBoard=UEMA_PAES&preferNatureza=1';
      final body = _semana1HealthBody(map);
      setState(() => msg = map['message']?.toString() ?? body);

      if (!mounted) return;
      if (inserted > 0) await _dismissFirstRunCoach();
      if (empty && inserted == 0) {
        final portals = (map['portals'] as List? ?? []);
        final portal = portals.isNotEmpty
            ? (Map<String, dynamic>.from(portals.first as Map)['portal']?.toString())
            : null;
        await _showFetchPlaybook(
          title: 'Semana 1 — sem PDFs',
          body: body,
          portal: portal,
          canCommitDisk: (map['onDiskCount'] as int? ?? 0) > 0,
        );
        await _load();
        return;
      }

      final fetchErrs = map['fetchErrors'] as List? ?? const [];
      if (fetchErrs.isNotEmpty && inserted == 0) {
        await _showFetchPlaybook(
          title: 'Semana 1 — fetch falhou',
          body: body,
          canCommitDisk: (map['onDiskCount'] as int? ?? 0) > 0,
        );
      }

      await _showPostCommitCta(
        title: 'Semana 1 concluída',
        body: '$body\nEstudar Natureza agora?',
        sessaoPath: sessao,
        professor: map['professor'] is Map ? Map<String, dynamic>.from(map['professor'] as Map) : null,
        naturezaPack: pack,
      );
      // Ciclo I: reclassificar Natureza 1x após commit
      try {
        await apiClient.post('/api/ingest/classify-pending', {});
      } catch (e) {
        if (mounted) {
          final note = humanApiError(e, fallback: 'Reclassificação Natureza não rodou.');
          setState(() => msg = msg == null || msg!.isEmpty ? note : '${msg!} · $note');
        }
      }
      ref.read(refreshTickProvider.notifier).state++;
      await _load();
    } catch (e) {
      final err = humanApiError(e, fallback: 'Semana 1 falhou — tente de novo.');
      setState(() => msg = err);
      if (mounted) {
        await _showFetchPlaybook(
          title: 'Semana 1 — erro',
          body: '$err\nUse Abrir provas/gabaritos ou o portal da lista de materiais.',
          canCommitDisk: true,
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _commitOnDisk() async {
    setState(() {
      busy = true;
      msg = 'Gravando PDFs no acervo…';
    });
    try {
      final data = await apiClient.post('/api/acervo/commit-on-disk', {
        'dryRun': false,
        'minConfidence': 0.55,
        'skipCommitted': true,
        'autoProfessor': true,
      });
      final map = Map<String, dynamic>.from(data as Map);
      final inserted = map['insertedTotal'] ?? 0;
      final n = map['officialCount'] ?? 0;
      final healthLine = _healthLine(map, inserted: inserted);
      final pack = map['naturezaPack'] is Map ? Map<String, dynamic>.from(map['naturezaPack'] as Map) : null;
      final packLine = _naturezaPackLine(pack);
      final sessao = map['sessionPath']?.toString() ?? '/sessao?examBoard=UEMA_PAES&preferNatureza=1';
      setState(() => msg = map['message']?.toString() ?? 'Disco: $inserted · base $n$healthLine');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disco OK · +$inserted · oficiais $n$healthLine'),
          action: SnackBarAction(label: 'Estudar agora', onPressed: () { HapticFeedback.mediumImpact(); _goStudy(sessao); }),
          duration: const Duration(seconds: 6),
        ),
      );
      await _showPostCommitCta(
        title: 'PDFs gravados no computador',
        body: 'Disco OK · +$inserted · base $n$healthLine$packLine\nAbrir sessão UEMA Natureza?',
        sessaoPath: sessao,
        professor: map['professor'] is Map ? Map<String, dynamic>.from(map['professor'] as Map) : null,
        naturezaPack: pack,
      );
      ref.read(refreshTickProvider.notifier).state++;
      await _load();
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Commit no disco falhou — tente de novo.'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _importAllComplete() async {
    setState(() {
      busy = true;
      msg = 'Importando todos os pares com gabarito…';
    });
    try {
      final data = await apiClient.post('/api/acervo/import-all-complete', {
        'minConfidence': 0.55,
        'skipIfCommitted': false,
        'classifyAfter': true,
      });
      final map = Map<String, dynamic>.from(data as Map);
      final inserted = map['insertedTotal'] ?? 0;
      final n = map['officialCount'] ?? 0;
      final years = (map['years'] as List?) ?? const [];
      final waiting = (map['waitingYears'] as List?) ?? const [];
      final health = map['healthByYear'] is Map
          ? Map<String, dynamic>.from(map['healthByYear'] as Map)
          : <String, dynamic>{};
      final perYear = years.map((raw) {
        final y = Map<String, dynamic>.from(raw as Map);
        final yr = y['year'];
        final ins = y['inserted'] ?? 0;
        final err = y['error']?.toString();
        final pct = y['gabaritoPct'] ?? (health['$yr'] is Map ? (health['$yr'] as Map)['gabaritoPct'] : null);
        final pctTxt = pct != null ? ' · gabarito $pct%' : '';
        if (err != null && err.isNotEmpty) return '$yr: erro ($err)';
        if (y['needsGabarito'] == true) return '$yr: precisa gabarito';
        if (y['skipped'] == true || y['reason'] == 'already_committed') {
          return '$yr: já na base · +$ins$pctTxt';
        }
        return '$yr: +$ins$pctTxt';
      }).join('\n');
      final waitLine = waiting.isEmpty
          ? ''
          : '\nAguardando gabarito: ${waiting.map((e) => e.toString()).join(', ')}.';
      final sessao = map['sessionPath']?.toString() ??
          '/sessao?examBoard=UEMA_PAES&preferNatureza=1&officialWithGab=1';
      setState(
        () => msg = map['message']?.toString() ?? 'Import todos · +$inserted · base $n',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import todos · +$inserted · oficiais $n'),
          action: SnackBarAction(label: 'Estudar', onPressed: () { HapticFeedback.mediumImpact(); _goStudy(sessao); }),
          duration: const Duration(seconds: 7),
        ),
      );
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Importar todos com gabarito'),
          content: SingleChildScrollView(
            child: Text(
              '${map['message'] ?? ''}\n\n$perYear$waitLine\n\n'
              'Base oficial: $n. Abrir sessão só com oficiais com gabarito?',
            ),
          ),
          actions: [
            if (waiting.isNotEmpty)
              TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(ctx);
                  _openFolder('gabaritos');
                },
                child: const Text('Abrir pasta Gabaritos'),
              ),
            TextButton(onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(ctx); }, child: const Text('Fechar')),
            FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(ctx);
                _goStudy(sessao);
              },
              child: const Text('Estudar'),
            ),
          ],
        ),
      );
      ref.read(refreshTickProvider.notifier).state++;
      await _load();
    } catch (e) {
      setState(
        () => msg = humanApiError(e, fallback: 'Importar todos com gab falhou — tente de novo.'),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _uiStatusLabel(String? s) {
    switch (s) {
      case 'committed':
        return 'No acervo';
      case 'onDisk':
        return 'Par com gabarito · pode gravar';
      case 'partial':
        return 'Parcial · sem gabarito';
      case 'partialGab':
        return 'Só gabarito · falta prova';
      case 'preview':
        return 'Precisa revisar';
      case 'found':
        return 'Pode baixar';
      case 'needs_manual':
        return 'Baixar à mão';
      default:
        return 'Vazio';
    }
  }

  String _uiBadge(String? status, {required bool ready, required bool diskOk, required bool hasProva, required bool hasGab}) {
    if (ready) return 'pronto';
    if (status == 'partial' || (hasProva && !hasGab)) return 'parcial';
    if (diskOk) return 'prova + gabarito';
    return status ?? '';
  }

  Future<void> _importYearSafe(int year) async {
    setState(() {
      busy = true;
      msg = 'Importando do PC · PAES $year…';
    });
    try {
      final data = await apiClient.post('/api/acervo/import-year-safe', {
        'year': year,
        'commit': true,
        'minConfidence': 0.55,
        'skipIfCommitted': false,
      });
      final map = Map<String, dynamic>.from(data as Map);
      if (map['needsGabarito'] == true) {
        setState(() => msg = map['message']?.toString() ?? 'Falta gabarito.');
        if (!mounted) return;
        final open = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('PAES $year · sem gabarito'),
            content: Text(
              map['message']?.toString() ??
                  'Coloque gabarito_$year.pdf em data/gabaritos. Preview pronto: ${map['count'] ?? 0} questões.',
            ),
            actions: [
              TextButton(onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(ctx, false); }, child: const Text('OK')),
              FilledButton(
                onPressed: () { HapticFeedback.mediumImpact(); Navigator.pop(ctx, true); },
                child: const Text('Abrir gabaritos'),
              ),
              if (map['previewId'] != null)
                TextButton(
                  onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(ctx, null); },
                  child: const Text('Ver preview'),
                ),
            ],
          ),
        );
        if (open == true) {
          await _openFolder('gabaritos');
        } else if (open == null && map['previewId'] != null && mounted) {
          final questions = List<Map<String, dynamic>>.from(
            (map['questions'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
          );
          context.push(
            '/biblioteca/revisao',
            extra: IngestReviewArgs(
              year: year,
              previewId: map['previewId'].toString(),
              questions: questions,
              meta: map,
            ),
          );
        }
        await _load();
        return;
      }
      final inserted = map['inserted'] ?? 0;
      final n = map['officialCount'] ?? 0;
      final sessao = map['sessionPath']?.toString() ??
          '/sessao?examBoard=UEMA_PAES&year=$year&preferNatureza=1';
      setState(() => msg = map['message']?.toString() ?? 'OK · $inserted');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PAES $year · +$inserted · base $n'),
          action: SnackBarAction(label: 'Estudar', onPressed: () { HapticFeedback.mediumImpact(); _goStudy(sessao); }),
        ),
      );
      ref.read(refreshTickProvider.notifier).state++;
      await _load();
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Importação do PC $year falhou.'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _naturezaPackLine(Map<String, dynamic>? pack) {
    if (pack == null) return '';
    final n = pack['cardsCreated'] as int? ?? 0;
    final d = pack['drafts'] as int? ?? 0;
    if (n <= 0 && d <= 0) return '';
    return '\nPacote Natureza: $n cartões para revisar amanhã'
        '${d > 0 ? ' · $d com rascunho professor' : ''}.';
  }

  Future<bool> _confirmStudyDespiteParse({
    Map<String, dynamic>? yearHealth,
    Map<String, dynamic>? pending,
  }) async {
    try {
      final data = await apiClient.post('/api/acervo/parse-gate', {
        if (yearHealth != null) 'yearHealth': yearHealth,
        if (pending != null) 'pending': pending,
      });
      final gate = Map<String, dynamic>.from(data as Map);
      if (gate['warn'] != true) return true;
      if (!mounted) return false;
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Revisão necessária'),
          content: Text(
            '${gate['message'] ?? 'Revise as suspeitas e os PDFs escaneados antes de estudar.'}\n'
            'Suspeitas: ${gate['suspects'] ?? 0} · PDFs escaneados: ${gate['needsOcr'] == true ? 'sim' : 'não'}',
          ),
          actions: [
            TextButton(onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(ctx, 'review'); }, child: const Text('Revisar suspeitas')),
            FilledButton(onPressed: () { HapticFeedback.mediumImpact(); Navigator.pop(ctx, 'study'); }, child: const Text('Estudar mesmo assim')),
          ],
        ),
      );
      if (choice == 'review') {
        // scroll mentally — user stays on biblioteca / pending section
        return false;
      }
      return choice == 'study';
    } catch (e) {
      if (mounted) {
        setState(
          () => msg = humanApiError(
            e,
            fallback: 'Verificação de parse indisponível — siga com cuidado.',
          ),
        );
      }
      return true;
    }
  }

  Future<void> _goStudy(String sessaoPath, {Map<String, dynamic>? yearHealth}) async {
    final pending = Map<String, dynamic>.from(
      (library?['pendingPreviews'] as Map?) ??
          ((library?['checklist'] as Map?)?['pendingPreviews'] as Map?) ??
          const {},
    );
    final ok = await _confirmStudyDespiteParse(
      yearHealth: yearHealth,
      pending: pending.isEmpty ? null : pending,
    );
    if (!ok || !mounted) return;
    final path = sessaoPath.contains('preferNatureza')
        ? sessaoPath
        : '$sessaoPath${sessaoPath.contains('?') ? '&' : '?'}preferNatureza=1';
    context.go(path);
  }

  Future<void> _bootstrapAndCommitYear(int year) async {
    setState(() {
      busy = true;
      msg = 'Gravando PAES $year no acervo…';
    });
    try {
      final data = await apiClient.post('/api/acervo/bootstrap-and-commit', {
        'dryRun': false,
        'overwrite': false,
        'year': year,
        'minConfidence': 0.55,
        'autoProfessor': true,
      });
      final map = Map<String, dynamic>.from(data as Map);
      final inserted = map['inserted'] ?? 0;
      final n = map['officialCount'] ?? 0;
      final healthLine = _healthLine(map, inserted: inserted);
      final pack = map['naturezaPack'] is Map ? Map<String, dynamic>.from(map['naturezaPack'] as Map) : null;
      final packLine = _naturezaPackLine(pack);
      final sessao = map['sessionPath']?.toString() ??
          '/sessao?examBoard=UEMA_PAES&year=$year&preferNatureza=1';
      setState(() => msg = map['message']?.toString() ?? 'OK · $inserted · base $n$healthLine');
      if (!mounted) return;
      await _showPostCommitCta(
        title: 'PAES $year no acervo',
        body: 'Gravamos $inserted · base $n$healthLine$packLine\nEstudar Natureza agora?',
        sessaoPath: sessao,
        professor: map['professor'] is Map ? Map<String, dynamic>.from(map['professor'] as Map) : null,
        yearHealth: map['yearHealth'] is Map ? Map<String, dynamic>.from(map['yearHealth'] as Map) : null,
        naturezaPack: pack,
      );
      ref.read(refreshTickProvider.notifier).state++;
      await _load();
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Gravação $year falhou — tente de novo.'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _importYear(int year) async {
    setState(() {
      busy = true;
      msg = 'Importando $year para revisão...';
    });
    try {
      final data = await apiClient.post('/api/ingest/import-year', {'year': year, 'commit': false});
      final map = Map<String, dynamic>.from(data as Map);
      setState(() => msg = map['message']?.toString() ?? '$map');
      if (map['previewId'] != null && map['ok'] != false) {
        if (!mounted) return;
        final questions = List<Map<String, dynamic>>.from(
          (map['questions'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
        );
        context.push(
          '/biblioteca/revisao',
          extra: IngestReviewArgs(
            year: year,
            previewId: map['previewId'].toString(),
            questions: questions,
            meta: map,
          ),
        );
      }
      ref.read(refreshTickProvider.notifier).state++;
      await _load();
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Não deu para concluir. Tente de novo.'));
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _openFolder(String folder) async {
    try {
      final data = await apiClient.post('/api/library/open-folder', {'folder': folder});
      final path = (data as Map)['path']?.toString() ?? folder;
      setState(() => msg = 'Pasta aberta: $path');
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Não deu para concluir. Tente de novo.'));
    }
  }

  Future<void> _loadSearchHistory() async {
    try {
      final data = await apiClient.get('/api/library/search-history', {'limit': '12'});
      final map = Map<String, dynamic>.from(data as Map);
      if (!mounted) return;
      setState(() {
        searchHistory = (map['items'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        searchHistoryNote = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        searchHistory = [];
        searchHistoryNote = humanApiError(e, fallback: 'Histórico de buscas indisponível.');
      });
    }
  }

  /// Debounce: dispara a busca 350ms após o usuário parar de digitar.
  /// Evita 1 HTTP por tecla e cancela buscas anteriores obsoletas.
  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  Future<void> _runSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        searchHits = [];
        searchNote = null;
        _hitSelected = 0;
      });
      return;
    }
    setState(() => searching = true);
    try {
      final params = <String, String>{
        'q': q,
        'limit': '30',
      };
      if (searchSourceKind == 'oficial') {
        params['sourceKind'] = 'oficial';
      } else if (searchSourceKind == 'estudo') {
        params['sourceKind'] = 'estudo';
      }
      final data = await apiClient.get('/api/library/search', params);
      final map = Map<String, dynamic>.from(data as Map);
      setState(() {
        searchHits = (map['items'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        searchNote = map['note']?.toString();
        _hitSelected = 0;
      });
      await _loadSearchHistory();
    } catch (e) {
      setState(() {
        searchHits = [];
        searchNote = humanApiError(e, fallback: 'Busca indisponível agora. Tente de novo.');
      });
    } finally {
      setState(() => searching = false);
    }
  }

  Future<void> _openSearchHit(Map<String, dynamic> hit) async {
    final id = hit['id']?.toString();
    final path = hit['path']?.toString() ?? '';
    if (hit['kind'] == 'question' && id != null && id.isNotEmpty) {
      if (mounted) context.go('/questoes/$id');
      return;
    }
    if (path.isNotEmpty) {
      try {
        await apiClient.openPath(path);
        setState(() => msg = 'Abrindo ${hit['label'] ?? path}');
      } catch (e) {
        setState(
          () => msg = humanOpenPathError(
            e,
            label: hit['label']?.toString() ?? 'Arquivo',
          ),
        );
      }
    }
  }

  Future<void> _fetchAvailable() async {
    setState(() {
      busy = true;
      msg = 'Baixando todos os oficiais disponíveis...';
    });
    try {
      final data = await apiClient.post('/api/acervo/fetch-available', {
        'dryRun': false,
        'overwrite': false,
      });
      final map = Map<String, dynamic>.from(data as Map);
      setState(() => msg = map['message']?.toString() ?? '$map');
      await _load();
      final next = map['nextReviewYear'];
      if (next is int && mounted) {
        final go = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Revisar PAES $next'),
            content: const Text('Anos baixados. Abrir revisão do próximo ano completo?'),
            actions: [
              TextButton(onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(ctx, false); }, child: const Text('Depois')),
              FilledButton(onPressed: () { HapticFeedback.mediumImpact(); Navigator.pop(ctx, true); }, child: const Text('Revisar')),
            ],
          ),
        );
        if (go == true) await _importYear(next);
      }
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Não deu para concluir. Tente de novo.'));
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _fetchYear(int year) async {
    setState(() {
      busy = true;
      msg = 'Baixando oficiais PAES $year...';
    });
    try {
      final data = await apiClient.post('/api/acervo/fetch-year', {
        'year': year,
        'dryRun': false,
        'overwrite': false,
      });
      final map = Map<String, dynamic>.from(data as Map);
      setState(() => msg = map['message']?.toString() ?? '$map');
      await _load();
      final local = map['local'] as Map?;
      if (local != null && local['hasProva'] == true && local['hasGabarito'] == true && mounted) {
        final go = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('PAES $year baixado'),
            content: const Text('PDFs na pasta. Abrir revisão agora?'),
            actions: [
              TextButton(onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(ctx, false); }, child: const Text('Depois')),
              FilledButton(onPressed: () { HapticFeedback.mediumImpact(); Navigator.pop(ctx, true); }, child: const Text('Revisar')),
            ],
          ),
        );
        if (go == true) await _importYear(year);
      } else if (map['fetchFailed'] == true || map['ok'] != true) {
        if (!mounted) return;
        await _showFetchPlaybook(
          title: 'Importação do PAES $year falhou',
          body: map['message']?.toString() ??
              'A importação falhou. Use o portal, escolha os arquivos manualmente ou tente de novo.',
          portal: map['portal']?.toString() ??
              (map['playbook'] is Map ? (map['playbook'] as Map)['portal']?.toString() : null),
          year: year,
          canCommitDisk: local != null && local['hasProva'] == true && local['hasGabarito'] == true,
        );
      }
    } catch (e) {
      final err = humanApiError(e, fallback: 'Não deu para concluir. Tente de novo.');
      setState(() => msg = err);
      if (mounted) {
        await _showFetchPlaybook(
          title: 'Importação do PAES $year falhou',
          body: err,
          year: year,
        );
      }
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _classify() async {
    setState(() => busy = true);
    try {
      final data = await apiClient.post('/api/ingest/classify-pending', {});
      setState(() => msg = 'Classificação: $data');
      await _load();
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Não deu para concluir. Tente de novo.'));
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _syncEdital() async {
    setState(() => busy = true);
    try {
      final data = await apiClient.post('/api/edital/sync-syllabus', {});
      setState(() => msg = 'Syllabus: $data');
      await _load();
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Não deu para concluir. Tente de novo.'));
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _fixQuestions() async {
    setState(() => busy = true);
    try {
      final data = await apiClient.post('/api/library/fix-questions', {});
      final msgStr = data is Map ? (data['message']?.toString() ?? 'Correção concluída') : 'Correção concluída';
      setState(() => msg = msgStr);
      await _load();
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Não deu para corrigir agora. Tente de novo.'));
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _generateResolutions() async {
    setState(() { busy = true; msg = 'Gerando resoluções com IA... isso pode levar alguns minutos.'; });
    try {
      final data = await apiClient.post('/api/ai/generate-resolutions', {'limit': 20});
      final msgStr = data is Map ? (data['message']?.toString() ?? 'Resoluções geradas') : 'Resoluções geradas';
      setState(() => msg = msgStr);
      await _loadResolutionStats();
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Não deu para gerar resoluções agora. Tente de novo.'));
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _generateLessons() async {
    setState(() { busy = true; msg = 'Gerando aulas com IA... isso pode levar alguns minutos.'; });
    try {
      final data = await apiClient.post('/api/ai/generate-lessons', {'limit': 10});
      final msgStr = data is Map ? (data['message']?.toString() ?? 'Aulas geradas') : 'Aulas geradas';
      setState(() => msg = msgStr);
      await _loadLessonStats();
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Não deu para gerar aulas agora. Tente de novo.'));
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _loadResolutionStats() async {
    try {
      final data = await apiClient.get('/api/ai/resolution-stats');
      if (data is Map) setState(() => resolutionStats = data['message']?.toString());
    } catch (_) {}
  }

  Future<void> _loadLessonStats() async {
    try {
      final data = await apiClient.get('/api/ai/lesson-stats');
      if (data is Map) setState(() => lessonStats = data['message']?.toString());
    } catch (_) {}
  }

  Future<void> _loadStudyPdfs() async {
    try {
      final res = await apiClient.get('/api/materials/pdf-list');
      final list = (res as List).cast<Map<String, dynamic>>();
      setState(() {
        _studyPdfs = list;
        _pdfsLoaded = true;
      });
    } catch (_) {
      setState(() => _pdfsLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (busy && library == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonList(count: 4, lines: 2),
      );
    }
    if (error != null) {
      return EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'Biblioteca indisponível',
        subtitle: error!,
        action: FilledButton(onPressed: () { HapticFeedback.mediumImpact(); _load(); }, child: const Text('Tentar de novo')),
      );
    }
    final checklist = Map<String, dynamic>.from(library?['checklist'] as Map? ?? {});
    final officialN = (checklist['officialCount'] as int?) ?? 0;
    final gridAll = (library?['yearGrid'] as List?) ?? (checklist['yearGrid'] as List?) ?? const [];
    final board = gridAll
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((g) {
          final y = g['year'] as int? ?? 0;
          return y >= 2024 && y <= 2026;
        })
        .toList();
    final hist = gridAll
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((g) {
          final y = g['year'] as int? ?? 0;
          return y >= 2014 && y <= 2023;
        })
        .toList();
    final pending = Map<String, dynamic>.from(
      (library?['pendingPreviews'] as Map?) ?? (checklist['pendingPreviews'] as Map?) ?? const {},
    );
    final pendingItems = pending['items'] as List? ?? const [];
    final pendingN = pending['pendingCount'] as int? ?? pendingItems.length;
    final anosParciais = (checklist['anosParciaisCount'] as int?) ??
        (checklist['anosParciais'] as List?)?.length ??
        0;
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: 'Materiais',
                title: 'Biblioteca',
                subtitle: officialN > 0
                    ? '$officialN questões oficiais disponíveis'
                    : 'Importe as provas oficiais e comece a estudar',
                trailing: IconButton(
                  tooltip: 'Atualizar',
                  onPressed: busy ? null : () { HapticFeedback.selectionClick(); _load(); },
                  icon: busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded),
                ),
              ),

              if (busy)
                SurfacePanel(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: cs.secondaryContainer.f45,
                  child: Row(
                    children: [
                      const SoftLoader(compact: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          msg ?? 'Trabalhando no acervo… pode demorar um pouco.',
                          style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: cs.onSurface.withOpacity(0.85)),
                        ),
                      ),
                    ],
                  ),
                ),

              if (showFirstRunCoach && officialN == 0) ...[
                SurfacePanel(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: cs.primaryContainer.f55,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bem-vindo — Semana 1', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                      const SizedBox(height: 8),
                      Text(
                        'Toque em Atualizar 2024–26 abaixo para importar provas UEMA. '
                        'Sem PDFs no PC? Use Abrir provas e coloque paes_YYYY.pdf na pasta.',
                        style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.9)),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: busy ? null : () { HapticFeedback.mediumImpact(); unawaited(_semana1Real()); },
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text('Atualizar 2024–26'),
                          ),
                          TextButton(onPressed: () { HapticFeedback.selectionClick(); _dismissFirstRunCoach(); }, child: const Text('Depois')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              if (partialLoadNote != null && error == null) ...[
                QuietEmpty(
                  message: partialLoadNote!,
                  action: TextButton(
                    onPressed: busy ? null : () { HapticFeedback.selectionClick(); _load(); },
                    child: const Text('Tentar'),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 8),
              TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Buscar no acervo',
                  hintText: 'ex.: genética, osmose…',
                  suffixIcon: IconButton(
                    tooltip: 'Buscar',
                    onPressed: searching ? null : () { HapticFeedback.selectionClick(); _runSearch(); },
                    icon: searching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search_rounded),
                  ),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _runSearch(),
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final kind in const [
                    ('todos', 'Todos'),
                    ('oficial', 'Oficial'),
                    ('estudo', 'Estudo'),
                  ])
                    ChoiceChip(
                      label: Text(kind.$2),
                      selected: searchSourceKind == kind.$1,
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => searchSourceKind = kind.$1);
                        if (_searchCtrl.text.trim().isNotEmpty) _runSearch();
                      },
                    ),
                ],
              ),
              if (searchHistoryNote != null) ...[
                const SizedBox(height: 8),
                Text(
                  searchHistoryNote!,
                  style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (searchHistory.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final h in searchHistory.take(8))
                      ActionChip(
                        label: Text(
                          h['q']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          final q = h['q']?.toString() ?? '';
                          if (q.isEmpty) return;
                          _searchCtrl.text = q;
                          final sk = h['sourceKind']?.toString();
                          if (sk == 'oficial' || sk == 'estudo') {
                            searchSourceKind = sk!;
                          } else {
                            searchSourceKind = 'todos';
                          }
                          _runSearch();
                        },
                      ),
                  ],
                ),
              ],
              if (searchNote != null && searchHits.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: QuietEmpty(
                    message: searchNote!,
                    action: TextButton(
                      onPressed: searching ? null : () { HapticFeedback.selectionClick(); _runSearch(); },
                      child: const Text('Tentar'),
                    ),
                  ),
                ),
              if (searchHits.isNotEmpty) ...[
                SectionLabel('Resultados', hint: '↑/↓ J/K · Enter abre · ${searchHits.length} local'),
                for (var i = 0; i < searchHits.take(12).length; i++)
                  Builder(
                    builder: (_) {
                      final hit = searchHits[i];
                      return PlaylistTile(
                        title: hit['label']?.toString() ?? 'arquivo',
                        subtitle:
                            '${hit['sourceKind'] ?? hit['kind'] ?? ''}${hit['year'] != null ? ' · ${hit['year']}' : ''}',
                        badge: hit['sourceKind']?.toString() == 'oficial' ? 'oficial' : 'local',
                        active: i == _hitSelected,
                        leadingIcon: hit['kind'] == 'question'
                            ? Icons.quiz_outlined
                            : Icons.description_outlined,
                        onPlay: () {
                          HapticFeedback.selectionClick();
                          setState(() => _hitSelected = i);
                          _openSearchHit(hit);
                        },
                      );
                    },
                  ),
              ],

              // Painel de boas-vindas só aparece quando não há oficiais
              if (showFirstRunCoach && officialN == 0) ...[
                SurfacePanel(
                  key: _semana1PanelKey,
                  margin: const EdgeInsets.only(bottom: 16),
                  color: cs.primaryContainer.withOpacity(0.65),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.waving_hand_rounded, color: cs.primary, size: 24),
                          const SizedBox(width: 8),
                          Text('Bem-vindo!', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onPrimaryContainer)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Importe as provas oficiais da UEMA para começar a estudar. '
                        'Toque em "Importar todos" abaixo.',
                        style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: cs.onPrimaryContainer.withOpacity(0.9)),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: busy ? null : () { HapticFeedback.mediumImpact(); _semana1Real(); },
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text('Importar provas 2024–26'),
                          ),
                          TextButton(onPressed: () { HapticFeedback.selectionClick(); _dismissFirstRunCoach(); }, child: const Text('Depois')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              SectionLabel('Provas recentes', hint: '2024–26'),
              if (board.isEmpty)
                QuietEmpty(
                  message: 'Nenhuma prova 2024–26 ainda. Toque para importar.',
                  action: Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: busy ? null : () { HapticFeedback.mediumImpact(); _semana1Real(); },
                        child: const Text('Importar provas'),
                      ),
                      TextButton(
                        onPressed: () { HapticFeedback.selectionClick(); context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1'); },
                        child: const Text('Ir para Sessão'),
                      ),
                    ],
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: board.length,
                  itemBuilder: (context, i) {
                    final g = board[i];
                    final y = g['year'] as int? ?? 0;
                    final status = g['uiStatus']?.toString() ?? 'empty';
                    final n = g['committedCount'] as int? ?? 0;
                    final canFetch = g['canFetch'] == true;
                    final onDisk = Map<String, dynamic>.from(g['onDisk'] as Map? ?? {});
                    final hasProva = onDisk['hasProva'] == true;
                    final hasGab = onDisk['hasGabarito'] == true;
                    final diskOk = hasProva && hasGab;
                    final partial = hasProva && !hasGab;
                    final ready = status == 'committed' || n > 0;
                    final label = g['labelHint']?.toString() ?? _uiStatusLabel(status);
                    final cardColor = ready
                        ? cs.primaryContainer
                        : partial
                            ? cs.tertiaryContainer
                            : cs.surfaceContainerHigh;
                    final iconColor = ready ? cs.primary : partial ? cs.tertiary : cs.onSurfaceVariant;
                    final statusIcon = ready ? Icons.check_circle_rounded : partial ? Icons.warning_amber_rounded : Icons.hourglass_empty_rounded;
                    return TapScale(
                      child: Material(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: busy ? null : () {
                            HapticFeedback.selectionClick();
                            if (ready) {
                              _goStudy('/sessao?examBoard=UEMA_PAES&year=$y&preferNatureza=1');
                            } else if (partial) {
                              _importYear(y);
                            } else if (canFetch || diskOk) {
                              diskOk ? _importYearSafe(y) : _bootstrapAndCommitYear(y);
                            } else {
                              _fetchYear(y);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$y',
                                      style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: iconColor,
                                      ),
                                    ),
                                    Icon(statusIcon, color: iconColor, size: 22),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ready ? '${n} questões' : label,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: ready ? cs.onPrimaryContainer : cs.onSurface.withOpacity(0.85),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      ready ? 'Pronto para estudar' : partial ? 'Falta gabarito' : canFetch ? 'Toque para importar' : 'Sem PDF',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: ready ? cs.onPrimaryContainer.withOpacity(0.85) : cs.onSurface.withOpacity(0.6),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // Ações rápidas em linha
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: busy ? null : () { HapticFeedback.mediumImpact(); _importAllComplete(); },
                    icon: const Icon(Icons.library_add_check_rounded, size: 18),
                    label: const Text('Importar todos com gabarito'),
                  ),
                  if (officialN > 0)
                    FilledButton.tonal(
                      onPressed: () { HapticFeedback.mediumImpact(); context.go(
                        '/sessao?examBoard=UEMA_PAES&preferNatureza=1&officialWithGab=1',
                      ); },
                      child: const Text('Estudar agora'),
                    ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : () { HapticFeedback.selectionClick(); _commitOnDisk(); },
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Gravar PDFs do PC'),
                  ),
                ],
              ),
              if (anosParciais > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '$anosParciais ano(s) com prova mas sem gabarito. Coloque o gabarito na pasta para importar.',
                  style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
                ),
              ],

              if (pendingN > 0) ...[
                SectionLabel('Precisa da sua revisão', hint: '$pendingN arquivo(s)'),
                for (final raw in pendingItems.take(4))
                  Builder(
                    builder: (_) {
                      final it = Map<String, dynamic>.from(raw as Map);
                      final y = it['year'];
                      return PlaylistTile(
                        title: it['filename']?.toString() ?? 'Preview',
                        subtitle: '${it['count'] ?? 0} questões',
                        badge: 'revisar',
                        leadingIcon: Icons.preview_rounded,
                        onPlay: y is int ? () { HapticFeedback.selectionClick(); _importYear(y); } : null,
                      );
                    },
                  ),
              ],

              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Provas antigas (2014–23)', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
                subtitle: Text(
                  anosParciais > 0
                      ? '$anosParciais sem gabarito — coloque o arquivo na pasta'
                      : 'Importe se tiver os PDFs no computador',
                ),
                children: [
                  if (hist.isEmpty)
                    QuietEmpty(
                      message:
                          'Nenhuma prova 2014–23 no computador. Coloque os PDFs nas pastas Provas e Gabaritos para importar.',
                      action: TextButton(
                        onPressed: busy ? null : () { HapticFeedback.selectionClick(); _importAllComplete(); },
                        child: const Text('Importar todos com gabarito'),
                      ),
                    )
                  else
                    for (final g in hist)
                      Builder(
                        builder: (_) {
                          final y = g['year'] as int? ?? 0;
                          final status = g['uiStatus']?.toString() ?? 'empty';
                          final n = g['committedCount'] as int? ?? 0;
                          final onDisk = Map<String, dynamic>.from(g['onDisk'] as Map? ?? {});
                          final hasProva = onDisk['hasProva'] == true;
                          final hasGab = onDisk['hasGabarito'] == true;
                          final diskOk = hasProva && hasGab;
                          final partial = hasProva && !hasGab || status == 'partial';
                          final ready = status == 'committed' || n > 0;
                          final label = g['labelHint']?.toString() ??
                              (!diskOk && !ready && !partial
                                  ? 'Falta o PDF deste ano'
                                  : _uiStatusLabel(status));
                          return PlaylistTile(
                            title: 'PAES $y',
                            subtitle: partial
                                ? 'Sem gabarito — coloque o arquivo'
                                : ready
                                    ? 'Pronto ($n questões)'
                                    : label,
                            badge: _uiBadge(
                              status,
                              ready: ready,
                              diskOk: diskOk,
                              hasProva: hasProva,
                              hasGab: hasGab,
                            ),
                            onPlay: ready
                                ? () { HapticFeedback.mediumImpact(); _goStudy(
                                      '/sessao?examBoard=UEMA_PAES&year=$y&preferNatureza=1',
                                    ); }
                                : partial
                                    ? () { HapticFeedback.selectionClick(); _importYear(y); }
                                    : diskOk
                                        ? () { HapticFeedback.selectionClick(); _importYearSafe(y); }
                                        : null,
                            secondary: partial
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextButton(
                                        onPressed: busy ? null : () { HapticFeedback.selectionClick(); _openFolder('gabaritos'); },
                                        child: const Text('Gabaritos'),
                                      ),
                                      TextButton(
                                        onPressed: busy ? null : () { HapticFeedback.selectionClick(); _importYear(y); },
                                        child: const Text('Preview'),
                                      ),
                                    ],
                                  )
                                : !ready && diskOk
                                    ? TextButton(
                                        onPressed: busy ? null : () { HapticFeedback.selectionClick(); _importYearSafe(y); },
                                        child: const Text('Importar do PC'),
                                      )
                                    : null,
                          );
                        },
                      ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: busy ? null : () { HapticFeedback.selectionClick(); _commitOnDisk(); },
                          child: const Text('Gravar todos do PC (só com gab)'),
                        ),
                        TextButton(
                          onPressed: busy ? null : () { HapticFeedback.selectionClick(); _openFolder('gabaritos'); },
                          child: const Text('Abrir gabaritos'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                initiallyExpanded: false,
                title: Text('Opções avançadas', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
                subtitle: const Text('Estatísticas, pastas, download e edital'),
                children: [
                  if (curation != null) ...[
                    Text(
                      'Questões oficiais: ${curation!['officialCount'] ?? '—'}\n'
                      'Com gabarito oficial: ${curation!['realCount'] ?? 0}'
                      '${curation!['realPercent'] != null ? ' (${curation!['realPercent']}%)' : ''}\n'
                      'Questões interdisciplinares: ${curation!['crossDomainCount'] ?? 0}',
                      style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
                    ),
                    if (curation!['message'] != null)
                      Text(
                        curation!['message'].toString(),
                        style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
                      ),
                    const SizedBox(height: 8),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () { HapticFeedback.selectionClick(); _openFolder('provas'); },
                        icon: const Icon(Icons.folder_open_rounded, size: 18),
                        label: const Text('Provas'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () { HapticFeedback.selectionClick(); _openFolder('gabaritos'); },
                        icon: const Icon(Icons.folder_open_rounded, size: 18),
                        label: const Text('Gabaritos'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () { HapticFeedback.selectionClick(); _openFolder('edital'); },
                        icon: const Icon(Icons.folder_open_rounded, size: 18),
                        label: const Text('Edital'),
                      ),
                    ],
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Atualizar conteúdos da prova'),
                    trailing: OutlinedButton(onPressed: busy ? null : () { HapticFeedback.selectionClick(); _syncEdital(); }, child: const Text('Atualizar')),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Organizar questões por assunto'),
                    trailing: OutlinedButton(onPressed: busy ? null : () { HapticFeedback.selectionClick(); _classify(); }, child: const Text('Executar')),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Baixar todos os materiais'),
                    trailing: OutlinedButton(onPressed: busy ? null : () { HapticFeedback.selectionClick(); _fetchAvailable(); }, child: const Text('Baixar')),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Importar e revisar 1º ano'),
                    trailing: OutlinedButton(onPressed: busy ? null : () { HapticFeedback.selectionClick(); _bootstrapFirstYear(); }, child: const Text('Ir')),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Corrigir questões (enunciados, alternativas e gabaritos)'),
                    subtitle: const Text('Limpa artefatos, corta texto misturado e aplica gabaritos oficiais'),
                    trailing: OutlinedButton(onPressed: busy ? null : () { HapticFeedback.selectionClick(); _fixQuestions(); }, child: const Text('Corrigir')),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Gerar resoluções com IA'),
                    subtitle: Text(resolutionStats ?? 'Cria resoluções didáticas (Comando, Conceito, Gabarito, Distrator)'),
                    trailing: OutlinedButton(onPressed: busy ? null : () { HapticFeedback.selectionClick(); _generateResolutions(); }, child: const Text('Gerar')),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Gerar aulas com IA'),
                    subtitle: Text(lessonStats ?? 'Cria aulas estruturadas para cada tópico do edital'),
                    trailing: OutlinedButton(onPressed: busy ? null : () { HapticFeedback.selectionClick(); _generateLessons(); }, child: const Text('Gerar')),
                  ),
                  if (coverage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      coverage!['message']?.toString() ?? '',
                      style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
                    ),
                  ],
                  if (library?['dataDir'] != null)
                    Text(
                      'Pasta: ${library!['dataDir']}',
                      style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
                    ),
                ],
              ),

              if (msg != null && !busy) ...[
                const SizedBox(height: 12),
                if (msg!.contains('sumiu') ||
                    msg!.contains('não abriu') ||
                    msg!.contains('nao abriu') ||
                    msg!.contains('Sem PDF'))
                  QuietEmpty(
                    message: msg!,
                    action: FilledButton.tonal(
                      onPressed: () { HapticFeedback.selectionClick(); unawaited(_openFolder('provas')); },
                      child: const Text('Abrir provas'),
                    ),
                  )
                else if (msg!.toLowerCase().contains('oficiais') ||
                    msg!.toLowerCase().contains('grav') ||
                    msg!.toLowerCase().contains('import') ||
                    msg!.toLowerCase().contains('base'))
                  QuietEmpty(
                    message: msg!,
                    action: Wrap(
                      spacing: 8,
                      children: [
                        FilledButton(
                          onPressed: () { HapticFeedback.mediumImpact(); _goStudy(
                            '/sessao?examBoard=UEMA_PAES&preferNatureza=1&officialWithGab=1',
                          ); },
                          child: const Text('Estudar agora'),
                        ),
                        TextButton(
                          onPressed: () { HapticFeedback.selectionClick(); context.go('/fila'); },
                          child: const Text('Abrir fila'),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    msg!,
                    style: GoogleFonts.inter(fontSize: 13, color: cs.primary),
                  ),
              ],

              // === SEÇÃO: PDFs de estudo ===
              if (_pdfsLoaded && _studyPdfs.isNotEmpty) ...[
                const SizedBox(height: 24),
                SurfacePanel(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.picture_as_pdf_rounded, size: 22, color: cs.error),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Materiais de Estudo',
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface),
                            ),
                          ),
                          Text(
                            '${_studyPdfs.length} PDFs',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(0.5)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toque em qualquer material para abrir o leitor integrado',
                        style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 14),
                      // Agrupar por disciplina
                      ..._buildPdfGroups(cs),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPdfGroups(ColorScheme cs) {
    final bySubject = <String, List<Map<String, dynamic>>>{};
    for (final p in _studyPdfs) {
      final subj = p['subject']?.toString() ?? 'Outros';
      bySubject.putIfAbsent(subj, () => []).add(p);
    }
    final subjects = bySubject.keys.toList()..sort();
    final subjectIcons = {
      'Biologia': Icons.biotech_rounded,
      'Química': Icons.science_rounded,
      'Física': Icons.bolt_rounded,
      'Matemática': Icons.calculate_rounded,
      'Geografia': Icons.public_rounded,
      'História': Icons.account_balance_rounded,
      'Português': Icons.menu_book_rounded,
      'Inglês': Icons.translate_rounded,
      'Espanhol': Icons.language_rounded,
      'Filosofia': Icons.psychology_rounded,
      'Sociologia': Icons.groups_rounded,
    };
    final subjectColors = {
      'Biologia': Colors.green,
      'Química': Colors.deepOrange,
      'Física': Colors.blue,
      'Matemática': Colors.purple,
      'Geografia': Colors.teal,
      'História': Colors.brown,
      'Português': Colors.red,
      'Inglês': Colors.lightBlue,
      'Espanhol': Colors.amber,
      'Filosofia': Colors.blueGrey,
      'Sociologia': Colors.deepPurple,
    };

    return subjects.map((subject) {
      final items = bySubject[subject]!;
      final icon = subjectIcons[subject] ?? Icons.book_rounded;
      final color = subjectColors[subject] ?? cs.primary;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  '$subject (${items.length})',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((pdf) {
              final title = pdf['title']?.toString() ?? 'Material';
              final filename = pdf['filename']?.toString() ?? '';
              return ActionChip(
                avatar: Icon(Icons.picture_as_pdf, size: 16, color: color),
                label: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.go(Uri(path: '/estudar', queryParameters: {
                    'pdf': filename,
                    'title': title,
                    'subject': subject,
                  }).toString());
                },
              );
            }).toList(),
          ),
        ],
      );
    }).toList();
  }
}
