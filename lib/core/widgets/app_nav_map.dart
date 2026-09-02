import 'package:flutter/material.dart';

import '../widgets/ui/surface_panel.dart';

/// Mapa compacto do app — loop diário vs ferramentas.
class AppNavMapPanel extends StatelessWidget {
  const AppNavMapPanel({super.key});

  static const _daily = [
    (Icons.home_rounded, 'Hoje', 'Plano do dia, checklist e começar sessão'),
    (Icons.school_rounded, 'Estudar', 'Sessão guiada com teoria e questões'),
    (Icons.replay_rounded, 'Fila', 'Playlist do dia: sessão, cards, redação'),
    (Icons.trending_up_rounded, 'Progresso', 'Ritmo, conquistas e evolução'),
  ];

  static const _library = [
    (Icons.menu_book_rounded, 'Biblioteca', 'Provas UEMA e PDFs de estudo'),
    (Icons.assignment_rounded, 'Simulados', 'Blocos cronometrados como na prova'),
    (Icons.edit_note_rounded, 'Redação', 'Escrever, corrigir e treinar eixos'),
    (Icons.auto_awesome_rounded, 'Tutor', 'Tire dúvidas citando seu material'),
  ];

  static const _tools = [
    (Icons.calendar_month_outlined, 'Plano', 'Cronograma até a data da prova'),
    (Icons.insights_rounded, 'Domínio', 'Mapa de matérias e lacunas'),
    (Icons.settings_rounded, 'Ajustes', 'Prova, foco, tema e chaves de IA'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SurfacePanel(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        initiallyExpanded: false,
        leading: Icon(Icons.map_outlined, color: cs.primary),
        title: const Text('Mapa do app', style: TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          'Onde fica cada parte do estudo',
          style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.6)),
        ),
        children: [
          _section(context, 'Loop diário', _daily),
          const SizedBox(height: 12),
          _section(context, 'Conteúdo', _library),
          const SizedBox(height: 12),
          _section(context, 'Ferramentas', _tools),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    List<(IconData, String, String)> items,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: cs.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 8),
        for (final (icon, name, desc) in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: cs.primary.withOpacity(0.85)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        desc,
                        style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.65), height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
