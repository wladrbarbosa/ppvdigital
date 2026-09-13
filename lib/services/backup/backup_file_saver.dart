import 'package:ppvdigital/services/backup/backup_file_saver_non_web.dart'
    if (dart.library.html) 'package:ppvdigital/services/backup/backup_file_saver_web.dart';

Future<String?> saveBackupFile(String content, String fileName) =>
    saveBackupFileImpl(content, fileName);
