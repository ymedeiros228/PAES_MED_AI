import 'dart:async';

import 'package:flutter/material.dart';
import 'widgets/figura_aviso.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/widgets/media_reinforcement.dart';
import '../../../core/widgets/resolution_debrief.dart';
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
    'conceito': 'Não sabia o conteúdo',
    'interpretacao': 'Li errado',
    'calculo': 'Erro de conta',
    'distracao': 'Marquei outra',
    'tempo': 'Faltou tempo',
  };
  Map<String, dynamic>? adaptive;
  bool adaptiveLoading = false;
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
  }

  @override
  void dispose() {
    super.dispose();
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
    // Haptic feedback: acerto = leve, erro = forte (sensação tátil de feedback)
    if (correct) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ver explicação salvo.')));
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
          SnackBar(content: Text('Cartões criados: ${(data as Map)['created'] ?? data}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para criar cartões.'))),
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
      await apiClient.openPath(path);
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ErrorState(
            title: 'Não deu para abrir a questão',
            message: error!,
            onRetry: () {
              setState(() => error = null);
              unawaited(_load());
            },
            secondary: AppButton.tertiary(label: 'Voltar à lista', onPressed: () => context.go('/questoes')),
          ),
        ),
      );
    }
    final q = question;
    if (q == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: SkeletonList(count: 3, lines: 4),
      );
    }

    final pm = q.professorMode ?? {};
    final freq = pm['frequency'] as Map<String, dynamic>? ?? {};
    final chance = pm['returnChance'] as Map<String, dynamic>? ?? {};
    final wide = MediaQuery.sizeOf(context).width >= 1100;

    final cs = Theme.of(context).colorScheme;
    final questionPane = ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      children: [
        Hero(
          tag: 'question_${q.id}',
          child: Material(
            type: MaterialType.transparency,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                QuestionMetaChips(
                  subject: q.subject,
                  topic: q.topic,
                  year: q.year,
                  extra: q.semGabarito ? 'Sem gabarito' : null,
                ),
                SourceBadge(official: q.examBoard.toUpperCase() == 'UEMA_PAES', year: q.year),
              ],
            ),
          ),
        ),
        if (saveError != null) ...[
          const SizedBox(height: 8),
          QuietEmpty(
            message: saveError!,
            action: TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => saveError = null);
              },
              child: const Text('Ok'),
            ),
          ),
        ],
        if (q.sourcePdf != null && q.sourcePdf!.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                _openSourcePdf();
              },
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
                  'O PDF da prova de ${q.year} ainda não está na pasta Provas deste PC.',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    HapticFeedback.selectionClick();
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
        // StatementView formata o enunciado em parágrafos legíveis
        FiguraAviso(statement: q.statement, sourcePdf: q.sourcePdf, year: q.year),
        QuestionReadingCard(
          subject: q.subject,
          child: StatementView(key: ValueKey('stmt_${q.id}'), text: q.statement, framed: false),
        ),
        const SizedBox(height: 18),
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
          if (q.semGabarito)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Esta questão ainda não tem gabarito no app, então não dá para corrigir. Use só para ler e treinar a interpretação.',
                style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
              ),
            ),
        ] else ...[
          const SizedBox(height: 6),
          AnswerFeedbackBanner(
            key: ValueKey('feedback_${q.id}'),
            correct: selected == q.correctIndex,
            correctIndex: q.correctIndex,
            detail: pendingErrorPick
                ? 'Marque o tipo de erro para ver a explicação.'
                : (wide ? 'A explicação do professor está ao lado.' : 'A explicação do professor está logo abaixo.'),
            child: pendingErrorPick
                ? ErrorTypePicker(
                    options: _errorTypes,
                    value: errorType,
                    onChanged: (t) => setState(() => errorType = t),
                  )
                : null,
          ),
        ],
      ],
    );

    final professorPane = ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Text(
          'Professor',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
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
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.go(
                      '/adaptativo?subject=${Uri.encodeComponent(q.subject)}'
                      '&topic=${Uri.encodeComponent(q.topic)}',
                    );
                  },
                  child: const Text('Treinar este tópico'),
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
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
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _cardsFromQuestion();
                  },
                  child: const Text('Criar cartão'),
                ),
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
            title: Text(
              'Chance de cair de novo (estimativa do app)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            children: [
              SelectableText(
                'Prioridade ${chance['priorityScore'] ?? chance['probability'] ?? '—'}'
                ' · ${chance['confidence'] ?? '—'}\n'
                '${chance['reason'] ?? ''}\n${chance['disclaimer'] ?? ''}',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: cs.onSurface.withOpacity(0.75),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: professorBusy
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        _generateProfessor();
                      },
                child: const Text('Rascunho IA'),
              ),
              FilledButton.tonal(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _cardsFromQuestion();
                },
                child: const Text('Criar cartões'),
              ),
              FilledButton.tonal(
                onPressed: adaptiveLoading
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        _adaptive();
                      },
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
                  Text(
                    'Rascunho',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    professorDraft!['resolution']?.toString() ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      color: cs.onSurface.withOpacity(0.88),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ActionRow(children: [
                    AppButton.primary(
                      onPressed: professorBusy
                          ? null
                          : () {
                              HapticFeedback.mediumImpact();
                              _acceptProfessor();
                            },
                      label: 'Aceitar',
                    ),
                  ]),
                ],
              ),
            ),
          ],
          if (adaptiveLoadError != null) ...[
            const SizedBox(height: 8),
            QuietEmpty(
              message: adaptiveLoadError!,
              action: TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => adaptiveLoadError = null);
                },
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

    final layout = wide
        ? Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: questionPane,
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: professorPane,
                    ),
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: SizedBox(height: 420, child: questionPane),
                  ),
                ),
                const Divider(),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: SizedBox(height: 520, child: professorPane),
                  ),
                ),
              ],
            );

    // Barra inferior fixa: Responder → Ver explicação; depois some.
    final Widget? bar = !revealed
        ? QuestionActionBar(
            maxWidth: 1400,
            hint: q.semGabarito
                ? 'Sem gabarito no app: dá para ler, mas não para corrigir.'
                : selected == null
                    ? 'Escolha uma alternativa (teclas 1–5 ou A–E).'
                    : 'Enter para responder.',
            primary: AppButton.primary(
              onPressed: selected == null || q.semGabarito ? null : _submit,
              icon: Icons.check_rounded,
              label: 'Responder',
            ),
          )
        : pendingErrorPick
            ? QuestionActionBar(
                maxWidth: 1400,
                hint: 'Teclas 1–5 escolhem o tipo de erro · Enter mostra a explicação.',
                primary: AppButton.primary(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _confirmErrorAndSave();
                  },
                  icon: Icons.lightbulb_outline_rounded,
                  label: 'Ver explicação',
                ),
              )
            : null;
    return QuestionKeyHandler(
      optionCount: pendingErrorPick ? _errorTypes.length : q.options.length,
      onSelect: pendingErrorPick
          ? (i) => setState(() => errorType = _errorTypes.keys.elementAt(i))
          : revealed
              ? null
              : (i) => setState(() => selected = i),
      onEnter: !revealed
          ? (selected == null || q.semGabarito ? null : _submit)
          : pendingErrorPick
              ? _confirmErrorAndSave
              : null,
      child: bar == null
          ? layout
          : Column(
              children: [
                Expanded(child: layout),
                bar,
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
