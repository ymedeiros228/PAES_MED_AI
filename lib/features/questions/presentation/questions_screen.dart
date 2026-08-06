import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/providers.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/ui_kit.dart';

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
  int page = 0;
  static const pageSize = 40;

  @override
  void initState() {
    super.initState();
    subject = widget.initialSubject;
    topic = widget.initialTopic;
    examBoard = widget.initialExamBoard;
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
    map['limit'] = '$pageSize';
    map['offset'] = '${page * pageSize}';
    return map;
  }

  void _resetPage(VoidCallback fn) {
    setState(() {
      fn();
      page = 0;
    });
  }

  void _clearFilters() {
    setState(() {
      subject = null;
      topic = null;
      difficulty = null;
      year = null;
      source = null;
      examBoard = null;
      similares = false;
      medicine = false;
      page = 0;
    });
  }

  bool get _hasActiveFilters =>
      subject != null ||
      topic != null ||
      difficulty != null ||
      year != null ||
      source != null ||
      examBoard != null ||
      similares ||
      medicine;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(questionsProvider(filters));
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        PageBody(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: 'Banco',
                title: 'Questões',
                subtitle: 'Filtre e abra item a item — ou use a Sessão para o bloco do dia',
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
                      for (var y = 2017; y <= 2026; y++) DropdownMenuEntry(value: '$y', label: '$y'),
                    ],
                  ),
                  FilterChip(
                    label: const Text('Só UEMA'),
                    selected: examBoard == 'UEMA_PAES',
                    onSelected: (v) => _resetPage(() => examBoard = v ? 'UEMA_PAES' : null),
                  ),
                  FilterChip(
                    label: const Text('Medicina'),
                    selected: medicine,
                    onSelected: (v) => _resetPage(() => medicine = v),
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
                        onSelected: (v) => _resetPage(() => similares = v),
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => EmptyState(
              title: 'Não foi possível carregar',
              subtitle: 'Reabra o app e tente de novo.',
              action: FilledButton(
                onPressed: () => ref.read(refreshTickProvider.notifier).state++,
                child: const Text('Tentar de novo'),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                final filterHint = examBoard == 'UEMA_PAES'
                    ? 'Nenhuma oficial UEMA neste recorte — tente “Todos” no ano ou importe na Biblioteca.'
                    : page > 0
                        ? 'Volte uma página ou limpe os filtros.'
                        : 'Importe provas na Biblioteca ou afrouxe os filtros.';
                return EmptyState(
                  title: 'Nada neste filtro',
                  subtitle: filterHint,
                  action: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      if (page > 0)
                        TextButton(
                          onPressed: () => setState(() => page--),
                          child: const Text('Página anterior'),
                        ),
                      if (_hasActiveFilters)
                        OutlinedButton(
                          onPressed: _clearFilters,
                          child: const Text('Limpar filtros'),
                        ),
                      FilledButton(
                        onPressed: () => context.go('/biblioteca'),
                        child: const Text('Biblioteca'),
                      ),
                      FilledButton.tonal(
                        onPressed: () => context.go('/sessao'),
                        child: const Text('Sessão'),
                      ),
                      if (subject != null && subject!.isNotEmpty)
                        OutlinedButton(
                          onPressed: () => context.go(
                            '/adaptativo?subject=${Uri.encodeComponent(subject!)}'
                            '${topic != null && topic!.isNotEmpty ? '&topic=${Uri.encodeComponent(topic!)}' : ''}',
                          ),
                          child: const Text('Treinar tópico'),
                        ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final q = items[i];
                        final badge = _badgeLabel(
                          source: q.source,
                          generated: q.generated,
                          approved: q.approved,
                          examBoard: q.examBoard,
                        );
                        return PlaylistTile(
                          title: '${q.subject} · ${q.topic}',
                          subtitle: '${q.year} · ${q.difficulty} · ${q.statement}',
                          badge: badge,
                          leadingIcon: Icons.quiz_outlined,
                          onPlay: () => context.go('/questoes/${q.id}'),
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
                          onPressed: page == 0 ? null : () => setState(() => page--),
                          child: const Text('Anterior'),
                        ),
                        Text(
                          'Pág. ${page + 1}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: cs.onSurface.withOpacity(0.65),
                              ),
                        ),
                        TextButton(
                          onPressed: items.length < pageSize ? null : () => setState(() => page++),
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
