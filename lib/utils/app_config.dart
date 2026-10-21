import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String appVersion = "1.5.0";
  static const int buildNumber = 22;
  static const String fullVersionString = "NiyoSense Field v$appVersion";
  static const String modelEngine = "Vision v2.6.0 (Controlled Station Guide & 70/30 Fusion)";
  static const String defaultServerUrl = "https://niyosense.me";

  /// Sanitizes user-entered or QR-scanned server URLs by stripping accidental
  /// paths (/install, /download-app, /admin, /api/...) and trailing slashes.
  static String sanitizeServerUrl(String? rawUrl) {
    String clean = (rawUrl ?? '').trim();
    if (clean.isEmpty) return defaultServerUrl;

    // Automatically upgrade legacy ephemeral Cloudflare quick tunnels or old hardcoded LAN IP to permanent domain
    if (clean.contains('.trycloudflare.com') || clean.contains('192.168.1.26')) {
      return defaultServerUrl;
    }

    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      final isSecureTunnel = clean.contains('niyosense.me') ||
          clean.contains('.trycloudflare.com') ||
          clean.contains('.ngrok') ||
          clean.contains('.loca.lt');
      clean = '${isSecureTunnel ? 'https' : 'http'}://$clean';
    }

    try {
      final uri = Uri.parse(clean);
      final portPart = (uri.hasPort && uri.port != 80 && uri.port != 443) ? ':${uri.port}' : '';
      return '${uri.scheme}://${uri.host}$portPart';
    } catch (_) {
      while (clean.endsWith('/')) {
        clean = clean.substring(0, clean.length - 1);
      }
      for (final suffix in ['/install', '/download-app', '/admin', '/logs']) {
        if (clean.toLowerCase().endsWith(suffix)) {
          clean = clean.substring(0, clean.length - suffix.length);
        }
      }
      return clean;
    }
  }

  /// Returns a persistent unique device identifier (e.g. NYS-DEV-A1B2C3)
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('persistent_device_id');
    if (id == null || id.isEmpty || id == 'NYS-FIELD-0024') {
      final randomSuffix = DateTime.now().microsecondsSinceEpoch.toRadixString(36).toUpperCase();
      final tail = randomSuffix.length > 6 ? randomSuffix.substring(randomSuffix.length - 6) : randomSuffix.padLeft(6, '0');
      id = "NYS-DEV-$tail";
      await prefs.setString('persistent_device_id', id);
    }
    return id;
  }
}
