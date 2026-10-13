import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTranslations {
  static final ValueNotifier<String> currentLang = ValueNotifier<String>('en');

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General & Common
      'back': 'Back',
      'skip': 'Skip',
      'close': 'Close',

      // Home Screen
      'app_title': 'NiyoSense Field',
      'app_role': 'Small-Scale Aggregator',
      'server_live': 'Server Live',
      'server_offline': 'Server Offline',
      'pending_scans': 'Pending Scans',
      'pending_scans_count': '{count} Pending Scans',
      'stored_local_sqlite': 'Stored in local SQLite database',
      'sync_button': 'SYNC NOW TO SERVER',
      'syncing_button': 'SYNCING TO HOST...',
      'all_synced_msg': 'All local logs are already synced!',
      'sync_success_msg': 'Synchronization complete! Logs updated in PostgreSQL.',
      'sync_failed_msg': 'Sync failed: Cannot connect to server',
      'maturity_profiling_title': 'Coconut Maturity Profiling',
      'maturity_profiling_sub': 'Dual-Modality Visual & Acoustic Field Profiler',
      'start_scan': 'START NEW SCAN',
      'storage_label': 'Storage',
      'storage_val': 'Local SQLite',
      'model_label': 'AI Model',
      'model_val': 'TFLite Ready',

      // Cluster / Bungkos Sampling
      'cluster_notice_title': 'Cluster Maturity Baseline',
      'cluster_notice_body': 'The scanned coconut serves as the base maturity stage for the entire cluster (bungkos) it was harvested from. Please ensure this coconut is kept and matched with its original bunch.',
      'cluster_sampling_tip': 'Select 1 sample coconut per cluster (bungkos)',

      // Visual Scan Screen
      'step_1_title': 'Step 1: Visual',
      'step_2_title': 'Step 2: Acoustic',
      'position_coconut': 'Position coconut within frame',
      'ai_ready_step1': 'AI Ready • Step 1 of 2',
      'photo_auto_advance': 'Photo taken → auto-advances to Step 2: Acoustic →',

      // Acoustic Scan Screen
      'recording_tap_signal': 'Recording tapping signal...',
      'ready_to_record': 'Ready to record',
      'tapping_intensity': 'Tapping Intensity',
      'ideal_range': 'Ideal Range',
      'tap_equator_title': 'Tap the equator (middle)',
      'tap_equator_desc': 'Strike the widest center section of the coconut for the most accurate acoustic reading.',
      'tap_to_stop': 'Tap to Stop',
      'start_recording': 'Start Recording',
      'mic_permission_req': 'Microphone permission is required to record tapping sound.',
      'incomplete_data_title': 'Incomplete Data',
      'reduced_accuracy_warning': 'Reduced accuracy warning',
      'incomplete_data_desc': 'Are you sure you want to proceed with only a photo scan? It is highly recommended you take an acoustic recording as well for more accurate results.',
      'record_audio_btn': 'Record Audio',
      'proceed_photo_only_btn': 'Proceed with Photo Only',

      // Scan Result Screen
      'scan_results_title': 'Scan Results',
      'performing_inference': 'Performing multimodal inference...',
      'fused_confidence': 'Fused Confidence',
      'visual_model_husk': 'Visual Model (Husk)',
      'audio_model_spec': 'Audio Model (Spectrogram)',
      'storage_status': 'Storage Status',
      'saved_sqlite_ready': 'Saved to SQLite (Ready)',
      'return_home': 'RETURN TO HOME',
      'unrecognized_object': 'UNRECOGNIZED OBJECT',
      'skipped_audio': 'N/A (Skipped)',

      // Settings Screen
      'settings_title': 'Server Configuration',
      'settings_sub': 'Connect to your NiyoSense web dashboard',
      'connection_status': 'Connection Status',
      'status_connected': 'Connected',
      'status_disconnected': 'Disconnected',
      'status_live': 'Live',
      'status_offline': 'Offline',
      'language_label': 'Language / Wika',
      'language_sub': 'English / Filipino (Tagalog)',
      'web_dashboard_url': 'Web Dashboard URL / IP Address',
      'url_hint': 'e.g., 192.168.1.26:8000 or dashboard.niyosense.local',
      'connect_server_btn': 'Connect to Server',
      'connecting_btn': 'CONNECTING...',
      'pending_sync_scans': 'Pending Sync Scans',
      'device_id': 'Device ID',
      'app_version': 'App Version',
      'model_engine': 'Model Engine',
      'connected_sync_msg': 'Connected & synchronized with server',
      'cannot_reach_server': 'Cannot reach server. Ensure Django is running on port 8000.',
      'operator_account': 'Operator Account',
      'operator_account_sub': 'Identity assigned to this phone for grading logs',
      'operator_username': 'Username',
      'operator_password': 'Password',
      'logged_in_as': 'Logged in as',
      'current_operator': 'Current Operator',
      'operator_active': 'Active',
      'switch_account': 'Switch Operator',
      'login_title': 'Field Operator Login',
      'login_sub': 'Sign in with your aggregator credentials to start recording coconut scans',
      'login_ask_admin': 'Ask your admin for your login credentials',
      'login_button': 'Sign In',
      'login_signing_in': 'Signing In...',
      'login_success': 'Welcome, {user}! Successfully authenticated.',
      'login_invalid': 'Invalid username or password. Check with your admin.',
      'logout_btn': 'Log Out',
    },
    'tl': {
      // General & Common
      'back': 'Bumalik',
      'skip': 'Laktawan',
      'close': 'Isara',

      // Home Screen
      'app_title': 'NiyoSense Field',
      'app_role': 'Maliit na Aggregator',
      'server_live': 'Buhay ang Server',
      'server_offline': 'Offline ang Server',
      'pending_scans': 'Mga Nakabinbing Scan',
      'pending_scans_count': '{count} Nakabinbing Scan',
      'stored_local_sqlite': 'Naka-imbak sa lokal na SQLite database',
      'sync_button': 'ISABAY SA SERVER NGAYON',
      'syncing_button': 'NAGSASABAY SA HOST...',
      'all_synced_msg': 'Lahat ng lokal na scan ay nai-sync na!',
      'sync_success_msg': 'Kumpleto ang pagsasabay! Na-update ang mga log sa PostgreSQL.',
      'sync_failed_msg': 'Bigo ang pag-sync: Hindi makakonekta sa server',
      'maturity_profiling_title': 'Pagsusuri ng Kapanahunan ng Niyog',
      'maturity_profiling_sub': 'Dual-Modality Biswal at Akustikong Pagsusuri',
      'start_scan': 'MAGSIMULA NG BAGONG SCAN',
      'storage_label': 'Imbakan',
      'storage_val': 'Lokal na SQLite',
      'model_label': 'AI Model',
      'model_val': 'Handa ang TFLite',

      // Cluster / Bungkos Sampling
      'cluster_notice_title': 'Batayan ng Buong Bungkos',
      'cluster_notice_body': 'Ang resulta ng bukong ito ay nagsisilbing batayan ng maturity para sa buong bungkos na pinag-anihan nito. Siguraduhing itabi o itugma ang bukong ito sa kanyang orihinal na bungkos.',
      'cluster_sampling_tip': 'Pumili ng 1 kinatawang buko mula sa bawat bungkos',

      // Visual Scan Screen
      'step_1_title': 'Hakbang 1: Biswal',
      'step_2_title': 'Hakbang 2: Akustika',
      'position_coconut': 'Ipuwesto ang buko sa loob ng frame',
      'ai_ready_step1': 'Handa ang AI • Hakbang 1 ng 2',
      'photo_auto_advance': 'Kunan ng litrato → kusang tutuloy sa Hakbang 2: Akustika →',

      // Acoustic Scan Screen
      'recording_tap_signal': 'Nirerekord ang tunog ng pagkatok...',
      'ready_to_record': 'Handang magrekord',
      'tapping_intensity': 'Lakas ng Pagkatok',
      'ideal_range': 'Tamang Antas',
      'tap_equator_title': 'Katukin ang gitna (ekwador)',
      'tap_equator_desc': 'Patunugin ang pinakamalapad na gitnang bahagi ng buko para sa pinakatumpak na pagbasa.',
      'tap_to_stop': 'Pindutin para Ihinto',
      'start_recording': 'Magsimula ng Pagrekord',
      'mic_permission_req': 'Kailangan ang pahintulot sa mikropono upang mairekord ang tunog ng pagkatok.',
      'incomplete_data_title': 'Kulang ang Datos',
      'reduced_accuracy_warning': 'Babala: Maaaring mabawasan ang katumpakan',
      'incomplete_data_desc': 'Sigurado ka bang nais mong magpatuloy sa litrato lamang? Lubos na inirerekomenda ang pagrekord ng tunog para sa mas tumpak na pagsusuri.',
      'record_audio_btn': 'Magrekord ng Tunog',
      'proceed_photo_only_btn': 'Magpatuloy sa Litrato Lamang',

      // Scan Result Screen
      'scan_results_title': 'Mga Resulta ng Scan',
      'performing_inference': 'Isinasagawa ang multimodal na pagsusuri...',
      'fused_confidence': 'Pinagsamang Kumpiyansa',
      'visual_model_husk': 'Biswal na Modelo (Bunot)',
      'audio_model_spec': 'Akustikong Modelo (Tunog)',
      'storage_status': 'Katayuan ng Imbakan',
      'saved_sqlite_ready': 'Nai-save sa SQLite (Handa)',
      'return_home': 'BUMALIK SA TAHANAN',
      'unrecognized_object': 'HINDI KILALANG BAGAY',
      'skipped_audio': 'N/A (Nilaktawan)',

      // Settings Screen
      'settings_title': 'Konpigurasyon ng Server',
      'settings_sub': 'Kumonekta sa iyong NiyoSense web dashboard',
      'connection_status': 'Katayuan ng Koneksyon',
      'status_connected': 'Konektado',
      'status_disconnected': 'Hindi Konektado',
      'status_live': 'Buhay',
      'status_offline': 'Offline',
      'language_label': 'Wika / Language',
      'language_sub': 'Filipino (Tagalog) / English',
      'web_dashboard_url': 'URL o IP Address ng Web Dashboard',
      'url_hint': 'hal., 192.168.1.26:8000 o dashboard.niyosense.local',
      'connect_server_btn': 'Kumonekta sa Server',
      'connecting_btn': 'KUMOKONEKTA...',
      'pending_sync_scans': 'Mga Nakabinbing Scan',
      'device_id': 'ID ng Device',
      'app_version': 'Bersyon ng App',
      'model_engine': 'Engine ng Model',
      'connected_sync_msg': 'Konektado at naisabay sa server',
      'cannot_reach_server': 'Hindi maabot ang server. Tiyaking tumatakbo ang Django sa port 8000.',
      'operator_account': 'Account ng Operator',
      'operator_account_sub': 'Pagkakakilanlan ng teleponong ito sa mga tala',
      'operator_username': 'Username',
      'operator_password': 'Password',
      'logged_in_as': 'Naka-log in bilang',
      'current_operator': 'Kasalukuyang Operator',
      'operator_active': 'Aktibo',
      'switch_account': 'Palitan ang Operator',
      'login_title': 'Login ng Field Operator',
      'login_sub': 'Mag-log in gamit ang iyong mga kredensyal ng aggregator upang magsimula ng pagsusuri ng niyog',
      'login_ask_admin': 'Humingi sa admin para sa iyong login credentials',
      'login_button': 'Mag-login',
      'login_signing_in': 'Nagla-login...',
      'login_success': 'Maligayang pagdating, {user}! Tagumpay ang pag-authenticate.',
      'login_invalid': 'Maling username o password. Sumangguni sa iyong admin.',
      'logout_btn': 'Mag-logout',
    },
  };

  static String text(String key) {
    return _localizedValues[currentLang.value]?[key] ?? _localizedValues['en']?[key] ?? key;
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