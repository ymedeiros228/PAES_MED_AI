import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paes_med_ai/features/ai_tutor/application/ai_tutor_controller.dart';
import 'package:paes_med_ai/features/ai_tutor/domain/chat_message.dart';

import '../../../core/data/api_client.dart';
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
  late final Future<dynamic> _aiConfigFuture;
  bool _seedApplied = false;

  static const _styles = <(String, String)>[
    ('professor', 'Professor'),
    ('macete', 'Macete'),
    ('resumo', 'Resumo'),
    ('analogia', 'Analogia'),
    ('mapa', 'Mapa'),
    ('flashcard', 'Cartão de estudo'),
    ('medico', 'Médico'),
    ('crianca', 'Simples'),
  ];

  @override
  void initState() {
    super.initState();
    _aiConfigFuture = apiClient.get('/api/ai/config');
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
        const SingleActivator(LogicalKeyboardKey.numpadEnter, control: true):
            () {
          if (!state.isLoading) unawaited(_send());
        },
      },
      child: Focus(
        autofocus: false,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, kGap16, kGap16, 0),
                child: PageHeader(
                  eyebrow: 'Ajuda',
                  title: 'Tutor',
                  subtitle:
                      'Pergunte sobre o plano · Ctrl+Enter envia · fontes clicáveis na resposta',
                  trailing: IconButton(
                    tooltip: 'Limpar conversa',
                    onPressed: state.isLoading
                        ? null
                        : () => ref
                            .read(aiTutorControllerProvider.notifier)
                            .clearConversation(),
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
                ),
              ),
              FutureBuilder<dynamic>(
                future: _aiConfigFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data is! Map) {
                    return const SizedBox.shrink();
                  }
                  final config = Map<String, dynamic>.from(snapshot.data as Map);
                  final configured = config['geminiConfigured'] == true ||
                      config['openaiConfigured'] == true;
                  if (configured) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, kGap8),
                    child: QuietEmpty(
                      icon: Icons.cloud_off_outlined,
                      message:
                          'Modo sem internet com base local. Configure uma chave em Ajustes para conversar com a IA conectada.',
                      action: TextButton(
                        onPressed: () => context.go('/configuracoes'),
                        child: const Text('Abrir Ajustes'),
                      ),
                    ),
                  );
                },
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
                          onPressed: () => ref
                              .read(aiTutorControllerProvider.notifier)
                              .clearConversation(),
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
                padding: const EdgeInsets.fromLTRB(28, 0, 28, kGap8),
                child: Row(
                  children: [
                    for (final s in _styles)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(s.$2),
                          selected: state.style == s.$1,
                          showCheckmark: false,
                          onSelected: (_) => ref
                              .read(aiTutorControllerProvider.notifier)
                              .setStyle(s.$1),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: (state.messages.length <= 1 && !state.isLoading)
                    ? Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (state.messages.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    state.messages.first.content,
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              const QuietEmpty(
                                message: 'Escolha um atalho ou digite abaixo.',
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  ActionChip(
                                    label: const Text('Meta de hoje'),
                                    onPressed: state.isLoading
                                        ? null
                                        : () {
                                            ref
                                                .read(aiTutorControllerProvider
                                                    .notifier)
                                                .send(
                                                  'Qual a meta de estudo de hoje e o que priorizar?',
                                                );
                                          },
                                  ),
                                  ActionChip(
                                    label: const Text('Macete do tópico'),
                                    onPressed: state.isLoading
                                        ? null
                                        : () {
                                            ref
                                                .read(aiTutorControllerProvider
                                                    .notifier)
                                                .send(
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
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
                        itemCount:
                            state.messages.length + (state.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.messages.length) {
                            return const _TypingIndicator();
                          }
                          return _MessageBubble(
                            message: state.messages[index],
                            onPrompt: state.isLoading ? null : _sendPrompt,
                          );
                        },
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
                              fillColor:
                                  cs.surfaceContainerHigh.withOpacity(0.45),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
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
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
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

  Future<void> _sendPrompt(String prompt) async {
    await ref.read(aiTutorControllerProvider.notifier).send(prompt);
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
  const _MessageBubble({
    required this.message,
    this.onPrompt,
  });

  final ChatMessage message;
  final ValueChanged<String>? onPrompt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: message.isUser
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Conteúdo geral · sem questão da base local',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
            if (!message.isUser &&
                message.model != null &&
                message.model!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Chip(
                  avatar: Icon(
                    message.model!.startsWith('offline-')
                        ? Icons.cloud_off_outlined
                        : Icons.auto_awesome_outlined,
                    size: 16,
                  ),
                  label: Text(
                    message.model!.startsWith('offline-')
                        ? 'Modo sem internet'
                        : 'IA conectada · ${message.model}',
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
            SelectableText(message.content),
            if (!message.isUser && onPrompt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Próximo passo',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withOpacity(0.78),
                    ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _TutorAction(
                    label: 'Explicar mais simples',
                    icon: Icons.lightbulb_outline_rounded,
                    onPressed: () => onPrompt!(
                      'Explique a resposta anterior de forma mais simples, '
                      'com um exemplo curto e sem inventar informação fora da base local.',
                    ),
                  ),
                  _TutorAction(
                    label: 'Testar meu entendimento',
                    icon: Icons.quiz_outlined,
                    onPressed: () => onPrompt!(
                      'Faça uma pergunta curta para testar meu entendimento da resposta anterior. '
                      'Não mostre a resposta ainda.',
                    ),
                  ),
                  _TutorAction(
                    label: 'Virar cartões de estudo',
                    icon: Icons.style_outlined,
                    onPressed: () => onPrompt!(
                      'Transforme a resposta anterior em até 3 cartões de estudo de pergunta e resposta, '
                      'usando somente a base local quando houver.',
                    ),
                  ),
                ],
              ),
            ],
            if (message.citations.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Fontes na base (clique abre ficha/treino)',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
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
                      } else if ((type == 'edital' || type == 'lesson') &&
                          subject.isNotEmpty) {
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

class _TutorAction extends StatelessWidget {
  const _TutorAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
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
