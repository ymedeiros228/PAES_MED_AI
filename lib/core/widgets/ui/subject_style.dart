// Nome `subjectVisual` (e não `subjectStyle`) para não colidir com app_theme.dart.
import 'package:flutter/material.dart';

/// Identidade visual de uma disciplina: cor forte, fundo suave e ícone.
class SubjectVisual {
  const SubjectVisual({required this.color, required this.soft, required this.icon});

  /// Cor principal (faixas, ícones, barras).
  final Color color;

  /// Versão suave para fundos de chips e cartões.
  final Color soft;
  final IconData icon;
}

String _norm(String s) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
  const to = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
  final b = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b.toString().toLowerCase();
}

SubjectVisual _mk(Color c, IconData i) =>
    SubjectVisual(color: c, soft: c.withOpacity(0.14), icon: i);

/// Cor e ícone consistentes por disciplina (acento e caixa são ignorados).
SubjectVisual subjectVisual(String? subject) {
  final s = _norm(subject ?? '');
  if (s.contains('biolog')) return _mk(const Color(0xFF2E9E5B), Icons.eco_rounded);
  if (s.contains('quimic')) return _mk(const Color(0xFF7E57C2), Icons.science_rounded);
  if (s.contains('fisic')) return _mk(const Color(0xFF2F7DE1), Icons.bolt_rounded);
  if (s.contains('matemat')) return _mk(const Color(0xFFF08A24), Icons.calculate_rounded);
  if (s.contains('portugu') || s.contains('literat') || s.contains('redac')) {
    return _mk(const Color(0xFFE05A9C), Icons.menu_book_rounded);
  }
  if (s.contains('histor')) return _mk(const Color(0xFFD99A0B), Icons.account_balance_rounded);
  if (s.contains('geograf')) return _mk(const Color(0xFF1AA5A0), Icons.public_rounded);
  if (s.contains('filosof') || s.contains('sociolog')) {
    return _mk(const Color(0xFF4F5BD5), Icons.psychology_alt_rounded);
  }
  if (s.contains('ingles') || s.contains('espanhol') || s.contains('lingua estrang')) {
    return _mk(const Color(0xFFD64545), Icons.translate_rounded);
  }
  return _mk(const Color(0xFF6B7A90), Icons.school_rounded);
}
