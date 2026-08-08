import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/dashboard_page.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_habitos_controller.dart';
import 'package:ppvdigital/app/login/login_controller.dart';
import 'package:ppvdigital/models/categorias_tarefas_habitos_model.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:ppvdigital/models/local/app_database.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_qtd_model.dart';
import 'package:ppvdigital/repositories/tarefa_habito_repository.dart';

class DummyRepo implements TarefaHabitoRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  
  @override
  Future<List<HistoricoItemModel>> getHistorico({String? usuarioId, bool forceLocal = false, DateTime? lastSyncedAt}) async {
    return [];
  }
}

class MockTarefasHabitosController extends TarefasHabitosController {
  MockTarefasHabitosController() : super(DummyRepo());

  @override
  Future<void> loadConfiguredColors() async {}

  @override
  List<TarefaHabitoModel> get tarefasHabitosList => [
    TarefaHabitoModel(
      id: '1',
      nome: 'Tarefa Teste',
      tipo: 'tarefa',
      usuario: 'user_123',
      concluida: false,
      agendamento: DateTime.now(),
      duration: 30,
      tarefasHabitosQtd: [
        TarefaHabitoQtdModel(
          id: 'q1',
          metaVezes: 1,
          usuario: 'user_123',
          valor: 0,
          reiniciaEmQtd: 1,
          reiniciaEmTipo: 'dias',
          vezesPraticado: 0,
          createdAt: DateTime.now(),
        ),
      ],
    ),
    TarefaHabitoModel(
      id: '2',
      nome: 'Habito Teste',
      tipo: 'habito',
      usuario: 'user_123',
      concluida: false,
      agendamento: DateTime.now(),
      duration: 15,
      tarefasHabitosQtd: [
        TarefaHabitoQtdModel(
          id: 'q2',
          metaVezes: 2,
          usuario: 'user_123',
          categoriasTarefasHabitos: CategoriasTarefasHabitosModel(
            id: 'cat1',
            nome: 'Saúde',
            cor: Colors.green,
            usuario: 'user_123',
          ),
          valor: 0,
          reiniciaEmQtd: 1,
          reiniciaEmTipo: 'dias',
          vezesPraticado: 1,
          createdAt: DateTime.now(),
        ),
      ],
    ),
  ];
  
}

class MockLoginController extends LoginController {
  @override
  Future<void> init() async {}
  @override
  Future<void> loadUser() async {}

  @override
  String? get userid => 'user_123';
}

void main() {
  setUp(() {
    GetIt.I.registerSingleton<AppDatabase>(AppDatabase(NativeDatabase.memory()));
    GetIt.I.registerSingleton<TarefaHabitoRepository>(DummyRepo());
    GetIt.I.registerSingleton<TarefasHabitosController>(MockTarefasHabitosController());
    GetIt.I.registerSingleton<LoginController>(MockLoginController());
  });

  tearDown(() {
    GetIt.I.reset();
  });

  testWidgets('DashboardPage exibe os cards e gráficos corretamente', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardPage()));
    await tester.pumpAndSettle();
    
    debugDumpApp();

    // Verifica se os textos de título dos gráficos aparecem
    expect(find.text('Taxa de Conclusão (7 dias)'), findsOneWidget);
    expect(find.textContaining('Tempo de Comprometimento'), findsOneWidget);
    expect(find.textContaining('Meta por Categoria'), findsOneWidget);
    expect(find.textContaining('Atenção por Categoria'), findsOneWidget);

    // Verifica se os gráficos em si estão presentes
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.byType(PieChart), findsOneWidget); // Hábitos vs Tarefas
    expect(find.byType(LinearProgressIndicator), findsWidgets); // Progress bars por Categoria
    expect(find.byType(LineChart), findsOneWidget);
  });
}
