import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paes_med_ai/features/ai_tutor/application/ai_tutor_controller.dart';

import '../../../core/data/api_client.dart';
import '../../../core/widgets/ui_kit.dart';
import 'widgets/tutor_composer.dart';
import 'widgets/tutor_message_bubble.dart';
import 'widgets/tutor_typing_indicator.dart';

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
  Map<String, dynamic>? _aiConfig;
  bool _seedApplied = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAiConfig());
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyRouteSeed());
  }

  Future<void> _loadAiConfig() async {
    try {
      final raw = await apiClient.get('/api/ai/config');
      if (!mounted || raw is! Map) return;
      setState(() => _aiConfig = Map<String, dynamic>.from(raw));
    } catch (_) {}
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
    buf.write('Explique com seu material, sem inventar incidência UEMA.');
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

  bool _aiConfigured(Map<String, dynamic>? config) {
    if (config == null) return true;
    return config['geminiConfigured'] == true ||
        config['groqConfigured'] == true ||
        config['openrouterConfigured'] == true ||
        config['openaiConfigured'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiTutorControllerProvider);
    final cs = Theme.of(context).colorScheme;
    final chatting = state.messages.length > 1 || state.isLoading;

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

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(28, kGap16, kGap16, chatting ? 8 : 0),
            child: chatting
                ? Row(
                    children: [
                      Text(
                        'Tutor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Limpar conversa',
                        onPressed: state.isLoading
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                ref
                                    .read(aiTutorControllerProvider.notifier)
                                    .clearConversation();
                              },
                        icon: const Icon(Icons.delete_sweep_outlined),
                      ),
                    ],
                  )
                : PageHeader(
                    eyebrow: 'Ajuda',
                    title: 'Tutor',
                    subtitle:
                        'Pergunte sobre o plano — respostas citam seu material',
                    trailing: IconButton(
                      tooltip: 'Limpar conversa',
                      onPressed: state.isLoading
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(aiTutorControllerProvider.notifier)
                                  .clearConversation();
                            },
                      icon: const Icon(Icons.delete_sweep_outlined),
                    ),
                  ),
          ),
          if (_aiConfig != null && !_aiConfigured(_aiConfig))
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, kGap8),
              child: QuietEmpty(
                icon: Icons.cloud_off_outlined,
                message:
                    'Sem internet no momento. Configure uma chave de IA em Ajustes para usar o tutor.',
                action: TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.go('/configuracoes');
                  },
                  child: const Text('Abrir Ajustes'),
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
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(aiTutorControllerProvider.notifier)
                            .clearConversation();
                      },
                      child: const Text('Limpar'),
                    ),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.go('/sessao');
                      },
                      child: const Text('Sessão'),
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
                              child: SelectableText(
                                state.messages.first.content,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: cs.onSurface.withOpacity(0.85),
                                ),
                              ),
                            ),
                          const QuietEmpty(
                            message: 'Digite sua dúvida abaixo.',
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              for (final prompt in const [
                                'Explique osmose',
                                'O que é homeostase?',
                                'Diferença entre mitose e meiose',
                                'Como funciona a fotossíntese?',
                                'Explique o ciclo de Krebs',
                              ])
                                ActionChip(
                                  label: Text(prompt),
                                  onPressed: () => _sendPrompt(prompt),
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
                        return const RepaintBoundary(
                            child: TutorTypingIndicator());
                      }
                      final isLast = index == state.messages.length - 1;
                      return isLast
                          ? AnimatedTutorMessageBubble(
                              key: ValueKey('msg_$index'),
                              message: state.messages[index],
                              onPrompt: state.isLoading ? null : _sendPrompt,
                            )
                          : TutorMessageBubble(
                              message: state.messages[index],
                              onPrompt: state.isLoading ? null : _sendPrompt,
                            );
                    },
                  ),
          ),
          TutorComposer(
            controller: _controller,
            isLoading: state.isLoading,
            onSend: _send,
            aiConfig: _aiConfig,
            selectedProvider: state.provider,
            onProviderSelected: (p) => ref
                .read(aiTutorControllerProvider.notifier)
                .setProvider(p),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    HapticFeedback.selectionClick();
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
