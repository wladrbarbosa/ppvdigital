import 'package:appwrite/appwrite.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:intl/date_symbol_data_local.dart';
import 'package:ppvdigital/app/home/widgets/configuracoes_modal_widget.dart';
import 'package:ppvdigital/app/login/login_controller.dart';
import 'package:ppvdigital/controllers/backup_controller.dart';
import 'package:ppvdigital/controllers/theme_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/design_system/design_system.dart';
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

  group('ConfiguracoesModalWidget Tests', () {
    late AppDatabase db;
    late ThemeController themeController;
    late BackupController backupController;
    late FakeBackupService fakeBackupService;
    late FakeRestoreService fakeRestoreService;
    late FakeGoogleDriveBackupService fakeDriveService;
    late FakeLoginController fakeLoginController;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      themeController = ThemeController(db);
      fakeBackupService = FakeBackupService();
      fakeRestoreService = FakeRestoreService();
      fakeDriveService = FakeGoogleDriveBackupService();
      fakeLoginController = FakeLoginController();

      backupController = BackupController(
        backupService: fakeBackupService,
        restoreService: fakeRestoreService,
        googleDriveService: fakeDriveService,
        database: db,
        loginController: fakeLoginController,
      );

      if (!Core.getIt.isRegistered<ThemeController>()) {
        Core.getIt.registerSingleton<ThemeController>(themeController);
      }
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

    testWidgets('Exibe seção de Backup e Restauração com cards manual e Google Drive', (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfiguracoesModalWidget(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Rola até o final
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Backup e Restauração de Dados'), findsOneWidget);
      expect(find.text('Backup Manual (.json)'), findsOneWidget);
      expect(find.text('Exportar Arquivo'), findsOneWidget);
      expect(find.text('Restaurar Arquivo'), findsOneWidget);

      expect(find.text('Google Drive'), findsOneWidget);
      expect(find.text('Não conectado ao Google Drive'), findsOneWidget);
      expect(find.text('Conectar'), findsOneWidget);
      expect(find.text('Backup Automático Diário'), findsOneWidget);
    });

    testWidgets('Toca em Exportar Arquivo e executa downloadManualBackup', (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfiguracoesModalWidget(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Exportar Arquivo'));
      await tester.pumpAndSettle();

      // Verifica snackbar exibido
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Toca em Conectar sem Client ID configurado abre showGoogleClientIdDialog', (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfiguracoesModalWidget(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Conectar'));
      await tester.pumpAndSettle();

      expect(find.text('Configurar Google Drive'), findsOneWidget);
      expect(find.text('Salvar e Conectar'), findsOneWidget);
    });

    testWidgets('Exibe estado conectado e permite desconectar com sucesso', (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      fakeDriveService.isSignedInValue = true;
      await backupController.loadSettings();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfiguracoesModalWidget(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Desconectar'), findsOneWidget);
      expect(find.textContaining('teste@gmail.com'), findsOneWidget);

      await tester.tap(find.text('Desconectar'));
      await tester.pumpAndSettle();

      expect(find.text('Conectar'), findsOneWidget);
      expect(find.text('Não conectado ao Google Drive'), findsOneWidget);
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
  String? get userEmail => isSignedInValue ? 'teste@gmail.com' : null;

  @override
  String? get userDisplayName => isSignedInValue ? 'Teste User' : null;

  @override
  Future<void> signOut() async {
    isSignedInValue = false;
  }

  @override
  Future<List<drive.File>> listBackups({drive.DriveApi? customDriveApi}) async {
    return driveFiles;
  }
}

class FakeLoginController implements LoginController {
  FakeLoginController({this.mockEmail = 'teste@usuario.com'});

  String? mockEmail;

  @override
  String? get email => mockEmail;

  @override
  String? get userid => 'user_test_id';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
