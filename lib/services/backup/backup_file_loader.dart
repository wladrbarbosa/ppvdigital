import 'package:ppvdigital/services/backup/backup_file_loader_non_web.dart'
    if (dart.library.html) 'package:ppvdigital/services/backup/backup_file_loader_web.dart';

/// Helper multiplataforma para carregar o conteúdo de um arquivo JSON (.json) de backup.
Future<String?> pickJsonFile() => pickJsonFileImpl();
