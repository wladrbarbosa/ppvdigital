import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/app/login/login_controller.dart';
import 'package:ppvdigital/controllers/theme_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/design_system/design_system.dart';
import 'package:ppvdigital/models/local/app_database.dart';
import 'package:ppvdigital/root_app_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RootAppWidget Reactive Theme Tests', () {
    late AppDatabase db;
    late ThemeController themeController;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      themeController = ThemeController(db);
      if (!Core.getIt.isRegistered<ThemeController>()) {
        Core.getIt.registerSingleton<ThemeController>(themeController);
      }
      if (!Core.getIt.isRegistered<LoginController>()) {
        Core.getIt.registerSingleton<LoginController>(LoginController());
      }
    });

    tearDown(() async {
      await db.close();
      await Core.getIt.reset();
    });

    testWidgets('RootAppWidget reage a mudanças de ThemeMode e AppThemePalette', (tester) async {
      await tester.pumpWidget(const RootAppWidget());
      await tester.pump(const Duration(milliseconds: 100));

      MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.system);
      expect(app.theme?.colorScheme.primary, AppThemePalette.menta.primaryLight);

      // Alterna modo para escuro
      await themeController.setThemeMode(ThemeMode.dark);
      await tester.pump(const Duration(milliseconds: 100));

      app = tester.widget(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);

      // Alterna paleta para Lavanda Suave
      await themeController.setPalette(AppThemePalette.lavanda);
      await tester.pump(const Duration(milliseconds: 100));

      app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.colorScheme.primary, AppThemePalette.lavanda.primaryLight);
      expect(app.darkTheme?.colorScheme.primary, AppThemePalette.lavanda.primaryDark);

      // Alterna paleta para Pêssego Pastel
      await themeController.setPalette(AppThemePalette.pessego);
      await tester.pump(const Duration(milliseconds: 100));

      app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.colorScheme.primary, AppThemePalette.pessego.primaryLight);
      expect(app.darkTheme?.colorScheme.primary, AppThemePalette.pessego.primaryDark);
    });
  });
}
