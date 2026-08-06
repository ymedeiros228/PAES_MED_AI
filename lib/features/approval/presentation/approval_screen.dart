import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/data/theory_reads.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/theory_topic_sheet.dart';
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
  Map<String, bool> theoryReadByKey = {};

  bool _isTheoryRead(String subject, String topic) =>
      theoryReadByKey[theoryReadKey(subject, topic)] == true;

  Future<void> _loadReads() async {
    final pairs = <(String, String)>[];
    for (final q in items) {
      final s = q['subject']?.toString() ?? '';
      final t = q['topic']?.toString() ?? '';
      if (s.isNotEmpty && t.isNotEmpty) pairs.add((s, t));
    }
    if (pairs.isEmpty) return;
    final out = await fetchTheoryReadMap(pairs);
    if (mounted) setState(() => theoryReadByKey = out);
  }

  Future<void> _openTheory(String subject, String topic) async {
    await TheoryTopicSheet.show(
      context,
      subject: subject,
      topic: topic,
      onMarkedRead: () {
        if (mounted) setState(() => theoryReadByKey[theoryReadKey(subject, topic)] = true);
      },
    );
  }

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
      await _loadReads();
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
                EmptyState(
                  title: 'Fila limpa',
                  subtitle: 'Nenhuma questão pendente de aprovação.',
                  actionLabel: 'Biblioteca',
                  onAction: () => context.go('/biblioteca'),
                ),
              for (final q in items)
                Builder(
                  builder: (_) {
                    final s = q['subject']?.toString() ?? '';
                    final t = q['topic']?.toString() ?? '';
                    return SurfacePanel(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$s · $t (${q['year']})'
                        '${_isTheoryRead(s, t) ? ' · Li' : ''}',
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
                          if (s.isNotEmpty && t.isNotEmpty)
                            TextButton(
                              onPressed: () => _openTheory(s, t),
                              child: Text(_isTheoryRead(s, t) ? 'Teoria · Li' : 'Teoria'),
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
        ),
      ],
    );
  }
}
