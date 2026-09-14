import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:ppvdigital/services/backup/google_drive_backup_service.dart';

class FakeGoogleSignInClientAuthorization
    implements GoogleSignInClientAuthorization {
  FakeGoogleSignInClientAuthorization({this.accessToken = 'test_token'});

  @override
  final String accessToken;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGoogleSignInAuthorizationClient
    implements GoogleSignInAuthorizationClient {
  FakeGoogleSignInAuthorizationClient({this.token = 'test_token'});

  final String token;
  bool returnNullOnAuthorization = false;

  @override
  Future<GoogleSignInClientAuthorization?> authorizationForScopes(
      List<String> scopes) async {
    if (returnNullOnAuthorization) return null;
    return FakeGoogleSignInClientAuthorization(accessToken: token);
  }

  @override
  Future<GoogleSignInClientAuthorization> authorizeScopes(
      List<String> scopes) async {
    return FakeGoogleSignInClientAuthorization(accessToken: token);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: avoid_implementing_value_types
class FakeGoogleSignInAccount implements GoogleSignInAccount {
  FakeGoogleSignInAccount({
    this.email = 'tester@gmail.com',
    this.displayName = 'Tester Google',
    this.photoUrl = 'https://example.com/photo.jpg',
    this.id = 'user_12345',
    FakeGoogleSignInAuthorizationClient? client,
  }) : _authClient = client ?? FakeGoogleSignInAuthorizationClient();

  @override
  final String email;

  @override
  final String? displayName;

  @override
  final String? photoUrl;

  @override
  final String id;

  final FakeGoogleSignInAuthorizationClient _authClient;

  @override
  GoogleSignInAuthorizationClient get authorizationClient => _authClient;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFilesResource implements drive.FilesResource {
  final List<drive.File> filesStore = [];
  final Map<String, List<int>> fileContents = {};
  bool failCreateFolder = false;
  bool failDelete = false;
  bool returnNonMediaOnGet = false;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #list) {
      final q = invocation.namedArguments[#q] as String?;
      final orderBy = invocation.namedArguments[#orderBy] as String?;
      List<drive.File> result = List.from(filesStore);

      if (q != null) {
        if (q.contains("mimeType = 'application/vnd.google-apps.folder'") &&
            q.contains("name = 'PPVDigital Backups'")) {
          result = result
              .where((f) =>
                  f.mimeType == 'application/vnd.google-apps.folder' &&
                  f.name == GoogleDriveBackupService.backupFolderName &&
                  !(f.trashed ?? false))
              .toList();
        } else if (q.contains('in parents')) {
          final match = RegExp("'([^']+)' in parents").firstMatch(q);
          if (match != null) {
            final parentId = match.group(1);
            result = result
                .where((f) =>
                    f.parents?.contains(parentId) == true &&
                    !(f.trashed ?? false))
                .toList();
          }
        }
      }

      if (orderBy != null && orderBy.contains('createdTime desc')) {
        result.sort((a, b) {
          final timeA = a.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
          final timeB = b.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
          return timeB.compareTo(timeA);
        });
      }

      return Future.value(drive.FileList()..files = result);
    }

    if (invocation.memberName == #create) {
      final request = invocation.positionalArguments[0] as drive.File;
      final uploadMedia =
          invocation.namedArguments[#uploadMedia] as drive.Media?;

      if (failCreateFolder &&
          request.mimeType == 'application/vnd.google-apps.folder') {
        return Future.value(drive.File());
      }

      final id = 'drive_file_${filesStore.length + 1}';
      final newFile = drive.File()
        ..id = id
        ..name = request.name
        ..mimeType = request.mimeType
        ..parents = request.parents
        ..createdTime = DateTime.now()
        ..size = uploadMedia?.length?.toString();

      filesStore.add(newFile);

      if (uploadMedia != null) {
        return uploadMedia.stream
            .fold<List<int>>([], (prev, elem) => prev..addAll(elem))
            .then((bytes) {
          fileContents[id] = bytes;
          return newFile;
        });
      }

      return Future.value(newFile);
    }

    if (invocation.memberName == #get) {
      final fileId = invocation.positionalArguments[0] as String;
      if (returnNonMediaOnGet) {
        return Future.value(drive.File()..id = fileId);
      }
      final bytes = fileContents[fileId] ?? [];
      return Future.value(drive.Media(Stream.value(bytes), bytes.length));
    }

    if (invocation.memberName == #delete) {
      final fileId = invocation.positionalArguments[0] as String;
      if (failDelete) {
        return Future.error(Exception('Network error during delete'));
      }
      filesStore.removeWhere((f) => f.id == fileId);
      fileContents.remove(fileId);
      return Future.value();
    }

    return super.noSuchMethod(invocation);
  }
}

class FakeDriveApi implements drive.DriveApi {
  FakeDriveApi({FakeFilesResource? files})
      : fakeFiles = files ?? FakeFilesResource();

  final FakeFilesResource fakeFiles;

  @override
  drive.FilesResource get files => fakeFiles;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpClient extends http.BaseClient {
  http.BaseRequest? lastRequest;
  bool isClosed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    final bodyBytes = utf8.encode('{"status":"ok"}');
    return http.StreamedResponse(
      Stream.value(bodyBytes),
      200,
      headers: {'content-type': 'application/json'},
    );
  }

  @override
  void close() {
    isClosed = true;
    super.close();
  }
}

void main() {
  group('GoogleAuthClient', () {
    test('adiciona cabeçalhos de autenticação e encaminha requisição', () async {
      final fakeHttp = FakeHttpClient();
      final authClient = GoogleAuthClient(
        {'Authorization': 'Bearer token_123', 'X-Custom': 'header_val'},
        client: fakeHttp,
      );

      final response = await authClient.get(Uri.parse('https://example.com/api'));
      expect(response.statusCode, 200);
      expect(fakeHttp.lastRequest?.headers['Authorization'], 'Bearer token_123');
      expect(fakeHttp.lastRequest?.headers['X-Custom'], 'header_val');

      authClient.close();
      expect(fakeHttp.isClosed, isTrue);
    });

    test('instanciação padrão sem client cria client interno', () {
      final authClient = GoogleAuthClient({'Authorization': 'Bearer token'});
      expect(authClient, isNotNull);
      authClient.close();
    });
  });

  group('GoogleDriveBackupService - Autenticação & Propriedades', () {
    test('propriedades refletem o estado do usuário inicial', () {
      final account = FakeGoogleSignInAccount(
        email: 'usuario@gmail.com',
        displayName: 'Usuario Nome',
        photoUrl: 'https://foto.com/1.png',
      );
      final service = GoogleDriveBackupService(initialUser: account);

      expect(service.isSignedIn, isTrue);
      expect(service.userEmail, 'usuario@gmail.com');
      expect(service.userDisplayName, 'Usuario Nome');
      expect(service.userPhotoUrl, 'https://foto.com/1.png');
      expect(service.currentUser, account);
    });

    test('quando não autenticado, propriedades retornam null/false', () {
      final service = GoogleDriveBackupService();

      expect(service.isSignedIn, isFalse);
      expect(service.userEmail, isNull);
      expect(service.userDisplayName, isNull);
      expect(service.userPhotoUrl, isNull);
      expect(service.currentUser, isNull);
    });

    test('signIn autentica via signInHandler com sucesso', () async {
      final account = FakeGoogleSignInAccount();
      final service = GoogleDriveBackupService(
        signInHandler: () async => account,
      );

      final user = await service.signIn();
      expect(user, account);
      expect(service.isSignedIn, isTrue);
    });

    test('signIn propaga exceção caso ocorra erro', () {
      final service = GoogleDriveBackupService(
        signInHandler: () async => throw Exception('Falha simulada no signIn'),
      );

      expect(() => service.signIn(), throwsA(isA<Exception>()));
    });

    test('signInSilently autentica com sucesso', () async {
      final account = FakeGoogleSignInAccount();
      final service = GoogleDriveBackupService(
        signInSilentlyHandler: () async => account,
      );

      final user = await service.signInSilently();
      expect(user, account);
      expect(service.isSignedIn, isTrue);
    });

    test('signInSilently retorna null caso ocorra exceção silenciosa', () async {
      final service = GoogleDriveBackupService(
        signInSilentlyHandler: () async =>
            throw Exception('Falha silenciosa'),
      );

      final user = await service.signInSilently();
      expect(user, isNull);
    });

    test('signOut limpa a sessão e propaga exceção se falhar', () async {
      final account = FakeGoogleSignInAccount();
      var signOutCalled = false;
      final service = GoogleDriveBackupService(
        initialUser: account,
        signOutHandler: () async => signOutCalled = true,
      );

      expect(service.isSignedIn, isTrue);
      await service.signOut();
      expect(service.isSignedIn, isFalse);
      expect(signOutCalled, isTrue);

      final errorService = GoogleDriveBackupService(
        initialUser: account,
        signOutHandler: () async => throw Exception('Sign out error'),
      );
      expect(() => errorService.signOut(), throwsA(isA<Exception>()));
    });
  });

  group('GoogleDriveBackupService - getDriveApi', () {
    test('retorna driveApi injetado diretamente', () async {
      final fakeDrive = FakeDriveApi();
      final service = GoogleDriveBackupService(driveApi: fakeDrive);

      final api = await service.getDriveApi();
      expect(api, fakeDrive);
    });

    test('lança StateError se usuário não estiver autenticado', () {
      final service = GoogleDriveBackupService();
      expect(() => service.getDriveApi(), throwsStateError);
    });

    test('utiliza driveApiBuilder caso fornecido', () async {
      final account = FakeGoogleSignInAccount();
      final fakeDrive = FakeDriveApi();

      final service = GoogleDriveBackupService(
        initialUser: account,
        driveApiBuilder: (user) async => fakeDrive,
      );

      final api = await service.getDriveApi();
      expect(api, fakeDrive);
    });

    test('cria DriveApi com token do authorizationClient', () async {
      final account = FakeGoogleSignInAccount();
      final service = GoogleDriveBackupService(initialUser: account);

      final api = await service.getDriveApi();
      expect(api, isNotNull);
      expect(api.files, isNotNull);
    });

    test('solicita autorização de escopo se authorizationForScopes retornar null', () async {
      final client = FakeGoogleSignInAuthorizationClient()
        ..returnNullOnAuthorization = true;
      final account = FakeGoogleSignInAccount(client: client);
      final service = GoogleDriveBackupService(initialUser: account);

      final api = await service.getDriveApi();
      expect(api, isNotNull);
    });
  });

  group('GoogleDriveBackupService - Operações de Pasta e Arquivo', () {
    late FakeFilesResource fakeFiles;
    late FakeDriveApi fakeDrive;
    late GoogleDriveBackupService service;

    setUp(() {
      fakeFiles = FakeFilesResource();
      fakeDrive = FakeDriveApi(files: fakeFiles);
      service = GoogleDriveBackupService(
        driveApi: fakeDrive,
        initialUser: FakeGoogleSignInAccount(),
      );
    });

    test('getOrCreateBackupFolder cria nova pasta se não existir', () async {
      final folderId = await service.getOrCreateBackupFolder();
      expect(folderId, isNotEmpty);
      expect(fakeFiles.filesStore.length, 1);
      expect(fakeFiles.filesStore.first.name, GoogleDriveBackupService.backupFolderName);
      expect(fakeFiles.filesStore.first.mimeType, 'application/vnd.google-apps.folder');
    });

    test('getOrCreateBackupFolder reutiliza pasta existente', () async {
      final existingFolder = drive.File()
        ..id = 'existing_folder_999'
        ..name = GoogleDriveBackupService.backupFolderName
        ..mimeType = 'application/vnd.google-apps.folder'
        ..trashed = false;
      fakeFiles.filesStore.add(existingFolder);

      final folderId = await service.getOrCreateBackupFolder();
      expect(folderId, 'existing_folder_999');
      expect(fakeFiles.filesStore.length, 1);
    });

    test('getOrCreateBackupFolder lança StateError se id retornado for nulo', () {
      fakeFiles.failCreateFolder = true;
      expect(() => service.getOrCreateBackupFolder(), throwsStateError);
    });

    test('uploadBackup faz upload de arquivo JSON com nome padrão gerado', () async {
      const jsonContent = '{"version":1,"test":"data"}';
      final file = await service.uploadBackup(jsonContent: jsonContent);

      expect(file.id, isNotNull);
      expect(file.name?.startsWith('ppvdigital_backup_'), isTrue);
      expect(file.name?.endsWith('.json'), isTrue);
      expect(file.mimeType, 'application/json');

      final storedContent = utf8.decode(fakeFiles.fileContents[file.id!]!);
      expect(storedContent, jsonContent);
    });

    test('uploadBackup aceita nome de arquivo personalizado', () async {
      const jsonContent = '{"custom":"file"}';
      final file = await service.uploadBackup(
        jsonContent: jsonContent,
        fileName: 'custom_backup_file.json',
      );

      expect(file.name, 'custom_backup_file.json');
      expect(utf8.decode(fakeFiles.fileContents[file.id!]!), jsonContent);
    });

    test('listBackups retorna lista ordenada por data decrescente', () async {
      final folderId = await service.getOrCreateBackupFolder();

      final file1 = drive.File()
        ..id = 'f1'
        ..name = 'backup_1.json'
        ..parents = [folderId]
        ..createdTime = DateTime(2026);
      final file2 = drive.File()
        ..id = 'f2'
        ..name = 'backup_2.json'
        ..parents = [folderId]
        ..createdTime = DateTime(2026, 1, 10);

      fakeFiles.filesStore.addAll([file1, file2]);

      final backups = await service.listBackups();
      expect(backups.length, 2);
      expect(backups.first.id, 'f2'); // Mais recente primeiro
      expect(backups.last.id, 'f1');
    });

    test('downloadBackup recupera e decodifica conteúdo do arquivo', () async {
      const originalJson = '{"key":"value","restaurado":true}';
      final uploaded = await service.uploadBackup(jsonContent: originalJson);

      final downloaded = await service.downloadBackup(uploaded.id!);
      expect(downloaded, originalJson);
    });

    test('downloadBackup lança StateError se retorno não for Media', () {
      fakeFiles.returnNonMediaOnGet = true;
      expect(() => service.downloadBackup('file_123'), throwsStateError);
    });

    test('pruneOldBackups remove arquivos com mais de 30 dias e mantém os recentes', () async {
      final folderId = await service.getOrCreateBackupFolder();
      final now = DateTime(2026, 9, 13, 12);

      // Arquivo recente (5 dias atrás)
      final recentFile = drive.File()
        ..id = 'recent_1'
        ..name = 'ppvdigital_backup_recent.json'
        ..parents = [folderId]
        ..createdTime = now.subtract(const Duration(days: 5));

      // Arquivo antigo (35 dias atrás)
      final oldFile1 = drive.File()
        ..id = 'old_1'
        ..name = 'ppvdigital_backup_old1.json'
        ..parents = [folderId]
        ..createdTime = now.subtract(const Duration(days: 35));

      // Arquivo muito antigo (60 dias atrás)
      final oldFile2 = drive.File()
        ..id = 'old_2'
        ..name = 'ppvdigital_backup_old2.json'
        ..parents = [folderId]
        ..createdTime = now.subtract(const Duration(days: 60));

      // Arquivo sem ID ou sem createdTime (deve ser ignorado)
      final incompleteFile = drive.File()
        ..name = 'incomplete.json'
        ..parents = [folderId];

      fakeFiles.filesStore.addAll([recentFile, oldFile1, oldFile2, incompleteFile]);

      final deleted = await service.pruneOldBackups(now: now);

      expect(deleted, 2);
      expect(fakeFiles.filesStore.any((f) => f.id == 'recent_1'), isTrue);
      expect(fakeFiles.filesStore.any((f) => f.id == 'old_1'), isFalse);
      expect(fakeFiles.filesStore.any((f) => f.id == 'old_2'), isFalse);
    });

    test('pruneOldBackups trata falhas individuais de delete sem interromper execução', () async {
      final folderId = await service.getOrCreateBackupFolder();
      final now = DateTime(2026, 9, 13, 12);

      final oldFile = drive.File()
        ..id = 'old_error'
        ..name = 'ppvdigital_backup_err.json'
        ..parents = [folderId]
        ..createdTime = now.subtract(const Duration(days: 40));

      fakeFiles.filesStore.add(oldFile);
      fakeFiles.failDelete = true;

      final deleted = await service.pruneOldBackups(now: now);

      expect(deleted, 0); // Não incrementou por causa da falha capturada
    });

    test('pruneOldBackups utiliza DateTime.now() quando now não for fornecido', () async {
      final folderId = await service.getOrCreateBackupFolder();
      final oldFile = drive.File()
        ..id = 'old_default_now'
        ..name = 'ppvdigital_backup_default.json'
        ..parents = [folderId]
        ..createdTime = DateTime.now().subtract(const Duration(days: 45));

      fakeFiles.filesStore.add(oldFile);

      final deleted = await service.pruneOldBackups();
      expect(deleted, 1);
      expect(fakeFiles.filesStore.any((f) => f.id == 'old_default_now'), isFalse);
    });
  });
}
