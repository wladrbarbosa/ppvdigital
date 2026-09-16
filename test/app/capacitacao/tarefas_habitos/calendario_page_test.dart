import 'package:appwrite/models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/calendario_page.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/historico_controller.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_habitos_controller.dart';
import 'package:ppvdigital/app/login/login_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/repositories/tarefa_habito_repository.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class DummyTarefaHabitoRepository implements TarefaHabitoRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<HistoricoItemModel>> getHistorico({
    required String usuarioId,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
  }) async => [];

  @override
  Stream<List<HistoricoItemModel>> watchHistorico({
    required String usuarioId,
  }) => const Stream.empty();

  @override
  Stream<List<TarefaHabitoModel>> watchTarefasEHabitos({
    required String usuarioId,
  }) => const Stream.empty();
}

class MockHistoricoController extends HistoricoController {
  MockHistoricoController(this.mockItems);

  final List<HistoricoItemModel> mockItems;
  String? updatedDateId;
  DateTime? updatedNewDate;

  @override
  List<HistoricoItemModel> get historicoList => mockItems;

  @override
  Future<bool> loadDocuments() async => true;

  @override
  Future<bool> updateHistoricoDate(String id, DateTime newDate) async {
    updatedDateId = id;
    updatedNewDate = newDate;
    return true;
  }

  @override
  Future<bool> deleteHistoricoItem(String documentId) async => true;
}

class MockTarefasHabitosController extends TarefasHabitosController {
  MockTarefasHabitosController() : super(DummyTarefaHabitoRepository());

  @override
  Future<List<TarefaHabitoModel>> loadDocuments({bool forceSync = false}) async => [];
}

class MockLoginController implements LoginController {
  @override
  User? get currentUser => User.fromMap({
        r'$id': 'user_1',
        'name': 'User 1',
        'email': 'user1@test.com',
        'phone': '',
        'status': true,
        'labels': [],
        'passwordUpdate': '',
        'emailVerification': true,
        'phoneVerification': false,
        'mfa': false,
        'prefs': <String, dynamic>{},
        'targets': [],
        'accessedAt': '',
        r'$createdAt': '',
        r'$updatedAt': '',
      });

  @override
  Future<void> loadUser() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall methodCall) async => '.',
  );

  late MockHistoricoController mockHistoricoController;
  late MockTarefasHabitosController mockTarefasHabitosController;
  late MockLoginController mockLoginController;

  final testHistoryItem = HistoricoItemModel(
    id: 'item_1',
    usuario: 'user_1',
    tarefasEHabitos: TarefaHabitoModel(
      id: 'task_1',
      nome: 'Ler Livro',
      tipo: 'habito',
      usuario: 'user_1',
      concluida: false,
      agendamento: null,
      tarefasHabitosQtd: [],
    ),
    createdAt: DateTime(2026, 9, 10, 8),
  );

  setUp(() {
    mockHistoricoController = MockHistoricoController([testHistoryItem]);
    mockTarefasHabitosController = MockTarefasHabitosController();
    mockLoginController = MockLoginController();

    if (Core.getIt.isRegistered<TarefaHabitoRepository>()) {
      Core.getIt.unregister<TarefaHabitoRepository>();
    }
    Core.getIt.registerSingleton<TarefaHabitoRepository>(
      DummyTarefaHabitoRepository(),
    );

    if (Core.getIt.isRegistered<HistoricoController>()) {
      Core.getIt.unregister<HistoricoController>();
    }
    Core.getIt.registerSingleton<HistoricoController>(mockHistoricoController);

    if (Core.getIt.isRegistered<TarefasHabitosController>()) {
      Core.getIt.unregister<TarefasHabitosController>();
    }
    Core.getIt.registerSingleton<TarefasHabitosController>(
      mockTarefasHabitosController,
    );

    if (Core.getIt.isRegistered<LoginController>()) {
      Core.getIt.unregister<LoginController>();
    }
    Core.getIt.registerSingleton<LoginController>(mockLoginController);
  });

  testWidgets('CalendarioPage renders SfCalendar with allowDragAndDrop enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CalendarioPage(),
      ),
    );
    await tester.pumpAndSettle();

    final calendarFinder = find.byType(SfCalendar);
    expect(calendarFinder, findsOneWidget);

    final SfCalendar calendar = tester.widget(calendarFinder);
    expect(calendar.allowDragAndDrop, isTrue);
  });

  testWidgets('tapping appointment opens details modal with options', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CalendarioPage(),
      ),
    );
    await tester.pumpAndSettle();

    final calendarFinder = find.byType(SfCalendar);
    final SfCalendar calendar = tester.widget(calendarFinder);

    // Trigger onTap with the appointment
    final appt = Appointment(
      id: 'item_1',
      startTime: DateTime(2026, 9, 10, 8),
      endTime: DateTime(2026, 9, 10, 8, 30),
      subject: 'Ler Livro',
    );

    calendar.onTap?.call(
      CalendarTapDetails(
        [appt],
        DateTime(2026, 9, 10, 8),
        CalendarElement.appointment,
        null,
      ),
    );
    await tester.pumpAndSettle();

    // Verify modal appeared with item name, type badge, and action buttons
    expect(find.text('Ler Livro'), findsWidgets);
    expect(find.text('Alterar data e horário'), findsOneWidget);
    expect(find.text('Excluir registro'), findsOneWidget);
  });

  testWidgets('onDragEnd triggers updateHistoricoDate on dropTime change', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CalendarioPage(),
      ),
    );
    await tester.pumpAndSettle();

    final calendarFinder = find.byType(SfCalendar);
    final SfCalendar calendar = tester.widget(calendarFinder);

    final appt = Appointment(
      id: 'item_1',
      startTime: DateTime(2026, 9, 10, 8),
      endTime: DateTime(2026, 9, 10, 8, 30),
      subject: 'Ler Livro',
    );

    final newDropTime = DateTime(2026, 9, 11, 14);
    calendar.onDragEnd?.call(
      AppointmentDragEndDetails(
        appt,
        null,
        null,
        newDropTime,
      ),
    );
    await tester.pumpAndSettle();

    expect(mockHistoricoController.updatedDateId, 'item_1');
    expect(mockHistoricoController.updatedNewDate, newDropTime);
  });

  testWidgets('onDragEnd preserves original hour and minute when dropped at midnight', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CalendarioPage(),
      ),
    );
    await tester.pumpAndSettle();

    final calendarFinder = find.byType(SfCalendar);
    final SfCalendar calendar = tester.widget(calendarFinder);

    final appt = Appointment(
      id: 'item_1',
      startTime: DateTime(2026, 9, 10, 8, 30),
      endTime: DateTime(2026, 9, 10, 9),
      subject: 'Ler Livro',
    );

    // Drop time at midnight (00:00) on September 15
    final midnightDropTime = DateTime(2026, 9, 15);
    calendar.onDragEnd?.call(
      AppointmentDragEndDetails(
        appt,
        null,
        null,
        midnightDropTime,
      ),
    );
    await tester.pumpAndSettle();

    expect(mockHistoricoController.updatedDateId, 'item_1');
    // Verify targetDateTime retained original 8:00 time of day from testHistoryItem
    expect(mockHistoricoController.updatedNewDate, DateTime(2026, 9, 15, 8));
  });

  testWidgets('onDragEnd resolves itemId from notes if id is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CalendarioPage(),
      ),
    );
    await tester.pumpAndSettle();

    final calendarFinder = find.byType(SfCalendar);
    final SfCalendar calendar = tester.widget(calendarFinder);

    final appt = Appointment(
      notes: 'item_1',
      startTime: DateTime(2026, 9, 10, 8),
      endTime: DateTime(2026, 9, 10, 8, 30),
      subject: 'Ler Livro',
    );

    final newDropTime = DateTime(2026, 9, 12, 10);
    calendar.onDragEnd?.call(
      AppointmentDragEndDetails(
        appt,
        null,
        null,
        newDropTime,
      ),
    );
    await tester.pumpAndSettle();

    expect(mockHistoricoController.updatedDateId, 'item_1');
    expect(mockHistoricoController.updatedNewDate, newDropTime);
  });

  testWidgets('SfCalendar configures monthViewSettings with appointment display mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CalendarioPage(),
      ),
    );
    await tester.pumpAndSettle();

    final calendarFinder = find.byType(SfCalendar);
    final SfCalendar calendar = tester.widget(calendarFinder);

    expect(
      calendar.monthViewSettings.appointmentDisplayMode,
      MonthAppointmentDisplayMode.appointment,
    );
  });
}
