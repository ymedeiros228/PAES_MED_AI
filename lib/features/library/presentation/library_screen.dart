import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/library_api.dart';
import '../data/library_formatters.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/ui_kit.dart';
import 'ingest_review_screen.dart';
import 'library_dialogs.dart';
import 'widgets/library_acervo_tab.dart';
import 'widgets/library_materiais_tab.dart';
import 'widgets/library_tab_bar.dart';

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
      final data = await LibraryApi.fetchLibrary();
      Map<String, dynamic>? cov;
      Map<String, dynamic>? cur;
      String? partialNote;
      try {
        final c = await LibraryApi.fetchCoverage();
        cov = Map<String, dynamic>.from(c as Map);
      } catch (e) {
        partialNote = humanApiError(e, fallback: 'Cobertura do edital indisponível.');
      }
      try {
        final inv = await LibraryApi.fetchCurationInventory();
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
      unawaited(_loadStudyPdfs());
    } catch (e) {
      setState(() => error = humanApiError(e, fallback: 'Não deu para carregar a Biblioteca. Tente de novo.'));
    } finally {
      setState(() => busy = false);
    }
  }

  String _healthLine(Map<String, dynamic> map, {Object? inserted}) =>
      libraryHealthLine(map, inserted: inserted);

  String _semana1HealthBody(Map<String, dynamic> map) => librarySemana1HealthBody(map);

  String _naturezaPackLine(Map<String, dynamic>? pack) => libraryNaturezaPackLine(pack);

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
    final choice = await LibraryDialogs.postCommitCta(
      context: context,
      title: title,
      body: '$body$packLine',
    );
    if (!mounted) return;
    if (choice == 'study') {
      await _goStudy(sessaoPath, yearHealth: yearHealth);
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
    final choice = await LibraryDialogs.fetchPlaybook(
      context: context,
      title: title,
      body: body,
      canCommitDisk: canCommitDisk,
      showPortal: portal != null && portal.isNotEmpty,
      showRetry: year != null,
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
      final data = await LibraryApi.openUrl(portal);
      setState(() => msg = 'Portal aberto no navegador: ${data['url'] ?? portal}');
    } catch (e) {
      setState(() => msg = humanApiError(
            e,
            fallback:
                'Portal: $portal — abra no navegador e drope paes_YYYY.pdf / gabarito_YYYY.pdf.',
          ));
    }
  }

  Future<void> _semana1Real() async {
    setState(() {
      busy = true;
      msg = 'Semana 1: atualizando 2024–26…';
    });
    try {
      final data = await LibraryApi.semana1Bootstrap();
      final map = data;
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
        await LibraryApi.classifyPending();
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
      final map = await LibraryApi.commitOnDisk();
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
      final map = await LibraryApi.importAllComplete();
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
      await LibraryDialogs.importAllComplete(
        context: context,
        message: map['message']?.toString() ?? '',
        perYear: perYear,
        waitLine: waitLine,
        officialN: n,
        hasWaitingYears: waiting.isNotEmpty,
        onOpenGabaritos: () => unawaited(_openFolder('gabaritos')),
        onStudy: () => unawaited(_goStudy(sessao)),
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

  Future<void> _importYearSafe(int year) async {
    setState(() {
      busy = true;
      msg = 'Importando do PC · PAES $year…';
    });
    try {
      final map = await LibraryApi.importYearSafe(year);
      if (map['needsGabarito'] == true) {
        setState(() => msg = map['message']?.toString() ?? 'Falta gabarito.');
        if (!mounted) return;
        final open = await LibraryDialogs.importYearMissingGabarito(
          context: context,
          year: year,
          message: map['message']?.toString() ??
              'Coloque gabarito_$year.pdf em data/gabaritos. Preview pronto: ${map['count'] ?? 0} questões.',
          hasPreview: map['previewId'] != null,
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

  Future<bool> _confirmStudyDespiteParse({
    Map<String, dynamic>? yearHealth,
    Map<String, dynamic>? pending,
  }) async {
    try {
      final gate = await LibraryApi.parseGate(
        yearHealth: yearHealth,
        pending: pending,
      );
      if (gate['warn'] != true) return true;
      if (!mounted) return false;
      final choice = await LibraryDialogs.confirmStudyReady(context: context);
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
      final map = await LibraryApi.bootstrapAndCommitYear(year);
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
      final map = await LibraryApi.importYearPreview(year);
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
      final data = await LibraryApi.openFolder(folder);
      final path = (data as Map)['path']?.toString() ?? folder;
      setState(() => msg = 'Pasta aberta: $path');
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Não deu para concluir. Tente de novo.'));
    }
  }

  Future<void> _loadSearchHistory() async {
    try {
      final map = await LibraryApi.fetchSearchHistory();
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
      final map = await LibraryApi.search(query: q, sourceKind: searchSourceKind);
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
        await LibraryApi.openPath(path);
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

  Future<void> _fetchYear(int year) async {
    setState(() {
      busy = true;
      msg = 'Baixando oficiais PAES $year...';
    });
    try {
      final map = await LibraryApi.fetchYear(year);
      setState(() => msg = map['message']?.toString() ?? '$map');
      await _load();
      final local = map['local'] as Map?;
      if (local != null && local['hasProva'] == true && local['hasGabarito'] == true && mounted) {
        final go = await LibraryDialogs.fetchYearDownloaded(context: context, year: year);
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
      await LibraryApi.classifyPending();
      setState(() => msg = 'Classificação concluída');
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
      final data = await LibraryApi.syncEdital();
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
      final data = await LibraryApi.fixQuestions();
      final msgStr = data is Map ? (data['message']?.toString() ?? 'Correção concluída') : 'Correção concluída';
      setState(() => msg = msgStr);
      await _load();
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Não deu para corrigir agora. Tente de novo.'));
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _loadStudyPdfs() async {
    try {
      final list = await LibraryApi.fetchPdfList();
      setState(() {
        _studyPdfs = list;
        _pdfsLoaded = true;
      });
    } catch (_) {
      setState(() => _pdfsLoaded = true);
    }
  }

  LibraryAcervoActions _acervoActions() {
    return LibraryAcervoActions(
      onRefresh: _load,
      onDismissFirstRunCoach: _dismissFirstRunCoach,
      onSemana1: () => unawaited(_semana1Real()),
      onRunSearch: _runSearch,
      onSearchChanged: _onSearchChanged,
      onSearchSourceKindChanged: (kind) {
        setState(() => searchSourceKind = kind);
        if (_searchCtrl.text.trim().isNotEmpty) _runSearch();
      },
      onApplySearchHistory: (q, sk) {
        _searchCtrl.text = q;
        setState(() {
          if (sk == 'oficial' || sk == 'estudo') {
            searchSourceKind = sk!;
          } else {
            searchSourceKind = 'todos';
          }
        });
        _runSearch();
      },
      onHitSelected: (i) => setState(() => _hitSelected = i),
      onOpenSearchHit: _openSearchHit,
      onGoStudy: (path) => unawaited(_goStudy(path)),
      onImportYear: (y) => unawaited(_importYear(y)),
      onImportYearSafe: (y) => unawaited(_importYearSafe(y)),
      onBootstrapYear: (y) => unawaited(_bootstrapAndCommitYear(y)),
      onFetchYear: (y) => unawaited(_fetchYear(y)),
      onImportAllComplete: () => unawaited(_importAllComplete()),
      onOpenFolder: (folder) => unawaited(_openFolder(folder)),
      onSyncEdital: () => unawaited(_syncEdital()),
      onClassify: () => unawaited(_classify()),
      onFixQuestions: () => unawaited(_fixQuestions()),
    );
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

    return Column(
      children: [
        // Tab bar
        Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                LibraryTab(
                  label: 'Acervo',
                  icon: Icons.inventory_2_rounded,
                  selected: _tabIndex == 0,
                  onTap: () => setState(() => _tabIndex = 0),
                ),
                const SizedBox(width: 8),
                LibraryTab(
                  label: 'Materiais',
                  icon: Icons.picture_as_pdf_rounded,
                  selected: _tabIndex == 1,
                  onTap: () => setState(() => _tabIndex = 1),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _tabIndex == 0
              ? LibraryAcervoTab(
                  searchController: _searchCtrl,
                  actions: _acervoActions(),
                  busy: busy,
                  msg: msg,
                  showFirstRunCoach: showFirstRunCoach,
                  officialN: officialN,
                  partialLoadNote: partialLoadNote,
                  error: error,
                  searching: searching,
                  searchHits: searchHits,
                  searchNote: searchNote,
                  searchHistory: searchHistory,
                  searchHistoryNote: searchHistoryNote,
                  searchSourceKind: searchSourceKind,
                  hitSelected: _hitSelected,
                  board: board,
                  hist: hist,
                  pendingItems: pendingItems,
                  pendingN: pendingN,
                  anosParciais: anosParciais,
                  curation: curation,
                  coverage: coverage,
                  showLocalDataHint: library?['dataDir'] != null,
                  semana1PanelKey: _semana1PanelKey,
                )
              : LibraryMateriaisTab(pdfsLoaded: _pdfsLoaded, pdfs: _studyPdfs),
        ),
      ],
    );
  }

}
