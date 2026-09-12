import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ppvdigital/app/capacitacao/financas/financas_controller.dart';
import 'package:ppvdigital/app/capacitacao/financas/financas_layout.dart';
import 'package:ppvdigital/app/capacitacao/financas/widgets/exportar_transacoes_dialog.dart';
import 'package:ppvdigital/app/login/login_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/categoria_transacao_model.dart';
import 'package:ppvdigital/models/conta_model.dart';
import 'package:ppvdigital/models/contato_model.dart';
import 'package:ppvdigital/models/transacao_model.dart';
import 'package:ppvdigital/repositories/financas_repository.dart';

class MockFinancasRepoForIntegration implements FinancasRepository {
  final List<ContaModel> contas = [];
  final List<CategoriaTransacaoModel> categorias = [];
  final List<ContatoModel> contatos = [];
  final List<TransacaoModel> transacoes = [];

  @override
  Future<String?> getSetting(String key) async => null;

  @override
  Future<void> saveSetting(String key, String value) async {}

  @override
  Future<List<ContaModel>> getContas({required String usuarioId, bool forceLocal = false, DateTime? lastSyncedAt}) async => contas;

  @override
  Future<List<CategoriaTransacaoModel>> getCategorias({required String usuarioId, bool forceLocal = false, DateTime? lastSyncedAt}) async => categorias;

  @override
  Future<List<TransacaoModel>> getTransacoes({required String usuarioId, required List<String> contaIds, DateTime? targetMonth, DateTime? beforeDate, bool forceLocal = false, DateTime? lastSyncedAt}) async => transacoes;

  @override
  Stream<List<ContaModel>> watchContas({required String usuarioId, bool forceLocal = false}) =>
      Stream.value(contas);

  @override
  Stream<List<CategoriaTransacaoModel>> watchCategorias({required String usuarioId, bool forceLocal = false}) =>
      Stream.value(categorias);

  @override
  Stream<List<ContatoModel>> watchContatos({required String usuarioId, bool forceLocal = false}) =>
      Stream.value(contatos);

  @override
  Stream<List<TransacaoModel>> watchTransacoes({required String usuarioId, required List<String> contaIds, DateTime? targetMonth, DateTime? beforeDate}) =>
      Stream.value(transacoes);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLoginControllerForIntegration extends LoginController {
  @override
  void init() {}

  @override
  Future<void> loadUser() async {}

  @override
  String? get userid => 'u1';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall methodCall) async => '.',
  );

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  late MockFinancasRepoForIntegration mockRepo;
  late FinancasController controller;

  setUp(() {
    mockRepo = MockFinancasRepoForIntegration();
    controller = FinancasController(mockRepo);

    if (Core.getIt.isRegistered<FinancasController>()) {
      Core.getIt.unregister<FinancasController>();
    }
    Core.getIt.registerSingleton<FinancasController>(controller);

    if (Core.getIt.isRegistered<LoginController>()) {
      Core.getIt.unregister<LoginController>();
    }
    Core.getIt.registerSingleton<LoginController>(MockLoginControllerForIntegration());
  });

  testWidgets('FinancasLayout abre ExportarTransacoesDialog ao clicar no botão de exportar', (
    tester,
  ) async {
    final conta = ContaModel(
      id: 'c1',
      name: 'Inter',
      saldoAtual: 500,
      userId: 'u1',
    );
    final categoria = CategoriaTransacaoModel(
      id: 'cat1',
      name: 'Mercado',
      icone: 'shopping_cart',
      userId: 'u1',
    );
    final now = DateTime.now();
    final t1 = TransacaoModel(
      id: 't1',
      descricao: 'Compras da Semana',
      valor: 150.0,
      tipo: 'despesa',
      dataCompetencia: DateTime(now.year, now.month, 5),
      consolidada: true,
      conta: conta,
      categoria: categoria,
      divisoes: [],
    );

    mockRepo.contas.add(conta);
    mockRepo.categorias.add(categoria);
    mockRepo.transacoes.add(t1);

    await controller.loadDocuments(selectedMonth: now);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FinancasLayout(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Localizar botão de exportar no SeletorMesWidget
    final exportButtonFinder = find.byTooltip('Exportar transações');
    expect(exportButtonFinder, findsOneWidget);

    // Tocar no botão de exportar
    await tester.tap(exportButtonFinder);
    await tester.pumpAndSettle();

    // Verificar se o diálogo ExportarTransacoesDialog abriu e contém a transação na prévia
    expect(find.byType(ExportarTransacoesDialog), findsOneWidget);
    expect(find.text('Exportar Transações'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ExportarTransacoesDialog),
        matching: find.textContaining('Compras da Semana'),
      ),
      findsOneWidget,
    );
  });
}
