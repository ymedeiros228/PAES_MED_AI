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
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/theory_read_sheet.dart';
import '../../../core/widgets/ui_kit.dart';
import '../domain/question.dart';

class QuestionDetailScreen extends ConsumerStatefulWidget {
  const QuestionDetailScreen({required this.questionId, super.key});

  final String questionId;

  @override
  ConsumerState<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends ConsumerState<QuestionDetailScreen> {
  Question? question;
  String? error;
  int? selected;
  bool revealed = false;
  bool pendingErrorPick = false;
  final stopwatch = Stopwatch();
  String errorType = 'conceito';
  static const _errorTypes = {
    'conceito': 'Conceito',
    'interpretacao': 'Interpretação',
    'calculo': 'Cálculo',
    'distracao': 'Distração',
    'tempo': 'Tempo',
  };
  Map<String, dynamic>? adaptive;
  bool adaptiveLoading = false;
  final focusNode = FocusNode();
  Map<String, dynamic>? professorDraft;
  bool professorBusy = false;
  String? saveError;
  String? adaptiveLoadError;
  bool theoryRead = false;

  @override
  void initState() {
    super.initState();
    stopwatch.start();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => focusNode.requestFocus());
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || question == null) return KeyEventResult.ignored;

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
    final errorKeys = _errorTypes.keys.toList();

    // Miss: 1–5 tipo · Enter grava — não sair enquanto pendente
    if (pendingErrorPick) {
      final ei = digitMap[event.logicalKey];
      if (ei != null && ei < errorKeys.length) {
        setState(() => errorType = errorKeys[ei]);
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
        context.go('/questoes');
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final opt = digitMap[event.logicalKey];
    if (opt != null) {
      setState(() => selected = opt);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (selected != null) unawaited(_submit());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _load() async {
    try {
      final data = await apiClient.get('/api/questions/${widget.questionId}');
      final q = Question.fromJson(Map<String, dynamic>.from(data as Map));
      var read = false;
      if (q.subject.isNotEmpty && q.topic.isNotEmpty) {
        try {
          final rr = await apiClient.get('/api/study/reads', {
            'subject': q.subject,
            'topic': q.topic,
          });
          read = (rr as Map)['read'] == true;
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        question = q;
        theoryRead = read;
      });
    } catch (e) {
      setState(() => error = humanApiError(e, fallback: 'Não deu para abrir a ficha. Tente de novo.'));
    }
  }

  Future<void> _submit() async {
    final q = question;
    if (q == null || selected == null || revealed) return;
    final correct = selected == q.correctIndex;
    stopwatch.stop();
    if (!correct) {
      setState(() {
        revealed = true;
        pendingErrorPick = true;
      });
      return;
    }
    await _persist(correct: true);
  }

  Future<void> _confirmErrorAndSave() async {
    await _persist(correct: false);
  }

  Future<void> _persist({required bool correct}) async {
    final q = question;
    if (q == null || selected == null) return;
    try {
      await apiClient.post('/api/answers', {
        'questionId': q.id,
        'correct': correct,
        'subject': q.subject,
        'topic': q.topic,
        'errorType': correct ? null : errorType,
        'timeMs': stopwatch.elapsedMilliseconds,
      });
      ref.read(refreshTickProvider.notifier).state++;
      setState(() {
        revealed = true;
        pendingErrorPick = false;
        saveError = null;
      });
      if (!correct) {
        try {
          final data = await apiClient.post('/api/training/adaptive', {
            'subject': q.subject,
            'topic': q.topic,
            'nSimilar': 2,
            'nHarder': 0,
            'nGenerated': 0,
          });
          setState(() {
            adaptive = Map<String, dynamic>.from(data as Map);
            adaptiveLoadError = null;
          });
        } catch (e) {
          setState(
            () => adaptiveLoadError = humanApiError(
              e,
              fallback: 'Sugestões adaptativas indisponíveis.',
            ),
          );
        }
      }
    } catch (e) {
      setState(
        () => saveError = humanApiError(e, fallback: 'Resposta não gravada — tente de novo.'),
      );
    }
  }

  Future<void> _generateProfessor() async {
    final q = question;
    if (q == null) return;
    setState(() => professorBusy = true);
    try {
      final data = await apiClient.post('/api/professor/generate', {'questionId': q.id});
      setState(() => professorDraft = Map<String, dynamic>.from(data as Map));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para gerar o rascunho.'))),
        );
      }
    } finally {
      setState(() => professorBusy = false);
    }
  }

  Future<void> _acceptProfessor() async {
    final q = question;
    final d = professorDraft;
    if (q == null || d == null) return;
    setState(() => professorBusy = true);
    try {
      await apiClient.post('/api/professor/accept', {
        'questionId': q.id,
        'resolution': d['resolution'],
        'bancaIntent': d['bancaIntent'],
        'macete': d['macete'],
        'pegadinha': d['pegadinha'],
        'relatedTopics': d['relatedTopics'] ?? [],
      });
      setState(() => professorDraft = null);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Modo professor salvo.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para salvar o professor.'))),
        );
      }
    } finally {
      setState(() => professorBusy = false);
    }
  }

  Future<void> _cardsFromQuestion() async {
    final q = question;
    if (q == null) return;
    try {
      final data = await apiClient.post('/api/flashcards/from-question', {'questionId': q.id, 'count': 5});
      ref.read(refreshTickProvider.notifier).state++;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cards: ${(data as Map)['created'] ?? data}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para criar cards.'))),
        );
      }
    }
  }

  Future<void> _adaptive() async {
    final q = question;
    if (q == null) return;
    setState(() => adaptiveLoading = true);
    try {
      final data = await apiClient.post('/api/training/adaptive', {
        'subject': q.subject,
        'topic': q.topic,
        'nSimilar': 10,
        'nHarder': 20,
        'nGenerated': 0,
      });
      setState(() => adaptive = Map<String, dynamic>.from(data as Map));
    } catch (e) {
      setState(() => adaptive = {
            'error': humanApiError(e, fallback: 'Não deu para montar o treino. Tente de novo.'),
          });
    } finally {
      setState(() => adaptiveLoading = false);
    }
  }

  Future<void> _openSourcePdf() async {
    final q = question;
    if (q == null) return;
    final path = q.sourcePdf;
    if (path == null || path.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sem PDF de ${q.year} na pasta Provas deste PC — não inventamos arquivo.'),
        ),
      );
      return;
    }
    try {
      await apiClient.post('/api/library/open-path', {'path': path});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Abrindo PDF PAES ${q.year}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              humanOpenPathError(e, label: 'PDF PAES ${q.year}'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: EmptyState(
          title: 'Não deu para abrir a ficha',
          subtitle: error!,
          action: Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton(
                onPressed: () {
                  setState(() => error = null);
                  unawaited(_load());
                },
                child: const Text('Tentar'),
              ),
              TextButton(
                onPressed: () => context.go('/questoes'),
                child: const Text('Lista'),
              ),
              TextButton(
                onPressed: () => context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1'),
                child: const Text('Sessão'),
              ),
            ],
          ),
        ),
      );
    }
    final q = question;
    if (q == null) return const Center(child: CircularProgressIndicator());

    final pm = q.professorMode ?? {};
    final freq = pm['frequency'] as Map<String, dynamic>? ?? {};
    final chance = pm['returnChance'] as Map<String, dynamic>? ?? {};
    final wide = MediaQuery.sizeOf(context).width >= 1100;

    final cs = Theme.of(context).colorScheme;
    final questionPane = ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('${q.subject} · ${q.topic} · ${q.year}', style: Theme.of(context).textTheme.titleMedium),
        Text(
          kSoftAtalhosHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.55),
              ),
        ),
        if (saveError != null) ...[
          const SizedBox(height: 8),
          QuietEmpty(
            message: saveError!,
            action: TextButton(
              onPressed: () => setState(() => saveError = null),
              child: const Text('Ok'),
            ),
          ),
        ],
        if (q.sourcePdf != null && q.sourcePdf!.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _openSourcePdf,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: Text('Abrir PDF do ano ${q.year}'),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PDF ${q.year}: ainda não está na pasta Provas do PC (sem inventar).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await apiClient.post('/api/library/open-folder', {'folder': 'provas'});
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Pasta provas aberta — coloque o PDF do ano e reimporte na Biblioteca.'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              humanApiError(e, fallback: 'Não abriu a pasta provas.'),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.folder_open_outlined, size: 18),
                  label: const Text('Onde colocar o PDF'),
                ),
              ],
            ),
          ),
        if (q.generated)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Item gerado — aprove antes de simulado sério.',
              style: TextStyle(color: cs.tertiary),
            ),
          ),
        const SizedBox(height: 12),
        Text(q.statement, style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.35)),
        const SizedBox(height: 16),
        for (var i = 0; i < q.options.length; i++)
          ChoiceOptionTile(
            index: i,
            label: q.options[i],
            selected: selected == i,
            enabled: !revealed,
            revealCorrect: revealed
                ? (i == q.correctIndex
                    ? true
                    : (i == selected ? false : null))
                : null,
            onTap: () => setState(() => selected = i),
          ),
        if (!revealed) ...[
          const SizedBox(height: 12),
          FilledButton(onPressed: selected == null ? null : _submit, child: const Text('Responder')),
        ] else ...[
          Text(
            selected == q.correctIndex
                ? 'Correto!'
                : 'Incorreto. Resposta da banca: ${'ABCDE'[q.correctIndex]}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: selected == q.correctIndex ? Colors.green : Colors.red,
            ),
          ),
          if (pendingErrorPick) ...[
            const SizedBox(height: 8),
            const Text('Por que errou?'),
            Wrap(
              spacing: 6,
              children: [
                for (final e in _errorTypes.entries)
                  ChoiceChip(
                    label: Text(e.value),
                    selected: errorType == e.key,
                    onSelected: (_) => setState(() => errorType = e.key),
                  ),
              ],
            ),
            FilledButton(onPressed: _confirmErrorAndSave, child: const Text('Salvar erro')),
          ],
        ],
      ],
    );

    final professorPane = ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Professor', style: Theme.of(context).textTheme.titleLarge),
        if (!revealed || pendingErrorPick)
          Text(
            pendingErrorPick
                ? 'Marque o tipo de erro para ver a resolução.'
                : 'Responda à esquerda para liberar a resolução.',
          )
        else ...[
          ResolutionDebrief(
            question: {
              'resolution': q.resolution,
              'resolutionQuality': q.resolutionQuality ?? pm['resolutionQuality'],
              'resolutionAxes': q.resolutionAxes ?? pm['resolutionAxes'],
              'studentResolutionLabel': q.studentResolutionLabel ?? pm['studentResolutionLabel'],
              'macete': q.macete,
              'pegadinha': q.pegadinha,
              'bancaIntent': q.bancaIntent,
              'examBoard': q.examBoard,
              'similarityOf': q.similarityOf,
            },
            professor: {
              ...pm,
              'resolution': pm['resolution'] ?? q.resolution,
              'macete': pm['macete'] ?? q.macete,
              'pegadinha': pm['pegadinha'] ?? q.pegadinha,
              'bancaIntent': pm['bancaIntent'] ?? q.bancaIntent,
              'examBoard': pm['examBoard'] ?? q.examBoard,
            },
            trailing: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () async {
                    await openTheoryReadSheet(
                      context,
                      subject: q.subject,
                      topic: q.topic,
                      trainPath: '/adaptativo?subject=${Uri.encodeComponent(q.subject)}'
                          '&topic=${Uri.encodeComponent(q.topic)}',
                    );
                    if (!mounted) return;
                    try {
                      final rr = await apiClient.get('/api/study/reads', {
                        'subject': q.subject,
                        'topic': q.topic,
                      });
                      if (!mounted) return;
                      setState(() => theoryRead = (rr as Map)['read'] == true);
                    } catch (_) {}
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        theoryRead ? Icons.menu_book_rounded : Icons.menu_book_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(theoryRead ? 'Teoria (lida)' : 'Ler teoria'),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(
                    '/adaptativo?subject=${Uri.encodeComponent(q.subject)}'
                    '&topic=${Uri.encodeComponent(q.topic)}',
                  ),
                  child: const Text('Treinar este tópico'),
                ),
                TextButton(
                  onPressed: () {
                    final stmt = q.statement;
                    final seed = stmt.length > 240 ? '${stmt.substring(0, 240)}…' : stmt;
                    final qp = <String, String>{
                      if (q.subject.isNotEmpty) 'subject': q.subject,
                      if (q.topic.isNotEmpty) 'topic': q.topic,
                      if (seed.isNotEmpty) 'q': seed,
                    };
                    final qs = qp.entries
                        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
                        .join('&');
                    context.go(qs.isEmpty ? '/tutor' : '/tutor?$qs');
                  },
                  child: const Text('Perguntar ao tutor'),
                ),
                TextButton(onPressed: _cardsFromQuestion, child: const Text('Criar card')),
              ],
            ),
          ),
          if (revealed && !pendingErrorPick && q.subject.isNotEmpty && q.topic.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: MediaReinforcement(
                subject: q.subject,
                topic: q.topic,
                compact: true,
              ),
            ),
          const SizedBox(height: 8),
          _Block('Relacionados', ((pm['relatedTopics'] as List?) ?? q.relatedTopics).join(', ')),
          _Block('No acervo', 'Anos: ${(freq['years'] as List?)?.join(', ') ?? q.year} · ${freq['count'] ?? 1}x'),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('Prioridade local (não é incidência UEMA)', style: Theme.of(context).textTheme.titleSmall),
            children: [
              Text(
                'Score ${chance['priorityScore'] ?? chance['probability'] ?? '—'}'
                ' · ${chance['confidence'] ?? '—'}\n'
                '${chance['reason'] ?? ''}\n${chance['disclaimer'] ?? ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: professorBusy ? null : _generateProfessor,
                child: const Text('Rascunho IA'),
              ),
              FilledButton.tonal(onPressed: _cardsFromQuestion, child: const Text('Criar cards')),
              FilledButton.tonal(
                onPressed: adaptiveLoading ? null : _adaptive,
                child: const Text('Mais do tópico'),
              ),
            ],
          ),
          if (professorDraft != null) ...[
            const SizedBox(height: 8),
            SurfacePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rascunho', style: Theme.of(context).textTheme.titleSmall),
                  Text(professorDraft!['resolution']?.toString() ?? ''),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: professorBusy ? null : _acceptProfessor, child: const Text('Aceitar')),
                ],
              ),
            ),
          ],
          if (adaptiveLoadError != null) ...[
            const SizedBox(height: 8),
            QuietEmpty(
              message: adaptiveLoadError!,
              action: TextButton(
                onPressed: () => setState(() => adaptiveLoadError = null),
                child: const Text('Ok'),
              ),
            ),
          ],
          if (adaptive != null) ...[
            SectionLabel('Semelhantes'),
            for (final g in ((adaptive!['similar'] as List?) ?? []).take(3))
              PlaylistTile(
                title: '${(g as Map)['topic'] ?? g['id']}',
                leadingIcon: Icons.quiz_outlined,
                onPlay: () {
                  final id = g['id']?.toString();
                  if (id != null) context.go('/questoes/$id');
                },
              ),
          ],
        ],
      ],
    );

    return Focus(
      focusNode: focusNode,
      onKeyEvent: _onKey,
      child: wide
          ? Row(
              children: [
                Expanded(flex: 3, child: questionPane),
                const VerticalDivider(width: 1),
                Expanded(flex: 2, child: professorPane),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SizedBox(height: 420, child: questionPane),
                const Divider(),
                SizedBox(height: 520, child: professorPane),
              ],
            ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block(this.title, this.body);
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(body),
        ],
      ),
    );
  }
}
