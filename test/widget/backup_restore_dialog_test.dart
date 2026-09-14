import 'package:appwrite/appwrite.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:intl/date_symbol_data_local.dart';
import 'package:ppvdigital/app/home/widgets/backup_restore_dialog.dart';
import 'package:ppvdigital/app/login/login_controller.dart';
import 'package:ppvdigital/controllers/backup_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/backup/backup_payload_model.dart';
import 'package:ppvdigital/models/local/app_database.dart';
import 'package:ppvdigital/services/backup/backup_service.dart';
import 'package:ppvdigital/services/backup/google_drive_backup_service.dart';
import 'package:ppvdigital/services/backup/restore_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  group('BackupRestoreDialog Widget Tests', () {
    late AppDatabase db;
    late BackupController backupController;
    late FakeGoogleDriveBackupService fakeDriveService;
    late FakeBackupService fakeBackupService;
    late FakeRestoreService fakeRestoreService;
    late FakeLoginController fakeLoginController;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      fakeBackupService = FakeBackupService();
      fakeRestoreService = FakeRestoreService();
      fakeDriveService = FakeGoogleDriveBackupService(isSignedInValue: true);
      fakeLoginController = FakeLoginController();

      backupController = BackupController(
        backupService: fakeBackupService,
        restoreService: fakeRestoreService,
        googleDriveService: fakeDriveService,
        database: db,
        loginController: fakeLoginController,
      );

      if (!Core.getIt.isRegistered<BackupController>()) {
        Core.getIt.registerSingleton<BackupController>(backupController);
      }
      if (!Core.getIt.isRegistered<LoginController>()) {
        Core.getIt.registerSingleton<LoginController>(fakeLoginController);
      }
    });

    tearDown(() async {
      await db.close();
      await Core.getIt.reset();
    });

    testWidgets('showProgressDialog exibe barra e mensagem de progresso', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  BackupRestoreDialog.showProgressDialog(
                    context: context,
                    title: 'Restaurando Teste...',
                    controller: backupController,
                  );
                },
                child: const Text('Abrir Progresso'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Progresso'));
      await tester.pump();

      expect(find.text('Restaurando Teste...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Por favor, aguarde e não feche o aplicativo.'), findsOneWidget);
    });

    testWidgets('showRestoreConfirmationDialog exibe contadores e permite alternar modo', (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final payload = BackupPayloadModel(
        exportedAt: DateTime(2026, 9, 14, 10, 30),
        userId: 'user_123',
        userEmail: 'outro_usuario@teste.com',
        data: {
          'contas': [
            {r'$id': 'c1', 'nome': 'Conta 1'}
          ],
          'transacoes': [
            {r'$id': 't1', 'descricao': 'Transacao 1'},
            {r'$id': 't2', 'descricao': 'Transacao 2'},
          ],
          'tarefasEHabitos': [
            {r'$id': 'th1', 'titulo': 'Tarefa 1'}
          ],
          'historicoTarefasHabitos': [],
          'categoriasTransacoes': [
            {r'$id': 'cat1', 'nome': 'Alimentacao'}
          ],
          'categoriasTarefasHabitos': [],
          'contatos': [],
        },
      );

      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await BackupRestoreDialog.showRestoreConfirmationDialog(
                    context: context,
                    payload: payload,
                  );
                },
                child: const Text('Confirmar'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmar Restauração'), findsOneWidget);
      // Aviso de usuário diferente
      expect(find.textContaining('outro_usuario@teste.com'), findsOneWidget);
      // Entidades
      expect(find.text('Transações'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
      expect(find.text('Contas Financeiras'), findsOneWidget);

      // Alterna para substituição limpa
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Confirma
      await tester.tap(find.text('Restaurar Agora'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('showDriveBackupsDialog exibe lista e permite selecionar para restauração', (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      drive.File? selectedItem;
      bool? cleanFirstResult;

      final item = drive.File(
        id: 'file_99',
        name: 'backup_ppvdigital_2026-09-14.json',
        createdTime: DateTime(2026, 9, 14, 12),
        size: '2048',
      );

      fakeDriveService.driveFiles.add(item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  BackupRestoreDialog.showDriveBackupsDialog(
                    context: context,
                    controller: backupController,
                    onSelect: (item, cleanReplace) async {
                      selectedItem = item;
                      cleanFirstResult = cleanReplace;
                    },
                  );
                },
                child: const Text('Ver Backups'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ver Backups'));
      await tester.pumpAndSettle();

      expect(find.text('Backups no Google Drive'), findsOneWidget);
      expect(find.text('backup_ppvdigital_2026-09-14.json'), findsOneWidget);
      expect(find.textContaining('2.0 KB'), findsOneWidget);

      // Toca em restaurar
      await tester.tap(find.text('Restaurar'));
      await tester.pumpAndSettle();

      expect(find.text('Restaurar este arquivo?'), findsOneWidget);

      // Escolhe Mesclar (Padrão)
      await tester.tap(find.text('Mesclar (Padrão)'));
      await tester.pumpAndSettle();

      expect(selectedItem?.id, 'file_99');
      expect(cleanFirstResult, isFalse);
    });

    testWidgets('showPasteJsonDialog valida JSON e aciona callback', (tester) async {
      String? pastedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  BackupRestoreDialog.showPasteJsonDialog(
                    context: context,
                    onConfirm: (content) async {
                      pastedResult = content;
                    },
                  );
                },
                child: const Text('Colar JSON'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Colar JSON'));
      await tester.pumpAndSettle();

      expect(find.text('Colar Conteúdo JSON do Backup'), findsOneWidget);

      // Tenta enviar vazio
      await tester.tap(find.text('Carregar e Analisar'));
      await tester.pumpAndSettle();
      expect(find.text('Por favor, informe o conteúdo JSON.'), findsOneWidget);

      // Digita JSON inválido
      await tester.enterText(find.byType(TextField), 'invalido');
      await tester.tap(find.text('Carregar e Analisar'));
      await tester.pumpAndSettle();
      expect(find.text('Conteúdo JSON inválido.'), findsOneWidget);

      // Digita JSON válido
      await tester.enterText(find.byType(TextField), '{"version": 1}');
      await tester.tap(find.text('Carregar e Analisar'));
      await tester.pumpAndSettle();

      expect(pastedResult, '{"version": 1}');
    });

    testWidgets(
        'showGoogleClientIdDialog exibe campo e retorna Client ID inserido',
        (tester) async {
      String? enteredClientId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  enteredClientId =
                      await BackupRestoreDialog.showGoogleClientIdDialog(
                    context: context,
                    initialValue: 'antigo-client-id',
                  );
                },
                child: const Text('Configurar Client ID'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Configurar Client ID'));
      await tester.pumpAndSettle();

      expect(find.text('Configurar Google Drive'), findsOneWidget);
      expect(find.text('antigo-client-id'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('google_client_id_field')),
        'novo-client-id-123.apps.googleusercontent.com',
      );
      await tester.tap(find.text('Salvar e Conectar'));
      await tester.pumpAndSettle();

      expect(
        enteredClientId,
        'novo-client-id-123.apps.googleusercontent.com',
      );
    });
  });
}

class FakeBackupService extends BackupService {
  FakeBackupService() : super(tablesDB: FakeTablesDB());

  @override
  Future<BackupPayloadModel> generateBackup({
    required String userId,
    required String userEmail,
    void Function(String step, double progress)? onProgress,
  }) async {
    return BackupPayloadModel(
      exportedAt: DateTime.now(),
      userId: userId,
      userEmail: userEmail,
      data: {},
    );
  }

  @override
  Future<String?> downloadBackup(
    BackupPayloadModel payload, {
    String? customFileName,
  }) async {
    return '/downloads/backup.json';
  }
}

class FakeRestoreService extends RestoreService {
  FakeRestoreService() : super(tablesDB: FakeTablesDB());
}

class FakeTablesDB implements TablesDB {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGoogleDriveBackupService extends GoogleDriveBackupService {
  FakeGoogleDriveBackupService({this.isSignedInValue = false});

  bool isSignedInValue;
  final List<drive.File> driveFiles = [];

  @override
  bool get isSignedIn => isSignedInValue;

  @override
  Future<List<drive.File>> listBackups({drive.DriveApi? customDriveApi}) async {
    return driveFiles;
  }
}

class FakeLoginController implements LoginController {
  FakeLoginController({this.mockEmail = 'usuario_atual@teste.com'});

  String? mockEmail;

  @override
  String? get email => mockEmail;

  @override
  String? get userid => 'user_atual_123';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
