import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/design_system/design_system.dart';
import 'package:ppvdigital/models/local/app_database.dart';

void main() {
  group('AppThemePalette Unit Tests', () {
    test('Possui exatamente as 10 paletas pastéis do Design System', () {
      expect(AppThemePalette.values.length, 10);
      expect(AppThemePalette.values, contains(AppThemePalette.menta));
      expect(AppThemePalette.values, contains(AppThemePalette.lavanda));
      expect(AppThemePalette.values, contains(AppThemePalette.pessego));
      expect(AppThemePalette.values, contains(AppThemePalette.ceuSereno));
      expect(AppThemePalette.values, contains(AppThemePalette.salvia));
      expect(AppThemePalette.values, contains(AppThemePalette.rosaBlush));
      expect(AppThemePalette.values, contains(AppThemePalette.turquesa));
      expect(AppThemePalette.values, contains(AppThemePalette.ametista));
      expect(AppThemePalette.values, contains(AppThemePalette.baunilha));
      expect(AppThemePalette.values, contains(AppThemePalette.areia));
    });

    test('fromString resolve corretamente por ID e por nome com tolerância a caixa', () {
      expect(AppThemePalette.fromString('menta'), AppThemePalette.menta);
      expect(AppThemePalette.fromString('LAVANDA'), AppThemePalette.lavanda);
      expect(AppThemePalette.fromString('pessego'), AppThemePalette.pessego);
      expect(AppThemePalette.fromString('ceuSereno'), AppThemePalette.ceuSereno);
      expect(AppThemePalette.fromString('  salvia  '), AppThemePalette.salvia);
      expect(AppThemePalette.fromString('ROSAblush'), AppThemePalette.rosaBlush);
      expect(AppThemePalette.fromString('turquesa'), AppThemePalette.turquesa);
      expect(AppThemePalette.fromString('ametista'), AppThemePalette.ametista);
      expect(AppThemePalette.fromString('baunilha'), AppThemePalette.baunilha);
      expect(AppThemePalette.fromString('areia'), AppThemePalette.areia);
    });

    test('fromString faz fallback seguro para menta em valores nulos ou desconhecidos', () {
      expect(AppThemePalette.fromString(null), AppThemePalette.menta);
      expect(AppThemePalette.fromString(''), AppThemePalette.menta);
      expect(AppThemePalette.fromString('cor_inexistente'), AppThemePalette.menta);
    });

    test('Todas as paletas possuem cores válidas para light e dark', () {
      for (final palette in AppThemePalette.values) {
        expect(palette.id.isNotEmpty, isTrue);
        expect(palette.label.isNotEmpty, isTrue);
        expect(palette.primaryLight.a, greaterThan(0));
        expect(palette.primaryDark.a, greaterThan(0));
        expect(palette.primaryContainerLight.a, greaterThan(0));
        expect(palette.primaryContainerDark.a, greaterThan(0));
        expect(palette.onPrimaryLight, Colors.white);
        expect(palette.onPrimaryDark, isNotNull);
      }
    });
  });

  group('AppDatabase Theme Persistence & clearAllUserData', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('clearAllUserData limpa dados operacionais mas preserva theme_mode e theme_palette', () async {
      // 1. Inserir configurações normais e de tema
      await db.setSetting('last_sync', '2026-09-11T00:00:00Z');
      await db.setSetting('user_profile_cache', '{"name":"Tester"}');
      await db.setSetting('theme_mode', 'dark');
      await db.setSetting('theme_palette', 'lavanda');

      expect(await db.getSetting('last_sync'), isNotNull);
      expect(await db.getSetting('theme_mode'), 'dark');
      expect(await db.getSetting('theme_palette'), 'lavanda');

      // 2. Executar limpeza total de logout
      await db.clearAllUserData();

      // 3. Verificar que preferências de tema sobreviveram
      expect(await db.getSetting('theme_mode'), 'dark');
      expect(await db.getSetting('theme_palette'), 'lavanda');

      // 4. Verificar que dados operacionais do usuário foram limpos
      expect(await db.getSetting('last_sync'), isNull);
      expect(await db.getSetting('user_profile_cache'), isNull);
    });
  });
}
