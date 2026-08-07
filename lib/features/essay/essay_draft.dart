import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Rascunho local de redação (tema + texto), persistido em SharedPreferences
/// para sobreviver a reloads/reaberturas. Não é enviado à banca.
class EssayDraft {
  const EssayDraft({required this.theme, required this.text});

  final String theme;
  final String text;

  Map<String, dynamic> toJson() => {'theme': theme, 'text': text};

  factory EssayDraft.fromJson(Map<String, dynamic> json) => EssayDraft(
        theme: json['theme']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
      );

  bool get isEmpty => text.trim().isEmpty;

  @override
  bool operator ==(Object other) =>
      other is EssayDraft && other.theme == theme && other.text == text;

  @override
  int get hashCode => Object.hash(theme, text);
}

const _essayDraftKey = 'essay_draft_v1';

/// Salva o rascunho. Se o texto estiver vazio, limpa o rascunho salvo.
Future<void> saveEssayDraft(EssayDraft draft) async {
  final prefs = await SharedPreferences.getInstance();
  if (draft.isEmpty) {
    await prefs.remove(_essayDraftKey);
    return;
  }
  await prefs.setString(_essayDraftKey, jsonEncode(draft.toJson()));
}

/// Carrega o rascunho salvo, ou null se não houver / for inválido.
Future<EssayDraft?> loadEssayDraft() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_essayDraftKey);
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final draft = EssayDraft.fromJson(Map<String, dynamic>.from(decoded));
    return draft.isEmpty ? null : draft;
  } catch (_) {
    return null;
  }
}

/// Remove o rascunho salvo.
Future<void> clearEssayDraft() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_essayDraftKey);
}
