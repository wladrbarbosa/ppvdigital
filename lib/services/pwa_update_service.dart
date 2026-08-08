import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ppvdigital/services/pwa_update_stub.dart'
    if (dart.library.js_interop) 'package:ppvdigital/services/pwa_update_web.dart';

class PwaUpdateService {
  /// Clears PWA CacheStorage, unregisters Service Workers, and forces window reload.
  static void forceAppUpdate() {
    if (kIsWeb) {
      try {
        clearAppCacheAndReload();
      } catch (e) {
        debugPrint('Error triggering clearAppCacheAndReload: $e');
      }
    }
  }

  /// Checks server's version.json against local version string (e.g. "0.23.0+1")
  static Future<bool> isUpdateAvailable(String currentVersion) async {
    if (!kIsWeb) return false;

    try {
      final cacheBustUrl = Uri.parse(
        'assets/version.json?t=${DateTime.now().millisecondsSinceEpoch}',
      );
      final response = await http.get(cacheBustUrl);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final String serverVersion =
            '${data['version']}+${data['build_number']}';

        // Strip leading non-numeric characters (e.g. 'b0.25.2+1' -> '0.25.2+1')
        final String cleanCurrentVersion = currentVersion
            .replaceAll(RegExp(r'^[^\d]+'), '')
            .trim();

        debugPrint(
          '[PWA] Current local version: $currentVersion (cleaned: $cleanCurrentVersion)',
        );
        debugPrint('[PWA] Server version: $serverVersion');

        return serverVersion.trim() != cleanCurrentVersion;
      }
    } catch (e) {
      debugPrint('[PWA] Error checking for version update: $e');
    }
    return false;
  }
}
