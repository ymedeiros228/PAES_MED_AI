import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ui_kit.dart';

/// Aula em vídeo do assunto: abre a busca do YouTube numa aba nova.
///
/// O catálogo antigo de links fixos apontava para vídeos que não existiam;
/// a busca sempre traz aulas de verdade sobre o assunto.
class MediaReinforcement extends StatelessWidget {
  const MediaReinforcement({
    required this.subject,
    required this.topic,
    this.compact = false,
    this.heading = 'Aula em vídeo',
    super.key,
  });

  final String subject;
  final String topic;
  final bool compact;
  final String heading;

  /// Nome curto da matéria para a busca (áreas genéricas ficam de fora).
  static String _materiaNaBusca(String s) {
    if (s == 'Língua Portuguesa e Literatura') return 'português';
    if (const {'Natureza', 'Humanas', 'Linguagens'}.contains(s) ||
        s.startsWith('Medicina')) {
      return '';
    }
    return s;
  }

  Uri get _busca => Uri.https('www.youtube.com', '/results', {
        'search_query': [topic, _materiaNaBusca(subject), 'aula vestibular']
            .where((p) => p.isNotEmpty)
            .join(' '),
      });

  Future<void> _abrir(BuildContext context) async {
    HapticFeedback.selectionClick();
    final abriu = await launchUrl(
      _busca,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!abriu && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não deu para abrir o YouTube.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (subject.isEmpty || topic.isEmpty) return const SizedBox.shrink();
    final botao = OutlinedButton.icon(
      onPressed: () => _abrir(context),
      icon: const Icon(Icons.smart_display_outlined),
      label: Text('Ver aulas de $topic no YouTube',
          overflow: TextOverflow.ellipsis),
    );
    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Align(alignment: Alignment.centerLeft, child: botao),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(heading, hint: 'abre numa aba nova'),
        Align(alignment: Alignment.centerLeft, child: botao),
      ],
    );
  }
}
