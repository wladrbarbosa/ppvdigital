import 'dart:developer';
import 'package:timezone/browser.dart' as tz_browser;
import 'package:timezone/data/latest_all.dart' as tz_fallback;

Future<void> initTimeZones() async {
  try {
    await tz_browser.initializeTimeZone();
  } catch (e) {
    log(
      'Failed to initialize timezone on web via asset: $e. Using in-memory fallback.',
    );
    try {
      tz_fallback.initializeTimeZones();
    } catch (fallbackError) {
      log('Failed to initialize in-memory timezone fallback: $fallbackError');
    }
  }
}
