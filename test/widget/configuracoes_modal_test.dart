import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/app/home/widgets/configuracoes_modal_widget.dart';
import 'package:ppvdigital/controllers/theme_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/design_system/design_system.dart';
import 'package:ppvdigital/models/local/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConfiguracoesModalWidget Tests', () {
    late AppDatabase db;
    late ThemeController themeController;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      themeController = ThemeController(db);
      if (!Core.getIt.isRegistered<ThemeController>()) {
        Core.getIt.registerSingleton<ThemeController>(themeController);
      }
    });

    tearDown(() async {
      await db.close();
      await Core.getIt.reset();
    });

    testWidgets('Exibe títulos, 3 modos e as 10 paletas pastéis do Design System', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfiguracoesModalWidget(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Modo de Exibição'), findsOneWidget);
      expect(find.text('Paleta Pastel do Design System'), findsOneWidget);

      // Verifica os 3 botões de modo
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Escuro'), findsOneWidget);
      expect(find.text('Sistema'), findsOneWidget);

      // Verifica que todas as 10 paletas estão visíveis
      for (final palette in AppThemePalette.values) {
        expect(find.text(palette.label), findsOneWidget);
      }
    });

    testWidgets('Alterna ThemeMode ao interagir com o SegmentedButton', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfiguracoesModalWidget(),
          ),
        ),
      );
      await tester.pump();

      expect(themeController.themeMode, ThemeMode.system);

      // Clica em 'Escuro'
      await tester.tap(find.text('Escuro'));
      await tester.pump();
      expect(themeController.themeMode, ThemeMode.dark);

      // Clica em 'Claro'
      await tester.tap(find.text('Claro'));
      await tester.pump();
      expect(themeController.themeMode, ThemeMode.light);

      // Clica em 'Sistema'
      await tester.tap(find.text('Sistema'));
      await tester.pump();
      expect(themeController.themeMode, ThemeMode.system);
    });

    testWidgets('Alterna AppThemePalette ao tocar em cada cartão de cor', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfiguracoesModalWidget(),
          ),
        ),
      );
      await tester.pump();

      expect(themeController.palette, AppThemePalette.menta);

      // Toca em Lavanda Suave
      await tester.tap(find.text('Lavanda Suave'));
      await tester.pump();
      expect(themeController.palette, AppThemePalette.lavanda);

      // Toca em Pêssego Pastel
      await tester.tap(find.text('Pêssego Pastel'));
      await tester.pump();
      expect(themeController.palette, AppThemePalette.pessego);

      // Toca em Céu Sereno
      await tester.tap(find.text('Céu Sereno'));
      await tester.pump();
      expect(themeController.palette, AppThemePalette.ceuSereno);

      // Toca em Rosa Blush
      await tester.tap(find.text('Rosa Blush'));
      await tester.pump();
      expect(themeController.palette, AppThemePalette.rosaBlush);
    });

    testWidgets('ConfiguracoesModalWidget.show abre o modal bottom sheet e fecha ao tocar fechar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ConfiguracoesModalWidget.show(context),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ConfiguracoesModalWidget), findsNothing);

      // Abre o modal
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.byType(ConfiguracoesModalWidget), findsOneWidget);

      // Fecha pelo botão de fechar
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();

      expect(find.byType(ConfiguracoesModalWidget), findsNothing);
    });
  });
}
