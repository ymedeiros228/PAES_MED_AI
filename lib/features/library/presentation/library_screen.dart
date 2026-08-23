import 'dart:async';

import 'package:flutter/material.dart';
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
  int _tabIndex = 0; // 0 = Acervo, 1 = Materiais
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
        ' · Bio ${nat['Biologia'] ?? 0}/Qui ${nat['Química'] ?? 0}/Fis ${nat['Física'] ?? 0}';
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
      buf.writeln(
        '· ${y['year']}: +${y['inserted'] ?? 0}'
        '${y['skipped'] == true ? ' (já commitado)' : ''}'
        '${h.isNotEmpty ? ' · Bio ${nat['Biologia'] ?? 0}/Qui ${nat['Química'] ?? 0}/Fis ${nat['Física'] ?? 0}' : ''}',
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
          title: const Text('Tudo pronto para estudar'),
          content: const Text(
            'As questões foram importadas e estão prontas para uso.\n'
            'Bons estudos!',
          ),
          actions: [
            FilledButton(onPressed: () { HapticFeedback.mediumImpact(); Navigator.pop(ctx, 'study'); }, child: const Text('Estudar agora')),
          ],
        ),
      );
      return choice == 'study';
    } catch (e) {
      if (mounted) {
        setState(
          () => msg = humanApiError(
            e,
            fallback: 'Tudo pronto para estudar.',
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
    final readyYears = gridAll
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((g) => g['uiStatus']?.toString() == 'committed' || (g['committedCount'] as int? ?? 0) > 0)
        .length;
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        PageBody(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: 'Acervo UEMA',
                title: 'Biblioteca',
                badge: officialN > 0 ? '$officialN oficiais' : null,
                subtitle: _tabIndex == 0
                    ? (officialN > 0
                        ? 'Provas oficiais prontas para estudar, organizadas por ano.'
                        : 'Importe as provas oficiais para começar a estudar.')
                    : (_studyPdfs.isEmpty
                        ? 'Materiais de estudo em PDF aparecem aqui automaticamente.'
                        : 'Materiais de estudo em PDF, filtrados por disciplina.'),
                trailing: IconButton(
                  tooltip: 'Atualizar',
                  onPressed: busy ? null : () { HapticFeedback.selectionClick(); _load(); },
                  icon: busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded),
                ),
              ),
              _SegmentedTabs(
                index: _tabIndex,
                onChanged: (i) => setState(() => _tabIndex = i),
                items: [
                  _SegmentItem(
                    label: 'Acervo',
                    icon: Icons.inventory_2_rounded,
                    hint: readyYears > 0 ? '$readyYears ${readyYears == 1 ? 'ano' : 'anos'}' : null,
                  ),
                  _SegmentItem(
                    label: 'Materiais',
                    icon: Icons.picture_as_pdf_rounded,
                    hint: _studyPdfs.isEmpty ? null : '${_studyPdfs.length} PDFs',
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _tabIndex == 0
              ? _buildAcervoTab(cs, checklist, officialN, board, hist, pending, pendingItems, pendingN,
                  anosParciais, readyYears)
              : _buildMateriaisTab(cs),
        ),
      ],
    );
  }

  Widget _buildAcervoTab(
    ColorScheme cs,
    Map<String, dynamic> checklist,
    int officialN,
    List board,
    List hist,
    Map<String, dynamic> pending,
    List pendingItems,
    int pendingN,
    int anosParciais,
    int readyYears,
  ) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        PageBody(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (officialN > 0 || readyYears > 0 || pendingN > 0) ...[
                StatsStrip(
                  items: [
                    ('$officialN', 'questões oficiais'),
                    ('$readyYears', readyYears == 1 ? 'ano pronto' : 'anos prontos'),
                    ('$pendingN', pendingN == 1 ? 'para revisar' : 'para revisar'),
                  ],
                ),
                const SizedBox(height: kGap16),
              ],

              if (busy)
                SurfacePanel(
                  margin: const EdgeInsets.only(bottom: kGap12),
                  color: cs.secondaryContainer.f45,
                  child: Row(
                    children: [
                      const SoftLoader(compact: true),
                      const SizedBox(width: kGap12),
                      Expanded(
                        child: Text(
                          msg ?? 'Trabalhando no acervo… pode demorar um pouco.',
                          style: TextStyle(fontSize: 14, height: 1.5, color: cs.onSurface.f85),
                        ),
                      ),
                    ],
                  ),
                ),

              // Boas-vindas — só quando o acervo está vazio.
              if (showFirstRunCoach && officialN == 0)
                SurfacePanel(
                  key: _semana1PanelKey,
                  margin: const EdgeInsets.only(bottom: kGap16),
                  color: cs.primaryContainer.f55,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.waving_hand_rounded, color: cs.primary, size: 22),
                          const SizedBox(width: kGap8),
                          Text(
                            'Bem-vindo — Semana 1',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: kGap8),
                      Text(
                        'Importe as provas oficiais da UEMA (2024–26) para começar a estudar. '
                        'Sem PDFs no computador? Use Abrir provas e coloque paes_ANO.pdf na pasta.',
                        style: TextStyle(fontSize: 14, height: 1.5, color: cs.onPrimaryContainer.f90),
                      ),
                      const SizedBox(height: kGap12),
                      Wrap(
                        spacing: kGap8,
                        runSpacing: kGap8,
                        children: [
                          FilledButton.icon(
                            onPressed: busy ? null : () { HapticFeedback.mediumImpact(); unawaited(_semana1Real()); },
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text('Importar provas 2024–26'),
                          ),
                          OutlinedButton(
                            onPressed: busy ? null : () { HapticFeedback.selectionClick(); _openFolder('provas'); },
                            child: const Text('Abrir provas'),
                          ),
                          TextButton(
                            onPressed: () { HapticFeedback.selectionClick(); _dismissFirstRunCoach(); },
                            child: const Text('Depois'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              if (partialLoadNote != null && error == null) ...[
                QuietEmpty(
                  message: partialLoadNote!,
                  action: TextButton(
                    onPressed: busy ? null : () { HapticFeedback.selectionClick(); _load(); },
                    child: const Text('Tentar'),
                  ),
                ),
                const SizedBox(height: kGap12),
              ],

              // ---------------- Busca ----------------
              SurfacePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Buscar no acervo — ex.: genética, osmose…',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: searching
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : (_searchCtrl.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Limpar',
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      _searchCtrl.clear();
                                      setState(() {
                                        searchHits = [];
                                        searchNote = null;
                                      });
                                    },
                                  )),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.f50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(kRadiusButton),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(kRadiusButton),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: kGap16, vertical: 14),
                      ),
                      onSubmitted: (_) => _runSearch(),
                      onChanged: _onSearchChanged,
                    ),
                    const SizedBox(height: kGap12),
                    Wrap(
                      spacing: kGap8,
                      runSpacing: kGap8,
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
                    if (searchHistory.isNotEmpty) ...[
                      const SizedBox(height: kGap12),
                      Text(
                        'Buscas recentes',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.f60),
                      ),
                      const SizedBox(height: kGap8),
                      Wrap(
                        spacing: kGap8,
                        runSpacing: kGap8,
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
                    if (searchHistoryNote != null) ...[
                      const SizedBox(height: kGap8),
                      Text(
                        searchHistoryNote!,
                        style: TextStyle(fontSize: 13, color: cs.error),
                      ),
                    ],
                    if (searchNote != null && searchHits.isEmpty) ...[
                      const SizedBox(height: kGap8),
                      QuietEmpty(
                        message: searchNote!,
                        action: TextButton(
                          onPressed: searching ? null : () { HapticFeedback.selectionClick(); _runSearch(); },
                          child: const Text('Tentar'),
                        ),
                      ),
                    ],
                    if (searchHits.isNotEmpty) ...[
                      const SizedBox(height: kGap8),
                      SectionLabel(
                        'Resultados',
                        hint: '${searchHits.length} ${searchHits.length == 1 ? 'item' : 'itens'} no acervo local',
                      ),
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
                  ],
                ),
              ),

              // ---------------- Provas recentes ----------------
              const SizedBox(height: kGap8),
              SectionLabel('Provas recentes', hint: 'PAES 2024–26'),
              if (board.isEmpty)
                QuietEmpty(
                  message: 'Nenhuma prova 2024–26 ainda. Importe para liberar as questões oficiais.',
                  action: Wrap(
                    spacing: kGap8,
                    runSpacing: kGap8,
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
                    maxCrossAxisExtent: 230,
                    childAspectRatio: 1.25,
                    crossAxisSpacing: kGap12,
                    mainAxisSpacing: kGap12,
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
                    return _YearCard(
                      year: y,
                      ready: ready,
                      partial: partial,
                      headline: ready ? '$n questões' : label,
                      hint: ready
                          ? 'Pronto para estudar'
                          : partial
                              ? 'Falta o gabarito'
                              : canFetch
                                  ? 'Toque para importar'
                                  : diskOk
                                      ? 'PDFs no computador'
                                      : 'Sem PDF ainda',
                      onTap: busy
                          ? null
                          : () {
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
                    );
                  },
                ),

              // ---------------- Ações principais ----------------
              const SizedBox(height: kGap16),
              SurfacePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: kGap8,
                      runSpacing: kGap8,
                      children: [
                        if (officialN > 0)
                          FilledButton.icon(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1&officialWithGab=1');
                            },
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: const Text('Estudar agora'),
                          ),
                        FilledButton.tonalIcon(
                          onPressed: busy ? null : () { HapticFeedback.mediumImpact(); _importAllComplete(); },
                          icon: const Icon(Icons.library_add_check_rounded, size: 18),
                          label: const Text('Importar todos com gabarito'),
                        ),
                        OutlinedButton.icon(
                          onPressed: busy ? null : () { HapticFeedback.selectionClick(); _commitOnDisk(); },
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text('Gravar PDFs do PC'),
                        ),
                      ],
                    ),
                    if (anosParciais > 0) ...[
                      const SizedBox(height: kGap12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: cs.tertiary),
                          const SizedBox(width: kGap8),
                          Expanded(
                            child: Text(
                              '$anosParciais ${anosParciais == 1 ? 'ano tem prova' : 'anos têm prova'} '
                              'sem gabarito. Coloque o gabarito na pasta para importar.',
                              style: TextStyle(fontSize: 13, height: 1.4, color: cs.onSurface.f72),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // ---------------- Pendências de revisão ----------------
              if (pendingN > 0) ...[
                const SizedBox(height: kGap8),
                SectionLabel(
                  'Precisa da sua revisão',
                  hint: '$pendingN ${pendingN == 1 ? 'arquivo' : 'arquivos'} aguardando conferência',
                ),
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

              // ---------------- Provas antigas ----------------
              const SizedBox(height: kGap16),
              _CollapsiblePanel(
                icon: Icons.history_rounded,
                title: 'Provas antigas',
                subtitle: anosParciais > 0
                    ? 'PAES 2014–23 · $anosParciais sem gabarito'
                    : 'PAES 2014–23 · importe se tiver os PDFs',
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
                            leadingIcon: ready
                                ? Icons.play_circle_outline_rounded
                                : partial
                                    ? Icons.warning_amber_rounded
                                    : Icons.description_outlined,
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
                  const SizedBox(height: kGap8),
                  Wrap(
                    spacing: kGap8,
                    runSpacing: kGap8,
                    children: [
                      OutlinedButton(
                        onPressed: busy ? null : () { HapticFeedback.selectionClick(); _commitOnDisk(); },
                        child: const Text('Gravar todos do PC (só com gabarito)'),
                      ),
                      TextButton(
                        onPressed: busy ? null : () { HapticFeedback.selectionClick(); _openFolder('gabaritos'); },
                        child: const Text('Abrir gabaritos'),
                      ),
                    ],
                  ),
                ],
              ),

              // ---------------- Opções avançadas ----------------
              const SizedBox(height: kGap12),
              _CollapsiblePanel(
                icon: Icons.tune_rounded,
                title: 'Opções avançadas',
                subtitle: 'Pastas, download, edital e geração com IA',
                children: [
                  if (curation != null) ...[
                    _InfoLines(
                      lines: [
                        'Questões oficiais: ${curation!['officialCount'] ?? '—'}',
                        'Com gabarito oficial: ${curation!['realCount'] ?? 0}'
                            '${curation!['realPercent'] != null ? ' (${curation!['realPercent']}%)' : ''}',
                        'Questões interdisciplinares: ${curation!['crossDomainCount'] ?? 0}',
                        if (curation!['message'] != null) curation!['message'].toString(),
                      ],
                    ),
                    const SizedBox(height: kGap12),
                  ],
                  Text(
                    'Pastas do acervo',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.f60),
                  ),
                  const SizedBox(height: kGap8),
                  Wrap(
                    spacing: kGap8,
                    runSpacing: kGap8,
                    children: [
                      for (final folder in const [
                        ('provas', 'Provas'),
                        ('gabaritos', 'Gabaritos'),
                        ('edital', 'Edital'),
                      ])
                        OutlinedButton.icon(
                          onPressed: () { HapticFeedback.selectionClick(); _openFolder(folder.$1); },
                          icon: const Icon(Icons.folder_open_rounded, size: 18),
                          label: Text(folder.$2),
                        ),
                    ],
                  ),
                  const SizedBox(height: kGap16),
                  _AdvancedAction(
                    title: 'Atualizar conteúdos da prova',
                    actionLabel: 'Atualizar',
                    onPressed: busy ? null : () { HapticFeedback.selectionClick(); _syncEdital(); },
                  ),
                  _AdvancedAction(
                    title: 'Organizar questões por assunto',
                    actionLabel: 'Executar',
                    onPressed: busy ? null : () { HapticFeedback.selectionClick(); _classify(); },
                  ),
                  _AdvancedAction(
                    title: 'Baixar todos os materiais',
                    actionLabel: 'Baixar',
                    onPressed: busy ? null : () { HapticFeedback.selectionClick(); _fetchAvailable(); },
                  ),
                  _AdvancedAction(
                    title: 'Importar e revisar 1º ano',
                    actionLabel: 'Ir',
                    onPressed: busy ? null : () { HapticFeedback.selectionClick(); _bootstrapFirstYear(); },
                  ),
                  _AdvancedAction(
                    title: 'Corrigir questões',
                    subtitle: 'Limpa artefatos, corta texto misturado e aplica gabaritos oficiais',
                    actionLabel: 'Corrigir',
                    onPressed: busy ? null : () { HapticFeedback.selectionClick(); _fixQuestions(); },
                  ),
                  _AdvancedAction(
                    title: 'Gerar resoluções com IA',
                    subtitle: resolutionStats ??
                        'Cria resoluções didáticas (Comando, Conceito, Gabarito, Distrator)',
                    actionLabel: 'Gerar',
                    onPressed: busy ? null : () { HapticFeedback.selectionClick(); _generateResolutions(); },
                  ),
                  _AdvancedAction(
                    title: 'Gerar aulas com IA',
                    subtitle: lessonStats ?? 'Cria aulas estruturadas para cada tópico do edital',
                    actionLabel: 'Gerar',
                    onPressed: busy ? null : () { HapticFeedback.selectionClick(); _generateLessons(); },
                  ),
                  if (coverage != null || library?['dataDir'] != null) ...[
                    const SizedBox(height: kGap12),
                    _InfoLines(
                      lines: [
                        if (coverage?['message'] != null && coverage!['message'].toString().isNotEmpty)
                          coverage!['message'].toString(),
                        if (library?['dataDir'] != null) 'Pasta: ${library!['dataDir']}',
                      ],
                    ),
                  ],
                ],
              ),

              if (msg != null && !busy) ...[
                const SizedBox(height: kGap16),
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
                      spacing: kGap8,
                      runSpacing: kGap8,
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
                  SurfacePanel(
                    color: cs.secondaryContainer.f45,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 18, color: cs.primary),
                        const SizedBox(width: kGap8),
                        Expanded(
                          child: Text(
                            msg!,
                            style: TextStyle(fontSize: 13, height: 1.5, color: cs.onSurface.f85),
                          ),
                        ),
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

  // ==========================================================
  // Tab Materiais — estante enxuta de PDFs de estudo
  // ==========================================================

  Widget _buildMateriaisTab(ColorScheme cs) {
    if (!_pdfsLoaded) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(28, 16, 28, 0),
        child: SkeletonList(count: 4, lines: 2),
      );
    }
    if (_studyPdfs.isEmpty) {
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          PageBody(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
            child: EmptyState(
              icon: Icons.picture_as_pdf_outlined,
              title: 'Nenhum PDF disponível',
              subtitle: 'Os materiais de estudo aparecem aqui automaticamente '
                  'quando estiverem no acervo.',
              action: OutlinedButton.icon(
                onPressed: () { HapticFeedback.selectionClick(); _openFolder('aulas'); },
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: const Text('Abrir pasta de materiais'),
              ),
            ),
          ),
        ],
      );
    }
    return _MateriaisShelf(pdfs: _studyPdfs, cs: cs);
  }
}

// ============================================================
// _SegmentedTabs — seletor Acervo / Materiais
// ============================================================

class _SegmentItem {
  const _SegmentItem({required this.label, required this.icon, this.hint});
  final String label;
  final IconData icon;
  final String? hint;
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.index,
    required this.items,
    required this.onChanged,
  });

  final int index;
  final List<_SegmentItem> items;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.f45,
          borderRadius: BorderRadius.circular(kRadiusPanel),
          border: Border.all(color: cs.outlineVariant.f45),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 4),
                child: _SegmentButton(
                  item: items[i],
                  selected: index == i,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(i);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _SegmentItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(kRadiusButton),
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadiusButton),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? cs.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(kRadiusButton),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: cs.shadow.f22,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: selected ? cs.primary : cs.onSurface.f60,
                ),
                const SizedBox(width: kGap8),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? cs.onSurface : cs.onSurface.f72,
                  ),
                ),
                if (item.hint != null) ...[
                  const SizedBox(width: kGap8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: selected ? cs.primaryContainer.f65 : cs.surfaceContainerHighest.f65,
                      borderRadius: BorderRadius.circular(kRadiusMicro + 4),
                    ),
                    child: Text(
                      item.hint!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? cs.onPrimaryContainer : cs.onSurface.f60,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// _YearCard — card de ano do acervo
// ============================================================

class _YearCard extends StatelessWidget {
  const _YearCard({
    required this.year,
    required this.ready,
    required this.partial,
    required this.headline,
    required this.hint,
    required this.onTap,
  });

  final int year;
  final bool ready;
  final bool partial;
  final String headline;
  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = ready
        ? cs.primary
        : partial
            ? cs.tertiary
            : cs.onSurfaceVariant;
    final statusIcon = ready
        ? Icons.check_circle_rounded
        : partial
            ? Icons.warning_amber_rounded
            : Icons.hourglass_empty_rounded;
    final statusLabel = ready
        ? 'pronto'
        : partial
            ? 'parcial'
            : 'vazio';

    return TapScale(
      child: Material(
        color: ready ? cs.primaryContainer.f45 : cs.surfaceContainerHigh.f65,
        borderRadius: BorderRadius.circular(kRadiusHighlight),
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadiusHighlight),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kRadiusHighlight),
              border: Border.all(color: ready ? accent.f38 : cs.outlineVariant.f45),
            ),
            padding: const EdgeInsets.all(kGap16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$year',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: cs.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.f22,
                        borderRadius: BorderRadius.circular(kRadiusMicro + 4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 13, color: accent),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.f88,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: TextStyle(fontSize: 11, color: cs.onSurface.f60),
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
  }
}

// ============================================================
// _CollapsiblePanel — bloco recolhível em SurfacePanel
// ============================================================

class _CollapsiblePanel extends StatelessWidget {
  const _CollapsiblePanel({
    required this.icon,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SurfacePanel(
      padding: const EdgeInsets.symmetric(horizontal: kGap16, vertical: kGap4),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: kGap12),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.f55,
              borderRadius: BorderRadius.circular(kRadiusControl),
            ),
            child: Icon(icon, size: 18, color: cs.primary),
          ),
          title: Text(
            title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle!,
                  style: TextStyle(fontSize: 12, color: cs.onSurface.f60),
                ),
          children: children,
        ),
      ),
    );
  }
}

// ============================================================
// _AdvancedAction — linha de ação das opções avançadas
// ============================================================

class _AdvancedAction extends StatelessWidget {
  const _AdvancedAction({
    required this.title,
    required this.actionLabel,
    required this.onPressed,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12, height: 1.4, color: cs.onSurface.f60),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: kGap12),
          OutlinedButton(onPressed: onPressed, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

// ============================================================
// _InfoLines — bloco de informações secundárias
// ============================================================

class _InfoLines extends StatelessWidget {
  const _InfoLines({required this.lines});
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final visible = lines.where((l) => l.trim().isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(kGap12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.f38,
        borderRadius: BorderRadius.circular(kRadiusControl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                line,
                style: TextStyle(fontSize: 13, height: 1.5, color: cs.onSurface.f72),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// _MateriaisShelf — estante de PDFs (tab Materiais)
// ============================================================

class _MateriaisShelf extends StatefulWidget {
  const _MateriaisShelf({required this.pdfs, required this.cs});
  final List<Map<String, dynamic>> pdfs;
  final ColorScheme cs;

  @override
  State<_MateriaisShelf> createState() => _MateriaisShelfState();
}

class _MateriaisShelfState extends State<_MateriaisShelf> {
  String? _selectedSubject;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    var pdfs = widget.pdfs;
    if (_selectedSubject != null) {
      pdfs = pdfs.where((p) => (p['subject'] ?? '') == _selectedSubject).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      pdfs = pdfs.where((p) {
        final title = (p['title'] ?? '').toString().toLowerCase();
        final subj = (p['subject'] ?? '').toString().toLowerCase();
        return title.contains(q) || subj.contains(q);
      }).toList();
    }
    return pdfs;
  }

  List<String> get _subjects {
    final s = widget.pdfs.map((p) => (p['subject'] ?? 'Outros').toString()).toSet().toList();
    s.sort();
    return s;
  }

  int _countFor(String subject) =>
      widget.pdfs.where((p) => (p['subject'] ?? 'Outros').toString() == subject).length;

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final filtered = _filtered;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        PageBody(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SurfacePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Buscar material por título ou disciplina…',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Limpar',
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.f50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(kRadiusButton),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(kRadiusButton),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: kGap16, vertical: 14),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: kGap12),
                    Wrap(
                      spacing: kGap8,
                      runSpacing: kGap8,
                      children: [
                        FilterChip(
                          label: Text('Todas (${widget.pdfs.length})'),
                          selected: _selectedSubject == null,
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedSubject = null);
                          },
                        ),
                        for (final s in _subjects)
                          FilterChip(
                            label: Text('$s (${_countFor(s)})'),
                            selected: _selectedSubject == s,
                            avatar: Icon(kSubjectIcons[s] ?? Icons.menu_book_rounded, size: 15),
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedSubject = s);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kGap8),
              SectionLabel(
                _selectedSubject ?? 'Todos os materiais',
                hint: '${filtered.length} ${filtered.length == 1 ? 'material' : 'materiais'}',
              ),
              if (filtered.isEmpty)
                QuietEmpty(
                  message: 'Nenhum material encontrado com esse filtro.',
                  action: TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _searchCtrl.clear();
                      setState(() {
                        _searchQuery = '';
                        _selectedSubject = null;
                      });
                    },
                    child: const Text('Limpar filtros'),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 760 ? 2 : 1;
                    if (columns == 1) {
                      return Column(
                        children: [
                          for (final pdf in filtered) _MateriaisPdfCard(pdf: pdf, cs: cs),
                        ],
                      );
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 76,
                        crossAxisSpacing: kGap12,
                        mainAxisSpacing: 0,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => _MateriaisPdfCard(pdf: filtered[i], cs: cs),
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

// ============================================================
// _MateriaisPdfCard — card compacto de PDF
// ============================================================

const Map<String, IconData> kSubjectIcons = {
  'Biologia': Icons.biotech_rounded,
  'Química': Icons.science_rounded,
  'Física': Icons.bolt_rounded,
  'Matemática': Icons.calculate_rounded,
  'Português': Icons.menu_book_rounded,
  'Inglês': Icons.language_rounded,
  'Espanhol': Icons.translate_rounded,
  'História': Icons.history_edu_rounded,
  'Geografia': Icons.public_rounded,
  'Filosofia': Icons.psychology_rounded,
  'Sociologia': Icons.groups_rounded,
};

class _MateriaisPdfCard extends StatelessWidget {
  const _MateriaisPdfCard({required this.pdf, required this.cs});
  final Map<String, dynamic> pdf;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final title = pdf['title']?.toString() ?? 'Material';
    final subject = pdf['subject']?.toString() ?? 'Outros';
    final filename = pdf['filename']?.toString() ?? '';
    final sizeKb = (pdf['size_kb'] as num?)?.toDouble() ?? 0;
    final sizeStr = sizeKb > 1024 ? '${(sizeKb / 1024).toStringAsFixed(1)} MB' : '${sizeKb.round()} KB';
    final icon = kSubjectIcons[subject] ?? Icons.menu_book_rounded;

    return TapScale(
      child: Container(
        margin: const EdgeInsets.only(bottom: kGap8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(kRadiusPanel),
          border: Border.all(color: cs.outlineVariant.f45),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(kRadiusPanel),
          child: InkWell(
            borderRadius: BorderRadius.circular(kRadiusPanel),
            onTap: () {
              HapticFeedback.selectionClick();
              context.go(Uri(path: '/estudar', queryParameters: {
                'pdf': filename,
                'title': title,
                'subject': subject,
              }).toString());
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.f55,
                      borderRadius: BorderRadius.circular(kRadiusControl),
                    ),
                    child: Icon(icon, color: cs.onPrimaryContainer, size: 20),
                  ),
                  const SizedBox(width: kGap12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$subject · $sizeStr',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cs.onSurface.f60),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: kGap8),
                  Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurface.f38),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
