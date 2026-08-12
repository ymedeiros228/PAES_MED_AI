import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
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
                      'Pergunte sobre o plano · Ctrl+Enter envia · fontes na resposta',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FutureBuilder<dynamic>(
                        future: _aiConfigFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data is! Map) {
                            return const SizedBox.shrink();
                          }
                          final config = Map<String, dynamic>.from(snapshot.data as Map);
                          return _ModelSelectorButton(
                            config: config,
                            selectedProvider: state.provider,
                            onSelected: (p) {
                              HapticFeedback.selectionClick();
                              ref.read(aiTutorControllerProvider.notifier).setProvider(p);
                            },
                          );
                        },
                      ),
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
                          'Sem internet no momento. Configure uma chave de IA em Ajustes para usar o tutor.',
                      action: TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.go('/configuracoes');
                        },
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
                                    style: GoogleFonts.inter(
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
                                  ActionChip(
                                    label: const Text('Explique osmose'),
                                    onPressed: () {
                                      _sendPrompt('Explique osmose');
                                    },
                                  ),
                                  ActionChip(
                                    label: const Text('O que é homeostase?'),
                                    onPressed: () {
                                      _sendPrompt('O que é homeostase?');
                                    },
                                  ),
                                  ActionChip(
                                    label: const Text(
                                        'Diferença entre mitose e meiose'),
                                    onPressed: () {
                                      _sendPrompt(
                                          'Diferença entre mitose e meiose');
                                    },
                                  ),
                                  ActionChip(
                                    label: const Text(
                                        'Como funciona a fotossíntese?'),
                                    onPressed: () {
                                      _sendPrompt(
                                          'Como funciona a fotossíntese?');
                                    },
                                  ),
                                  ActionChip(
                                    label: const Text('Explique o ciclo de Krebs'),
                                    onPressed: () {
                                      _sendPrompt('Explique o ciclo de Krebs');
                                    },
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
                            return const RepaintBoundary(child: _TypingIndicator());
                          }
                          // Anima apenas a última mensagem (nova)
                          final isLast = index == state.messages.length - 1;
                          return isLast
                              ? _AnimatedMessageBubble(
                                  key: ValueKey('msg_$index'),
                                  message: state.messages[index],
                                  onPrompt: state.isLoading ? null : _sendPrompt,
                                )
                              : _MessageBubble(
                                  message: state.messages[index],
                                  onPrompt: state.isLoading ? null : _sendPrompt,
                                );
                        },
                      ),
              ),
              // Botão de recarregar conversa (limpa e reinicia)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Recarregar conversa',
                    onPressed: state.isLoading
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(aiTutorControllerProvider.notifier)
                                .clearConversation();
                          },
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    style: IconButton.styleFrom(
                      foregroundColor: cs.onSurface.f55,
                    ),
                  ),
                ),
              ),
              Material(
                elevation: 6,
                color: cs.surface,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    16 + MediaQuery.viewInsetsOf(context).bottom,
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
                                  cs.surfaceContainerHigh.f45,
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
                        const SizedBox(width: 8),
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

String _citeLine(Map<String, dynamic> c) {
  final type = c['type']?.toString() ?? 'fonte';
  final year = c['year']?.toString();
  final tag = year != null && year.isNotEmpty ? '[$type · $year]' : '[$type]';
  final label = c['label'] ?? c['id'] ?? '—';
  final snippet = c['snippet']?.toString();
  if (snippet != null && snippet.isNotEmpty) return '$tag $label — $snippet';
  return '$tag $label';
}

/// Wrapper que anima a entrada da mensagem nova (fade + slide up).
class _AnimatedMessageBubble extends StatefulWidget {
  const _AnimatedMessageBubble({
    required this.message,
    this.onPrompt,
    super.key,
  });

  final ChatMessage message;
  final ValueChanged<String>? onPrompt;

  @override
  State<_AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<_AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _MessageBubble(
          message: widget.message,
          onPrompt: widget.onPrompt,
        ),
      ),
    );
  }
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
    final bubble = Container(
        constraints: const BoxConstraints(maxWidth: 760),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: message.isUser
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16).copyWith(
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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.f55,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Conteúdo geral · sem questão do seu material',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ).copyWith(
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
                        : 'IA conectada',
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
            SelectableText(
              message.content,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: scheme.onSurface.withOpacity(0.85),
              ),
            ),
            if (!message.isUser && onPrompt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Próximo passo',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ).copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withOpacity(0.78),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TutorAction(
                    label: 'Explicar mais simples',
                    icon: Icons.lightbulb_outline_rounded,
                    onPressed: () => onPrompt!(
                      'Explique a resposta anterior de forma mais simples, '
                      'com um exemplo curto e sem inventar informação fora do seu material.',
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
                      'usando somente o seu material quando houver.',
                    ),
                  ),
                ],
              ),
            ],
            if (message.citations.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Fontes na resposta',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              for (final c in message.citations.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
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
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: scheme.onSurface.withOpacity(0.7),
                      ).copyWith(
                        color: scheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      );
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: message.isUser
          ? bubble
          : Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 8, bottom: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.primaryContainer],
                    ),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: scheme.onPrimary,
                  ),
                ),
                Flexible(child: bubble),
              ],
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
      onPressed: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      visualDensity: VisualDensity.compact,
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Três pontos pulsantes
            for (var i = 0; i < 3; i++) ...[
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  // Cada ponto tem um atraso diferente
                  final t = (_controller.value + i * 0.2) % 1.0;
                  final scale = 0.6 + 0.4 * (0.5 + 0.5 * (t < 0.5 ? t * 2 : (1 - t) * 2));
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.4 + 0.4 * scale),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(width: 8),
            Text(
              'Pensando…',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: cs.onSurface.withOpacity(0.7),
              ).copyWith(
                color: cs.onSurface.f55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão com ícone de cérebro que abre um seletor de modelo de IA.
class _ModelSelectorButton extends StatelessWidget {
  const _ModelSelectorButton({
    required this.config,
    required this.selectedProvider,
    required this.onSelected,
  });

  final Map<String, dynamic> config;
  final String? selectedProvider;
  final void Function(String?) onSelected;

  static const _providerInfo = <String, ({String label, String icon, String modelKey})>{
    'gemini': (label: 'Gemini', icon: 'gemini-3-flash-preview', modelKey: 'geminiModel'),
    'groq': (label: 'Groq Llama', icon: 'llama-3.3-70b-versatile', modelKey: 'groqModel'),
    'openrouter': (label: 'OpenRouter', icon: 'llama-3.3-70b-instruct:free', modelKey: 'openrouterModel'),
    'openai': (label: 'OpenAI GPT', icon: 'gpt-4.1-mini', modelKey: 'openaiModel'),
  };

  String? _currentLabel() {
    final p = selectedProvider ?? config['activeProvider'] as String?;
    if (p == null) return null;
    final info = _providerInfo[p];
    if (info == null) return null;
    final model = config[info.modelKey] ?? info.icon;
    return '${info.label} · $model';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = _currentLabel();
    return PopupMenuButton<String?>(
      tooltip: 'Escolher modelo de IA',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.primary.withOpacity(0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology_alt, size: 18, color: cs.primary),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                label ?? 'Auto',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onPrimaryContainer,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: cs.onPrimaryContainer.withOpacity(0.6)),
          ],
        ),
      ),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String?>>[];
        items.add(PopupMenuItem<String?>(
          value: null,
          child: Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: cs.primary),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Automático', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('Melhor provedor disponível', style: GoogleFonts.inter(fontSize: 11, color: cs.onSurface.withOpacity(0.5))),
                ],
              ),
            ],
          ),
        ));
        items.add(const PopupMenuDivider());
        for (final entry in _providerInfo.entries) {
          final provider = entry.key;
          final info = entry.value;
          final configured = config['${provider}Configured'] == true;
          final model = config[info.modelKey] ?? info.icon;
          items.add(PopupMenuItem<String?>(
            value: provider,
            enabled: configured,
            child: Row(
              children: [
                Icon(
                  Icons.psychology,
                  size: 18,
                  color: configured ? cs.primary : cs.onSurface.withOpacity(0.3),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: configured ? null : cs.onSurface.withOpacity(0.4),
                        ),
                      ),
                      Text(
                        configured ? model : 'Não configurado',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (selectedProvider == provider)
                  Icon(Icons.check_circle, size: 16, color: cs.primary),
              ],
            ),
          ));
        }
        return items;
      },
      onSelected: onSelected,
    );
  }
}
