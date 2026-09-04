import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTranslations {
  static final ValueNotifier<String> currentLang = ValueNotifier<String>('en');

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'settings_title': 'App Settings & Sync',
      'language_label': 'Language / Wika',
      'paired_server': 'Paired Server Endpoint',
      'pending_scans': 'Pending Offline Scans',
      'sync_button': 'SYNC NOW TO SERVER',
      'syncing': 'SYNCING...',
      'start_scan': 'START NEW SCAN',
    },
    'tl': {
      'settings_title': 'Mga Setting at Sync',
      'language_label': 'Wika / Language',
      'paired_server': 'Konektadong Server IP',
      'pending_scans': 'Mga Hindi Pa Naisasabay na Scan',
      'sync_button': 'ISABAY SA SERVER NGAYON',
      'syncing': 'NAGSASABAY...',
      'start_scan': 'MAGSIMULA NG BAGONG SCAN',
    },
  };

  static String text(String key) {
    return _localizedValues[currentLang.value]?[key] ?? key;
  }

  static Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    currentLang.value = prefs.getString('app_language') ?? 'en';
  }

  static Future<void> changeLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);
    currentLang.value = lang;
  }
}