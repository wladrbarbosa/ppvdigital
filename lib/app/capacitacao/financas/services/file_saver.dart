import 'package:ppvdigital/app/capacitacao/financas/services/file_saver_non_web.dart'
    if (dart.library.html) 'package:ppvdigital/app/capacitacao/financas/services/file_saver_web.dart';

Future<String?> saveCsvFile(String content, String fileName) =>
    saveCsvFileImpl(content, fileName);
