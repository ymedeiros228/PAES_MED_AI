import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/ui_kit.dart';

class ApprovalScreen extends ConsumerStatefulWidget {
  const ApprovalScreen({super.key});

  @override
  ConsumerState<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends ConsumerState<ApprovalScreen> {
  List<Map<String, dynamic>> items = [];
  String? error;
  bool loading = true;
  int selected = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await apiClient.get('/api/approval/pending', {'limit': '80'});
      setState(() {
        items = (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (selected >= items.length && items.isNotEmpty) selected = items.length - 1;
      });
    } catch (e) {
      setState(() => error = humanApiError(e, fallback: 'Não deu para carregar a fila de aprovação.'));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _decide(String id, bool approve) async {
    try {
      await apiClient.post('/api/approval/decide', {'questionId': id, 'approve': approve});
      ref.read(refreshTickProvider.notifier).state++;
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para registrar a decisão.'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: 'Avançado',
                title: 'Aprovar',
                subtitle: items.isEmpty
                    ? 'Questões geradas entram nos simulados após aprovação'
                    : '${items.length} pendente(s) · ↑/↓ J/K · A = aprovar · R = rejeitar · Enter/O abrir',
                trailing: IconButton(
                  tooltip: 'Atualizar',
                  onPressed: loading
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          _load();
                        },
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SkeletonList(count: 3, lines: 3),
                ),
              if (error != null)
                QuietEmpty(
                  message: error!,
                  action: Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _load();
                        },
                        child: const Text('Tentar'),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.go('/biblioteca');
                        },
                        child: const Text('Biblioteca'),
                      ),
                    ],
                  ),
                ),
              if (!loading && error == null && items.isEmpty)
                EmptyState(
                  title: 'Fila limpa',
                  subtitle: 'Nenhuma questão pendente de aprovação.',
                  action: Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          context.go('/biblioteca');
                        },
                        child: const Text('Biblioteca'),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1');
                        },
                        child: const Text('Sessão'),
                      ),
                    ],
                  ),
                ),
              StaggeredFadeIn(
                itemDelay: const Duration(milliseconds: 70),
                children: [
                  for (var i = 0; i < items.length; i++)
                    Builder(
                      builder: (_) {
                        final q = items[i];
                        final active = i == selected;
                        return SurfacePanel(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: active
                      ? Theme.of(context).colorScheme.primaryContainer.f45
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${q['subject']} · ${q['topic']} (${q['year']})',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        q['statement']?.toString() ?? '',
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontFamilyFallback: const ['Times New Roman', 'serif'],
                          fontSize: 13.5,
                          height: 1.5,
                          color: Theme.of(context).colorScheme.onSurface.f72,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              setState(() => selected = i);
                              _decide(q['id'].toString(), true);
                            },
                            child: const Text('Aprovar (A)'),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() => selected = i);
                              _decide(q['id'].toString(), false);
                            },
                            child: const Text('Rejeitar (R)'),
                          ),
                          TextButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setState(() => selected = i);
                              context.go('/questoes/${q['id']}');
                            },
                            child: const Text('Abrir (O)'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
                  },
                ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
