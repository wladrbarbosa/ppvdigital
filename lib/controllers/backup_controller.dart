import 'dart:developer';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:mobx/mobx.dart' as mobx;
import 'package:ppvdigital/app/login/login_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/backup/backup_payload_model.dart';
import 'package:ppvdigital/models/local/app_database.dart';
import 'package:ppvdigital/services/backup/backup_service.dart';
import 'package:ppvdigital/services/backup/google_drive_backup_service.dart';
import 'package:ppvdigital/services/backup/restore_service.dart';

/// Controller reativo manual em MobX para orquestrar backups manuais e automáticos
/// (Google Drive) e restauração segura de dados com integridade referencial.
class BackupController {
  BackupController({
    required this.backupService,
    required this.restoreService,
    required this.googleDriveService,
    required this.database,
    required this.loginController,
  });

  final BackupService backupService;
  final RestoreService restoreService;
  final GoogleDriveBackupService googleDriveService;
  final AppDatabase database;
  final LoginController loginController;

  static const String keyGDriveAutoBackupEnabled = 'gdrive_auto_backup_enabled';
  static const String keyLastGDriveBackupTimestamp = 'last_gdrive_backup_timestamp';

  // Manual MobX observables
  final mobx.Observable<bool> _isLoading =
      mobx.Observable<bool>(false, name: 'isLoading');
  final mobx.Observable<bool> _isBackingUp =
      mobx.Observable<bool>(false, name: 'isBackingUp');
  final mobx.Observable<bool> _isRestoring =
      mobx.Observable<bool>(false, name: 'isRestoring');
  final mobx.Observable<String> _progressMessage =
      mobx.Observable<String>('', name: 'progressMessage');
  final mobx.Observable<double?> _progressValue =
      mobx.Observable<double?>(null, name: 'progressValue');
  final mobx.Observable<bool> _isAutoBackupEnabled =
      mobx.Observable<bool>(false, name: 'isAutoBackupEnabled');
  final mobx.Observable<DateTime?> _lastBackupTime =
      mobx.Observable<DateTime?>(null, name: 'lastBackupTime');
  final mobx.Observable<String?> _errorMessage =
      mobx.Observable<String?>(null, name: 'errorMessage');
  final mobx.Observable<String?> _successMessage =
      mobx.Observable<String?>(null, name: 'successMessage');
  final mobx.Observable<bool> _driveBackupsLoading =
      mobx.Observable<bool>(false, name: 'driveBackupsLoading');
  final mobx.ObservableList<drive.File> _driveBackups =
      mobx.ObservableList<drive.File>();

  // Observables para sessão do Google Drive
  final mobx.Observable<bool> _isGoogleConnected =
      mobx.Observable<bool>(false, name: 'isGoogleConnected');
  final mobx.Observable<String?> _googleUserEmail =
      mobx.Observable<String?>(null, name: 'googleUserEmail');
  final mobx.Observable<String?> _googleUserName =
      mobx.Observable<String?>(null, name: 'googleUserName');
  final mobx.Observable<String?> _googleClientId =
      mobx.Observable<String?>(null, name: 'googleClientId');

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isBackingUp => _isBackingUp.value;
  bool get isRestoring => _isRestoring.value;
  bool get isBusy => _isLoading.value || _isBackingUp.value || _isRestoring.value;
  String get progressMessage => _progressMessage.value;
  double? get progressValue => _progressValue.value;
  bool get isAutoBackupEnabled => _isAutoBackupEnabled.value;
  DateTime? get lastBackupTime => _lastBackupTime.value;
  String? get errorMessage => _errorMessage.value;
  String? get successMessage => _successMessage.value;
  bool get driveBackupsLoading => _driveBackupsLoading.value;
  List<drive.File> get driveBackups => _driveBackups.toList();

  bool get isGoogleConnected =>
      _isGoogleConnected.value || googleDriveService.isSignedIn;
  String? get googleUserEmail =>
      _googleUserEmail.value ?? googleDriveService.userEmail;
  String? get googleUserName =>
      _googleUserName.value ?? googleDriveService.userDisplayName;
  String? get googleClientId => _googleClientId.value;
  bool get hasGoogleClientId =>
      (_googleClientId.value != null &&
          _googleClientId.value!.trim().isNotEmpty) ||
      Core.defaultGoogleClientId.isNotEmpty;

  /// Define e persiste o Google Client ID nas configurações locais.
  Future<void> setGoogleClientId(String clientId) async {
    final trimmed = clientId.trim();
    mobx.runInAction(() {
      _googleClientId.value = trimmed;
    });
    try {
      await database.setSetting('google_client_id', trimmed);
    } catch (_) {}
  }

  /// Carrega as preferências persistidas no SQLite e tenta recuperar sessão silenciosa.
  Future<void> loadSettings() async {
    try {
      final autoBackupStr = await database.getSetting(keyGDriveAutoBackupEnabled);
      final lastTimestampStr = await database.getSetting(keyLastGDriveBackupTimestamp);
      final savedClientId = await database.getSetting('google_client_id');

      DateTime? parsedTime;
      if (lastTimestampStr != null && lastTimestampStr.isNotEmpty) {
        parsedTime = DateTime.tryParse(lastTimestampStr);
      }

      final autoBackup = autoBackupStr == 'true';
      final effectiveClientId = (savedClientId != null && savedClientId.isNotEmpty)
          ? savedClientId
          : Core.defaultGoogleClientId;

      mobx.runInAction(() {
        _isAutoBackupEnabled.value = autoBackup;
        _lastBackupTime.value = parsedTime;
        if (effectiveClientId.isNotEmpty) {
          _googleClientId.value = effectiveClientId;
        }
      });

      // Tenta recuperar sessão silenciosamente se não estiver conectado
      if (!googleDriveService.isSignedIn) {
        await googleDriveService.signInSilently();
      }

      mobx.runInAction(() {
        _isGoogleConnected.value = googleDriveService.isSignedIn;
        _googleUserEmail.value = googleDriveService.userEmail;
        _googleUserName.value = googleDriveService.userDisplayName;
      });

      if (googleDriveService.isSignedIn) {
        await fetchDriveBackups();
      }
    } catch (e, stack) {
      log('Erro ao carregar configurações de backup: $e', stackTrace: stack);
    }
  }

  /// Alterna ativação do backup diário automático para o Google Drive.
  Future<void> setAutoBackupEnabled(bool enabled) async {
    mobx.runInAction(() {
      _isAutoBackupEnabled.value = enabled;
    });

    try {
      await database.setSetting(keyGDriveAutoBackupEnabled, enabled.toString());
    } catch (_) {}

    if (enabled && isGoogleConnected) {
      await checkAndExecuteDailyBackup();
    }
  }

  /// Conecta interativamente a conta Google Drive do usuário.
  Future<bool> connectGoogleDrive({String? clientId}) async {
    clearMessages();
    mobx.runInAction(() => _isLoading.value = true);

    try {
      final effectiveClientId = (clientId != null && clientId.trim().isNotEmpty)
          ? clientId.trim()
          : (_googleClientId.value ?? Core.defaultGoogleClientId);

      final account = await googleDriveService.signIn(
        clientId: effectiveClientId.isNotEmpty ? effectiveClientId : null,
      );

      if (account != null || googleDriveService.isSignedIn) {
        if (clientId != null && clientId.trim().isNotEmpty) {
          await setGoogleClientId(clientId.trim());
        }
        await fetchDriveBackups();
        final email = googleDriveService.userEmail ?? account?.email ?? '';
        final displayName =
            googleDriveService.userDisplayName ?? account?.displayName;
        mobx.runInAction(() {
          _isGoogleConnected.value = true;
          _googleUserEmail.value = email;
          _googleUserName.value = displayName;
          _successMessage.value =
              'Conectado ao Google Drive com sucesso${email.isNotEmpty ? ' ($email)' : ''}';
        });
        return true;
      }
      return false;
    } catch (e) {
      mobx.runInAction(() {
        _errorMessage.value = 'Falha ao conectar conta Google: $e';
      });
      return false;
    } finally {
      mobx.runInAction(() => _isLoading.value = false);
    }
  }

  /// Desconecta a conta Google Drive e desativa backups automáticos.
  Future<void> disconnectGoogleDrive() async {
    clearMessages();
    mobx.runInAction(() => _isLoading.value = true);

    try {
      await googleDriveService.signOut();
      await setAutoBackupEnabled(false);
      mobx.runInAction(() {
        _isGoogleConnected.value = false;
        _googleUserEmail.value = null;
        _googleUserName.value = null;
        _driveBackups.clear();
        _successMessage.value = 'Google Drive desconectado';
      });
    } catch (e) {
      mobx.runInAction(() {
        _errorMessage.value = 'Falha ao desconectar Google Drive: $e';
      });
    } finally {
      mobx.runInAction(() => _isLoading.value = false);
    }
  }

  /// Carrega a lista de arquivos de backup armazenados no Google Drive.
  Future<List<drive.File>> fetchDriveBackups() async {
    if (!isGoogleConnected) return [];

    mobx.runInAction(() => _driveBackupsLoading.value = true);
    try {
      final files = await googleDriveService.listBackups();
      mobx.runInAction(() {
        _driveBackups
          ..clear()
          ..addAll(files);
      });
      return files;
    } catch (e, stack) {
      log('Erro ao listar backups do Google Drive: $e', stackTrace: stack);
      return [];
    } finally {
      mobx.runInAction(() => _driveBackupsLoading.value = false);
    }
  }

  /// Gera o arquivo JSON de backup e dispara o download manual para o dispositivo.
  Future<String?> downloadManualBackup() async {
    clearMessages();
    final userId = loginController.userid;
    final userEmail = loginController.email ?? '';
    if (userId == null || userId.isEmpty) {
      mobx.runInAction(() => _errorMessage.value = 'Usuário não autenticado no aplicativo');
      return null;
    }

    mobx.runInAction(() {
      _isBackingUp.value = true;
      _progressMessage.value = 'Iniciando extração dos dados...';
      _progressValue.value = 0.0;
    });

    try {
      final payload = await backupService.generateBackup(
        userId: userId,
        userEmail: userEmail,
        onProgress: (step, progress) {
          mobx.runInAction(() {
            _progressMessage.value = step;
            _progressValue.value = progress;
          });
        },
      );

      final filePath = await backupService.downloadBackup(payload);

      final now = DateTime.now();
      await database.setSetting(
          keyLastGDriveBackupTimestamp, now.toIso8601String());

      mobx.runInAction(() {
        _lastBackupTime.value = now;
        _successMessage.value = 'Backup manual gerado e baixado com sucesso!';
      });
      return filePath;
    } catch (e) {
      mobx.runInAction(() {
        _errorMessage.value = 'Erro ao gerar backup manual: $e';
      });
      return null;
    } finally {
      mobx.runInAction(() {
        _isBackingUp.value = false;
        _progressMessage.value = '';
        _progressValue.value = null;
      });
    }
  }

  /// Gera o backup completo e realiza o upload para a pasta exclusiva do Google Drive.
  Future<bool> uploadBackupToGoogleDrive() async {
    clearMessages();
    final userId = loginController.userid;
    final userEmail = loginController.email ?? '';
    if (userId == null || userId.isEmpty) {
      mobx.runInAction(() => _errorMessage.value = 'Usuário não autenticado no aplicativo');
      return false;
    }
    if (!isGoogleConnected) {
      mobx.runInAction(() => _errorMessage.value = 'Google Drive não conectado');
      return false;
    }

    mobx.runInAction(() {
      _isBackingUp.value = true;
      _progressMessage.value = 'Extraindo dados para o Google Drive...';
      _progressValue.value = 0.0;
    });

    try {
      final payload = await backupService.generateBackup(
        userId: userId,
        userEmail: userEmail,
        onProgress: (step, progress) {
          mobx.runInAction(() {
            _progressMessage.value = step;
            _progressValue.value = progress;
          });
        },
      );

      mobx.runInAction(() {
        _progressMessage.value = 'Enviando arquivo para o Google Drive...';
        _progressValue.value = 0.9;
      });

      final jsonContent = payload.toJson();
      await googleDriveService.uploadBackup(jsonContent: jsonContent);

      // Limpa backups com mais de 30 dias de retenção
      await googleDriveService.pruneOldBackups();

      final now = DateTime.now();
      await database.setSetting(
          keyLastGDriveBackupTimestamp, now.toIso8601String());

      await fetchDriveBackups();

      mobx.runInAction(() {
        _lastBackupTime.value = now;
        _successMessage.value =
            'Backup enviado para o Google Drive com sucesso!';
      });
      return true;
    } catch (e) {
      mobx.runInAction(() {
        _errorMessage.value = 'Erro ao enviar backup para o Google Drive: $e';
      });
      return false;
    } finally {
      mobx.runInAction(() {
        _isBackingUp.value = false;
        _progressMessage.value = '';
        _progressValue.value = null;
      });
    }
  }

  /// Verifica se o backup diário automático está habilitado e pendente (>= 24h).
  ///
  /// Executado em segundo plano de forma silenciosa e não bloqueante.
  Future<void> checkAndExecuteDailyBackup() async {
    try {
      if (!isAutoBackupEnabled || !isGoogleConnected) {
        return;
      }

      final userId = loginController.userid;
      final userEmail = loginController.email ?? '';
      if (userId == null || userId.isEmpty) {
        return;
      }

      final lastTime = lastBackupTime;
      if (lastTime != null) {
        final difference = DateTime.now().difference(lastTime);
        if (difference < const Duration(hours: 24)) {
          return; // Já executado no intervalo diário
        }
      }

      final payload = await backupService.generateBackup(
        userId: userId,
        userEmail: userEmail,
      );
      final jsonContent = payload.toJson();
      await googleDriveService.uploadBackup(jsonContent: jsonContent);
      await googleDriveService.pruneOldBackups();

      final now = DateTime.now();
      await database.setSetting(
          keyLastGDriveBackupTimestamp, now.toIso8601String());

      mobx.runInAction(() {
        _lastBackupTime.value = now;
      });
      await fetchDriveBackups();
    } catch (e, stack) {
      log('Falha na execução silenciosa do backup diário no Google Drive: $e',
          stackTrace: stack);
    }
  }

  /// Executa a restauração completa a partir de um JSON (manual ou do Drive).
  Future<bool> restoreFromManualJson(
    String jsonContent, {
    bool cleanReplace = true,
  }) async {
    clearMessages();
    final userId = loginController.userid;
    if (userId == null || userId.isEmpty) {
      mobx.runInAction(() => _errorMessage.value = 'Usuário não autenticado no aplicativo');
      return false;
    }

    mobx.runInAction(() {
      _isRestoring.value = true;
      _progressMessage.value = 'Validando integridade do backup...';
      _progressValue.value = 0.0;
    });

    try {
      final payload = BackupPayloadModel.fromJson(jsonContent);
      await restoreService.restoreBackup(
        payload,
        cleanReplace: cleanReplace,
        onProgress: (step, progress) {
          mobx.runInAction(() {
            _progressMessage.value = step;
            _progressValue.value = progress;
          });
        },
      );

      mobx.runInAction(() {
        _successMessage.value =
            'Restauração concluída com sucesso! Todos os dados foram restabelecidos.';
      });
      return true;
    } catch (e) {
      mobx.runInAction(() {
        _errorMessage.value = 'Falha na restauração: $e';
      });
      return false;
    } finally {
      mobx.runInAction(() {
        _isRestoring.value = false;
        _progressMessage.value = '';
        _progressValue.value = null;
      });
    }
  }

  /// Baixa o backup selecionado do Google Drive e executa a restauração segura.
  Future<bool> restoreFromGoogleDrive(
    String fileId, {
    bool cleanReplace = true,
  }) async {
    clearMessages();
    if (!isGoogleConnected) {
      mobx.runInAction(() => _errorMessage.value = 'Google Drive não conectado');
      return false;
    }

    mobx.runInAction(() {
      _isRestoring.value = true;
      _progressMessage.value = 'Baixando arquivo do Google Drive...';
      _progressValue.value = 0.0;
    });

    try {
      final jsonContent = await googleDriveService.downloadBackup(fileId);
      return await restoreFromManualJson(jsonContent,
          cleanReplace: cleanReplace);
    } catch (e) {
      mobx.runInAction(() {
        _errorMessage.value = 'Falha ao baixar backup do Google Drive: $e';
      });
      return false;
    } finally {
      mobx.runInAction(() {
        _isRestoring.value = false;
        _progressMessage.value = '';
        _progressValue.value = null;
      });
    }
  }

  /// Limpa mensagens de erro e sucesso exibidas na interface.
  void clearMessages() {
    mobx.runInAction(() {
      _errorMessage.value = null;
      _successMessage.value = null;
    });
  }

  /// Restaura o estado em memória para valores iniciais seguros.
  void reset() {
    mobx.runInAction(() {
      _isLoading.value = false;
      _isBackingUp.value = false;
      _isRestoring.value = false;
      _progressMessage.value = '';
      _progressValue.value = null;
      _errorMessage.value = null;
      _successMessage.value = null;
      _driveBackupsLoading.value = false;
      _driveBackups.clear();
    });
  }
}
