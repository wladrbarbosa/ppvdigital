import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:ppvdigital/app/login/login_controller.dart';
import 'package:ppvdigital/routes.g.dart';
import 'package:routefly/routefly.dart';

class MockLoginController extends LoginController {
  bool signOutCalled = false;

  @override
  void init() {}

  @override
  Future<void> loadUser() async {}

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}

void main() {
  late MockLoginController mockLoginController;

  setUp(() {
    mockLoginController = MockLoginController();
    GetIt.I.registerSingleton<LoginController>(mockLoginController);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  testWidgets('Clica no botão de logout e exibe diálogo de confirmação', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: Routefly.routerConfig(
          routes: routes,
          initialPath: routePaths.home,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Clica no ícone de logout
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar Saída'), findsOneWidget);
    expect(find.text('Deseja realmente sair da sua conta?'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Sair'), findsOneWidget);
  });

  testWidgets('Ao cancelar no diálogo de logout, não executa signOut', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: Routefly.routerConfig(
          routes: routes,
          initialPath: routePaths.home,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    // Clica em Cancelar
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    // O diálogo fecha e signOut não é chamado
    expect(find.text('Confirmar Saída'), findsNothing);
    expect(mockLoginController.signOutCalled, isFalse);
  });

  testWidgets('Ao confirmar no diálogo de logout, executa signOut', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: Routefly.routerConfig(
          routes: routes,
          initialPath: routePaths.home,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    // Clica em Sair
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(mockLoginController.signOutCalled, isTrue);
  });
}
