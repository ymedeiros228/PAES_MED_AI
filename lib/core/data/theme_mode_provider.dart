import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// v2: o padrão passou a ser o escuro (o aluno estuda no escuro).
const _themeModeKey = 'theme_mode_v2';
const _themeModeKeyV1 = 'theme_mode_v1';

/// dark (padrão) | light | system
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    // Quem escolheu "claro" na versão antiga continua no claro; o resto vai ao escuro.
    final raw = p.getString(_themeModeKey) ??
        (p.getString(_themeModeKeyV1) == 'light' ? 'light' : 'dark');
    state = switch (raw) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    final p = await SharedPreferences.getInstance();
    final raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await p.setString(_themeModeKey, raw);
    state = mode;
  }

  /// Botão rápido do menu: alterna entre escuro e claro.
  Future<void> toggle(Brightness atual) =>
      setMode(atual == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
}
