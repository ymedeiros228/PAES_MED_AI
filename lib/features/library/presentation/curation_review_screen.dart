import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/widgets/ui_kit.dart';
import '../data/library_api.dart';

/// Fila de curadoria: questões suspeitas (enunciado/opções) com edição A–E.
class CurationReviewScreen extends ConsumerStatefulWidget {
  const CurationReviewScreen({super.key});

  @override
  ConsumerState<CurationReviewScreen> createState() => _CurationReviewScreenState();
}

class _CurationReviewScreenState extends ConsumerState<CurationReviewScreen> {
  bool loading = true;
  bool busy = false;
  String? msg;
  List<Map<String, dynamic>> problems = [];
  int index = 0;

  late final TextEditingController _statementCtrl;
  late final List<TextEditingController> _optionCtrls;
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _topicCtrl;
  int _correctIndex = 0;
  String? _currentId;
  List<String> _issues = [];

  @override
  void initState() {
    super.initState();
    _statementCtrl = TextEditingController();
    _optionCtrls = List.generate(5, (_) => TextEditingController());
    _subjectCtrl = TextEditingController();
    _topicCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQueue());
  }

  @override
  void dispose() {
    _statementCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    _subjectCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadQueue() async {
    setState(() {
      loading = true;
      msg = null;
    });
    try {
      final data = await LibraryApi.reviewQueue();
      final list = (data['problems'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (!mounted) return;
      setState(() {
        problems = list;
        index = 0;
        loading = false;
        msg = data['message']?.toString();
      });
      if (problems.isNotEmpty) {
        await _loadCurrent();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        msg = humanApiError(e, fallback: 'Não deu para carregar a fila.');
      });
    }
  }

  Future<void> _loadCurrent() async {
    if (problems.isEmpty || index < 0 || index >= problems.length) return;
    final meta = problems[index];
    final id = meta['id']?.toString();
    if (id == null || id.isEmpty) return;
    setState(() {
      busy = true;
      _issues = (meta['issues'] as List? ?? []).map((e) => e.toString()).toList();
    });
    try {
      final api = apiClient;
      final raw = await api.get('/api/questions/$id');
      final q = Map<String, dynamic>.from(raw as Map);
      final opts = (q['options'] as List? ?? []).map((e) => e.toString()).toList();
      while (opts.length < 5) {
        opts.add('');
      }
      if (!mounted) return;
      setState(() {
        _currentId = id;
        _statementCtrl.text = q['statement']?.toString() ?? '';
        for (var i = 0; i < 5; i++) {
          _optionCtrls[i].text = opts[i];
        }
        _subjectCtrl.text = q['subject']?.toString() ?? '';
        _topicCtrl.text = q['topic']?.toString() ?? '';
        _correctIndex = (q['correctIndex'] as num?)?.toInt() ?? 0;
        busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        msg = humanApiError(e, fallback: 'Não deu para carregar a fila.');
      });
    }
  }

  Future<void> _save({bool markOk = false}) async {
    final id = _currentId;
    if (id == null) return;
    setState(() => busy = true);
    try {
      final api = apiClient;
      await api.patch('/api/questions/$id', {
        'statement': _statementCtrl.text.trim(),
        'options': _optionCtrls.map((c) => c.text.trim()).toList(),
        'correctIndex': _correctIndex,
        'subject': _subjectCtrl.text.trim(),
        'topic': _topicCtrl.text.trim(),
      });
      if (markOk) {
        await LibraryApi.markReviewed(id);
      } else {
        // Salvar também tira da fila (conteúdo corrigido).
        await LibraryApi.markReviewed(id);
      }
      if (!mounted) return;
      setState(() {
        problems.removeAt(index);
        if (index >= problems.length) {
          index = (problems.length - 1).clamp(0, problems.length);
        }
        busy = false;
        msg = markOk ? 'Marcada como ok.' : 'Salva e removida da fila.';
      });
      if (problems.isNotEmpty) {
        await _loadCurrent();
      } else {
        setState(() => _currentId = null);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        msg = humanApiError(e, fallback: 'Não deu para carregar a fila.');
      });
    }
  }

  Future<void> _skip() async {
    if (problems.isEmpty) return;
    setState(() {
      index = (index + 1) % problems.length;
    });
    await _loadCurrent();
  }

  Future<void> _markOkOnly() async {
    final id = _currentId;
    if (id == null) return;
    setState(() => busy = true);
    try {
      await LibraryApi.markReviewed(id);
      if (!mounted) return;
      setState(() {
        problems.removeAt(index);
        if (index >= problems.length) {
          index = (problems.length - 1).clamp(0, problems.length);
        }
        busy = false;
        msg = 'Marcada como ok (sem editar).';
      });
      if (problems.isNotEmpty) {
        await _loadCurrent();
      } else {
        setState(() => _currentId = null);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        msg = humanApiError(e, fallback: 'Não deu para carregar a fila.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final letters = ['A', 'B', 'C', 'D', 'E'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisar suspeitas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/biblioteca');
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar fila',
            onPressed: busy ? null : () => unawaited(_loadQueue()),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : problems.isEmpty
              ? Center(
                  child: QuietEmpty(
                    message: msg ?? 'Nenhuma suspeita na fila. Bom sinal.',
                    action: FilledButton.tonal(
                      onPressed: () => context.go('/biblioteca'),
                      child: const Text('Voltar à Biblioteca'),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Text(
                      '${index + 1} / ${problems.length}'
                      '${_currentId != null ? ' · $_currentId' : ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                    if (_issues.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _issues
                            .map(
                              (i) => Chip(
                                label: Text(i, style: const TextStyle(fontSize: 11)),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (msg != null) ...[
                      const SizedBox(height: 8),
                      Text(msg!, style: TextStyle(color: cs.onSurface.withOpacity(0.7), fontSize: 13)),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _subjectCtrl,
                      decoration: const InputDecoration(labelText: 'Disciplina', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _topicCtrl,
                      decoration: const InputDecoration(labelText: 'Assunto', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _statementCtrl,
                      minLines: 4,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        labelText: 'Enunciado',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Alternativas', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    for (var i = 0; i < 5; i++) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Radio<int>(
                            value: i,
                            groupValue: _correctIndex,
                            onChanged: busy
                                ? null
                                : (v) {
                                    if (v == null) return;
                                    HapticFeedback.selectionClick();
                                    setState(() => _correctIndex = v);
                                  },
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: SizedBox(
                              width: 22,
                              child: Text(
                                letters[i],
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _correctIndex == i ? cs.primary : cs.onSurface,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _optionCtrls[i],
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Alternativa ${letters[i]}',
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'O círculo marca o gabarito (A–E).',
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: busy ? null : () {
                            HapticFeedback.mediumImpact();
                            unawaited(_save());
                          },
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text('Salvar'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: busy ? null : () {
                            HapticFeedback.selectionClick();
                            unawaited(_markOkOnly());
                          },
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Marcar ok'),
                        ),
                        OutlinedButton.icon(
                          onPressed: busy ? null : () {
                            HapticFeedback.selectionClick();
                            unawaited(_skip());
                          },
                          icon: const Icon(Icons.skip_next_rounded, size: 18),
                          label: const Text('Pular'),
                        ),
                      ],
                    ),
                    if (busy) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
    );
  }
}
