import 'package:flutter/material.dart';

import 'study_material_pack.dart';
import 'ui_kit.dart';

/// Reforço unificado — pack banca/vídeo/leitura/busca (não é edital/banca UEMA).
class MediaReinforcement extends StatelessWidget {
  const MediaReinforcement({
    required this.subject,
    required this.topic,
    this.compact = false,
    this.heading = 'Reforço (vídeo · leitura)',
    super.key,
  });

  final String subject;
  final String topic;
  final bool compact;
  final String heading;

  @override
  Widget build(BuildContext context) {
    if (subject.isEmpty || topic.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact)
          SectionLabel(heading, hint: 'escolha o material · não é banca UEMA'),
        StudyMaterialPack(subject: subject, topic: topic, compact: compact),
      ],
    );
  }
}
