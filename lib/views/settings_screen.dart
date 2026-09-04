import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../utils/app_translations.dart';
import 'server_config_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _unsyncedCount = 0;
  bool _isSyncing = false;
  String _serverBaseUrl = "http://192.168.1.26:8000";

  @override
  void initState() {
    super.initState();
    _loadSettingsData();
  }

  Future<void> _loadSettingsData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('backend_base_url');
    final logs = await DatabaseHelper.instance.getUnsyncedLogs();

    setState(() {
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _serverBaseUrl = savedUrl;
      }
      _unsyncedCount = logs.length;
    });
  }

  Future<void> _triggerManualSync() async {
    setState(() => _isSyncing = true);

    final authService = AuthService(backendBaseUrl: _serverBaseUrl);
    final syncService = SyncService(backendBaseUrl: _serverBaseUrl);

    final String? token = await authService.login("aggregator1", "SecurePassword123!");

    if (token != null) {
      await syncService.performSequentialSync(token);
      await _loadSettingsData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync completed successfully!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to authenticate with $_serverBaseUrl'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }

    if (mounted) setState(() => _isSyncing = false);
  }

  void _openServerConfig() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServerConfigScreen(
          onConfigComplete: () {
            Navigator.pop(context);
            _loadSettingsData();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppTranslations.currentLang,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            title: Text(AppTranslations.text('settings_title')),
            backgroundColor: const Color(0xFF121212),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Card(
                  color: Colors.grey.shade900,
                  child: ListTile(
                    leading: const Icon(Icons.language, color: Color(0xFF008080)),
                    title: Text(AppTranslations.text('language_label'), style: const TextStyle(color: Colors.white)),
                    subtitle: Text(lang == 'en' ? 'English' : 'Filipino (Tagalog)', style: const TextStyle(color: Colors.grey)),
                    trailing: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'en', label: Text('EN')),
                        ButtonSegment(value: 'tl', label: Text('TL')),
                      ],
                      selected: {lang},
                      onSelectionChanged: (Set<String> newSelection) {
                        AppTranslations.changeLanguage(newSelection.first);
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) return const Color(0xFF008080);
                          return Colors.transparent;
                        }),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  color: Colors.grey.shade900,
                  child: ListTile(
                    leading: const Icon(Icons.dns, color: Color(0xFF008080)),
                    title: Text(AppTranslations.text('paired_server'), style: const TextStyle(color: Colors.white)),
                    subtitle: Text(_serverBaseUrl, style: const TextStyle(color: Colors.grey, fontFamily: 'monospace')),
                    trailing: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF008080)),
                      onPressed: _openServerConfig,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  color: Colors.grey.shade900,
                  child: ListTile(
                    leading: const Icon(Icons.sd_card, color: Color(0xFF008080)),
                    title: Text(AppTranslations.text('pending_scans'), style: const TextStyle(color: Colors.white)),
                    subtitle: Text("$_unsyncedCount log(s)", style: const TextStyle(color: Colors.grey)),
                    trailing: IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _loadSettingsData,
                    ),
                  ),
                ),

                const Spacer(),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008080),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSyncing ? null : _triggerManualSync,
                  icon: _isSyncing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.sync, color: Colors.white),
                  label: Text(
                    _isSyncing ? AppTranslations.text('syncing') : AppTranslations.text('sync_button'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}