import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/controllers/theme_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/design_system/design_system.dart';
import 'package:ppvdigital/models/local/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeController Unit Tests', () {
    late AppDatabase db;
    late ThemeController controller;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      controller = ThemeController(db);
    });

    tearDown(() async {
      await db.close();
      await Core.getIt.reset();
    });

    test('Valores padrão iniciais são ThemeMode.system e AppThemePalette.menta', () {
      expect(controller.themeMode, ThemeMode.system);
      expect(controller.palette, AppThemePalette.menta);
    });

    test('setThemeMode atualiza o observable reativo e persiste no SQLite', () async {
      await controller.setThemeMode(ThemeMode.dark);
      expect(controller.themeMode, ThemeMode.dark);
      expect(await db.getSetting(ThemeController.keyThemeMode), 'dark');

      await controller.setThemeMode(ThemeMode.light);
      expect(controller.themeMode, ThemeMode.light);
      expect(await db.getSetting(ThemeController.keyThemeMode), 'light');

      await controller.setThemeMode(ThemeMode.system);
      expect(controller.themeMode, ThemeMode.system);
      expect(await db.getSetting(ThemeController.keyThemeMode), 'system');
    });

    test('setPalette atualiza o observable reativo e persiste no SQLite', () async {
      await controller.setPalette(AppThemePalette.lavanda);
      expect(controller.palette, AppThemePalette.lavanda);
      expect(await db.getSetting(ThemeController.keyThemePalette), 'lavanda');

      await controller.setPalette(AppThemePalette.pessego);
      expect(controller.palette, AppThemePalette.pessego);
      expect(await db.getSetting(ThemeController.keyThemePalette), 'pessego');

      await controller.setPalette(AppThemePalette.ceuSereno);
      expect(controller.palette, AppThemePalette.ceuSereno);
      expect(await db.getSetting(ThemeController.keyThemePalette), 'ceuSereno');
    });

    test('loadSettings restaura as configurações salvas no SQLite', () async {
      await db.setSetting(ThemeController.keyThemeMode, 'dark');
      await db.setSetting(ThemeController.keyThemePalette, 'ametista');

      final freshController = ThemeController(db);
      expect(freshController.themeMode, ThemeMode.system);
      expect(freshController.palette, AppThemePalette.menta);

      await freshController.loadSettings();
      expect(freshController.themeMode, ThemeMode.dark);
      expect(freshController.palette, AppThemePalette.ametista);
    });

    test('loadSettings lida com dados corrompidos ou desconhecidos com fallback seguro', () async {
      await db.setSetting(ThemeController.keyThemeMode, 'invalid_mode');
      await db.setSetting(ThemeController.keyThemePalette, 'unknown_palette');

      final freshController = ThemeController(db);
      await freshController.loadSettings();

      expect(freshController.themeMode, ThemeMode.system);
      expect(freshController.palette, AppThemePalette.menta);
    });

    test('Core.initialize registra e expõe ThemeController corretamente', () async {
      Core.initialize(db);
      expect(Core.getIt.isRegistered<ThemeController>(), isTrue);
      expect(Core.themeController, isNotNull);
      expect(Core.themeController.themeMode, ThemeMode.system);
      expect(Core.themeController.palette, AppThemePalette.menta);
    });
  });
}
