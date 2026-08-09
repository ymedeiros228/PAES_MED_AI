import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/ui_kit.dart';
import '../domain/question.dart';

class QuestionsScreen extends ConsumerStatefulWidget {
  const QuestionsScreen({
    this.initialSubject,
    this.initialTopic,
    this.initialExamBoard,
    super.key,
  });

  final String? initialSubject;
  final String? initialTopic;
  final String? initialExamBoard;

  @override
  ConsumerState<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends ConsumerState<QuestionsScreen> {
  String? subject;
  String? topic;
  String? difficulty;
  String? year;
  String? source;
  String? examBoard;
  bool similares = false;
  bool medicine = false;
  bool officialWithGab = false;
  int page = 0;
  int selected = 0;
  static const pageSize = 40;

  final _focusNode = FocusNode();
  final _scrollCtrl = ScrollController();
  List<Question> _pageItems = const [];

  @override
  void initState() {
    super.initState();
    subject = widget.initialSubject;
    topic = widget.initialTopic;
    examBoard = widget.initialExamBoard;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Map<String, String> get filters {
    final map = <String, String>{};
    if (subject != null && subject!.isNotEmpty) map['subject'] = subject!;
    if (topic != null && topic!.isNotEmpty) map['topic'] = topic!;
    if (difficulty != null && difficulty!.isNotEmpty) map['difficulty'] = difficulty!;
    if (year != null && year!.isNotEmpty) map['year'] = year!;
    if (source != null && source!.isNotEmpty) map['source'] = source!;
    if (examBoard != null && examBoard!.isNotEmpty) map['examBoard'] = examBoard!;
    if (similares) map['similares'] = 'true';
    if (medicine) map['medicine'] = 'true';
    if (officialWithGab) map['officialWithGab'] = 'true';
    map['limit'] = '$pageSize';
    map['offset'] = '${page * pageSize}';
    return map;
  }

  void _resetPage(VoidCallback fn) {
    setState(() {
      fn();
      page = 0;
      selected = 0;
    });
  }

  void _openSelected() {
    if (_pageItems.isEmpty) return;
    final idx = selected.clamp(0, _pageItems.length - 1);
    context.go('/questoes/${_pageItems[idx].id}');
  }

  void _scrollToSelected() {
    if (!_scrollCtrl.hasClients || _pageItems.isEmpty) return;
    const rowH = 76.0;
    final target = (selected * rowH).clamp(0.0, _scrollCtrl.position.maxScrollExtent);
    _scrollCtrl.animateTo(target, duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
  }

  void _moveSelection(int delta) {
    if (_pageItems.isEmpty) return;
    setState(() => selected = (selected + delta).clamp(0, _pageItems.length - 1));
    _scrollToSelected();
  }

  void _prevPage() {
    if (page == 0) return;
    setState(() {
      page--;
      selected = 0;
    });
  }

  void _nextPage() {
    if (_pageItems.length < pageSize) return;
    setState(() {
      page++;
      selected = 0;
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyJ) {
      _moveSelection(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyK) {
      _moveSelection(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      _openSelected();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.bracketRight || key == LogicalKeyboardKey.keyN) {
      _nextPage();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.bracketLeft || key == LogicalKeyboardKey.keyP) {
      _prevPage();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyR || key == LogicalKeyboardKey.f5) {
      ref.read(refreshTickProvider.notifier).state++;
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyS) {
      context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1');
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(questionsProvider(filtersKey(filters)));
    final cs = Theme.of(context).colorScheme;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      child: Column(
        children: [
          PageBody(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  eyebrow: 'Banco',
                  title: 'Questões',
                  subtitle: 'Filtre e abra o que quiser treinar com calma',
                  trailing: FilledButton.tonal(
                    onPressed: () => context.go('/sessao'),
                    child: const Text('Sessão'),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DropdownMenu<String>(
                      label: const Text('Disciplina'),
                      width: 200,
                      initialSelection: subject ?? '',
                      onSelected: (v) => _resetPage(() => subject = (v == null || v.isEmpty) ? null : v),
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(value: '', label: 'Todas'),
                        DropdownMenuEntry(value: 'Biologia', label: 'Biologia'),
                        DropdownMenuEntry(value: 'Matemática', label: 'Matemática'),
                        DropdownMenuEntry(value: 'Química', label: 'Química'),
                        DropdownMenuEntry(value: 'Física', label: 'Física'),
                        DropdownMenuEntry(value: 'Língua Portuguesa e Literatura', label: 'Português'),
                        DropdownMenuEntry(value: 'História', label: 'História'),
                        DropdownMenuEntry(value: 'Geografia', label: 'Geografia'),
                      ],
                    ),
                    DropdownMenu<String>(
                      label: const Text('Ano'),
                      width: 110,
                      initialSelection: year ?? '',
                      onSelected: (v) => _resetPage(() => year = (v == null || v.isEmpty) ? null : v),
                      dropdownMenuEntries: [
                        const DropdownMenuEntry(value: '', label: 'Todos'),
                        for (var y = 2014; y <= 2026; y++) DropdownMenuEntry(value: '$y', label: '$y'),
                      ],
                    ),
                    FilterChip(
                      label: const Text('Só UEMA'),
                      selected: examBoard == 'UEMA_PAES' && !officialWithGab,
                      onSelected: (v) {
                        HapticFeedback.selectionClick();
                        _resetPage(() {
                          officialWithGab = false;
                          examBoard = v ? 'UEMA_PAES' : null;
                          source = null;
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Oficiais com gabarito'),
                      selected: officialWithGab,
                      onSelected: (v) {
                        HapticFeedback.selectionClick();
                        _resetPage(() {
                          officialWithGab = v;
                          if (v) {
                            examBoard = 'UEMA_PAES';
                            source = 'oficial';
                          } else {
                            source = null;
                          }
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Medicina'),
                      selected: medicine,
                      onSelected: (v) {
                        HapticFeedback.selectionClick();
                        _resetPage(() => medicine = v);
                      },
                    ),
                  ],
                ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('Mais filtros', style: Theme.of(context).textTheme.titleSmall),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        DropdownMenu<String>(
                          label: const Text('Origem'),
                          width: 140,
                          onSelected: (v) => _resetPage(() => source = (v == null || v.isEmpty) ? null : v),
                          dropdownMenuEntries: const [
                            DropdownMenuEntry(value: '', label: 'Todas'),
                            DropdownMenuEntry(value: 'oficial', label: 'Oficial'),
                            DropdownMenuEntry(value: 'treino', label: 'Treino'),
                            DropdownMenuEntry(value: 'gerada', label: 'Gerada'),
                          ],
                        ),
                        DropdownMenu<String>(
                          label: const Text('Dificuldade'),
                          width: 140,
                          onSelected: (v) => _resetPage(() => difficulty = (v == null || v.isEmpty) ? null : v),
                          dropdownMenuEntries: const [
                            DropdownMenuEntry(value: '', label: 'Todas'),
                            DropdownMenuEntry(value: 'Fácil', label: 'Fácil'),
                            DropdownMenuEntry(value: 'Média', label: 'Média'),
                            DropdownMenuEntry(value: 'Difícil', label: 'Difícil'),
                          ],
                        ),
                        DropdownMenu<String>(
                          label: const Text('Banca'),
                          width: 160,
                          onSelected: (v) => _resetPage(() => examBoard = (v == null || v.isEmpty) ? null : v),
                          dropdownMenuEntries: const [
                            DropdownMenuEntry(value: '', label: 'Todas'),
                            DropdownMenuEntry(value: 'UEMA_PAES', label: 'Só UEMA'),
                            DropdownMenuEntry(value: 'TREINO', label: 'Treino'),
                            DropdownMenuEntry(value: 'OUTRA', label: 'Outra'),
                          ],
                        ),
                        FilterChip(
                          label: const Text('Similares'),
                          selected: similares,
                          onSelected: (v) {
                            HapticFeedback.selectionClick();
                            _resetPage(() => similares = v);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SoftLoader(compact: true),
                    const SizedBox(height: 16),
                    Text(
                      'Carregando questões do acervo local…',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.f72,
                          ),
                    ),
                  ],
                ),
              ),
              error: (e, _) => EmptyState(
                title: 'Não foi possível carregar',
                subtitle: humanApiError(e, fallback: 'Reabra o app e tente de novo.'),
                action: Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () => ref.read(refreshTickProvider.notifier).state++,
                      child: const Text('Tentar de novo'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/biblioteca'),
                      child: const Text('Biblioteca'),
                    ),
                  ],
                ),
              ),
              data: (items) {
                _pageItems = items;
                if (selected >= items.length && items.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => selected = items.length - 1);
                  });
                }
                if (items.isEmpty) {
                  return EmptyState(
                    title: 'Nenhuma questão aqui',
                    subtitle: page > 0
                        ? 'Volte uma página ou limpe os filtros.'
                        : officialWithGab
                            ? 'Sem oficiais com gabarito neste filtro. Importe pares com gabarito na Biblioteca ou desative o chip.'
                            : 'Importe provas na Biblioteca ou afrouxe os filtros.',
                    action: Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        if (page > 0)
                          TextButton(onPressed: _prevPage, child: const Text('Página anterior')),
                        if (subject != null ||
                            topic != null ||
                            examBoard != null ||
                            officialWithGab ||
                            source != null)
                          FilledButton.tonal(
                            onPressed: () => _resetPage(() {
                              subject = null;
                              topic = null;
                              examBoard = null;
                              source = null;
                              officialWithGab = false;
                              difficulty = null;
                              year = null;
                            }),
                            child: const Text('Limpar filtros'),
                          ),
                        FilledButton(
                          onPressed: () => context.go('/biblioteca'),
                          child: const Text('Biblioteca'),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: RepaintBoundary(
                        child: ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
                          cacheExtent: 500, // pré-renderiza além da viewport — scroll smoother
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                          final q = items[i];
                          final badge = _badgeLabel(
                            source: q.source,
                            generated: q.generated,
                            approved: q.approved,
                            examBoard: q.examBoard,
                          );
                          final subjStyle = subjectStyle(q.subject);
                          return PlaylistTile(
                            title: '${q.subject} · ${q.topic}',
                            subtitle: () {
                              final st = q.statement;
                              final short = st.length > 90 ? '${st.substring(0, 90)}…' : st;
                              return '${q.year} · ${q.difficulty} · $short';
                            }(),
                            badge: badge,
                            badgeColor: subjStyle.color.f22,
                            leadingIcon: subjStyle.icon,
                            active: i == selected,
                            onPlay: () {
                              setState(() => selected = i);
                              context.go('/questoes/${q.id}');
                            },
                          );
                        },
                      ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: page == 0 ? null : _prevPage,
                            child: const Text('Anterior'),
                          ),
                          Text(
                            'Página ${page + 1} · ${selected + 1} de ${items.length}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurface.f72,
                                ),
                          ),
                          TextButton(
                            onPressed: items.length < pageSize ? null : _nextPage,
                            child: const Text('Próxima'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _badgeLabel({
    required String? source,
    required bool generated,
    required bool approved,
    required String? examBoard,
  }) {
    final board = (examBoard ?? '').toUpperCase();
    if (board == 'UEMA_PAES') return 'UEMA';
    if (board == 'OUTRA') return 'outra';
    if (generated) return approved ? 'gerada' : 'pendente';
    final src = (source ?? '').toLowerCase();
    if (src.contains('pdf') || src.contains('oficial') || src.contains('ingest')) return 'oficial';
    return 'treino';
  }
}
