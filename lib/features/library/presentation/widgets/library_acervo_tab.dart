import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';
import 'library_helpers.dart';

/// Callbacks do tab Acervo — mantém ações no [LibraryScreen].
class LibraryAcervoActions {
  const LibraryAcervoActions({
    required this.onRefresh,
    required this.onDismissFirstRunCoach,
    required this.onSemana1,
    required this.onRunSearch,
    required this.onSearchChanged,
    required this.onSearchSourceKindChanged,
    required this.onApplySearchHistory,
    required this.onHitSelected,
    required this.onOpenSearchHit,
    required this.onGoStudy,
    required this.onImportYear,
    required this.onImportYearSafe,
    required this.onBootstrapYear,
    required this.onFetchYear,
    required this.onImportAllComplete,
    required this.onOpenFolder,
    required this.onSyncEdital,
    required this.onClassify,
    required this.onFixQuestions,
  });

  final VoidCallback onRefresh;
  final VoidCallback onDismissFirstRunCoach;
  final VoidCallback onSemana1;
  final VoidCallback onRunSearch;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSourceKindChanged;
  final void Function(String query, String? sourceKind) onApplySearchHistory;
  final ValueChanged<int> onHitSelected;
  final ValueChanged<Map<String, dynamic>> onOpenSearchHit;
  final void Function(String path) onGoStudy;
  final ValueChanged<int> onImportYear;
  final ValueChanged<int> onImportYearSafe;
  final ValueChanged<int> onBootstrapYear;
  final ValueChanged<int> onFetchYear;
  final VoidCallback onImportAllComplete;
  final ValueChanged<String> onOpenFolder;
  final VoidCallback onSyncEdital;
  final VoidCallback onClassify;
  final VoidCallback onFixQuestions;
}

class LibraryAcervoTab extends StatelessWidget {
  const LibraryAcervoTab({
    required this.searchController,
    required this.actions,
    required this.busy,
    required this.msg,
    required this.showFirstRunCoach,
    required this.officialN,
    required this.partialLoadNote,
    required this.error,
    required this.searching,
    required this.searchHits,
    required this.searchNote,
    required this.searchHistory,
    required this.searchHistoryNote,
    required this.searchSourceKind,
    required this.hitSelected,
    required this.board,
    required this.hist,
    required this.pendingItems,
    required this.pendingN,
    required this.anosParciais,
    required this.curation,
    required this.coverage,
    required this.showLocalDataHint,
    required this.semana1PanelKey,
    super.key,
  });

  final TextEditingController searchController;
  final LibraryAcervoActions actions;
  final bool busy;
  final String? msg;
  final bool showFirstRunCoach;
  final int officialN;
  final String? partialLoadNote;
  final String? error;
  final bool searching;
  final List<Map<String, dynamic>> searchHits;
  final String? searchNote;
  final List<Map<String, dynamic>> searchHistory;
  final String? searchHistoryNote;
  final String searchSourceKind;
  final int hitSelected;
  final List<dynamic> board;
  final List<dynamic> hist;
  final List<dynamic> pendingItems;
  final int pendingN;
  final int anosParciais;
  final Map<String, dynamic>? curation;
  final Map<String, dynamic>? coverage;
  final bool showLocalDataHint;
  final GlobalKey semana1PanelKey;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
    padding: const EdgeInsets.only(bottom: 24),
    children: [
      PageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              eyebrow: 'Materiais',
              title: 'Biblioteca',
              subtitle: officialN > 0
                  ? '$officialN questões oficiais disponíveis'
                  : 'Importe as provas oficiais e comece a estudar',
              trailing: IconButton(
                tooltip: 'Atualizar',
                onPressed: busy ? null : () { HapticFeedback.selectionClick(); actions.onRefresh(); },
                icon: busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded),
              ),
            ),

            if (busy)
              SurfacePanel(
                margin: const EdgeInsets.only(bottom: 12),
                color: cs.secondaryContainer.f45,
                child: Row(
                  children: [
                    const SoftLoader(compact: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        msg ?? 'Trabalhando no acervo… pode demorar um pouco.',
                        style: TextStyle(fontSize: 14, height: 1.5, color: cs.onSurface.withOpacity(0.85)),
                      ),
                    ),
                  ],
                ),
              ),

            if (showFirstRunCoach && officialN == 0) ...[
              SurfacePanel(
                key: semana1PanelKey,
                margin: const EdgeInsets.only(bottom: 12),
                color: cs.primaryContainer.f55,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bem-vindo — Semana 1', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                    const SizedBox(height: 8),
                    Text(
                      'Toque em Atualizar 2024–26 abaixo para importar provas UEMA. '
                      'Sem PDFs no PC? Use Abrir provas e coloque paes_YYYY.pdf na pasta.',
                      style: TextStyle(fontSize: 14, height: 1.5, color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.9)),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: busy ? null : () { HapticFeedback.mediumImpact(); actions.onSemana1(); },
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Atualizar 2024–26'),
                        ),
                        TextButton(onPressed: () { HapticFeedback.selectionClick(); actions.onDismissFirstRunCoach(); }, child: const Text('Depois')),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            if (partialLoadNote != null && error == null) ...[
              QuietEmpty(
                message: partialLoadNote!,
                action: TextButton(
                  onPressed: busy ? null : () { HapticFeedback.selectionClick(); actions.onRefresh(); },
                  child: const Text('Tentar'),
                ),
              ),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 8),
            TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Buscar no acervo',
                hintText: 'ex.: genética, osmose…',
                suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  onPressed: searching ? null : () { HapticFeedback.selectionClick(); actions.onRunSearch(); },
                  icon: searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search_rounded),
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => actions.onRunSearch(),
              onChanged: actions.onSearchChanged,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final kind in const [
                  ('todos', 'Todos'),
                  ('oficial', 'Oficial'),
                  ('estudo', 'Estudo'),
                ])
                  ChoiceChip(
                    label: Text(kind.$2),
                    selected: searchSourceKind == kind.$1,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                        actions.onSearchSourceKindChanged(kind.$1);
                      if (searchController.text.trim().isNotEmpty) actions.onRunSearch();
                    },
                  ),
              ],
            ),
            if (searchHistoryNote != null) ...[
              const SizedBox(height: 8),
              Text(
                searchHistoryNote!,
                style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (searchHistory.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final h in searchHistory.take(8))
                    ActionChip(
                      label: Text(
                        h['q']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        final q = h['q']?.toString() ?? '';
                        if (q.isEmpty) return;
                        actions.onApplySearchHistory(q, h['sourceKind']?.toString());
                      },
                    ),
                ],
              ),
            ],
            if (searchNote != null && searchHits.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: QuietEmpty(
                  message: searchNote!,
                  action: TextButton(
                    onPressed: searching ? null : () { HapticFeedback.selectionClick(); actions.onRunSearch(); },
                    child: const Text('Tentar'),
                  ),
                ),
              ),
            if (searchHits.isNotEmpty) ...[
              SectionLabel('Resultados', hint: '${searchHits.length} resultado(s) · toque para abrir'),
              for (var i = 0; i < searchHits.take(12).length; i++)
                Builder(
                  builder: (_) {
                    final hit = searchHits[i];
                    return PlaylistTile(
                      title: hit['label']?.toString() ?? 'arquivo',
                      subtitle:
                          '${hit['sourceKind'] ?? hit['kind'] ?? ''}${hit['year'] != null ? ' · ${hit['year']}' : ''}',
                      badge: hit['sourceKind']?.toString() == 'oficial' ? 'oficial' : 'local',
                      active: i == hitSelected,
                      leadingIcon: hit['kind'] == 'question'
                          ? Icons.quiz_outlined
                          : Icons.description_outlined,
                      onPlay: () {
                        HapticFeedback.selectionClick();
                        actions.onHitSelected(i);
                        actions.onOpenSearchHit(hit);
                      },
                    );
                  },
                ),
            ],

            // Painel de boas-vindas só aparece quando não há oficiais
            SectionLabel('Provas recentes', hint: '2024–26'),
            if (board.isEmpty)
              QuietEmpty(
                message: 'Nenhuma prova 2024–26 ainda. Toque para importar.',
                action: Wrap(
                  spacing: 8,
                  children: [
                    FilledButton(
                      onPressed: busy ? null : () { HapticFeedback.mediumImpact(); actions.onSemana1(); },
                      child: const Text('Importar provas'),
                    ),
                    TextButton(
                      onPressed: () { HapticFeedback.selectionClick(); context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1'); },
                      child: const Text('Ir para Sessão'),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: board.length,
                itemBuilder: (context, i) {
                  final g = board[i];
                  final y = g['year'] as int? ?? 0;
                  final status = g['uiStatus']?.toString() ?? 'empty';
                  final n = g['committedCount'] as int? ?? 0;
                  final canFetch = g['canFetch'] == true;
                  final onDisk = Map<String, dynamic>.from(g['onDisk'] as Map? ?? {});
                  final hasProva = onDisk['hasProva'] == true;
                  final hasGab = onDisk['hasGabarito'] == true;
                  final diskOk = hasProva && hasGab;
                  final partial = hasProva && !hasGab;
                  final ready = status == 'committed' || n > 0;
                  final label = g['labelHint']?.toString() ?? libraryUiStatusLabel(status);
                  final cardColor = ready
                      ? cs.primaryContainer
                      : partial
                          ? cs.tertiaryContainer
                          : cs.surfaceContainerHigh;
                  final iconColor = ready ? cs.primary : partial ? cs.tertiary : cs.onSurfaceVariant;
                  final statusIcon = ready ? Icons.check_circle_rounded : partial ? Icons.warning_amber_rounded : Icons.hourglass_empty_rounded;
                  return TapScale(
                    child: Material(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: busy ? null : () {
                          HapticFeedback.selectionClick();
                          if (ready) {
                            actions.onGoStudy('/sessao?examBoard=UEMA_PAES&year=$y&preferNatureza=1');
                          } else if (partial) {
                            actions.onImportYear(y);
                          } else if (canFetch || diskOk) {
                            diskOk ? actions.onImportYearSafe(y) : actions.onBootstrapYear(y);
                          } else {
                            actions.onFetchYear(y);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$y',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: iconColor,
                                    ),
                                  ),
                                  Icon(statusIcon, color: iconColor, size: 22),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ready ? '$n questões' : label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: ready ? cs.onPrimaryContainer : cs.onSurface.withOpacity(0.85),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    ready ? 'Pronto para estudar' : partial ? 'Falta gabarito' : canFetch ? 'Toque para importar' : 'Sem PDF',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ready ? cs.onPrimaryContainer.withOpacity(0.85) : cs.onSurface.withOpacity(0.6),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Ação principal — apenas uma, clara
            const SizedBox(height: 16),
            if (officialN > 0)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1&officialWithGab=1');
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Estudar agora'),
                ),
              )
            else if (!showFirstRunCoach)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : () { HapticFeedback.mediumImpact(); actions.onImportAllComplete(); },
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: const Text('Importar provas'),
                ),
              ),
            if (anosParciais > 0) ...[
              const SizedBox(height: 8),
              Text(
                '$anosParciais ano(s) com prova mas sem gabarito. Coloque o gabarito na pasta para importar.',
                style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
              ),
            ],

            if (pendingN > 0) ...[
              SectionLabel('Precisa da sua revisão', hint: '$pendingN arquivo(s)'),
              for (final raw in pendingItems.take(4))
                Builder(
                  builder: (_) {
                    final it = Map<String, dynamic>.from(raw as Map);
                    final y = it['year'];
                    return PlaylistTile(
                      title: it['filename']?.toString() ?? 'Preview',
                      subtitle: '${it['count'] ?? 0} questões',
                      badge: 'revisar',
                      leadingIcon: Icons.preview_rounded,
                      onPlay: y is int ? () { HapticFeedback.selectionClick(); actions.onImportYear(y); } : null,
                    );
                  },
                ),
            ],

            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Provas antigas (2014–23)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
              subtitle: Text(
                anosParciais > 0
                    ? '$anosParciais sem gabarito — coloque o arquivo na pasta'
                    : 'Importe se tiver os PDFs no computador',
              ),
              children: [
                if (hist.isEmpty)
                  QuietEmpty(
                    message:
                        'Nenhuma prova 2014–23 no computador. Coloque os PDFs nas pastas Provas e Gabaritos para importar.',
                    action: TextButton(
                      onPressed: busy ? null : () { HapticFeedback.selectionClick(); actions.onImportAllComplete(); },
                      child: const Text('Importar todos com gabarito'),
                    ),
                  )
                else
                  for (final g in hist)
                    Builder(
                      builder: (_) {
                        final y = g['year'] as int? ?? 0;
                        final status = g['uiStatus']?.toString() ?? 'empty';
                        final n = g['committedCount'] as int? ?? 0;
                        final onDisk = Map<String, dynamic>.from(g['onDisk'] as Map? ?? {});
                        final hasProva = onDisk['hasProva'] == true;
                        final hasGab = onDisk['hasGabarito'] == true;
                        final diskOk = hasProva && hasGab;
                        final partial = hasProva && !hasGab || status == 'partial';
                        final ready = status == 'committed' || n > 0;
                        final label = g['labelHint']?.toString() ??
                            (!diskOk && !ready && !partial
                                ? 'Falta o PDF deste ano'
                                : libraryUiStatusLabel(status));
                        return PlaylistTile(
                          title: 'PAES $y',
                          subtitle: partial
                              ? 'Sem gabarito — coloque o arquivo'
                              : ready
                                  ? 'Pronto ($n questões)'
                                  : label,
                          badge: libraryUiBadge(
                            status,
                            ready: ready,
                            diskOk: diskOk,
                            hasProva: hasProva,
                            hasGab: hasGab,
                          ),
                          onPlay: ready
                              ? () { HapticFeedback.mediumImpact(); actions.onGoStudy(
                                    '/sessao?examBoard=UEMA_PAES&year=$y&preferNatureza=1',
                                  ); }
                              : partial
                                  ? () { HapticFeedback.selectionClick(); actions.onImportYear(y); }
                                  : diskOk
                                      ? () { HapticFeedback.selectionClick(); actions.onImportYearSafe(y); }
                                      : null,
                          secondary: partial
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: busy ? null : () { HapticFeedback.selectionClick(); actions.onOpenFolder('gabaritos'); },
                                      child: const Text('Gabaritos'),
                                    ),
                                    TextButton(
                                      onPressed: busy ? null : () { HapticFeedback.selectionClick(); actions.onImportYear(y); },
                                      child: const Text('Preview'),
                                    ),
                                  ],
                                )
                              : !ready && diskOk
                                  ? TextButton(
                                      onPressed: busy ? null : () { HapticFeedback.selectionClick(); actions.onImportYearSafe(y); },
                                      child: const Text('Importar do PC'),
                                    )
                                  : null,
                        );
                      },
                    ),
              ],
            ),

            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              initiallyExpanded: false,
              title: Text('Opções avançadas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
              subtitle: const Text('Estatísticas, pastas, download e edital'),
              children: [
                if (curation != null) ...[
                  Text(
                    'Questões oficiais: ${curation!['officialCount'] ?? '—'}\n'
                    'Com gabarito validado: ${curation!['realCount'] ?? 0}'
                    '${curation!['realPercent'] != null ? ' (${curation!['realPercent']}%)' : ''}\n'
                    'Questões que misturam matérias: ${curation!['crossDomainCount'] ?? 0}',
                    style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
                  ),
                  if (curation!['message'] != null)
                    Text(
                      curation!['message'].toString(),
                      style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
                    ),
                  const SizedBox(height: 8),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () { HapticFeedback.selectionClick(); actions.onOpenFolder('provas'); },
                      icon: const Icon(Icons.folder_open_rounded, size: 18),
                      label: const Text('Provas'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () { HapticFeedback.selectionClick(); actions.onOpenFolder('gabaritos'); },
                      icon: const Icon(Icons.folder_open_rounded, size: 18),
                      label: const Text('Gabaritos'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () { HapticFeedback.selectionClick(); actions.onOpenFolder('edital'); },
                      icon: const Icon(Icons.folder_open_rounded, size: 18),
                      label: const Text('Edital'),
                    ),
                  ],
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Atualizar conteúdos da prova'),
                  trailing: OutlinedButton(onPressed: busy ? null : () { HapticFeedback.selectionClick(); actions.onSyncEdital(); }, child: const Text('Atualizar')),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Organizar questões por assunto'),
                  trailing: OutlinedButton(onPressed: busy ? null : () { HapticFeedback.selectionClick(); actions.onClassify(); }, child: const Text('Executar')),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Corrigir questões (enunciados, alternativas e gabaritos)'),
                  subtitle: const Text('Limpa artefatos, corta texto misturado e aplica gabaritos oficiais'),
                  trailing: OutlinedButton(onPressed: busy ? null : () { HapticFeedback.selectionClick(); actions.onFixQuestions(); }, child: const Text('Corrigir')),
                ),
                if (coverage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    coverage!['message']?.toString() ?? '',
                    style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
                  ),
                ],
                if (showLocalDataHint)
                  Text(
                    'Conteúdo salvo no seu computador',
                    style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
                  ),
              ],
            ),

            if (msg != null && !busy) ...[
              const SizedBox(height: 12),
              if (msg!.contains('sumiu') ||
                  msg!.contains('não abriu') ||
                  msg!.contains('nao abriu') ||
                  msg!.contains('Sem PDF'))
                QuietEmpty(
                  message: msg!,
                  action: FilledButton.tonal(
                    onPressed: () { HapticFeedback.selectionClick(); actions.onOpenFolder('provas'); },
                    child: const Text('Abrir provas'),
                  ),
                )
              else if (msg!.toLowerCase().contains('oficiais') ||
                  msg!.toLowerCase().contains('grav') ||
                  msg!.toLowerCase().contains('import') ||
                  msg!.toLowerCase().contains('base'))
                QuietEmpty(
                  message: msg!,
                  action: Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () { HapticFeedback.mediumImpact(); actions.onGoStudy(
                          '/sessao?examBoard=UEMA_PAES&preferNatureza=1&officialWithGab=1',
                        ); },
                        child: const Text('Estudar agora'),
                      ),
                      TextButton(
                        onPressed: () { HapticFeedback.selectionClick(); context.go('/fila'); },
                        child: const Text('Abrir fila'),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  msg!,
                  style: TextStyle(fontSize: 13, color: cs.primary),
                ),
            ],
          ],
        ),
      ),
    ],
  );
  }
}
