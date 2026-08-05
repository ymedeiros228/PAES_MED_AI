import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/providers.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/ui_kit.dart';

/// Domínio: ranking para estudar. Ferramentas de curadoria ficam em Avançado.
class MedicineScreen extends ConsumerWidget {
  const MedicineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(medicineProvider);
    final tick = ref.watch(refreshTickProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const EmptyState(
        title: 'Domínio indisponível',
        subtitle: 'Tente de novo em instantes.',
      ),
      data: (payload) {
        final items = (payload['items'] as List? ?? []);
        final basis = Map<String, dynamic>.from(payload['statsBasis'] as Map? ?? {});
        final curation = Map<String, dynamic>.from(payload['curation'] as Map? ?? {});
        final officialN = basis['officialCount'] as int? ?? 0;
        final realN = curation['realCount'] as int? ?? 0;
        final realPct = curation['realPercent'];
        final crossN = curation['crossDomainCount'] as int? ?? 0;
        final natN = curation['naturezaCount'] as int? ?? 0;
        final cs = Theme.of(context).colorScheme;

        return ListView(
          children: [
            PageBody(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(
                    eyebrow: 'Analisar',
                    title: 'Domínio',
                    subtitle: 'Onde vale focar · toque para abrir sessão no tópico',
                  ),

                  if (officialN == 0)
                    QuietEmpty(
                      message: 'Sem provas oficiais ainda — ranking usa base de treino.',
                      action: TextButton(
                        onPressed: () => context.go('/biblioteca'),
                        child: const Text('Biblioteca'),
                      ),
                    )
                  else
                    SurfacePanel(
                      margin: const EdgeInsets.only(bottom: 16),
                      color: cs.primaryContainer.withOpacity(0.4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Provas UEMA na base',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: () => context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1'),
                            child: const Text('Sessão Natureza'),
                          ),
                        ],
                      ),
                    ),

                  // Fila de revisão humana (Natureza non-real, cap 5 — Ciclo L)
                  FutureBuilder(
                    key: ValueKey('drafts-$tick'),
                    future: apiClient.get('/api/professor/draft-queue?limit=5'),
                    builder: (context, snap) {
                      if (!snap.hasData || snap.data is! Map) return const SizedBox.shrink();
                      final q = Map<String, dynamic>.from(snap.data as Map);
                      final draftItems = q['items'] as List? ?? const [];
                      final n = q['count'] as int? ?? draftItems.length;
                      if (n == 0) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionLabel(
                            'Para revisar hoje',
                            hint: '$n rascunho(s) Natureza — Aceitar grava “ok”, não é texto oficial da banca',
                          ),
                          for (final raw in draftItems.take(5))
                            Builder(
                              builder: (context) {
                                final it = Map<String, dynamic>.from(raw as Map);
                                final id = it['questionId']?.toString() ?? '';
                                final ql = it['studentLabel']?.toString() ??
                                    it['resolutionQuality']?.toString() ??
                                    'rascunho';
                                return PlaylistTile(
                                  title: '${it['subject']}',
                                  subtitle: '${it['topic']}',
                                  badge: ql == 'template' ? 'template' : 'rascunho',
                                  leadingIcon: Icons.edit_note_rounded,
                                  onPlay: () => context.go('/questoes/$id'),
                                  secondary: TextButton(
                                    onPressed: () async {
                                      try {
                                        await apiClient.post('/api/professor/draft-accept', {'questionId': id});
                                        ref.read(refreshTickProvider.notifier).state++;
                                        ref.invalidate(medicineProvider);
                                      } catch (_) {}
                                    },
                                    child: const Text('Ok'),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),

                  // Labels sujos (Ciclo K)
                  FutureBuilder(
                    key: ValueKey('dirty-$tick'),
                    future: apiClient.get('/api/curation/dirty-labels?limit=8'),
                    builder: (context, snap) {
                      if (!snap.hasData || snap.data is! Map) return const SizedBox.shrink();
                      final d = Map<String, dynamic>.from(snap.data as Map);
                      final n = d['count'] as int? ?? 0;
                      final items = d['items'] as List? ?? const [];
                      if (n == 0) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionLabel('Labels suspeitas', hint: '$n cross-domain · rode Reclassificar'),
                          for (final raw in items.take(6))
                            Builder(
                              builder: (_) {
                                final it = Map<String, dynamic>.from(raw as Map);
                                return PlaylistTile(
                                  title: '${it['subject']}',
                                  subtitle: '${it['topic']}',
                                  badge: 'sujo',
                                  leadingIcon: Icons.warning_amber_rounded,
                                  onPlay: () {
                                    final id = it['id']?.toString();
                                    if (id != null && id.isNotEmpty) context.go('/questoes/$id');
                                  },
                                );
                              },
                            ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),

                  SectionLabel(
                    'Prioridade',
                    hint: officialN >= 10
                        ? 'Score local de estudo (base oficial) — não é % de aprovação UEMA'
                        : 'Score local com base de treino — não é incidência UEMA',
                  ),
                  if (items.isEmpty)
                    const QuietEmpty(message: 'Nada ranqueado ainda — faça uma sessão primeiro.')
                  else
                    for (final raw in items.take(24))
                      Builder(
                        builder: (context) {
                          final item = Map<String, dynamic>.from(raw as Map);
                          final s = item['subject']?.toString() ?? '';
                          final t = item['topic']?.toString() ?? '';
                          final nat = const {'Biologia', 'Química', 'Física'}.contains(s);
                          final status = item['curationStatus']?.toString() ?? '';
                          final curated = item['curated'] == true;
                          final dirty = item['crossDomain'] == true || status == 'sujo';
                          // badges: curado / pendente (sujo sem alarde no título)
                          String? badge;
                          if (dirty) {
                            badge = 'revisar label';
                          } else if (curated) {
                            badge = 'curado';
                          } else if (status == 'natureza' || nat) {
                            badge = 'pendente';
                          }
                          final nOff = item['frequency'] ?? item['realInTopic'] ?? item['n'];
                          final years = item['years'] as List? ?? const [];
                          final yearHint = years.isNotEmpty
                              ? ' · anos ${years.take(3).join(', ')}'
                              : '';
                          final countHint = nOff != null
                              ? ' · $nOff na base'
                              : '';
                          final sessao =
                              '/sessao?examBoard=UEMA_PAES'
                              '&subject=${Uri.encodeComponent(s)}'
                              '&topic=${Uri.encodeComponent(t)}'
                              '&preferNatureza=${nat ? '1' : '0'}'
                              '${years.isNotEmpty ? '&year=${years.last}' : ''}'
                              '${officialN >= 10 ? '&preferOfficial=1' : ''}';
                          return PlaylistTile(
                            title: s,
                            subtitle: '$t$countHint$yearHint',
                            badge: badge,
                            active: curated,
                            leadingIcon: Icons.play_circle_outline_rounded,
                            onPlay: () => context.go(sessao),
                          );
                        },
                      ),

                  const SizedBox(height: 16),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text('Avançado', style: Theme.of(context).textTheme.titleSmall),
                    subtitle: const Text('Inventário honesto + ferramentas de curadoria'),
                    children: [
                      SurfacePanel(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Inventário (base local)', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 6),
                            Text(
                              'Oficiais: $officialN · Natureza: $natN\n'
                              'Resoluções reais: $realN'
                              '${realPct != null ? ' ($realPct%)' : ''}\n'
                              'Cross-domain (labels suspeitas): $crossN',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (curation['message'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                curation['message'].toString(),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: cs.onSurface.withOpacity(0.6),
                                    ),
                              ),
                            ],
                            const Text(
                              'Números da base — sem inventar % de incidência.',
                              style: TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        title: const Text('Gerar rascunhos de explicação'),
                        subtitle: const Text('Não substitui revisão humana'),
                        trailing: FilledButton.tonal(
                          onPressed: () async {
                            try {
                              final data = await apiClient.post('/api/professor/batch-fill', {
                                'limit': 8,
                                'preferUema': true,
                              });
                              if (!context.mounted) return;
                              final n = (data as Map)['updated'] ?? 0;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gerados: $n')),
                              );
                              ref.invalidate(medicineProvider);
                              ref.read(refreshTickProvider.notifier).state++;
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                            }
                          },
                          child: const Text('Gerar'),
                        ),
                      ),
                      ListTile(
                        title: const Text('Reclassificar assuntos'),
                        subtitle: const Text('Corrige labels cross-domain (Natureza × Humanas)'),
                        trailing: OutlinedButton(
                          onPressed: () async {
                            try {
                              final data = await apiClient.post('/api/ingest/classify-pending', {});
                              if (!context.mounted) return;
                              final m = data as Map;
                              final residual = m['residualCrossDomain'] ?? m['updated'];
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    m['message']?.toString() ??
                                        'Atualizados: ${m['updated'] ?? 0} · residual: $residual',
                                  ),
                                ),
                              );
                              ref.invalidate(medicineProvider);
                              ref.read(refreshTickProvider.notifier).state++;
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                            }
                          },
                          child: const Text('Rodar'),
                        ),
                      ),
                      ListTile(
                        title: const Text('Completar explicações Natureza'),
                        subtitle: const Text('Floor didático 4 eixos — não é texto da banca'),
                        trailing: OutlinedButton(
                          onPressed: () async {
                            try {
                              final data = await apiClient.post('/api/curation/promote-natureza-real', {
                                'limit': 8,
                              });
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Completadas: ${(data as Map)['promoted'] ?? 0}')),
                              );
                              ref.invalidate(medicineProvider);
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                            }
                          },
                          child: const Text('Rodar'),
                        ),
                      ),
                      ListTile(
                        title: const Text('Floor completo (Natureza → outras)'),
                        subtitle: const Text('Não inventa incidência; só preenche real didático'),
                        trailing: OutlinedButton(
                          onPressed: () async {
                            try {
                              final data = await apiClient.post('/api/curation/promote-all-pending', {
                                'limit': 40,
                              });
                              if (!context.mounted) return;
                              final m = data as Map;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Elevados: ${m['promotedTotal'] ?? 0}')),
                              );
                              ref.invalidate(medicineProvider);
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                            }
                          },
                          child: const Text('Rodar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
