import 'package:appwrite/models.dart' as models;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:ppvdigital/app/capacitacao/criar_editar_transacao_page.dart';
import 'package:ppvdigital/app/capacitacao/financas/financas_controller.dart';
import 'package:ppvdigital/app/login/login_controller.dart';
import 'package:ppvdigital/models/categoria_transacao_model.dart';
import 'package:ppvdigital/models/conta_model.dart';
import 'package:ppvdigital/models/contato_model.dart';
import 'package:ppvdigital/models/divisao_transacao_model.dart';
import 'package:ppvdigital/models/transacao_model.dart';
import 'package:ppvdigital/models/transacao_recorrencia_model.dart';
import 'package:ppvdigital/repositories/financas_repository.dart';

class MockLoginControllerForPage extends LoginController {
  @override
  void init() {}

  @override
  Future<void> loadUser() async {}

  @override
  models.User? get currentUser => models.User.fromMap({
        r'$id': 'user123',
        r'$createdAt': '2026-01-01',
        r'$updatedAt': '2026-01-01',
        'name': 'Wladimir',
        'registration': '2026-01-01',
        'status': true,
        'passwordUpdate': '2026-01-01',
        'email': 'wladimir@test.com',
        'phone': '',
        'emailVerification': true,
        'phoneVerification': false,
        'mfa': false,
        'accessedAt': '2026-01-01',
        'labels': <dynamic>[],
        'prefs': <String, dynamic>{},
        'targets': <dynamic>[],
      });
}

class MockRepoForPage implements FinancasRepository {
  @override
  Future<String?> getSetting(String key) async => null;
  @override
  Future<void> saveSetting(String key, String value) async {}
  @override
  Future<bool> createConta({required String name, required double saldoInicial, required String usuarioId}) async => true;
  @override
  Future<bool> updateConta({required String id, required String name, required double saldoAtual}) async => true;
  @override
  Future<bool> deleteConta({required String id}) async => true;
  @override
  Future<bool> createCategoria({required String name, String? icone, required String hexColor, required String usuarioId}) async => true;
  @override
  Future<bool> updateCategoria({required String id, required String name, String? icone, required String hexColor}) async => true;
  @override
  Future<bool> deleteCategoria({required String id}) async => true;
  @override
  Future<ContatoModel> createContato({required String ownerId, required String nome, String? email, String? userId}) async =>
      ContatoModel(id: 'ct_1', ownerId: ownerId, nome: nome);
  @override
  Future<void> updateAccountBalance({required String contaId, required double newSaldo}) async {}
  @override
  Future<void> executeBatchOperations(List<Map<String, dynamic>> operations) async {}
  @override
  Future<List<ContaModel>> getContas({required String usuarioId, bool forceLocal = false, DateTime? lastSyncedAt}) async => [];
  @override
  Future<List<CategoriaTransacaoModel>> getCategorias({required String usuarioId, bool forceLocal = false, DateTime? lastSyncedAt}) async => [];
  @override
  Future<List<ContatoModel>> getContatos({required String usuarioId, bool forceLocal = false, DateTime? lastSyncedAt}) async => [];
  @override
  Future<List<TransacaoModel>> getTransacoes({required String usuarioId, required List<String> contaIds, DateTime? targetMonth, DateTime? beforeDate, bool forceLocal = false, DateTime? lastSyncedAt}) async => [];
  @override
  Future<Set<String>> getActiveTransacaoIdsInMonth({required String usuarioId, required List<String> contaIds, required DateTime targetMonth}) async => {};
  @override
  Future<List<TransacaoModel>> getRecurrenceSeries({required String recurrenceId}) async => [];
  @override
  Future<List<DivisaoTransacaoModel>> getDivisoes({required List<String> contatoResponsavelIds, bool forceLocal = false, DateTime? lastSyncedAt}) async => [];
  @override
  Future<String> createRecorrenciaRow({required String tipoRecorrencia, required int frequencia, int? totalParcelas, int? parcelaInicio, DateTime? fimRecorrencia}) async => 'rec_id';
  @override
  Future<void> deleteRow({required String tableId, required String rowId}) async {}
  @override
  Future<void> updateRow({required String tableId, required String rowId, required Map<String, dynamic> data}) async {}
  @override
  Stream<List<ContaModel>> watchContas({required String usuarioId}) => Stream.value([]);
  @override
  Stream<List<CategoriaTransacaoModel>> watchCategorias({required String usuarioId}) => Stream.value([]);
  @override
  Stream<List<ContatoModel>> watchContatos({required String usuarioId}) => Stream.value([]);
  @override
  Stream<List<TransacaoModel>> watchTransacoes({required String usuarioId, required List<String> contaIds, DateTime? targetMonth}) => Stream.value([]);
}

void main() {
  late MockLoginControllerForPage mockLogin;
  late FinancasController financasController;

  setUp(() {
    mockLogin = MockLoginControllerForPage();
    financasController = FinancasController(MockRepoForPage());

    GetIt.I.registerSingleton<LoginController>(mockLogin);
    GetIt.I.registerSingleton<FinancasController>(financasController);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  testWidgets('Nova transação com recorrência exibe rótulo "Parcela Inicial"', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CriarEditarTransacaoPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Clica no checkbox de repetição
    final checkboxFinder = find.byType(CheckboxListTile);
    expect(checkboxFinder, findsOneWidget);
    await tester.tap(checkboxFinder);
    await tester.pumpAndSettle();

    // Rótulo deve ser 'Parcela Inicial'
    expect(find.text('Parcela Inicial'), findsOneWidget);
    expect(find.text('Nº Parcelas'), findsOneWidget);
  });

  testWidgets('Edição de transação com (Parcela 3/3) limpa descrição e exibe rótulo "Parcela Atual: 3"', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final t3 = TransacaoModel(
      id: 't3',
      descricao: 'Curso Flutter (Parcela 3/3)',
      valor: 200.0,
      tipo: 'despesa',
      dataCompetencia: DateTime(2026, 9, 10),
      consolidada: false,
      recorrencia: TransacaoRecorrenciaModel(
        id: 'rec_orig',
        tipoRecorrencia: 'mês',
        frequencia: 1,
        totalParcelas: 3,
        parcelaInicio: 1,
      ),
      divisoes: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CriarEditarTransacaoPage(editingItem: t3),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Descrição deve ter sido limpa do sufixo
    final descField = find.widgetWithText(TextFormField, 'Curso Flutter');
    expect(descField, findsOneWidget);
    expect(find.text('Curso Flutter (Parcela 3/3)'), findsNothing);

    // Deve exibir 'Parcela Atual' com valor 3
    expect(find.text('Parcela Atual'), findsOneWidget);
    expect(find.text('3'), findsNWidgets(2)); // Parcela Atual: 3, Nº Parcelas: 3
  });

  testWidgets('Validação impede total de parcelas menor que a parcela atual na edição', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final t3 = TransacaoModel(
      id: 't3',
      descricao: 'Smartphone (Parcela 3/3)',
      valor: 500.0,
      tipo: 'despesa',
      dataCompetencia: DateTime(2026, 9, 10),
      consolidada: false,
      recorrencia: TransacaoRecorrenciaModel(
        id: 'rec_orig',
        tipoRecorrencia: 'mês',
        frequencia: 1,
        totalParcelas: 3,
        parcelaInicio: 1,
      ),
      divisoes: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CriarEditarTransacaoPage(editingItem: t3),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Localiza o campo Nº Parcelas e altera para 2 (menor que Parcela Atual: 3)
    final numParcelasField = find.widgetWithText(TextFormField, 'Nº Parcelas');
    await tester.enterText(numParcelasField, '2');
    await tester.pumpAndSettle();

    // Clica no botão Salvar
    final saveBtn = find.widgetWithText(ElevatedButton, 'Salvar');
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    // Deve exibir erro de validação
    expect(find.text('Total não pode ser menor que a parcela atual.'), findsOneWidget);
  });
}
