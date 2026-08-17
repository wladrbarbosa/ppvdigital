import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:ppvdigital/app/login/login_controller.dart';
import 'package:ppvdigital/app/login/login_page.dart';

class MockLoginController extends LoginController {
  bool createUserCalled = false;
  String? createdEmail;
  String? createdPassword;
  String? createdName;

  bool loginCalled = false;
  String? loginEmail;
  String? loginPassword;

  @override
  void init() {}

  @override
  Future<void> loadUser() async {}

  @override
  Future<User> createUser(String email, String password, String name) async {
    createUserCalled = true;
    createdEmail = email;
    createdPassword = password;
    createdName = name;
    return User(
      $id: 'mock_user_id',
      $createdAt: '',
      $updatedAt: '',
      name: name,
      registration: '',
      status: true,
      labels: [],
      passwordUpdate: '',
      email: email,
      phone: '',
      emailVerification: false,
      phoneVerification: false,
      mfa: false,
      prefs: Preferences(data: {}),
      targets: [],
      accessedAt: '',
    );
  }

  @override
  Future<Session> createEmailPasswordSession(
    String email,
    String password,
  ) async {
    loginCalled = true;
    loginEmail = email;
    loginPassword = password;
    return Session(
      $id: 'mock_session_id',
      $createdAt: '',
      $updatedAt: '',
      userId: 'mock_user_id',
      expire: '',
      provider: 'email',
      providerUid: '',
      providerAccessToken: '',
      providerAccessTokenExpiry: '',
      providerRefreshToken: '',
      ip: '',
      osCode: '',
      osName: '',
      osVersion: '',
      clientType: '',
      clientCode: '',
      clientName: '',
      clientVersion: '',
      clientEngine: '',
      clientEngineVersion: '',
      deviceName: '',
      deviceBrand: '',
      deviceModel: '',
      countryCode: '',
      countryName: '',
      current: true,
      factors: [],
      secret: '',
      mfaUpdatedAt: '',
    );
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

  testWidgets('Valida campos vazios no login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    final entrarButton = find.widgetWithText(ElevatedButton, 'Entrar');
    await tester.ensureVisible(entrarButton);
    await tester.tap(entrarButton);
    await tester.pumpAndSettle();

    expect(find.text('Por favor, informe seu email.'), findsOneWidget);
    expect(mockLoginController.loginCalled, isFalse);
  });

  testWidgets('Exibe aba de cadastro com campos Nome, Email, Senha e Confirmar Senha', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    // Clica na aba "Cadastrar"
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Nome'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Senha'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Confirmar Senha'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Cadastrar'), findsOneWidget);
  });

  testWidgets('Valida que senhas devem coincidir no cadastro', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    final nomeFinder = find.widgetWithText(TextField, 'Nome');
    final emailFinder = find.widgetWithText(TextField, 'Email');
    final senhaFinder = find.widgetWithText(TextField, 'Senha');
    final confirmarSenhaFinder = find.widgetWithText(TextField, 'Confirmar Senha');

    await tester.enterText(nomeFinder, 'Wladimir');
    await tester.enterText(emailFinder, 'wlad@example.com');
    await tester.enterText(senhaFinder, '12345678');
    await tester.enterText(confirmarSenhaFinder, '87654321');

    final cadastrarButton = find.widgetWithText(ElevatedButton, 'Cadastrar');
    await tester.ensureVisible(cadastrarButton);
    await tester.tap(cadastrarButton);
    await tester.pumpAndSettle();

    expect(find.text('As senhas não coincidem.'), findsOneWidget);
    expect(mockLoginController.createUserCalled, isFalse);
  });

  testWidgets('Valida tamanho mínimo da senha no cadastro', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    final nomeFinder = find.widgetWithText(TextField, 'Nome');
    final emailFinder = find.widgetWithText(TextField, 'Email');
    final senhaFinder = find.widgetWithText(TextField, 'Senha');
    final confirmarSenhaFinder = find.widgetWithText(TextField, 'Confirmar Senha');

    await tester.enterText(nomeFinder, 'Wladimir');
    await tester.enterText(emailFinder, 'wlad@example.com');
    await tester.enterText(senhaFinder, '12345');
    await tester.enterText(confirmarSenhaFinder, '12345');

    final cadastrarButton = find.widgetWithText(ElevatedButton, 'Cadastrar');
    await tester.ensureVisible(cadastrarButton);
    await tester.tap(cadastrarButton);
    await tester.pumpAndSettle();

    expect(find.text('A senha deve ter no mínimo 8 caracteres.'), findsOneWidget);
    expect(mockLoginController.createUserCalled, isFalse);
  });

  testWidgets('Valida campos vazios no cadastro', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    final cadastrarButton = find.widgetWithText(ElevatedButton, 'Cadastrar');
    await tester.ensureVisible(cadastrarButton);
    await tester.tap(cadastrarButton);
    await tester.pumpAndSettle();

    expect(find.text('Por favor, informe seu nome.'), findsOneWidget);
    expect(mockLoginController.createUserCalled, isFalse);
  });

  testWidgets('Cadastra com sucesso quando dados e confirmação de senha são válidos', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    final nomeFinder = find.widgetWithText(TextField, 'Nome');
    final emailFinder = find.widgetWithText(TextField, 'Email');
    final senhaFinder = find.widgetWithText(TextField, 'Senha');
    final confirmarSenhaFinder = find.widgetWithText(TextField, 'Confirmar Senha');

    await tester.enterText(nomeFinder, 'Wladimir');
    await tester.enterText(emailFinder, 'wlad@example.com');
    await tester.enterText(senhaFinder, 'minhasenha123');
    await tester.enterText(confirmarSenhaFinder, 'minhasenha123');

    final cadastrarButton = find.widgetWithText(ElevatedButton, 'Cadastrar');
    await tester.ensureVisible(cadastrarButton);
    await tester.tap(cadastrarButton);
    await tester.pumpAndSettle();

    expect(mockLoginController.createUserCalled, isTrue);
    expect(mockLoginController.createdEmail, 'wlad@example.com');
    expect(mockLoginController.createdPassword, 'minhasenha123');
    expect(mockLoginController.createdName, 'Wladimir');
    expect(
      find.text('Conta cadastrada com sucesso! Faça login para entrar.'),
      findsOneWidget,
    );
  });
}
