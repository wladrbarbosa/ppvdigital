import 'timezone_helper_non_web.dart'
    if (dart.library.html) 'timezone_helper_web.dart';

Future<void> configureTimeZones() async {
  await initTimeZones();
}
