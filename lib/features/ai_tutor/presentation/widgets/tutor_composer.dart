import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/ui/layout_tokens.dart';
import 'tutor_model_selector.dart';

class TutorSendIntent extends Intent {
  const TutorSendIntent();
}

/// Composer fixo na base — modelo à esquerda, envio à direita, Ctrl+Enter envia.
class TutorComposer extends StatelessWidget {
  const TutorComposer({
    required this.controller,
    required this.isLoading,
    required this.onSend,
    this.aiConfig,
    this.selectedProvider,
    this.onProviderSelected,
    super.key,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;
  final Map<String, dynamic>? aiConfig;
  final String? selectedProvider;
  final void Function(String?)? onProviderSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter, control: true):
            TutorSendIntent(),
      },
      child: Actions(
        actions: {
          TutorSendIntent: CallbackAction<TutorSendIntent>(
            onInvoke: (_) {
              if (!isLoading) onSend();
              return null;
            },
          ),
        },
        child: Material(
          elevation: 6,
          color: cs.surface,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomInset),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kPageMaxWidth),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (aiConfig != null && onProviderSelected != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 4),
                      child: TutorModelSelectorButton(
                        config: aiConfig!,
                        selectedProvider: selectedProvider,
                        onSelected: (p) {
                          HapticFeedback.selectionClick();
                          onProviderSelected!(p);
                        },
                      ),
                    ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Sua dúvida…',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: cs.onSurface.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: cs.outline.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: cs.primary, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: cs.outline.withOpacity(0.2)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Enviar (Ctrl+Enter)',
                    onPressed: isLoading ? null : onSend,
                    icon: isLoading
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
      ),
    );
  }
}
