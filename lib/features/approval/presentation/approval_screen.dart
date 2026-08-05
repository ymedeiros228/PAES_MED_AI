import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
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
      });
    } catch (e) {
      setState(() => error = e.toString());
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: 'Avançado',
                title: 'Aprovar',
                subtitle: 'Itens gerados só entram em simulado sério depois de aprovados',
                trailing: IconButton(
                  tooltip: 'Atualizar',
                  onPressed: loading ? null : _load,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
              if (loading) const LinearProgressIndicator(),
              if (error != null)
                QuietEmpty(
                  message: 'Não deu para carregar a fila.',
                  action: TextButton(onPressed: _load, child: const Text('Tentar')),
                ),
              if (!loading && error == null && items.isEmpty)
                const EmptyState(
                  title: 'Fila limpa',
                  subtitle: 'Nenhuma questão pendente de aprovação.',
                ),
              for (final q in items)
                SurfacePanel(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${q['subject']} · ${q['topic']} (${q['year']})',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        q['statement']?.toString() ?? '',
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () => _decide(q['id'].toString(), true),
                            child: const Text('Aprovar'),
                          ),
                          OutlinedButton(
                            onPressed: () => _decide(q['id'].toString(), false),
                            child: const Text('Rejeitar'),
                          ),
                          TextButton(
                            onPressed: () => context.go('/questoes/${q['id']}'),
                            child: const Text('Abrir'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
