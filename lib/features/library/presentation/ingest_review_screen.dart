import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui_kit.dart';

/// Payload passado via `GoRouterState.extra` após import-year preview.
class IngestReviewArgs {
  const IngestReviewArgs({
    required this.year,
    required this.previewId,
    required this.questions,
    this.meta = const {},
  });

  final int year;
  final String previewId;
  final List<Map<String, dynamic>> questions;
  final Map<String, dynamic> meta;
}

class IngestReviewScreen extends ConsumerStatefulWidget {
  const IngestReviewScreen({required this.args, super.key});

  final IngestReviewArgs args;

  @override
  ConsumerState<IngestReviewScreen> createState() => _IngestReviewScreenState();
}

class _IngestReviewScreenState extends ConsumerState<IngestReviewScreen> {
  late List<Map<String, dynamic>> questions;
  int index = 0;
  bool busy = false;
  String? msg;
  bool filterSuspects = false;
  bool _bootstrapPromptShown = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    questions = widget.args.questions.map((e) => Map<String, dynamic>.from(e)).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeOfferBootstrapCommit();
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _prevQuestion() {
    final vis = _visibleIndices;
    if (vis.isEmpty) return;
    final pos = vis.indexOf(index);
    if (pos > 0) setState(() => index = vis[pos - 1]);
  }

  void _nextQuestion() {
    final vis = _visibleIndices;
    if (vis.isEmpty) return;
    final pos = vis.indexOf(index);
    if (pos >= 0 && pos < vis.length - 1) setState(() => index = vis[pos + 1]);
  }

  bool get _canPrev {
    final vis = _visibleIndices;
    if (vis.isEmpty) return false;
    return vis.indexOf(index) > 0;
  }

  bool get _canNext {
    final vis = _visibleIndices;
    if (vis.isEmpty) return false;
    final pos = vis.indexOf(index);
    return pos >= 0 && pos < vis.length - 1;
  }

  void _pickAnswer(int i) {
    final opts = current['options'] as List? ?? [];
    if (i < 0 || i >= opts.length) return;
    setState(() {
      current['correctIndex'] = i;
      current['gabaritoApplied'] = true;
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyJ) {
      _prevQuestion();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyK) {
      _nextQuestion();
      return KeyEventResult.handled;
    }
    const digitKeys = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
    ];
    const numpadKeys = [
      LogicalKeyboardKey.numpad1,
      LogicalKeyboardKey.numpad2,
      LogicalKeyboardKey.numpad3,
      LogicalKeyboardKey.numpad4,
      LogicalKeyboardKey.numpad5,
    ];
    for (var i = 0; i < 5; i++) {
      if (key == digitKeys[i] || key == numpadKeys[i]) {
        _pickAnswer(i);
        return KeyEventResult.handled;
      }
    }
    if (key == LogicalKeyboardKey.keyH && !busy && questions.isNotEmpty) {
      unawaited(_commit(highConfidenceOnly: true));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyE) {
      unawaited(_editMeta());
      return KeyEventResult.handled;
    }
    final primary = FocusManager.instance.primaryFocus;
    if (primary != null && primary.context?.widget is EditableText) {
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.keyS) {
      context.go(
        '/sessao?examBoard=UEMA_PAES&year=${widget.args.year}&preferNatureza=1',
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _maybeOfferBootstrapCommit() async {
    if (_bootstrapPromptShown || !mounted) return;
    final fromBootstrap = widget.args.meta['fromBootstrap'] == true;
    if (!fromBootstrap) return;
    _bootstrapPromptShown = true;
    final high = questions.where(_isHighConfidence).length;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gravar as boas agora?'),
        content: Text(
          high > 0
              ? 'Há $high questões boas (alta confiança + gabarito). '
                  'Confirme para colocar no acervo e estudar na sessão UEMA.'
              : 'Ainda não há questões boas o suficiente — confira gabarito e use “Só as boas” depois.',
        ),
        actions: [
          TextButton(onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(ctx, 'review'); }, child: const Text('Revisar primeiro')),
          if (high > 0)
            FilledButton(onPressed: () { HapticFeedback.mediumImpact(); Navigator.pop(ctx, 'commit'); }, child: const Text('Sim, gravar')),
        ],
      ),
    );
    if (choice == 'commit' && mounted) {
      await _commit(highConfidenceOnly: true);
    }
  }

  bool _isSuspect(Map<String, dynamic> q) {
    final conf = (q['parseConfidence'] as num?)?.toDouble() ?? 0;
    final gabMissing = q['gabaritoApplied'] != true;
    final hasPlaceholder = (q['options'] as List? ?? []).any((o) => '$o'.contains('(revisar)'));
    final topicWeak = (q['topic']?.toString() ?? '') == 'A classificar' ||
        ((q['topicConfidence'] as num?)?.toDouble() ?? 1) < 0.3;
    return conf < 0.5 || gabMissing || hasPlaceholder || topicWeak;
  }

  bool _isHighConfidence(Map<String, dynamic> q) {
    final conf = (q['parseConfidence'] as num?)?.toDouble() ?? 0;
    final gabOk = q['gabaritoApplied'] == true;
    final hasPlaceholder = (q['options'] as List? ?? []).any((o) => '$o'.contains('(revisar)'));
    return conf >= 0.55 && gabOk && !hasPlaceholder;
  }

  List<int> get _visibleIndices {
    if (!filterSuspects) return List.generate(questions.length, (i) => i);
    return [for (var i = 0; i < questions.length; i++) if (_isSuspect(questions[i])) i];
  }

  Map<String, dynamic> get current => questions[index.clamp(0, questions.length - 1)];

  Future<void> _commit({bool highConfidenceOnly = false}) async {
    setState(() {
      busy = true;
      msg = highConfidenceOnly ? 'Gravando itens com alta confiança…' : 'Gravando no acervo…';
    });
    try {
      await apiClient.post('/api/ingest/preview/update', {
        'previewId': widget.args.previewId,
        'questions': questions,
      });
      final data = await apiClient.post('/api/ingest/commit', {
        'previewId': widget.args.previewId,
        'questions': questions,
        'highConfidenceOnly': highConfidenceOnly,
        'minConfidence': 0.55,
        'autoProfessor': true,
      });
      ref.read(refreshTickProvider.notifier).state++;
      if (!mounted) return;
      final map = Map<String, dynamic>.from(data as Map);
      final n = map['officialCount'] ?? 0;
      final nInt = n is int ? n : int.tryParse('$n') ?? 0;
      final inserted = map['inserted'] ?? 0;
      final skipped = map['skipped'] ?? 0;
      final year = widget.args.year;
      final sessaoPath = map['sessionPath']?.toString() ??
          '/sessao?examBoard=UEMA_PAES&year=$year&preferNatureza=1';
      final health = Map<String, dynamic>.from(map['yearHealth'] as Map? ?? {});
      final nat = Map<String, dynamic>.from(health['natureza'] as Map? ?? {});
      final healthBit = health.isEmpty
          ? ''
          : ' · gabarito ${health['gabaritoPct'] ?? '—'}% · Bio ${nat['Biologia'] ?? 0}/Qui ${nat['Química'] ?? 0}/Fis ${nat['Física'] ?? 0}';
      final toast =
          'Gravamos $inserted oficiais no acervo'
          '${skipped is int && skipped > 0 ? ' · $skipped ficaram de fora (baixa confiança)' : ''}'
          ' · total na base: $nInt$healthBit'
          '${nInt >= 10 ? ' · base oficial pronta.' : ' · falta um pouco para ≥10 oficiais.'}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(toast),
          action: SnackBarAction(
            label: 'Estudar agora',
            onPressed: () { HapticFeedback.selectionClick(); context.go(sessaoPath); },
          ),
          duration: const Duration(seconds: 6),
        ),
      );
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Oficiais no acervo'),
          content: Text('$toast\n\nQuer estudar Natureza/UEMA agora?'),
          actions: [
            TextButton(
              onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(ctx, 'professor'); },
              child: const Text('Preparar explicações'),
            ),
            TextButton(onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(ctx, 'later'); }, child: const Text('Depois')),
            FilledButton(onPressed: () { HapticFeedback.mediumImpact(); Navigator.pop(ctx, 'study'); }, child: const Text('Estudar agora')),
          ],
        ),
      );
      if (!mounted) return;
      if (choice == 'study') {
        context.go(sessaoPath);
        return;
      }
      if (choice == 'professor') {
        try {
          await apiClient.post('/api/professor/batch-fill', {'limit': 30, 'preferUema': true});
        } catch (e) {
          if (mounted) {
            setState(
              () => msg = humanApiError(e, fallback: 'Rascunhos professor indisponíveis.'),
            );
          }
        }
      }
      if (!mounted) return;
      if (highConfidenceOnly) {
        setState(() => msg = toast);
      } else {
        context.go('/biblioteca');
      }
    } catch (e) {
      setState(() => msg = humanApiError(e, fallback: 'Não deu para gravar — revise e tente de novo.'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _editMeta() async {
    final q = current;
    final subjectCtrl = TextEditingController(text: '${q['subject'] ?? ''}');
    final topicCtrl = TextEditingController(text: '${q['topic'] ?? ''}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Q${q['number'] ?? index + 1}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: subjectCtrl, decoration: const InputDecoration(labelText: 'Disciplina')),
            TextField(controller: topicCtrl, decoration: const InputDecoration(labelText: 'Assunto')),
          ],
        ),
        actions: [
          TextButton(onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(ctx, false); }, child: const Text('Cancelar')),
          FilledButton(onPressed: () { HapticFeedback.mediumImpact(); Navigator.pop(ctx, true); }, child: const Text('Salvar')),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        q['subject'] = subjectCtrl.text.trim();
        q['topic'] = topicCtrl.text.trim();
      });
    }
  }

  bool get _gabaritoPct {
    if (questions.isEmpty) return false;
    final n = questions.where((q) => q['gabaritoApplied'] == true).length;
    return n > 0;
  }

  int get _gabaritoAppliedCount => questions.where((q) => q['gabaritoApplied'] == true).length;

  @override
  Widget build(BuildContext context) {
    final meta = widget.args.meta;
    final needsOcr = meta['needsOcr'] == true;
    final ocrFailed = meta['ocrFailed'] == true;
    final pair = Map<String, dynamic>.from(meta['pairValidation'] as Map? ?? {});
    final unmatchedQ = (pair['unmatchedQuestions'] as List? ?? []);
    final unmatchedA = (pair['unmatchedAnswers'] as List? ?? []);
    final letter = 'ABCDE'[(current['correctIndex'] as int? ?? 0).clamp(0, 4)];
    final suspects = questions.where(_isSuspect).length;
    final visible = _visibleIndices;
    final hasGab = _gabaritoPct;
    final highN = questions.where(_isHighConfidence).length;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      child: Scaffold(
      appBar: AppBar(
        title: Text('Revisão PAES ${widget.args.year}'),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/biblioteca'),
        ),
        actions: [
          TextButton(onPressed: busy ? null : () => context.go('/biblioteca'), child: const Text('Descartar')),
          FilledButton.tonal(
            onPressed: busy || questions.isEmpty || highN == 0
                ? null
                : () => _commit(highConfidenceOnly: true),
            child: Text('Só as boas ($highN)'),
          ),
          FilledButton(
            onPressed: busy || questions.isEmpty || !hasGab ? null : () => _commit(),
            child: const Text('Gravar todas no acervo'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: questions.isEmpty
          ? const Center(child: Text('Nenhuma questão no preview.'))
          : Column(
              children: [
                if (!hasGab)
                  Material(
                    color: Theme.of(context).colorScheme.tertiaryContainer.f45,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Sem gabarito aplicado (0/${questions.length}). '
                              'Coloque o gabarito do ano na pasta Gabaritos ou marque as respostas. '
                              'Gravar fica desativado para não inventar acertos.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.tertiary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Material(
                    color: Theme.of(context).colorScheme.primaryContainer.f45,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text(
                        'Gabarito: $_gabaritoAppliedCount/${questions.length} · altas conf. $highN',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer),
                      ),
                    ),
                  ),
                Expanded(
                  child: Row(
              children: [
                SizedBox(
                  width: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (needsOcr || ocrFailed)
                        Material(
                          color: Theme.of(context).colorScheme.tertiaryContainer.f45,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              ocrFailed
                                  ? 'A leitura automática falhou ou está indisponível. Revise o texto manualmente.'
                                  : 'O PDF parece escaneado. Confirme os enunciados e revise o texto antes de importar.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.tertiary),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${questions.length} questões · conf. média ${meta['avgParseConfidence'] ?? '—'} · '
                              '$suspects duvidosas',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(pair['message']?.toString() ?? '', style: Theme.of(context).textTheme.bodySmall),
                            if (unmatchedQ.isNotEmpty)
                              Text(
                                'Sem gabarito: ${unmatchedQ.take(12).join(', ')}${unmatchedQ.length > 12 ? '…' : ''}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onTertiaryContainer),
                              ),
                            if (unmatchedA.isNotEmpty)
                              Text(
                                'Gabarito sem questão: ${unmatchedA.take(12).join(', ')}${unmatchedA.length > 12 ? '…' : ''}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onTertiaryContainer),
                              ),
                            FilterChip(
                              label: Text(filterSuspects ? 'Só duvidosas ($suspects)' : 'Todas'),
                              selected: filterSuspects,
                              onSelected: (v) => setState(() {
                                filterSuspects = v;
                                if (visible.isNotEmpty) index = visible.first;
                              }),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: visible.length,
                          itemBuilder: (_, vi) {
                            final i = visible[vi];
                            final q = questions[i];
                            final conf = (q['parseConfidence'] as num?)?.toDouble();
                            final suspect = _isSuspect(q);
                            return ListTile(
                              selected: i == index,
                              dense: true,
                              tileColor: suspect ? Theme.of(context).colorScheme.tertiaryContainer.f45 : null,
                              leading: suspect
                                  ? Icon(Icons.warning_amber, color: Theme.of(context).colorScheme.onTertiaryContainer, size: 18)
                                  : const Icon(Icons.check_circle_outline, color: AppTheme.teal, size: 18),
                              title: Text('Q${q['number'] ?? i + 1}'),
                              subtitle: Text(
                                '${q['subject']} / ${q['topic']}'
                                '${conf != null ? ' · ${(conf * 100).round()}%' : ''}'
                                '${q['gabaritoApplied'] == true ? '' : ' · sem gab'}',
                              ),
                              onTap: () => setState(() => index = i),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                    children: [
                      if (_isSuspect(current))
                        SurfacePanel(
                          padding: EdgeInsets.zero,
                          color: Theme.of(context).colorScheme.tertiaryContainer.f45,
                          child: const ListTile(
                            leading: Icon(Icons.priority_high),
                            title: Text('Revisar com atenção'),
                            subtitle: Text('Baixa confiança, sem gabarito aplicado ou alternativa placeholder.'),
                          ),
                        ),
                      Text(
                        'Q${current['number'] ?? index + 1} · ${current['subject']} / ${current['topic']}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Confiança parse: ${((current['parseConfidence'] as num?)?.toDouble() ?? 0) * 100 ~/ 1}%'
                        '${current['gabaritoApplied'] == true ? ' · gabarito OK' : ' · gabarito NÃO aplicado'}',
                        style: TextStyle(
                          color: _isSuspect(current) ? Theme.of(context).colorScheme.onTertiaryContainer : AppTheme.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Dica: setas mudam a questão · 1–5 marca gabarito · H grava só as boas',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.f72,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(current['statement']?.toString() ?? ''),
                      const SizedBox(height: 16),
                      for (var i = 0; i < (current['options'] as List? ?? []).length; i++)
                        RadioListTile<int>(
                          value: i,
                          groupValue: current['correctIndex'] as int? ?? 0,
                          onChanged: (v) => setState(() {
                            current['correctIndex'] = v;
                            current['gabaritoApplied'] = true;
                          }),
                          title: Text('${'ABCDE'[i]}) ${(current['options'] as List)[i]}'),
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton.tonal(onPressed: _editMeta, child: const Text('Editar disciplina/assunto')),
                          OutlinedButton(
                            onPressed: _canPrev ? _prevQuestion : null,
                            child: const Text('Anterior (←/J)'),
                          ),
                          FilledButton(
                            onPressed: _canNext ? _nextQuestion : null,
                            child: const Text('Próxima (→/K)'),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              final suspects = [
                                for (var i = 0; i < questions.length; i++)
                                  if (_isSuspect(questions[i])) i,
                              ];
                              if (suspects.isEmpty) return;
                              final next = suspects.firstWhere((i) => i > index, orElse: () => suspects.first);
                              setState(() {
                                filterSuspects = true;
                                index = next;
                              });
                            },
                            child: const Text('Próxima duvidosa'),
                          ),
                          Chip(label: Text('Gabarito: $letter')),
                        ],
                      ),
                      if (msg != null) ...[
                        const SizedBox(height: 12),
                        QuietEmpty(message: msg!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
                ),
              ],
            ),
    ),
    );
  }
}
