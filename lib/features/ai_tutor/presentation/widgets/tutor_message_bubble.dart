import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:paes_med_ai/features/ai_tutor/domain/chat_message.dart';

import '../../../../core/theme/app_theme.dart';

String tutorCiteLine(Map<String, dynamic> c) {
  final type = c['type']?.toString() ?? 'fonte';
  final year = c['year']?.toString();
  final tag = year != null && year.isNotEmpty ? '[$type · $year]' : '[$type]';
  final label = c['label'] ?? c['id'] ?? '—';
  final snippet = c['snippet']?.toString();
  if (snippet != null && snippet.isNotEmpty) return '$tag $label — $snippet';
  return '$tag $label';
}

class TutorMessageBubble extends StatelessWidget {
  const TutorMessageBubble({
    required this.message,
    this.onPrompt,
    super.key,
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
        border: Border.all(
          color: message.isUser
              ? scheme.primary.withOpacity(0.25)
              : scheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: message.isUser
            ? [
                BoxShadow(
                  color: scheme.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser && message.uncited) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.f55,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Conteúdo geral · sem questão do seu material',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.onPrimaryContainer,
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
                  color: scheme.onPrimaryContainer,
                ),
                label: Text(
                  message.model!.startsWith('offline-')
                      ? 'Modo sem internet'
                      : 'IA conectada',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                backgroundColor: scheme.primaryContainer,
                side: BorderSide(
                    color: scheme.primary.withOpacity(0.3), width: 1),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
            ),
          ],
          SelectableText(
            message.content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: message.isUser
                  ? scheme.onPrimaryContainer
                  : scheme.onSurface.withOpacity(0.85),
            ),
          ),
          if (!message.isUser && onPrompt != null) ...[
            const SizedBox(height: 12),
            Text(
              'Próximo passo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withOpacity(0.78),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TutorActionChip(
                  label: 'Explicar mais simples',
                  icon: Icons.lightbulb_outline_rounded,
                  onPressed: () => onPrompt!(
                    'Explique a resposta anterior de forma mais simples, '
                    'com um exemplo curto e sem inventar informação fora do seu material.',
                  ),
                ),
                _TutorActionChip(
                  label: 'Testar meu entendimento',
                  icon: Icons.quiz_outlined,
                  onPressed: () => onPrompt!(
                    'Faça uma pergunta curta para testar meu entendimento da resposta anterior. '
                    'Não mostre a resposta ainda.',
                  ),
                ),
                _TutorActionChip(
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
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
                      context.go('/sessao');
                    }
                  },
                  child: Text(
                    '• ${tutorCiteLine(c)}',
                    style: TextStyle(
                      fontSize: 13,
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

class AnimatedTutorMessageBubble extends StatefulWidget {
  const AnimatedTutorMessageBubble({
    required this.message,
    this.onPrompt,
    super.key,
  });

  final ChatMessage message;
  final ValueChanged<String>? onPrompt;

  @override
  State<AnimatedTutorMessageBubble> createState() =>
      _AnimatedTutorMessageBubbleState();
}

class _AnimatedTutorMessageBubbleState extends State<AnimatedTutorMessageBubble>
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
        child: TutorMessageBubble(
          message: widget.message,
          onPrompt: widget.onPrompt,
        ),
      ),
    );
  }
}

class _TutorActionChip extends StatelessWidget {
  const _TutorActionChip({
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
