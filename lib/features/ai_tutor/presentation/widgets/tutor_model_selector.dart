import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';

/// Botão compacto que abre seletor de modelo de IA.
class TutorModelSelectorButton extends StatelessWidget {
  const TutorModelSelectorButton({
    required this.config,
    required this.selectedProvider,
    required this.onSelected,
    super.key,
  });

  final Map<String, dynamic> config;
  final String? selectedProvider;
  final void Function(String?) onSelected;

  static const _providerInfo =
      <String, ({String label, String icon, String modelKey})>{
    'gemini': (
      label: 'Gemini',
      icon: 'gemini-3-flash-preview',
      modelKey: 'geminiModel'
    ),
    'groq': (
      label: 'Groq Llama',
      icon: 'llama-3.3-70b-versatile',
      modelKey: 'groqModel'
    ),
    'openrouter': (
      label: 'OpenRouter',
      icon: 'nvidia/nemotron-3-super-120b-a12b:free',
      modelKey: 'openrouterModel'
    ),
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
                  const Text('Automático',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('Melhor provedor disponível',
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurface.withOpacity(0.5))),
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
                  color:
                      configured ? cs.primary : cs.onSurface.withOpacity(0.3),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              configured ? null : cs.onSurface.withOpacity(0.4),
                        ),
                      ),
                      Text(
                        configured ? model : 'Não configurado',
                        style: TextStyle(
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
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onPrimaryContainer,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: cs.onPrimaryContainer.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}
