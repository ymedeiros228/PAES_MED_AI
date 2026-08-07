import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/ux_copy.dart';
import '../../../core/widgets/media_reinforcement.dart';
import '../../../core/widgets/resolution_debrief.dart';
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
  bool pendingErrorPick = false;
  String? answerSaveError;
  String? generatedPartialNote;

  static const _errorTypes = [
    'conceito',
    'interpretacao',
    'calculo',
    'distracao',
    'tempo',
  ];

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
      answerSaveError = null;
      generatedPartialNote = null;
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
      var partialGenerated = 0;
      for (final g in generated) {
        final id = g['id']?.toString();
        if (id == null) continue;
        try {
          final full = await apiClient.get('/api/questions/$id');
          generatedFull.add({...Map<String, dynamic>.from(full as Map), '_phase': 'inédita'});
        } catch (_) {
          partialGenerated++;
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
        generatedPartialNote = partialGenerated > 0
            ? '$partialGenerated inédita(s) carregadas parcialmente — API instável?'
            : null;
        if (queue.isEmpty) {
          error =
              'Nenhuma questão para este tópico — importe na Biblioteca ou escolha outro assunto.';
        }
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

  Future<void> _postAnswer({required bool correct}) async {
    final q = queue[index];
    final correctIndex = (q['correctIndex'] as num?)?.toInt();
    final id = q['id']?.toString();
    if (id == null || correctIndex == null) return;
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
      if (mounted) setState(() => answerSaveError = null);
    } catch (e) {
      if (!mounted) return;
      setState(
        () => answerSaveError = humanApiError(
          e,
          fallback: 'Resposta não gravada — progresso local pode estar incompleto.',
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (selected == null || queue.isEmpty || revealed) return;
    final q = queue[index];
    final correctIndex = (q['correctIndex'] as num?)?.toInt();
    final correct = correctIndex != null && selected == correctIndex;
    if (correct) {
      setState(() {
        revealed = true;
        answeredCount++;
        correctCount++;
        pendingErrorPick = false;
      });
      await _postAnswer(correct: true);
    } else {
      setState(() {
        revealed = true;
        answeredCount++;
        pendingErrorPick = true;
      });
    }
  }

  Future<void> _confirmErrorAndSave() async {
    if (!pendingErrorPick) return;
    setState(() => pendingErrorPick = false);
    await _postAnswer(correct: false);
  }

  void _next() {
    if (pendingErrorPick) return;
    if (index >= queue.length - 1) {
      setState(() => finished = true);
      return;
    }
    setState(() {
      index++;
      selected = null;
      revealed = false;
      pendingErrorPick = false;
      errorType = 'conceito';
    });
    focusNode.requestFocus();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final primary = FocusManager.instance.primaryFocus;
    final inField = primary != null && primary.context?.widget is EditableText;
    if ((event.logicalKey == LogicalKeyboardKey.keyR ||
            event.logicalKey == LogicalKeyboardKey.f5) &&
        !inField &&
        !loading) {
      unawaited(_start());
      return KeyEventResult.handled;
    }
    if (queue.isEmpty || finished) return KeyEventResult.ignored;

    final digitMap = {
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

    // Após miss: 1–5 tipo de erro; Enter confirma e grava; N avança depois
    if (pendingErrorPick) {
      final ei = digitMap[event.logicalKey];
      if (ei != null && ei < _errorTypes.length) {
        setState(() => errorType = _errorTypes[ei]);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        unawaited(_confirmErrorAndSave());
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (revealed) {
      if (event.logicalKey == LogicalKeyboardKey.keyN ||
          event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        _next();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final opt = digitMap[event.logicalKey];
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
      unawaited(_submit());
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
                          : 'Semelhantes → mais difíceis no mesmo tópico',
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
                if (generatedPartialNote != null) ...[
                  Text(
                    generatedPartialNote!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.tertiary),
                  ),
                  const SizedBox(height: 8),
                ],
                if (answerSaveError != null) ...[
                  QuietEmpty(
                    message: answerSaveError!,
                    action: TextButton(
                      onPressed: loading ? null : () => unawaited(_start()),
                      child: const Text('Tentar'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
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
                            'Tipo dominante recente: ${errorTypeLabelPt(meta!['dominantErrorType'].toString())}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: () => context.go('/fila'),
                          icon: const Icon(Icons.playlist_play_rounded),
                          label: const Text('Continuar na Fila'),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.tonal(
                              onPressed: () => context.go('/flashcards?due=1'),
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
                                      const SnackBar(content: Text('Lacuna enviada para reforço na Fila.')),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para marcar a lacuna.'))),
                                    );
                                  }
                                },
                                child: const Text('Reforçar na Fila'),
                              ),
                            TextButton(
                              onPressed: loading ? null : () => unawaited(_start()),
                              child: const Text('Remontar treino'),
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
                      action: Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: loading || topic.isEmpty ? null : _start,
                            child: const Text('Tentar'),
                          ),
                          TextButton(
                            onPressed: () => context.go('/biblioteca'),
                            child: const Text('Biblioteca'),
                          ),
                          TextButton(
                            onPressed: () => context.go('/sessao'),
                            child: const Text('Sessão'),
                          ),
                        ],
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
                            ChoiceOptionTile(
                              index: i,
                              label: '${options[i]}',
                              selected: selected == i,
                              enabled: !revealed,
                              revealCorrect: revealed && correctIndex != null
                                  ? (i == correctIndex
                                      ? true
                                      : (i == selected ? false : null))
                                  : null,
                              onTap: () => setState(() => selected = i),
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
                          if (pendingErrorPick) ...[
                            const SizedBox(height: 8),
                            Text('Tipo de erro (1–5):', style: Theme.of(context).textTheme.bodySmall),
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
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed: () => unawaited(_confirmErrorAndSave()),
                              child: const Text('Registrar tipo e continuar'),
                            ),
                          ],
                          if (!pendingErrorPick) ...[
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
                                        SnackBar(
                                          content: Text(
                                            humanApiError(e, fallback: 'Não deu para criar o card.'),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Criar card'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          MediaReinforcement(
                            subject: (q['subject'] ?? subject).toString(),
                            topic: (q['topic'] ?? topic).toString(),
                            compact: true,
                            heading: 'Vídeos e leituras do tópico',
                          ),
                          ],
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
                              onPressed: revealed && !pendingErrorPick ? _next : null,
                              child: Text(index >= queue.length - 1 ? 'Concluir' : 'Próxima'),
                            ),
                            TextButton(
                              onPressed: index == 0
                                  ? null
                                  : () => setState(() {
                                        index--;
                                        selected = null;
                                        revealed = false;
                                        pendingErrorPick = false;
                                      }),
                              child: const Text('Anterior'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          pendingErrorPick
                              ? 'Atalhos: 1–5 tipo de erro · Enter registra'
                              : 'Atalhos: 1–5 opção · Enter confirma · N/Enter próxima',
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
