import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SubmitShortcutIntent extends Intent {
  const SubmitShortcutIntent();
}

/// Envolve um formulário/editor: Ctrl+Enter chama [onSubmit]; Enter sozinho = nova linha.
class CtrlEnterScope extends StatelessWidget {
  const CtrlEnterScope({
    required this.onSubmit,
    required this.child,
    this.enabled = true,
    super.key,
  });

  final VoidCallback onSubmit;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter, control: true):
            SubmitShortcutIntent(),
      },
      child: Actions(
        actions: {
          SubmitShortcutIntent: CallbackAction<SubmitShortcutIntent>(
            onInvoke: (_) {
              if (enabled) onSubmit();
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}
