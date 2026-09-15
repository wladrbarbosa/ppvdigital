import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:intl/date_symbol_data_local.dart';
import 'package:ppvdigital/app/home/widgets/configuracoes_modal_widget.dart';
import 'package:ppvdigital/app/home/widgets/legal_viewer_dialog.dart';
import 'package:ppvdigital/app/login/login_controller.dart';
import 'package:ppvdigital/app/login/login_page.dart';
import 'package:ppvdigital/controllers/backup_controller.dart';
import 'package:ppvdigital/controllers/theme_controller.dart';
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

  group('LegalViewerDialog & In-App Legal Navigation Tests', () {
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

    testWidgets(
      'Exibe diálogo da Política de Privacidade com seções e fecha ao tocar em Entendido',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1000, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => LegalViewerDialog.showPrivacyPolicy(context),
                  child: const Text('Abrir Privacidade'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Abrir Privacidade'));
        await tester.pumpAndSettle();

        expect(find.text('Política de Privacidade'), findsOneWidget);
        expect(find.textContaining('LGPD'), findsWidgets);
        expect(find.text('Abrir Web'), findsOneWidget);

        final entendidoBtn = find.widgetWithText(FilledButton, 'Entendido');
        expect(entendidoBtn, findsOneWidget);
        await tester.tap(entendidoBtn);
        await tester.pumpAndSettle();

        expect(find.text('Política de Privacidade'), findsNothing);
      },
    );

    testWidgets(
      'Exibe diálogo dos Termos de Serviço com seções e fecha ao tocar em Entendido',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1000, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      LegalViewerDialog.showTermsOfService(context),
                  child: const Text('Abrir Termos'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Abrir Termos'));
        await tester.pumpAndSettle();

        expect(find.text('Termos de Serviço'), findsOneWidget);
        expect(find.text('Abrir Web'), findsOneWidget);

        final entendidoBtn = find.widgetWithText(FilledButton, 'Entendido');
        await tester.tap(entendidoBtn);
        await tester.pumpAndSettle();

        expect(find.text('Termos de Serviço'), findsNothing);
      },
    );

    testWidgets('ConfiguracoesModalWidget exibe seção legal e abre diálogos', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ConfiguracoesModalWidget.show(context),
                child: const Text('Abrir Configurações'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Abre o modal de configurações
      await tester.tap(find.text('Abrir Configurações'));
      await tester.pumpAndSettle();

      expect(find.byType(ConfiguracoesModalWidget), findsOneWidget);

      // Rola para baixo para revelar a seção legal
      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();

      expect(find.text('Informações Legais & Sobre'), findsOneWidget);
      expect(find.text('Política de Privacidade'), findsOneWidget);
      expect(find.text('Termos de Serviço'), findsOneWidget);
      expect(find.textContaining('Seapruma • Versão 0.31.1'), findsOneWidget);

      // Toca em Política de Privacidade
      await tester.tap(find.text('Política de Privacidade'));
      await tester.pumpAndSettle();

      expect(find.byType(LegalViewerDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Entendido'));
      await tester.pumpAndSettle();

      // Toca em Termos de Serviço
      await tester.tap(find.text('Termos de Serviço'));
      await tester.pumpAndSettle();

      expect(find.byType(LegalViewerDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Entendido'));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'LoginPage exibe links para Termos de Serviço e Política de Privacidade',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1000, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(home: LoginPage()));
        await tester.pumpAndSettle();

        expect(find.text('Termos de Serviço'), findsOneWidget);
        expect(find.text('Política de Privacidade'), findsOneWidget);

        // Toca no link de Termos
        await tester.tap(find.text('Termos de Serviço'));
        await tester.pumpAndSettle();
        expect(find.byType(LegalViewerDialog), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Entendido'));
        await tester.pumpAndSettle();

        // Toca no link de Privacidade
        await tester.tap(find.text('Política de Privacidade'));
        await tester.pumpAndSettle();
        expect(find.byType(LegalViewerDialog), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Entendido'));
        await tester.pumpAndSettle();
      },
    );
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
  Future<GoogleSignInAccount?> signIn({String? clientId}) async {
    isSignedInValue = true;
    return null;
  }

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
  models.User? get currentUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
