import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paes_med_ai/features/ai_tutor/application/ai_tutor_controller.dart';
import 'package:paes_med_ai/features/ai_tutor/domain/chat_message.dart';

import '../../../core/widgets/ui_kit.dart';

class AiTutorScreen extends ConsumerStatefulWidget {
  const AiTutorScreen({
    super.key,
    this.seedSubject,
    this.seedTopic,
    this.seedQuery,
  });

  final String? seedSubject;
  final String? seedTopic;
  final String? seedQuery;

  @override
  ConsumerState<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends ConsumerState<AiTutorScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _seedApplied = false;

  static const _styles = <(String, String)>[
    ('professor', 'Professor'),
    ('macete', 'Macete'),
    ('resumo', 'Resumo'),
    ('analogia', 'Analogia'),
    ('mapa', 'Mapa'),
    ('flashcard', 'Flashcard'),
    ('medico', 'Médico'),
    ('crianca', 'Simples'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyRouteSeed());
  }

  void _applyRouteSeed() {
    if (_seedApplied || !mounted) return;
    if (_controller.text.trim().isNotEmpty) {
      _seedApplied = true;
      return;
    }
    final sub = widget.seedSubject?.trim() ?? '';
    final top = widget.seedTopic?.trim() ?? '';
    final q = widget.seedQuery?.trim() ?? '';
    if (sub.isEmpty && top.isEmpty && q.isEmpty) {
      _seedApplied = true;
      return;
    }
    final buf = StringBuffer();
    if (sub.isNotEmpty || top.isNotEmpty) {
      buf.write('Sobre ${sub.isEmpty ? '—' : sub}');
      if (top.isNotEmpty) buf.write(' · $top');
      buf.writeln('.');
    }
    if (q.isNotEmpty) {
      buf.writeln('Questão (trecho): $q');
    }
    buf.write('Explique com base local, sem inventar incidência UEMA.');
    setState(() {
      _controller.text = buf.toString().trim();
      _seedApplied = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiTutorControllerProvider);
    final cs = Theme.of(context).colorScheme;

    ref.listen(aiTutorControllerProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
          if (!state.isLoading) unawaited(_send());
        },
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): () {
          if (!state.isLoading) unawaited(_send());
        },
        const SingleActivator(LogicalKeyboardKey.numpadEnter, control: true): () {
          if (!state.isLoading) unawaited(_send());
        },
      },
      child: Focus(
        autofocus: false,
        child: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 0),
            child: PageHeader(
              eyebrow: 'Ajuda',
              title: 'Tutor',
              subtitle: 'Pergunte sobre o plano · Ctrl+Enter envia · fontes clicáveis na resposta',
              trailing: IconButton(
                tooltip: 'Limpar conversa',
                onPressed: state.isLoading
                    ? null
                    : () => ref.read(aiTutorControllerProvider.notifier).clearConversation(),
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
            ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
              child: QuietEmpty(
                message: state.error!,
                action: Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => ref.read(aiTutorControllerProvider.notifier).clearConversation(),
                      child: const Text('Limpar'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/sessao'),
                      child: const Text('Sessão'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/biblioteca'),
                      child: const Text('Biblioteca'),
                    ),
                  ],
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
            child: Row(
              children: [
                for (final s in _styles)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(s.$2),
                      selected: state.style == s.$1,
                      showCheckmark: false,
                      onSelected: (_) => ref.read(aiTutorControllerProvider.notifier).setStyle(s.$1),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
              children: [
                for (final m in state.messages) _MessageBubble(message: m),
                if (state.isLoading) const _TypingIndicator(),
                if (state.messages.length <= 1 && !state.isLoading) ...[
                  const SizedBox(height: 4),
                  const QuietEmpty(
                    message: 'Escolha um atalho ou digite abaixo.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Meta de hoje'),
                        onPressed: state.isLoading
                            ? null
                            : () {
                                ref.read(aiTutorControllerProvider.notifier).send(
                                      'Qual a meta de estudo de hoje e o que priorizar?',
                                    );
                              },
                      ),
                      ActionChip(
                        label: const Text('Macete do tópico'),
                        onPressed: state.isLoading
                            ? null
                            : () {
                                ref.read(aiTutorControllerProvider.notifier).send(
                                      'Me dá um macete do tópico da fila de hoje e como eliminar distratores.',
                                    );
                              },
                      ),
                      ActionChip(
                        label: const Text('Abrir sessão'),
                        onPressed: () => context.go('/sessao'),
                      ),
                      ActionChip(
                        label: const Text('Biblioteca'),
                        onPressed: () => context.go('/biblioteca'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Material(
            elevation: 6,
            color: cs.surface,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                14 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: 'Sua dúvida… (Ctrl+Enter envia)',
                          filled: true,
                          fillColor: cs.surfaceContainerHigh.withOpacity(0.45),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      tooltip: 'Enviar',
                      onPressed: state.isLoading ? null : _send,
                      icon: state.isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    await ref.read(aiTutorControllerProvider.notifier).send(text);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }
}

String _citeLine(Map<String, dynamic> c) {
  final type = c['type']?.toString() ?? 'fonte';
  final year = c['year']?.toString();
  final tag = year != null && year.isNotEmpty ? '[$type · $year]' : '[$type]';
  final label = c['label'] ?? c['id'] ?? '—';
  final snippet = c['snippet']?.toString();
  if (snippet != null && snippet.isNotEmpty) return '$tag $label — $snippet';
  return '$tag $label';
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: message.isUser ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: message.isUser ? const Radius.circular(4) : null,
            bottomLeft: message.isUser ? null : const Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser && message.uncited) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Sem base local · não inventa cobrança UEMA',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
            SelectableText(message.content),
            if (message.citations.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Fontes na base (clique abre ficha/treino)',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              for (final c in message.citations.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    onTap: () {
                      final type = c['type']?.toString();
                      final id = c['id']?.toString();
                      final subject = c['subject']?.toString() ?? '';
                      final topic = c['topic']?.toString() ?? '';
                      if (type == 'question' && id != null && id.isNotEmpty) {
                        context.go('/questoes/$id');
                      } else if ((type == 'edital' || type == 'lesson') && subject.isNotEmpty) {
                        context.go(
                          '/adaptativo?subject=${Uri.encodeComponent(subject)}'
                          '&topic=${Uri.encodeComponent(topic)}',
                        );
                      } else if (type == 'edital' || type == 'lesson') {
                        // Ciclo CF: lesson never hostil /aulas sob foco
                        context.go('/sessao');
                      }
                    },
                    child: Text(
                      '• ${_citeLine(c)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Pensando…'),
          ],
        ),
      ),
    );
  }
}
