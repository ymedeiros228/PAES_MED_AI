import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/media_reinforcement.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/study_path_trail.dart';
import '../../../core/widgets/theory_read_sheet.dart';
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
  List<Question>? _lastGood;

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

  /// Chave estável para o family provider (não Map por rebuild).
  String get filterQuery => encodeQuestionFilters(filters);

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
    const rowH = 88.0;
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
      // R atualiza · S sessão
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
    final async = ref.watch(questionsProvider(filterQuery));
    final pathAsync = ref.watch(studyPathProvider);
    final cs = Theme.of(context).colorScheme;
    final bright = Theme.of(context).brightness;

    // Mantém última lista boa só no callback data (evita setState no build).
    final isLoading = async.isLoading;
    final hasSnapshot = async.hasValue || (_lastGood != null && _lastGood!.isNotEmpty);

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient(bright),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 18, 28, 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: kPageMaxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BANCO LOCAL',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white.withOpacity(0.72),
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              'Questões',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                            ),
                          ),
                          FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.16),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => context.go('/sessao'),
                            child: const Text('Sessão'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Filtre e abra o que quiser treinar com calma · vídeos na ficha',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.82),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Material(
            color: cs.surface.withOpacity(0.92),
            elevation: 0,
            child: PageBody(
              padding: const EdgeInsets.fromLTRB(28, 14, 28, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  pathAsync.when(
                    skipLoadingOnReload: true,
                    skipLoadingOnRefresh: true,
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (path) {
                      if (path.isEmpty || path['nodes'] is! List) {
                        return const SizedBox.shrink();
                      }
                      return StudyPathTrail(path: path, compact: true);
                    },
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _SubjectChip(
                        label: 'Todas',
                        selected: subject == null,
                        onTap: () => _resetPage(() => subject = null),
                      ),
                      for (final s in const [
                        'Biologia',
                        'Matemática',
                        'Química',
                        'Física',
                        'Língua Portuguesa e Literatura',
                        'História',
                        'Geografia',
                      ])
                        _SubjectChip(
                          label: s == 'Língua Portuguesa e Literatura' ? 'Português' : s,
                          selected: subject == s,
                          onTap: () => _resetPage(() => subject = s),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        child: DropdownMenu<String>(
                          key: ValueKey('year_${year ?? "all"}'),
                          label: const Text('Ano'),
                          width: 120,
                          initialSelection: year ?? '',
                          onSelected: (v) =>
                              _resetPage(() => year = (v == null || v.isEmpty) ? null : v),
                          dropdownMenuEntries: [
                            const DropdownMenuEntry(value: '', label: 'Todos'),
                            for (var y = 2014; y <= 2026; y++)
                              DropdownMenuEntry(value: '$y', label: '$y'),
                          ],
                        ),
                      ),
                      FilterChip(
                        label: const Text('Só UEMA'),
                        selected: examBoard == 'UEMA_PAES' && !officialWithGab,
                        onSelected: (v) => _resetPage(() {
                          officialWithGab = false;
                          examBoard = v ? 'UEMA_PAES' : null;
                          source = null;
                        }),
                      ),
                      FilterChip(
                        label: const Text('Oficiais com gabarito'),
                        selected: officialWithGab,
                        onSelected: (v) => _resetPage(() {
                          officialWithGab = v;
                          if (v) {
                            examBoard = 'UEMA_PAES';
                            source = 'oficial';
                          } else {
                            source = null;
                          }
                        }),
                      ),
                      FilterChip(
                        label: const Text('Medicina'),
                        selected: medicine,
                        onSelected: (v) => _resetPage(() => medicine = v),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Recarregar (R)',
                        onPressed: () => ref.read(refreshTickProvider.notifier).state++,
                        icon: const Icon(Icons.refresh_rounded, size: 20),
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
                            key: ValueKey('src_${source ?? "all"}'),
                            label: const Text('Origem'),
                            width: 140,
                            initialSelection: source ?? '',
                            onSelected: (v) =>
                                _resetPage(() => source = (v == null || v.isEmpty) ? null : v),
                            dropdownMenuEntries: const [
                              DropdownMenuEntry(value: '', label: 'Todas'),
                              DropdownMenuEntry(value: 'oficial', label: 'Oficial'),
                              DropdownMenuEntry(value: 'treino', label: 'Treino'),
                              DropdownMenuEntry(value: 'gerada', label: 'Gerada'),
                            ],
                          ),
                          DropdownMenu<String>(
                            key: ValueKey('diff_${difficulty ?? "all"}'),
                            label: const Text('Dificuldade'),
                            width: 140,
                            initialSelection: difficulty ?? '',
                            onSelected: (v) => _resetPage(
                              () => difficulty = (v == null || v.isEmpty) ? null : v,
                            ),
                            dropdownMenuEntries: const [
                              DropdownMenuEntry(value: '', label: 'Todas'),
                              DropdownMenuEntry(value: 'Fácil', label: 'Fácil'),
                              DropdownMenuEntry(value: 'Média', label: 'Média'),
                              DropdownMenuEntry(value: 'Difícil', label: 'Difícil'),
                            ],
                          ),
                          DropdownMenu<String>(
                            key: ValueKey('board_${examBoard ?? "all"}'),
                            label: const Text('Banca'),
                            width: 160,
                            initialSelection: examBoard ?? '',
                            onSelected: (v) => _resetPage(
                              () => examBoard = (v == null || v.isEmpty) ? null : v,
                            ),
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
                            onSelected: (v) => _resetPage(() => similares = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                  if (subject != null && subject!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    if (topic != null && topic!.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: FilledButton.tonalIcon(
                            onPressed: () => openTheoryReadSheet(
                              context,
                              subject: subject!,
                              topic: topic!,
                            ),
                            icon: const Icon(Icons.menu_book_outlined, size: 18),
                            label: const Text('Ler teoria'),
                          ),
                        ),
                      ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        'Materiais e vídeos · $subject',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      subtitle: Text(
                        topic != null && topic!.isNotEmpty
                            ? 'Tópico filtrado: $topic'
                            : 'Escolha banca / YouTube / leituras (não é gabarito UEMA)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      children: [
                        MediaReinforcement(
                          subject: subject!,
                          topic: (topic != null && topic!.isNotEmpty) ? topic! : subject!,
                          compact: true,
                          heading: 'Estudo deste filtro',
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isLoading && hasSnapshot)
            LinearProgressIndicator(
              minHeight: 2,
              color: cs.primary,
              backgroundColor: cs.primaryContainer.withOpacity(0.4),
            ),
          Expanded(
            child: async.when(
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
              loading: () {
                final cached = _lastGood;
                if (cached != null && cached.isNotEmpty) {
                  return _buildList(context, cached, cs, dimmed: true);
                }
                return SoftLoader(
                  label: 'Carregando questões do acervo local…',
                  onRetry: () => ref.read(refreshTickProvider.notifier).state++,
                );
              },
              error: (e, _) {
                final cached = _lastGood;
                if (cached != null && cached.isNotEmpty) {
                  return Column(
                    children: [
                      Material(
                        color: cs.errorContainer,
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.wifi_off_rounded, color: cs.error, size: 20),
                          title: Text(
                            humanApiError(e, fallback: 'Falha ao atualizar a lista.'),
                            style: TextStyle(color: cs.onErrorContainer, fontSize: 13),
                          ),
                          trailing: TextButton(
                            onPressed: () => ref.read(refreshTickProvider.notifier).state++,
                            child: const Text('Tentar'),
                          ),
                        ),
                      ),
                      Expanded(child: _buildList(context, cached, cs)),
                    ],
                  );
                }
                return EmptyState(
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
                );
              },
              data: (items) {
                _pageItems = items;
                _lastGood = items;
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
                return _buildList(context, items, cs);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<Question> items,
    ColorScheme cs, {
    bool dimmed = false,
  }) {
    return Opacity(
      opacity: dimmed ? 0.72 : 1,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 12),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final q = items[i];
                final badge = _badgeLabel(
                  source: q.source,
                  generated: q.generated,
                  approved: q.approved,
                  examBoard: q.examBoard,
                );
                final active = i == selected;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: active
                        ? cs.primaryContainer.withOpacity(0.55)
                        : cs.surfaceContainerHighest.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() => selected = i);
                        context.go('/questoes/${q.id}');
                      },
                      // active: i == selected (teclado J/K)
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: active ? cs.primary : cs.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.quiz_outlined,
                                color: active ? cs.onPrimary : cs.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${q.subject} · ${q.topic}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    () {
                                      final st = q.statement.replaceAll('\n', ' ').trim();
                                      final short =
                                          st.length > 100 ? '${st.substring(0, 100)}…' : st;
                                      return '${q.year} · ${q.difficulty} · $short';
                                    }(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: cs.onSurface.withOpacity(0.62),
                                          height: 1.25,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: cs.outlineVariant.withOpacity(0.7)),
                              ),
                              child: Text(
                                badge,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: cs.primary,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right_rounded, color: cs.onSurface.withOpacity(0.35)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
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
                        color: cs.onSurface.withOpacity(0.65),
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

class _SubjectChip extends StatelessWidget {
  const _SubjectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: cs.primaryContainer,
      checkmarkColor: cs.primary,
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
        fontSize: 12.5,
      ),
    );
  }
}
