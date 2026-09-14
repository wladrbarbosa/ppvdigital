import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:ppvdigital/app/login/login_controller.dart';
import 'package:ppvdigital/controllers/backup_controller.dart';
import 'package:ppvdigital/models/backup/backup_payload_model.dart';
import 'package:ppvdigital/models/local/app_database.dart';
import 'package:ppvdigital/services/backup/backup_service.dart';
import 'package:ppvdigital/services/backup/google_drive_backup_service.dart';
import 'package:ppvdigital/services/backup/restore_service.dart';

import '../services/backup_service_test.dart';
import '../services/google_drive_backup_service_test.dart';

class FakeLoginController implements LoginController {
  FakeLoginController({this.mockUserId = 'user_abc', this.mockEmail = 'user@example.com'});

  String? mockUserId;
  String? mockEmail;

  @override
  String? get userid => mockUserId;

  @override
  String? get email => mockEmail;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeBackupService extends BackupService {
  FakeBackupService() : super(tablesDB: FakeTablesDB(tableData: {}));

  bool shouldThrowGenerate = false;
  bool shouldThrowDownload = false;
  BackupPayloadModel? payloadToReturn;
  String? downloadedPathToReturn = '/tmp/backup.json';

  @override
  Future<BackupPayloadModel> generateBackup({
    required String userId,
    required String userEmail,
    void Function(String step, double progress)? onProgress,
  }) async {
    if (shouldThrowGenerate) {
      throw Exception('Erro simulado ao gerar backup');
    }
    onProgress?.call('Extraindo dados...', 0.5);
    return payloadToReturn ??
        BackupPayloadModel(
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
    if (shouldThrowDownload) {
      throw Exception('Erro simulado no download');
    }
    return downloadedPathToReturn;
  }
}

class FakeRestoreService extends RestoreService {
  FakeRestoreService() : super(tablesDB: FakeTablesDB(tableData: {}));

  bool shouldThrowRestore = false;
  BackupPayloadModel? lastRestoredPayload;
  bool? lastCleanReplace;

  @override
  Future<void> restoreBackup(
    BackupPayloadModel payload, {
    required bool cleanReplace,
    void Function(String step, double progress)? onProgress,
  }) async {
    if (shouldThrowRestore) {
      throw Exception('Erro simulado na restauração');
    }
    lastRestoredPayload = payload;
    lastCleanReplace = cleanReplace;
    onProgress?.call('Restaurando dados...', 0.7);
  }
}

class FakeGoogleDriveBackupService extends GoogleDriveBackupService {
  FakeGoogleDriveBackupService({this.isSignedInValue = false});

  bool isSignedInValue;
  bool shouldThrowSignIn = false;
  bool shouldThrowSignOut = false;
  bool shouldThrowUpload = false;
  bool shouldThrowDownload = false;
  bool shouldThrowList = false;

  final List<drive.File> driveFiles = [];
  String downloadedContent =
      BackupPayloadModel(
        exportedAt: DateTime(2026),
        userId: 'user_abc',
        userEmail: 'user@example.com',
        data: {},
      ).toJson();

  @override
  bool get isSignedIn => isSignedInValue;

  @override
  String? get userEmail => isSignedInValue ? 'gdrive_user@gmail.com' : null;

  @override
  String? get userDisplayName => isSignedInValue ? 'GDrive User' : null;

  @override
  Future<FakeGoogleSignInAccount?> signIn() async {
    if (shouldThrowSignIn) throw Exception('Sign in failed');
    isSignedInValue = true;
    return FakeGoogleSignInAccount(email: 'gdrive_user@gmail.com');
  }

  @override
  Future<FakeGoogleSignInAccount?> signInSilently() async {
    if (shouldThrowSignIn) throw Exception('Silent sign in failed');
    return isSignedInValue
        ? FakeGoogleSignInAccount(email: 'gdrive_user@gmail.com')
        : null;
  }

  @override
  Future<void> signOut() async {
    if (shouldThrowSignOut) throw Exception('Sign out failed');
    isSignedInValue = false;
  }

  @override
  Future<List<drive.File>> listBackups({drive.DriveApi? customDriveApi}) async {
    if (shouldThrowList) throw Exception('List failed');
    return driveFiles;
  }

  @override
  Future<drive.File> uploadBackup({
    required String jsonContent,
    String? fileName,
    drive.DriveApi? customDriveApi,
  }) async {
    if (shouldThrowUpload) throw Exception('Upload failed');
    final file = drive.File()
      ..id = 'uploaded_file_id'
      ..name = fileName ?? 'backup.json'
      ..createdTime = DateTime.now();
    driveFiles.insert(0, file);
    return file;
  }

  @override
  Future<String> downloadBackup(String fileId,
      {drive.DriveApi? customDriveApi}) async {
    if (shouldThrowDownload) throw Exception('Download failed');
    return downloadedContent;
  }

  @override
  Future<int> pruneOldBackups({
    int retentionDays = 30,
    DateTime? now,
    drive.DriveApi? customDriveApi,
  }) async {
    return 0;
  }
}

void main() {
  late AppDatabase db;
  late FakeLoginController fakeLogin;
  late FakeBackupService fakeBackup;
  late FakeRestoreService fakeRestore;
  late FakeGoogleDriveBackupService fakeGDrive;
  late BackupController controller;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fakeLogin = FakeLoginController();
    fakeBackup = FakeBackupService();
    fakeRestore = FakeRestoreService();
    fakeGDrive = FakeGoogleDriveBackupService();

    controller = BackupController(
      backupService: fakeBackup,
      restoreService: fakeRestore,
      googleDriveService: fakeGDrive,
      database: db,
      loginController: fakeLogin,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('BackupController - Inicialização & Configurações', () {
    test('loadSettings carrega dados persistidos no SQLite', () async {
      await db.setSetting(BackupController.keyGDriveAutoBackupEnabled, 'true');
      final pastTime = DateTime(2026, 8, 1, 10);
      await db.setSetting(
          BackupController.keyLastGDriveBackupTimestamp, pastTime.toIso8601String());

      fakeGDrive.isSignedInValue = true;
      fakeGDrive.driveFiles.add(drive.File()..id = 'file_1');

      await controller.loadSettings();

      expect(controller.isAutoBackupEnabled, isTrue);
      expect(controller.lastBackupTime, pastTime);
      expect(controller.isGoogleConnected, isTrue);
      expect(controller.googleUserEmail, 'gdrive_user@gmail.com');
      expect(controller.googleUserName, 'GDrive User');
      expect(controller.driveBackups.length, 1);
    });

    test('loadSettings trata exceção sem quebrar estado', () async {
      // Força erro fechando o banco antes do load
      await db.close();
      await controller.loadSettings();
      expect(controller.isAutoBackupEnabled, isFalse);
    });

    test('setAutoBackupEnabled altera valor, persiste e dispara check se conectado', () async {
      fakeGDrive.isSignedInValue = true;
      expect(controller.isAutoBackupEnabled, isFalse);

      await controller.setAutoBackupEnabled(true);
      expect(controller.isAutoBackupEnabled, isTrue);

      final saved = await db.getSetting(BackupController.keyGDriveAutoBackupEnabled);
      expect(saved, 'true');
    });
  });

  group('BackupController - Integração Google Drive', () {
    test('connectGoogleDrive conecta com sucesso e atualiza backups', () async {
      final success = await controller.connectGoogleDrive();
      expect(success, isTrue);
      expect(controller.isGoogleConnected, isTrue);
      expect(controller.successMessage, contains('Conectado ao Google Drive'));
      expect(controller.errorMessage, isNull);
    });

    test('connectGoogleDrive captura erro e define mensagem de falha', () async {
      fakeGDrive.shouldThrowSignIn = true;
      final success = await controller.connectGoogleDrive();
      expect(success, isFalse);
      expect(controller.errorMessage, contains('Falha ao conectar'));
    });

    test('disconnectGoogleDrive desconecta, limpa backups e desativa autoBackup', () async {
      await controller.setAutoBackupEnabled(true);
      fakeGDrive.isSignedInValue = true;
      fakeGDrive.driveFiles.add(drive.File()..id = 'file_1');

      await controller.disconnectGoogleDrive();
      expect(controller.isGoogleConnected, isFalse);
      expect(controller.isAutoBackupEnabled, isFalse);
      expect(controller.driveBackups, isEmpty);
      expect(controller.successMessage, 'Google Drive desconectado');
    });

    test('disconnectGoogleDrive captura erro caso ocorra exceção', () async {
      fakeGDrive.shouldThrowSignOut = true;
      await controller.disconnectGoogleDrive();
      expect(controller.errorMessage, contains('Falha ao desconectar'));
    });

    test('fetchDriveBackups retorna vazio se não conectado', () async {
      fakeGDrive.isSignedInValue = false;
      final files = await controller.fetchDriveBackups();
      expect(files, isEmpty);
    });

    test('fetchDriveBackups captura erro e retorna lista vazia', () async {
      fakeGDrive.isSignedInValue = true;
      fakeGDrive.shouldThrowList = true;
      final files = await controller.fetchDriveBackups();
      expect(files, isEmpty);
      expect(controller.driveBackupsLoading, isFalse);
    });
  });

  group('BackupController - Backup Manual', () {
    test('downloadManualBackup gera e faz download com sucesso', () async {
      final path = await controller.downloadManualBackup();
      expect(path, '/tmp/backup.json');
      expect(controller.successMessage, contains('baixado com sucesso'));
      expect(controller.lastBackupTime, isNotNull);
      expect(controller.isBackingUp, isFalse);
      expect(controller.isBusy, isFalse);
    });

    test('downloadManualBackup falha se usuário não estiver autenticado', () async {
      fakeLogin.mockUserId = null;
      final path = await controller.downloadManualBackup();
      expect(path, isNull);
      expect(controller.errorMessage, contains('Usuário não autenticado'));
    });

    test('downloadManualBackup captura erro se backupService falhar', () async {
      fakeBackup.shouldThrowGenerate = true;
      final path = await controller.downloadManualBackup();
      expect(path, isNull);
      expect(controller.errorMessage, contains('Erro ao gerar backup manual'));
      expect(controller.isBackingUp, isFalse);
    });
  });

  group('BackupController - Upload & Backup Diário no Google Drive', () {
    test('uploadBackupToGoogleDrive realiza upload e rotação com sucesso', () async {
      fakeGDrive.isSignedInValue = true;

      final success = await controller.uploadBackupToGoogleDrive();
      expect(success, isTrue);
      expect(controller.successMessage, contains('Backup enviado para o Google Drive'));
      expect(fakeGDrive.driveFiles.length, 1);
      expect(controller.isBackingUp, isFalse);
    });

    test('uploadBackupToGoogleDrive falha se usuário deslogado ou Drive desconectado', () async {
      fakeLogin.mockUserId = null;
      var success = await controller.uploadBackupToGoogleDrive();
      expect(success, isFalse);
      expect(controller.errorMessage, contains('Usuário não autenticado'));

      fakeLogin.mockUserId = 'user_123';
      fakeGDrive.isSignedInValue = false;
      success = await controller.uploadBackupToGoogleDrive();
      expect(success, isFalse);
      expect(controller.errorMessage, contains('Google Drive não conectado'));
    });

    test('uploadBackupToGoogleDrive captura erro no upload', () async {
      fakeGDrive.isSignedInValue = true;
      fakeGDrive.shouldThrowUpload = true;

      final success = await controller.uploadBackupToGoogleDrive();
      expect(success, isFalse);
      expect(controller.errorMessage, contains('Erro ao enviar backup'));
      expect(controller.isBackingUp, isFalse);
    });

    test('checkAndExecuteDailyBackup não executa se autoBackup desligado ou Drive desconectado', () async {
      await controller.checkAndExecuteDailyBackup();
      expect(fakeGDrive.driveFiles, isEmpty);

      fakeGDrive.isSignedInValue = true;
      // autoBackup ainda false
      await controller.checkAndExecuteDailyBackup();
      expect(fakeGDrive.driveFiles, isEmpty);
    });

    test('checkAndExecuteDailyBackup não executa se já executado nas últimas 24 horas', () async {
      fakeGDrive.isSignedInValue = true;
      await controller.setAutoBackupEnabled(true);

      // Marca backup como executado há 2 horas
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      await db.setSetting(
          BackupController.keyLastGDriveBackupTimestamp, twoHoursAgo.toIso8601String());
      await controller.loadSettings();

      final initialFiles = fakeGDrive.driveFiles.length;
      await controller.checkAndExecuteDailyBackup();
      expect(fakeGDrive.driveFiles.length, initialFiles);
    });

    test('checkAndExecuteDailyBackup executa se nunca executado ou > 24h', () async {
      fakeGDrive.isSignedInValue = true;
      await controller.setAutoBackupEnabled(true);

      // Marca backup há 25 horas
      final yesterday = DateTime.now().subtract(const Duration(hours: 25));
      await db.setSetting(
          BackupController.keyLastGDriveBackupTimestamp, yesterday.toIso8601String());
      await controller.loadSettings();

      await controller.checkAndExecuteDailyBackup();
      expect(fakeGDrive.driveFiles.isNotEmpty, isTrue);
      expect(controller.lastBackupTime!.isAfter(yesterday), isTrue);
    });

    test('checkAndExecuteDailyBackup não lança exceção em caso de erro', () async {
      fakeGDrive.isSignedInValue = true;
      await controller.setAutoBackupEnabled(true);
      fakeGDrive.shouldThrowUpload = true;

      // Não deve lançar
      await expectLater(controller.checkAndExecuteDailyBackup(), completes);
    });
  });

  group('BackupController - Restauração Segura', () {
    test('restoreFromManualJson restaura com sucesso', () async {
      final payload = BackupPayloadModel(
        exportedAt: DateTime.now(),
        userId: 'user_abc',
        userEmail: 'user@example.com',
        data: {},
      );

      final success = await controller.restoreFromManualJson(payload.toJson());
      expect(success, isTrue);
      expect(controller.successMessage, contains('Restauração concluída'));
      expect(fakeRestore.lastRestoredPayload?.userId, 'user_abc');
      expect(fakeRestore.lastCleanReplace, isTrue);
      expect(controller.isRestoring, isFalse);
    });

    test('restoreFromManualJson falha se usuário deslogado', () async {
      fakeLogin.mockUserId = null;
      final success = await controller.restoreFromManualJson('{}');
      expect(success, isFalse);
      expect(controller.errorMessage, contains('Usuário não autenticado'));
    });

    test('restoreFromManualJson captura erro na restauração', () async {
      fakeRestore.shouldThrowRestore = true;
      final payload = BackupPayloadModel(
        exportedAt: DateTime.now(),
        userId: 'user_abc',
        userEmail: 'user@example.com',
        data: {},
      );

      final success = await controller.restoreFromManualJson(payload.toJson());
      expect(success, isFalse);
      expect(controller.errorMessage, contains('Falha na restauração'));
      expect(controller.isRestoring, isFalse);
    });

    test('restoreFromGoogleDrive baixa e restaura arquivo com sucesso', () async {
      fakeGDrive.isSignedInValue = true;
      final success = await controller.restoreFromGoogleDrive('drive_file_1');

      expect(success, isTrue);
      expect(controller.successMessage, contains('Restauração concluída'));
      expect(controller.isRestoring, isFalse);
    });

    test('restoreFromGoogleDrive falha se Drive desconectado ou falha no download', () async {
      fakeGDrive.isSignedInValue = false;
      var success = await controller.restoreFromGoogleDrive('file_1');
      expect(success, isFalse);
      expect(controller.errorMessage, contains('Google Drive não conectado'));

      fakeGDrive.isSignedInValue = true;
      fakeGDrive.shouldThrowDownload = true;
      success = await controller.restoreFromGoogleDrive('file_1');
      expect(success, isFalse);
      expect(controller.errorMessage, contains('Falha ao baixar backup'));
      expect(controller.isRestoring, isFalse);
    });
  });

  group('BackupController - Limpeza e Reset', () {
    test('clearMessages limpa erro e sucesso', () {
      controller.clearMessages();
      expect(controller.errorMessage, isNull);
      expect(controller.successMessage, isNull);
    });

    test('reset redefine todos os observables para valores limpos', () {
      controller.reset();
      expect(controller.isLoading, isFalse);
      expect(controller.isBackingUp, isFalse);
      expect(controller.isRestoring, isFalse);
      expect(controller.isBusy, isFalse);
      expect(controller.progressMessage, isEmpty);
      expect(controller.progressValue, isNull);
      expect(controller.errorMessage, isNull);
      expect(controller.successMessage, isNull);
      expect(controller.driveBackupsLoading, isFalse);
      expect(controller.driveBackups, isEmpty);
    });
  });
}
