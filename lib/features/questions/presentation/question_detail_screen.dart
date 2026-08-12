import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
    'conceito': 'Não sabia o conteúdo',
    'interpretacao': 'Li errado',
    'calculo': 'Erro de conta',
    'distracao': 'Marquei outra',
    'tempo': 'Faltou tempo',
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
        Text(
          '${q.subject} · ${q.topic} · ${q.year}',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          kSoftAtalhosHint,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            color: cs.onSurface.f60,
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
                  'PDF ${q.year}: ainda não está na pasta Provas do PC (sem inventar).',
                  style: GoogleFonts.inter(
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
        StatementView(key: ValueKey('stmt_${q.id}'), text: q.statement),
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
          // Animacao de entrada do feedback (slide + fade) — sensação de revelação
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Container(
                key: ValueKey('feedback_${selected == q.correctIndex}_$pendingErrorPick'),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      selected == q.correctIndex
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 24,
                      color: selected == q.correctIndex ? cs.primary : cs.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selected == q.correctIndex
                            ? 'Correto!'
                            : 'Incorreto. Resposta da banca: ${'ABCDE'[q.correctIndex]}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: selected == q.correctIndex ? cs.primary : cs.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => errorType = e.key);
                    },
                  ),
              ],
            ),
            FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _confirmErrorAndSave();
              },
              child: const Text('Salvar erro'),
            ),
          ],
        ],
      ],
    );

    final professorPane = ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Text(
          'Professor',
          style: GoogleFonts.poppins(
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
              'Prioridade local (não é incidência UEMA)',
              style: GoogleFonts.poppins(
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
                style: GoogleFonts.inter(
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
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    professorDraft!['resolution']?.toString() ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.55,
                      color: cs.onSurface.withOpacity(0.88),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: professorBusy
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            _acceptProfessor();
                          },
                    child: const Text('Aceitar'),
                  ),
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

    return Focus(
      focusNode: focusNode,
      onKeyEvent: _onKey,
      child: wide
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
