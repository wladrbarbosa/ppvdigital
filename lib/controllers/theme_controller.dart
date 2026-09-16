import 'package:material_ui/material_ui.dart';
import 'package:mobx/mobx.dart' as mobx;
import 'package:ppvdigital/design_system/design_system.dart';
import 'package:ppvdigital/models/local/app_database.dart';

/// Controller reativo manual em MobX para gerenciar o modo de tema (claro/escuro/sistema)
/// e a paleta do Design System, persistindo as preferências no SQLite via AppDatabase.
class ThemeController {
  ThemeController(this._database);

  final AppDatabase _database;

  static const String keyThemeMode = 'theme_mode';
  static const String keyThemePalette = 'theme_palette';

  final mobx.Observable<ThemeMode> _themeMode =
      mobx.Observable<ThemeMode>(ThemeMode.system, name: 'themeMode');
  ThemeMode get themeMode => _themeMode.value;

  final mobx.Observable<AppThemePalette> _palette =
      mobx.Observable<AppThemePalette>(AppThemePalette.menta, name: 'palette');
  AppThemePalette get palette => _palette.value;

  /// Carrega as preferências salvas no SQLite.
  Future<void> loadSettings() async {
    try {
      final savedMode = await _database.getSetting(keyThemeMode);
      final savedPalette = await _database.getSetting(keyThemePalette);

      mobx.runInAction(() {
        if (savedMode != null && savedMode.isNotEmpty) {
          _themeMode.value = switch (savedMode.toLowerCase().trim()) {
            'light' => ThemeMode.light,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          };
        }
        if (savedPalette != null && savedPalette.isNotEmpty) {
          _palette.value = AppThemePalette.fromString(savedPalette);
        }
      });
    } catch (_) {
      // Falhas de leitura mantêm os padrões seguros (system e menta)
    }
  }

  /// Altera o modo de tema e persiste a escolha no banco local.
  Future<void> setThemeMode(ThemeMode mode) async {
    mobx.runInAction(() {
      _themeMode.value = mode;
    });
    try {
      await _database.setSetting(keyThemeMode, mode.name);
    } catch (_) {
      // Ignora erro de gravação se SQLite estiver ocupado
    }
  }

  /// Altera a paleta de cores e persiste a escolha no banco local.
  Future<void> setPalette(AppThemePalette newPalette) async {
    mobx.runInAction(() {
      _palette.value = newPalette;
    });
    try {
      await _database.setSetting(keyThemePalette, newPalette.id);
    } catch (_) {
      // Ignora erro de gravação se SQLite estiver ocupado
    }
  }
}
