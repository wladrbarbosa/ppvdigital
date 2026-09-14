import 'dart:convert';
import 'dart:developer';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// Cliente HTTP autenticado via cabeçalhos OAuth do Google.
class GoogleAuthClient extends http.BaseClient {
  GoogleAuthClient(this._headers, {http.Client? client})
      : _client = client ?? http.Client();

  final Map<String, String> _headers;
  final http.Client _client;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}

/// Serviço de integração com o Google Drive para armazenamento seguro e automático de backups.
///
/// Utiliza o escopo restrito `https://www.googleapis.com/auth/drive.file`, garantindo
/// acesso estrito apenas aos arquivos e pastas criados pelo próprio aplicativo.
class GoogleDriveBackupService {
  GoogleDriveBackupService({
    GoogleSignIn? googleSignIn,
    drive.DriveApi? driveApi,
    this.driveApiBuilder,
    Future<GoogleSignInAccount?> Function()? signInHandler,
    Future<GoogleSignInAccount?> Function()? signInSilentlyHandler,
    Future<void> Function()? signOutHandler,
    GoogleSignInAccount? initialUser,
  })  : _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
        _injectedDriveApi = driveApi,
        _signInHandler = signInHandler,
        _signInSilentlyHandler = signInSilentlyHandler,
        _signOutHandler = signOutHandler,
        _currentUser = initialUser;

  static const String backupFolderName = 'PPVDigital Backups';

  final GoogleSignIn _googleSignIn;
  final drive.DriveApi? _injectedDriveApi;
  final Future<drive.DriveApi> Function(GoogleSignInAccount account)? driveApiBuilder;
  final Future<GoogleSignInAccount?> Function()? _signInHandler;
  final Future<GoogleSignInAccount?> Function()? _signInSilentlyHandler;
  final Future<void> Function()? _signOutHandler;

  GoogleSignInAccount? _currentUser;
  bool _initialized = false;

  GoogleSignIn get googleSignIn => _googleSignIn;
  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;
  String? get userEmail => _currentUser?.email;
  String? get userDisplayName => _currentUser?.displayName;
  String? get userPhotoUrl => _currentUser?.photoUrl;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      try {
        await _googleSignIn.initialize();
        _initialized = true;
      } catch (e, stack) {
        log('Erro ao inicializar GoogleSignIn: $e', stackTrace: stack);
      }
    }
  }

  /// Realiza login interativo na conta Google.
  Future<GoogleSignInAccount?> signIn() async {
    try {
      if (_signInHandler != null) {
        final account = await _signInHandler!();
        _currentUser = account;
        return account;
      }
      await _ensureInitialized();
      final account = await _googleSignIn.authenticate();
      _currentUser = account;
      return account;
    } catch (e, stack) {
      log('Erro ao autenticar no Google Sign-In: $e', stackTrace: stack);
      rethrow;
    }
  }

  /// Tenta restaurar a sessão do Google silenciosamente.
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      if (_signInSilentlyHandler != null) {
        final account = await _signInSilentlyHandler!();
        _currentUser = account;
        return account;
      }
      await _ensureInitialized();
      final account = await _googleSignIn.attemptLightweightAuthentication();
      _currentUser = account;
      return account;
    } catch (e, stack) {
      log('Erro ao autenticar silenciosamente no Google Sign-In: $e',
          stackTrace: stack);
      return null;
    }
  }

  /// Realiza logout e limpa credenciais da sessão.
  Future<void> signOut() async {
    try {
      if (_signOutHandler != null) {
        await _signOutHandler!();
        _currentUser = null;
        return;
      }
      await _googleSignIn.signOut();
      _currentUser = null;
    } catch (e, stack) {
      log('Erro ao deslogar do Google Sign-In: $e', stackTrace: stack);
      rethrow;
    }
  }

  /// Obtém o cliente da API do Google Drive autenticado.
  Future<drive.DriveApi> getDriveApi() async {
    if (_injectedDriveApi != null) {
      return _injectedDriveApi;
    }

    final user = currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado no Google');
    }

    if (driveApiBuilder != null) {
      return await driveApiBuilder!(user);
    }

    var auth = await user.authorizationClient.authorizationForScopes([
      drive.DriveApi.driveFileScope,
    ]);

    if (auth == null) {
      auth = await user.authorizationClient.authorizeScopes([
        drive.DriveApi.driveFileScope,
      ]);
    }

    final accessToken = auth.accessToken;

    final headers = <String, String>{
      'Authorization': 'Bearer $accessToken',
    };
    final client = GoogleAuthClient(headers);
    return drive.DriveApi(client);
  }

  /// Localiza ou cria a pasta exclusiva de backups no Google Drive do usuário.
  Future<String> getOrCreateBackupFolder({drive.DriveApi? customDriveApi}) async {
    final api = customDriveApi ?? await getDriveApi();

    // Busca pasta com nome 'PPVDigital Backups' que não esteja na lixeira
    const query =
        "mimeType = 'application/vnd.google-apps.folder' and name = '$backupFolderName' and trashed = false";
    final result = await api.files.list(
      q: query,
      spaces: 'drive',
      $fields: 'files(id, name)',
    );

    final files = result.files;
    if (files != null && files.isNotEmpty && files.first.id != null) {
      return files.first.id!;
    }

    // Cria a pasta caso não exista
    final folderMetadata = drive.File()
      ..name = backupFolderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final createdFolder = await api.files.create(
      folderMetadata,
      $fields: 'id, name',
    );

    if (createdFolder.id == null) {
      throw StateError('Falha ao criar pasta de backup no Google Drive');
    }

    return createdFolder.id!;
  }

  /// Realiza o upload do JSON de backup para o Google Drive.
  Future<drive.File> uploadBackup({
    required String jsonContent,
    String? fileName,
    drive.DriveApi? customDriveApi,
  }) async {
    final api = customDriveApi ?? await getDriveApi();
    final folderId = await getOrCreateBackupFolder(customDriveApi: api);

    final name = fileName ??
        'ppvdigital_backup_${DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now())}.json';

    final fileMetadata = drive.File()
      ..name = name
      ..parents = [folderId]
      ..mimeType = 'application/json';

    final bytes = utf8.encode(jsonContent);
    final media = drive.Media(
      Stream.value(bytes),
      bytes.length,
    );

    final uploadedFile = await api.files.create(
      fileMetadata,
      uploadMedia: media,
      $fields: 'id, name, size, createdTime, mimeType',
    );

    return uploadedFile;
  }

  /// Lista os backups existentes na pasta do Google Drive em ordem decrescente de criação.
  Future<List<drive.File>> listBackups({drive.DriveApi? customDriveApi}) async {
    final api = customDriveApi ?? await getDriveApi();
    final folderId = await getOrCreateBackupFolder(customDriveApi: api);

    final query = "'$folderId' in parents and trashed = false";
    final result = await api.files.list(
      q: query,
      orderBy: 'createdTime desc',
      spaces: 'drive',
      $fields: 'files(id, name, size, createdTime, mimeType)',
      pageSize: 100,
    );

    return result.files ?? [];
  }

  /// Baixa o conteúdo de um arquivo de backup por ID.
  Future<String> downloadBackup(String fileId,
      {drive.DriveApi? customDriveApi}) async {
    final api = customDriveApi ?? await getDriveApi();

    final dynamic media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );

    if (media is! drive.Media) {
      throw StateError(
          'Falha ao obter stream de download do arquivo do Google Drive');
    }

    final bytes = await media.stream.fold<List<int>>(
      <int>[],
      (previous, element) => previous..addAll(element),
    );

    return utf8.decode(bytes);
  }

  /// Remove backups automáticos com mais de `retentionDays` dias (padrão 30 dias).
  ///
  /// Retorna a quantidade de arquivos removidos.
  Future<int> pruneOldBackups({
    int retentionDays = 30,
    DateTime? now,
    drive.DriveApi? customDriveApi,
  }) async {
    final api = customDriveApi ?? await getDriveApi();
    final backups = await listBackups(customDriveApi: api);

    final referenceDate = now ?? DateTime.now();
    final cutoffDate = referenceDate.subtract(Duration(days: retentionDays));

    int deletedCount = 0;

    for (final file in backups) {
      if (file.id == null || file.createdTime == null) continue;

      // Verifica se o arquivo é anterior à data limite de retenção
      if (file.createdTime!.isBefore(cutoffDate)) {
        try {
          await api.files.delete(file.id!);
          deletedCount++;
        } catch (e, stack) {
          log('Erro ao remover backup antigo (${file.id}): $e',
              stackTrace: stack);
        }
      }
    }

    return deletedCount;
  }
}
