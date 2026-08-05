import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/providers.dart';
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
  bool busy = false;
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> searchHits = [];
  String? searchNote;
  bool searching = false;
  String searchSourceKind = 'todos'; // todos | oficial | estudo
  List<Map<String, dynamic>> searchHistory = [];

  @override
  void initState() {
    super.initState();
    _load();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data = await apiClient.get('/api/library');
      Map<String, dynamic>? cov;
      Map<String, dynamic>? cur;
      try {
        final c = await apiClient.get('/api/edital/coverage');
        cov = Map<String, dynamic>.from(c as Map);
      } catch (_) {}
      try {
        final inv = await apiClient.get('/api/curation/inventory');
        cur = Map<String, dynamic>.from(inv as Map);
      } catch (_) {}
      setState(() {
        library = Map<String, dynamic>.from(data as Map);
        coverage = cov;
        curation = cur;
      });
    } catch (e) {
      setState(() => error = e.toString());
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
            map['message']?.toString() ?? map['error']?.toString() ?? 'Bootstrap falhou.',
            if (portal != null && portal.isNotEmpty) 'Portal: $portal',
            'Use Biblioteca → Manual / Abrir provas se o host falhar.',
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
        msg =
            'Falha de rede/download: $e — confira o portal no manifesto ou use Biblioteca → Manual / Abrir provas.';
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
      setState(() => msg = e.toString());
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
      return total > 0 ? ' · saúde lote: $total qs · Bio $bio/Qui $qui/Fis $fis' : '';
    }
    final nat = Map<String, dynamic>.from(health['natureza'] as Map? ?? {});
    if (health.isEmpty) return '';
    return ' · saúde: ${health['total'] ?? inserted ?? '—'} qs · gab ${health['gabaritoPct'] ?? '—'}%'
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
            onPressed: () => Navigator.pop(ctx, 'professor'),
            child: const Text('Rascunhos professor'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx, 'later'), child: const Text('Depois')),
          FilledButton(onPressed: () => Navigator.pop(ctx, 'study'), child: const Text('Estudar agora')),
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
      if (mounted) context.go('/medicina');
    }
  }

  Future<void> _bootstrapAndCommit() async {
    setState(() {
      busy = true;
      msg = 'Baixando… commitando altas confianças…';
    });
    try {
      final data = await apiClient.post('/api/acervo/bootstrap-and-commit', {
        'dryRun': false,
        'overwrite': false,
        'minConfidence': 0.55,
        'autoProfessor': true,
      });
      final map = Map<String, dynamic>.from(data as Map);
      final year = map['year'] as int? ?? 0;
      final inserted = map['inserted'] ?? 0;
      final n = map['officialCount'] ?? 0;
      final healthLine = _healthLine(map, inserted: inserted);
      final pack = map['naturezaPack'] is Map ? Map<String, dynamic>.from(map['naturezaPack'] as Map) : null;
      final packLine = _naturezaPackLine(pack);
      final sessao = map['sessionPath']?.toString() ??
          (year > 0
              ? '/sessao?examBoard=UEMA_PAES&year=$year&preferNatureza=1'
              : '/sessao?examBoard=UEMA_PAES&preferNatureza=1');
      setState(() {
        msg = map['message']?.toString() ?? 'Commit OK · $inserted oficiais · base $n$healthLine';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('1 clique OK · $inserted UEMA · oficiais $n$healthLine'),
          action: SnackBarAction(
            label: 'Estudar agora',
            onPressed: () => _goStudy(
              sessao,
              yearHealth: map['yearHealth'] is Map ? Map<String, dynamic>.from(map['yearHealth'] as Map) : null,
            ),
          ),
          duration: const Duration(seconds: 6),
        ),
      );
      await _showPostCommitCta(
        title: 'Oficiais gravadas',
        body: 'Commit OK · $inserted · base $n$healthLine$packLine\nEstudar Natureza/UEMA agora?',
        sessaoPath: sessao,
        professor: map['professor'] is Map ? Map<String, dynamic>.from(map['professor'] as Map) : null,
        yearHealth: map['yearHealth'] is Map ? Map<String, dynamic>.from(map['yearHealth'] as Map) : null,
        naturezaPack: pack,
      );
      ref.read(refreshTickProvider.notifier).state++;
      await _load();
    } catch (e) {
      setState(() {
        msg =
            'Bootstrap+commit falhou: $e — use Baixar e revisar, ou Manual / Abrir provas.';
      });
    } finally {
      if (mounted) setState(() => busy = false);
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
          if (portal != null && portal.isNotEmpty)
            TextButton(onPressed: () => Navigator.pop(ctx, 'portal'), child: const Text('Portal')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'provas'), child: const Text('Abrir provas')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'gabaritos'), child: const Text('Abrir gabaritos')),
          if (canCommitDisk)
            TextButton(onPressed: () => Navigator.pop(ctx, 'disk'), child: const Text('Commitar disco')),
          if (year != null)
            TextButton(onPressed: () => Navigator.pop(ctx, 'retry'), child: const Text('Tentar de novo')),
          FilledButton(onPressed: () => Navigator.pop(ctx, 'ok'), child: const Text('OK')),
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
      setState(() => msg = 'Portal: $portal — abra no navegador e drope paes_YYYY.pdf / gabarito_YYYY.pdf.\n$e');
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
      msg = 'Semana 1 real: fetch+commit found 2024–26…';
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
        title: 'Semana 1 real',
        body: '$body\nEstudar Natureza agora?',
        sessaoPath: sessao,
        professor: map['professor'] is Map ? Map<String, dynamic>.from(map['professor'] as Map) : null,
        naturezaPack: pack,
      );
      // Ciclo I: reclassificar Natureza 1x após commit
      try {
        await apiClient.post('/api/ingest/classify-pending', {});
      } catch (_) {}
      ref.read(refreshTickProvider.notifier).state++;
      await _load();
    } catch (e) {
      setState(() => msg = 'Semana 1 falhou: $e');
      if (mounted) {
        await _showFetchPlaybook(
          title: 'Semana 1 — erro',
          body: '$e\nUse Abrir provas/gabaritos ou o portal do manifesto.',
          canCommitDisk: true,
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _commitFoundAvailable() async {
    await _semana1Real();
  }

  Future<void> _commitOnDisk() async {
    setState(() {
      busy = true;
      msg = 'Commitando PDFs no disco…';
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
          action: SnackBarAction(label: 'Estudar agora', onPressed: () => _goStudy(sessao)),
          duration: const Duration(seconds: 6),
        ),
      );
      await _showPostCommitCta(
        title: 'PDFs do disco commitados',
        body: 'Disco OK · +$inserted · base $n$healthLine$packLine\nAbrir sessão UEMA Natureza?',
        sessaoPath: sessao,
        professor: map['professor'] is Map ? Map<String, dynamic>.from(map['professor'] as Map) : null,
        naturezaPack: pack,
      );
      ref.read(refreshTickProvider.notifier).state++;
      await _load();
    } catch (e) {
      setState(() => msg = 'Commit no disco falhou: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _uiStatusLabel(String? s) {
    switch (s) {
      case 'committed':
        return 'Pronto';
      case 'onDisk':
        return 'PDFs no PC';
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

  String _naturezaPackLine(Map<String, dynamic>? pack) {
    if (pack == null) return '';
    final n = pack['cardsCreated'] as int? ?? 0;
    final d = pack['drafts'] as int? ?? 0;
    if (n <= 0 && d <= 0) return '';
    return '\nPack Natureza: $n cards due amanhã'
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
          title: const Text('Parse com suspeitas'),
          content: Text(
            '${gate['message'] ?? 'Revise suspeitas/needsOcr antes de estudar.'}\n'
            'Suspeitas: ${gate['suspects'] ?? 0} · needsOcr: ${gate['needsOcr'] == true}',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, 'review'), child: const Text('Revisar suspeitas')),
            FilledButton(onPressed: () => Navigator.pop(ctx, 'study'), child: const Text('Estudar mesmo assim')),
          ],
        ),
      );
      if (choice == 'review') {
        // scroll mentally — user stays on biblioteca / pending section
        return false;
      }
      return choice == 'study';
    } catch (_) {
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
      msg = 'Commitando PAES $year…';
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
        title: 'PAES $year commitado',
        body: 'Commit OK · $inserted · base $n$healthLine$packLine\nEstudar Natureza agora?',
        sessaoPath: sessao,
        professor: map['professor'] is Map ? Map<String, dynamic>.from(map['professor'] as Map) : null,
        yearHealth: map['yearHealth'] is Map ? Map<String, dynamic>.from(map['yearHealth'] as Map) : null,
        naturezaPack: pack,
      );
      ref.read(refreshTickProvider.notifier).state++;
      await _load();
    } catch (e) {
      setState(() => msg = 'Commit $year falhou: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _commitOnDiskYear(int year) async {
    // Reusa import+commit via bootstrap-and-commit (disco skip fetch) ou commit-on-disk lote.
    // Preferir bootstrap-and-commit com year — ele usa PDFs no disco se existirem.
    await _bootstrapAndCommitYear(year);
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
      setState(() => msg = e.toString());
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
      setState(() => msg = e.toString());
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
      });
    } catch (_) {}
  }

  Future<void> _runSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        searchHits = [];
        searchNote = null;
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
      });
      await _loadSearchHistory();
    } catch (e) {
      setState(() {
        searchHits = [];
        searchNote = e.toString();
      });
    } finally {
      setState(() => searching = false);
    }
  }

  Future<void> _openYearPdf(int year) async {
    try {
      final data = await apiClient.get('/api/library/year-pdf', {'year': '$year'});
      final map = Map<String, dynamic>.from(data as Map);
      if (map['exists'] != true || (map['path']?.toString() ?? '').isEmpty) {
        setState(() => msg = map['note']?.toString() ?? 'Sem PDF deste ano no PC.');
        return;
      }
      await apiClient.post('/api/library/open-path', {'path': map['path']});
      setState(() => msg = 'Abrindo PDF ${map['label'] ?? year}');
    } catch (e) {
      setState(() => msg = e.toString());
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
        await apiClient.post('/api/library/open-path', {'path': path});
        setState(() => msg = 'Abrindo ${hit['label'] ?? path}');
      } catch (e) {
        setState(() => msg = e.toString());
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
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Depois')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Revisar')),
            ],
          ),
        );
        if (go == true) await _importYear(next);
      }
    } catch (e) {
      setState(() => msg = e.toString());
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
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Depois')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Revisar')),
            ],
          ),
        );
        if (go == true) await _importYear(year);
      } else if (map['fetchFailed'] == true || map['ok'] != true) {
        if (!mounted) return;
        await _showFetchPlaybook(
          title: 'Fetch PAES $year falhou',
          body: map['message']?.toString() ??
              'Download falhou. Use portal, drop manual ou tentar de novo.',
          portal: map['portal']?.toString() ??
              (map['playbook'] is Map ? (map['playbook'] as Map)['portal']?.toString() : null),
          year: year,
          canCommitDisk: local != null && local['hasProva'] == true && local['hasGabarito'] == true,
        );
      }
    } catch (e) {
      setState(() => msg = e.toString());
      if (mounted) {
        await _showFetchPlaybook(
          title: 'Fetch PAES $year falhou',
          body: '$e',
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
      setState(() => msg = e.toString());
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
      setState(() => msg = e.toString());
    } finally {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (busy && library == null) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return EmptyState(
        title: 'Biblioteca indisponível',
        subtitle: 'Reabra o app e tente de novo.',
        action: FilledButton(onPressed: _load, child: const Text('Tentar de novo')),
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
          return y >= 2017 && y <= 2023;
        })
        .toList();
    final pending = Map<String, dynamic>.from(
      (library?['pendingPreviews'] as Map?) ?? (checklist['pendingPreviews'] as Map?) ?? const {},
    );
    final pendingItems = pending['items'] as List? ?? const [];
    final pendingN = pending['pendingCount'] as int? ?? pendingItems.length;
    final cs = Theme.of(context).colorScheme;

    return ListView(
      children: [
        PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: 'Acervo',
                title: 'Biblioteca',
                subtitle: officialN > 0
                    ? '$officialN oficiais · 2024–26 embaixo · study Natureza'
                    : 'Monte as provas 2024–26 e estude Natureza',
                trailing: IconButton(
                  tooltip: 'Atualizar',
                  onPressed: busy ? null : _load,
                  icon: busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded),
                ),
              ),

              const SizedBox(height: 8),
              TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Buscar no acervo',
                  hintText: 'ex.: genética, osmose…',
                  suffixIcon: IconButton(
                    tooltip: 'Buscar',
                    onPressed: searching ? null : _runSearch,
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
                        setState(() => searchSourceKind = kind.$1);
                        if (_searchCtrl.text.trim().isNotEmpty) _runSearch();
                      },
                    ),
                ],
              ),
              if (searchHistory.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final h in searchHistory.take(8))
                      ActionChip(
                        label: Text(
                          h['q']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () {
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
                  child: Text(searchNote!, style: Theme.of(context).textTheme.bodySmall),
                ),
              if (searchHits.isNotEmpty) ...[
                SectionLabel('Resultados', hint: '${searchHits.length} local'),
                for (final hit in searchHits.take(12))
                  PlaylistTile(
                    title: hit['label']?.toString() ?? 'item',
                    subtitle:
                        '${hit['sourceKind'] ?? hit['kind'] ?? ''}${hit['year'] != null ? ' · ${hit['year']}' : ''}',
                    badge: hit['sourceKind']?.toString() == 'oficial' ? 'oficial' : 'local',
                    leadingIcon: hit['kind'] == 'question'
                        ? Icons.quiz_outlined
                        : Icons.description_outlined,
                    onPlay: () => _openSearchHit(hit),
                  ),
              ],

              SurfacePanel(
                margin: const EdgeInsets.only(bottom: 16),
                color: cs.primaryContainer.withOpacity(0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      officialN == 0 ? 'Semana 1 · 2024–26' : 'Acervo 2024–26',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      officialN == 0
                          ? 'Atualize o acervo e estude de verdade — sem inventar prova antiga.'
                          : 'Um toque atualiza o que estiver no PC ou no portal.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: busy ? null : _semana1Real,
                          icon: const Icon(Icons.download_rounded),
                          label: Text(officialN == 0 ? 'Atualizar 2024–26' : 'Atualizar'),
                        ),
                        OutlinedButton(
                          onPressed: busy ? null : _commitOnDisk,
                          child: const Text('Gravar PDFs do PC'),
                        ),
                        FilledButton.tonal(
                          onPressed: () => context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1'),
                          child: const Text('Estudar agora'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SectionLabel('2024–26', hint: 'Toque Estudar quando estiver Pronto'),
              if (board.isEmpty)
                QuietEmpty(
                  message: 'Nenhum ano 2024–26 ainda — use Atualizar 2024–26.',
                  action: TextButton(
                    onPressed: busy ? null : _semana1Real,
                    child: const Text('Atualizar 2024–26'),
                  ),
                )
              else
                for (final g in board)
                  Builder(
                    builder: (_) {
                      final y = g['year'] as int? ?? 0;
                      final status = g['uiStatus']?.toString() ?? 'empty';
                      final n = g['committedCount'] as int? ?? 0;
                      final canFetch = g['canFetch'] == true;
                      final onDisk = Map<String, dynamic>.from(g['onDisk'] as Map? ?? {});
                      final diskOk = onDisk['hasProva'] == true && onDisk['hasGabarito'] == true;
                      final ready = status == 'committed' || n > 0;
                      return SurfacePanel(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: ready ? cs.primaryContainer : cs.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$y',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: ready ? cs.primary : cs.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('PAES $y', style: Theme.of(context).textTheme.titleSmall),
                                  Text(
                                    ready
                                        ? '${n > 0 ? '$n questões · ' : ''}${_uiStatusLabel(status)}'
                                        : _uiStatusLabel(status),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            if (ready)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (onDisk['hasProva'] == true)
                                    TextButton(
                                      onPressed: busy ? null : () => _openYearPdf(y),
                                      child: const Text('PDF'),
                                    ),
                                  FilledButton(
                                    onPressed: busy
                                        ? null
                                        : () => _goStudy(
                                              '/sessao?examBoard=UEMA_PAES&year=$y&preferNatureza=1',
                                            ),
                                    child: const Text('Estudar'),
                                  ),
                                ],
                              )
                            else if (canFetch || diskOk)
                              OutlinedButton(
                                onPressed: busy ? null : () => _bootstrapAndCommitYear(y),
                                child: Text(diskOk && !canFetch ? 'Gravar' : 'Importar'),
                              )
                            else
                              TextButton(
                                onPressed: busy ? null : () => _fetchYear(y),
                                child: const Text('Baixar'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

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
                        onPlay: y is int ? () => _importYear(y) : null,
                      );
                    },
                  ),
              ],

              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Anos antigos (2017–23)', style: Theme.of(context).textTheme.titleSmall),
                subtitle: const Text('Só se você tiver o PDF no PC — sem inventar cobertura'),
                children: [
                  if (hist.isEmpty)
                    QuietEmpty(
                      message:
                          'Falta o PDF deste intervalo (2017–23). Coloque paes_YYYY.pdf + gabarito_YYYY.pdf nas pastas Provas e Gabaritos e use Gravar — sem arquivo no disco não há cobertura.',
                      action: TextButton(
                        onPressed: busy ? null : _commitOnDisk,
                        child: const Text('Gravar PDFs do PC'),
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
                          final diskOk = onDisk['hasProva'] == true && onDisk['hasGabarito'] == true;
                          final ready = status == 'committed' || n > 0;
                          final emptyLabel = !diskOk && !ready
                              ? 'Falta o PDF deste ano'
                              : _uiStatusLabel(status);
                          return PlaylistTile(
                            title: 'PAES $y',
                            subtitle: emptyLabel,
                            badge: ready ? 'pronto' : (diskOk ? 'no disco' : null),
                            onPlay: ready
                                ? () => _goStudy(
                                      '/sessao?examBoard=UEMA_PAES&year=$y&preferNatureza=1',
                                    )
                                : diskOk
                                    ? () => _commitOnDiskYear(y)
                                    : null,
                            secondary: !ready && diskOk
                                ? TextButton(
                                    onPressed: busy ? null : () => _commitOnDiskYear(y),
                                    child: const Text('Gravar'),
                                  )
                                : null,
                          );
                        },
                      ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: busy ? null : _commitOnDisk,
                      child: const Text('Gravar todos do PC'),
                    ),
                  ),
                ],
              ),

              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                initiallyExpanded: false,
                title: Text('Avançado', style: Theme.of(context).textTheme.titleSmall),
                subtitle: const Text('Curação %, pastas, inventário, download, edital'),
                children: [
                  if (curation != null) ...[
                    Text(
                      'Oficiais: ${curation!['officialCount'] ?? '—'} · '
                      'Natureza: ${curation!['naturezaCount'] ?? '—'}\n'
                      'Resoluções reais: ${curation!['realCount'] ?? 0}'
                      '${curation!['realPercent'] != null ? ' (${curation!['realPercent']}%)' : ''}\n'
                      'Cross-domain: ${curation!['crossDomainCount'] ?? 0}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (curation!['message'] != null)
                      Text(
                        curation!['message'].toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 8),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _openFolder('provas'),
                        icon: const Icon(Icons.folder_open_rounded, size: 18),
                        label: const Text('Provas'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _openFolder('gabaritos'),
                        icon: const Icon(Icons.folder_open_rounded, size: 18),
                        label: const Text('Gabaritos'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _openFolder('edital'),
                        icon: const Icon(Icons.folder_open_rounded, size: 18),
                        label: const Text('Edital'),
                      ),
                    ],
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sincronizar edital'),
                    trailing: OutlinedButton(onPressed: busy ? null : _syncEdital, child: const Text('Sync')),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reclassificar assuntos'),
                    trailing: OutlinedButton(onPressed: busy ? null : _classify, child: const Text('Rodar')),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Baixar todos do manifesto'),
                    trailing: OutlinedButton(onPressed: busy ? null : _fetchAvailable, child: const Text('Baixar')),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Baixar e revisar 1º ano'),
                    trailing: OutlinedButton(onPressed: busy ? null : _bootstrapFirstYear, child: const Text('Ir')),
                  ),
                  if (coverage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      coverage!['message']?.toString() ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (library?['dataDir'] != null)
                    Text(
                      'Pasta: ${library!['dataDir']}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),

              if (msg != null) ...[
                const SizedBox(height: 12),
                Text(
                  msg!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.primary),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

