import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ppvdigital/app/home/home_page.dart';
import 'package:ppvdigital/app/home/widgets/configuracoes_modal_widget.dart';
import 'package:ppvdigital/controllers/theme_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/local/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomePage Settings Integration Tests', () {
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

    testWidgets('HomePage possui botão de configurações na AppBar que abre o ConfiguracoesModalWidget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pump();

      // Verifica presença do botão de configurações
      final settingsButton = find.byTooltip('Configurações');
      expect(settingsButton, findsOneWidget);

      // Abre o modal
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      // Confirma que o modal foi aberto na tela
      expect(find.byType(ConfiguracoesModalWidget), findsOneWidget);
    });

    testWidgets('HomePage exibe os cartões de Hábitos e Tarefas e Finanças', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pump();

      expect(find.text('Seapruma'), findsOneWidget);
      expect(find.text('Início'), findsOneWidget);
      expect(find.text('Hábitos e Tarefas'), findsOneWidget);
      expect(find.text('Finanças'), findsOneWidget);
      expect(find.byTooltip('Sair'), findsOneWidget);
    });
  });
}
