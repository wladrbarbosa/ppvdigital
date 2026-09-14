// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;

Future<String?> pickJsonFileImpl() {
  final completer = Completer<String?>();
  final input = html.FileUploadInputElement()..accept = '.json,application/json';
  input.click();
  input.onChange.listen((event) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    final file = files.first;
    final reader = html.FileReader();
    reader.onLoadEnd.listen((_) {
      if (!completer.isCompleted) completer.complete(reader.result as String?);
    });
    reader.onError.listen((_) {
      if (!completer.isCompleted) completer.complete(null);
    });
    reader.readAsText(file);
  });
  return completer.future;
}
