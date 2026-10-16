import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String appVersion = "1.3.8";
  static const int buildNumber = 10;
  static const String fullVersionString = "NiyoSense Field v$appVersion";
  static const String modelEngine = "Vision v2.5.0 (Hard 3-Gate Pre-Inference)";
  static const String defaultServerUrl = "http://192.168.1.26:8000";

  /// Returns a persistent unique device identifier (e.g. NYS-PH-A1B2C3D4)
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('persistent_device_id');
    if (id == null || id.isEmpty || id == 'NYS-FIELD-0024') {
      final randomSuffix = DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase().padLeft(6, '0');
      id = "NYS-DEV-$randomSuffix";
      await prefs.setString('persistent_device_id', id);
    }
    return id;
  }
}
