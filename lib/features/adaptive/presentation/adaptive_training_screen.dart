import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/widgets/resolution_debrief.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/ui_kit.dart';

class AdaptiveTrainingScreen extends ConsumerStatefulWidget {
  const AdaptiveTrainingScreen({this.initialSubject, this.initialTopic, super.key});

  final String? initialSubject;
  final String? initialTopic;

  @override
  ConsumerState<AdaptiveTrainingScreen> createState() => _AdaptiveTrainingScreenState();
}

class _AdaptiveTrainingScreenState extends ConsumerState<AdaptiveTrainingScreen> {
  late String subject;
  late final TextEditingController topicCtrl;
  final focusNode = FocusNode();
  List<Map<String, dynamic>> queue = [];
  int index = 0;
  int? selected;
  bool revealed = false;
  String? error;
  bool loading = false;
  Map<String, dynamic>? meta;
  int correctCount = 0;
  int answeredCount = 0;
  String errorType = 'conceito';
  bool autoStarted = false;
  bool finished = false;

  static const _errorLabels = {
    'conceito': 'Conceito',
    'interpretacao': 'Interpretação',
    'calculo': 'Cálculo',
    'distracao': 'Distração',
    'tempo': 'Tempo',
  };

  static const _phaseLabel = {
    'semelhante': 'semelhante',
    'difícil': 'mais difícil',
    'inédita': 'inédita',
  };

  @override
  void initState() {
    super.initState();
    subject = (widget.initialSubject?.isNotEmpty == true) ? widget.initialSubject! : 'Biologia';
    topicCtrl = TextEditingController(
      text: (widget.initialTopic?.isNotEmpty == true) ? widget.initialTopic! : 'Genética',
    );
    if (widget.initialSubject != null || widget.initialTopic != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!autoStarted && mounted) {
          autoStarted = true;
          _start();
        }
      });
    }
  }

  @override
  void dispose() {
    topicCtrl.dispose();
    focusNode.dispose();
    super.dispose();
  }

  String get topic => topicCtrl.text.trim();

  Future<void> _start() async {
    setState(() {
      loading = true;
      error = null;
      index = 0;
      selected = null;
      revealed = false;
      correctCount = 0;
      answeredCount = 0;
      finished = false;
    });
    try {
      final data = await apiClient.post('/api/training/adaptive', {
        'subject': subject,
        'topic': topic,
        'nSimilar': 10,
        'nHarder': 20,
        'nGenerated': 0,
      });
      final map = Map<String, dynamic>.from(data as Map);
      final similar = (map['similar'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final harder = (map['harder'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final generated = (map['generated'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

      final generatedFull = <Map<String, dynamic>>[];
      for (final g in generated) {
        final id = g['id']?.toString();
        if (id == null) continue;
        try {
          final full = await apiClient.get('/api/questions/$id');
          generatedFull.add({...Map<String, dynamic>.from(full as Map), '_phase': 'inédita'});
        } catch (_) {
          generatedFull.add({...g, '_phase': 'inédita'});
        }
      }

      setState(() {
        meta = map;
        queue = [
          ...similar.map((q) => {...q, '_phase': 'semelhante'}),
          ...harder.map((q) => {...q, '_phase': 'difícil'}),
          ...generatedFull,
        ];
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) focusNode.requestFocus();
      });
    } catch (e) {
      setState(() => error = humanApiError(e, fallback: 'Não deu para montar o treino. Tente de novo.'));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _submit() async {
    if (selected == null || queue.isEmpty || revealed) return;
    final q = queue[index];
    final correctIndex = (q['correctIndex'] as num?)?.toInt();
    final correct = correctIndex != null && selected == correctIndex;
    setState(() {
      revealed = true;
      answeredCount++;
      if (correct) correctCount++;
    });
    final id = q['id']?.toString();
    if (id != null && correctIndex != null) {
      try {
        await apiClient.post('/api/answers', {
          'questionId': id,
          'correct': correct,
          'subject': q['subject'] ?? subject,
          'topic': q['topic'] ?? topic,
          'errorType': correct ? null : errorType,
          'timeMs': null,
        });
        ref.read(refreshTickProvider.notifier).state++;
      } catch (_) {}
    }
  }

  void _next() {
    if (index >= queue.length - 1) {
      setState(() => finished = true);
      return;
    }
    setState(() {
      index++;
      selected = null;
      revealed = false;
    });
    focusNode.requestFocus();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || queue.isEmpty || finished) return KeyEventResult.ignored;
    if (revealed) {
      if (event.logicalKey == LogicalKeyboardKey.keyN ||
          event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        _next();
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
    final opt = keys[event.logicalKey];
    if (opt != null) {
      final opts = (queue[index]['options'] as List? ?? []);
      if (opt < opts.length) {
        setState(() => selected = opt);
        return KeyEventResult.handled;
      }
    }
    if ((event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) &&
        selected != null) {
      _submit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final q = (!finished && queue.isNotEmpty) ? queue[index] : null;
    final options = (q?['options'] as List? ?? []).map((e) => e.toString()).toList();
    final correctIndex = (q?['correctIndex'] as num?)?.toInt();
    final cs = Theme.of(context).colorScheme;
    final inQueue = queue.isNotEmpty && !finished;

    return Focus(
      focusNode: focusNode,
      onKeyEvent: _onKey,
      child: ListView(
        children: [
          PageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  eyebrow: 'Conteúdo',
                  title: 'Treino',
                  subtitle: finished
                      ? 'Fila concluída · $correctCount/$answeredCount'
                      : inQueue
                          ? 'Acertos $correctCount/$answeredCount · item ${index + 1}/${queue.length}'
                          : 'Semelhantes → mais difíceis (sem questões inventadas)',
                  trailing: (inQueue || finished)
                      ? TextButton(
                          onPressed: () => setState(() {
                            queue = [];
                            meta = null;
                            finished = false;
                          }),
                          child: const Text('Trocar tópico'),
                        )
                      : null,
                ),
                if (finished) ...[
                  SurfacePanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fim da fila', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Acertos $correctCount de $answeredCount'
                          '${answeredCount > 0 ? ' (${(100 * correctCount / answeredCount).toStringAsFixed(0)}%)' : ''}'
                          ' · $subject · $topic',
                        ),
                        if (meta?['dominantErrorType'] != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Tipo dominante recente: ${meta!['dominantErrorType']}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton(
                              onPressed: () => context.go('/fila'),
                              child: const Text('Fila'),
                            ),
                            FilledButton.tonal(
                              onPressed: () => context.go('/flashcards'),
                              child: const Text('Cards'),
                            ),
                            if (subject.isNotEmpty && topic.isNotEmpty)
                              OutlinedButton(
                                onPressed: () async {
                                  try {
                                    await apiClient.post('/api/gaps/recover', {
                                      'subject': subject,
                                      'topic': topic,
                                    });
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Lacuna marcada como recuperada (treino local).',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$e')),
                                    );
                                  }
                                },
                                child: const Text('Marcar recuperada'),
                              ),
                            OutlinedButton(
                              onPressed: () => context.go('/dashboard'),
                              child: const Text('Hoje'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else if (!inQueue) ...[
                  DropdownMenu<String>(
                    initialSelection: subject,
                    label: const Text('Disciplina'),
                    onSelected: (v) => setState(() => subject = v ?? subject),
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: 'Biologia', label: 'Biologia'),
                      DropdownMenuEntry(value: 'Matemática', label: 'Matemática'),
                      DropdownMenuEntry(value: 'Química', label: 'Química'),
                      DropdownMenuEntry(value: 'Língua Portuguesa e Literatura', label: 'Português'),
                      DropdownMenuEntry(value: 'Física', label: 'Física'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: topicCtrl,
                    decoration: const InputDecoration(labelText: 'Assunto'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: loading || topic.isEmpty ? null : _start,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(loading ? 'Montando…' : 'Iniciar treino'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    QuietEmpty(
                      message: error!,
                      action: TextButton(
                        onPressed: loading || topic.isEmpty ? null : _start,
                        child: const Text('Tentar'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  QuietEmpty(
                    message: 'Escolha tópico ou volte à sessão do dia.',
                    action: TextButton(
                      onPressed: () => context.go('/sessao'),
                      child: const Text('Abrir sessão'),
                    ),
                  ),
                ] else if (q != null) ...[
                  SurfacePanel(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Questão ${index + 1}/${queue.length}'
                          ' · ${_phaseLabel[q['_phase']] ?? q['_phase']}'
                          '${q['generated'] == true ? ' · revisar depois' : ''}',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${q['subject'] ?? subject} · ${q['topic'] ?? topic}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 10),
                        Text(q['statement']?.toString() ?? q['id']?.toString() ?? ''),
                        const SizedBox(height: 8),
                        if (options.isEmpty)
                          QuietEmpty(
                            message: 'Sem alternativas — abra a questão completa se precisar.',
                            action: TextButton(
                              onPressed: () {
                                final id = q['id']?.toString() ?? '';
                                if (id.isNotEmpty) context.go('/questoes/$id');
                              },
                              child: const Text('Abrir ficha'),
                            ),
                          )
                        else
                          for (var i = 0; i < options.length; i++)
                            RadioListTile<int>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              value: i,
                              groupValue: selected,
                              onChanged: revealed ? null : (v) => setState(() => selected = v),
                              title: Text('${'ABCDE'[i]}) ${options[i]}'),
                              secondary: revealed && correctIndex != null
                                  ? Icon(
                                      i == correctIndex
                                          ? Icons.check_circle
                                          : (i == selected ? Icons.cancel : null),
                                      color: i == correctIndex ? Colors.green : Colors.red,
                                    )
                                  : null,
                            ),
                        if (!revealed) ...[
                          const SizedBox(height: 6),
                          Text('Se errar, tipo de erro:', style: Theme.of(context).textTheme.bodySmall),
                          Wrap(
                            spacing: 6,
                            children: [
                              for (final e in _errorLabels.entries)
                                ChoiceChip(
                                  label: Text(e.value),
                                  selected: errorType == e.key,
                                  onSelected: (_) => setState(() => errorType = e.key),
                                ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          Text(
                            selected == correctIndex
                                ? 'Correto!'
                                : 'Incorreto · gabarito ${correctIndex != null ? 'ABCDE'[correctIndex] : '—'}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: selected == correctIndex ? Colors.green : cs.error,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ResolutionDebrief(
                            question: q,
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    final s = (q['subject'] ?? subject).toString();
                                    final t = (q['topic'] ?? topic).toString();
                                    context.go(
                                      '/adaptativo?subject=${Uri.encodeComponent(s)}'
                                      '&topic=${Uri.encodeComponent(t)}',
                                    );
                                  },
                                  child: const Text('Treinar este tópico'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final id = q['id']?.toString();
                                    if (id == null) return;
                                    try {
                                      final data = await apiClient.post(
                                        '/api/flashcards/from-question',
                                        {'questionId': id, 'count': 4},
                                      );
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Card(s): ${(data as Map)['created'] ?? 0}'),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('$e')),
                                      );
                                    }
                                  },
                                  child: const Text('Criar card'),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton(
                              onPressed: revealed || selected == null ? null : _submit,
                              child: const Text('Confirmar'),
                            ),
                            FilledButton.tonal(
                              onPressed: revealed ? _next : null,
                              child: Text(index >= queue.length - 1 ? 'Concluir' : 'Próxima'),
                            ),
                            TextButton(
                              onPressed: index == 0
                                  ? null
                                  : () => setState(() {
                                        index--;
                                        selected = null;
                                        revealed = false;
                                      }),
                              child: const Text('Anterior'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Atalhos: 1–5 opção · Enter/numpad confirma · N/Enter próxima',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withOpacity(0.45),
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
      ),
    );
  }
}
