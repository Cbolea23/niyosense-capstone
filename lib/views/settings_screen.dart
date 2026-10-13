import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/update_service.dart';
import '../utils/app_translations.dart';
import '../utils/app_config.dart';
import 'server_config_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const SettingsScreen({super.key, this.onLogout});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _ipController = TextEditingController(text: "192.168.1.26:8000");
  final TextEditingController _usernameController = TextEditingController(text: "maria_santos");
  final TextEditingController _passwordController = TextEditingController(text: "Password123!");
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isCheckingUpdate = false;
  UpdateInfo? _availableUpdate;
  int _pendingLogsCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    await _loadSavedServerUrl();
    await _loadOperatorCredentials();
    await _loadPendingLogs();
    await _checkServerHealth();
    _silentCheckForUpdate();
  }

  Future<void> _silentCheckForUpdate() async {
    final info = await UpdateService.checkForUpdate();
    if (mounted && info != null && info.hasUpdate) {
      setState(() => _availableUpdate = info);
    }
  }

  Future<void> _manualCheckForUpdate() async {
    setState(() => _isCheckingUpdate = true);
    final info = await UpdateService.checkForUpdate();
    if (mounted) {
      setState(() {
        _isCheckingUpdate = false;
        _availableUpdate = (info != null && info.hasUpdate) ? info : null;
      });

      if (info != null && info.hasUpdate) {
        UpdateService.showUpdateDialog(context, info);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTranslations.text('app_up_to_date')),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    }
  }

  Future<void> _loadOperatorCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('operator_username');
    final savedPass = prefs.getString('operator_password');
    if (mounted) {
      setState(() {
        if (savedUser != null && savedUser.isNotEmpty) {
          _usernameController.text = savedUser;
        }
        if (savedPass != null && savedPass.isNotEmpty) {
          _passwordController.text = savedPass;
        }
      });
    }
  }

  Future<void> _saveOperatorCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('operator_username', _usernameController.text.trim());
    await prefs.setString('operator_password', _passwordController.text.trim());
  }

  Future<void> _loadSavedServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('backend_base_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      if (mounted) {
        setState(() {
          _ipController.text = savedUrl.replaceAll('http://', '').replaceAll('https://', '');
        });
      }
    }
  }

  Future<void> _loadPendingLogs() async {
    final logs = await DatabaseHelper.instance.getUnsyncedLogs();
    if (mounted) {
      setState(() {
        _pendingLogsCount = logs.length;
      });
    }
  }

  String _getFormattedUrl() {
    String raw = _ipController.text.trim();
    if (raw.isEmpty) return "http://192.168.1.26:8000";
    if (!raw.startsWith("http://") && !raw.startsWith("https://")) {
      return "http://$raw";
    }
    return raw;
  }

  Future<bool> _pingServer(String baseUrl) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/admin/login/'))
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200 || response.statusCode == 302 || response.statusCode == 404;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkServerHealth() async {
    final formattedUrl = _getFormattedUrl();
    bool isAlive = await _pingServer(formattedUrl);
    if (mounted) {
      setState(() {
        _isConnected = isAlive;
      });
    }
  }

  Future<void> _connectToServer() async {
    setState(() => _isConnecting = true);

    final formattedUrl = _getFormattedUrl();
    bool isAlive = await _pingServer(formattedUrl);

    if (!isAlive) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isConnecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTranslations.text('cannot_reach_server')),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return;
    }

    // Save validated URL and credentials locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backend_base_url', formattedUrl);
    await _saveOperatorCredentials();

    // Perform Authentication and Sequential Offline Sync
    final authService = AuthService(backendBaseUrl: formattedUrl);
    final syncService = SyncService(backendBaseUrl: formattedUrl);

    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();
    final String? token = await authService.login(username, password);

    if (token != null) {
      await syncService.performSequentialSync(token);
      await _loadPendingLogs();

      if (mounted) {
        setState(() => _isConnected = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppTranslations.text('connected_sync_msg')} ($formattedUrl)'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() => _isConnected = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Server connected! (Note: Create superuser "aggregator1" for sync)'),
            backgroundColor: Colors.amber.shade800,
          ),
        );
      }
    }

    if (mounted) setState(() => _isConnecting = false);
  }

  void _openQrScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServerConfigScreen(
          onConfigComplete: () {
            Navigator.pop(context);
            _initializeSettings();
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
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.text('settings_title'),
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  AppTranslations.text('settings_sub'),
                  style: const TextStyle(color: Colors.black45, fontSize: 11),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Language Selection Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFECFDF5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.language, color: Color(0xFF10B981), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.text('language_label'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppTranslations.text('language_sub'),
                                style: const TextStyle(fontSize: 11, color: Colors.black45),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => AppTranslations.changeLanguage('en'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: lang == 'en' ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: lang == 'en'
                                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                      : null,
                                ),
                                child: Text(
                                  "EN",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: lang == 'en' ? const Color(0xFF10B981) : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => AppTranslations.changeLanguage('tl'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: lang == 'tl' ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: lang == 'tl'
                                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                      : null,
                                ),
                                child: Text(
                                  "TL",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: lang == 'tl' ? const Color(0xFF10B981) : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Connection Status Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isConnected ? const Color(0xFFECFDF5) : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _isConnected ? const Color(0xFFA7F3D0) : Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _isConnected ? const Color(0xFFD1FAE5) : Colors.red.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isConnected ? Icons.check_circle : Icons.error_outline,
                          color: _isConnected ? const Color(0xFF10B981) : Colors.red.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isConnected ? AppTranslations.text('status_connected') : AppTranslations.text('status_disconnected'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _isConnected ? const Color(0xFF065F46) : Colors.red.shade800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _ipController.text,
                              style: TextStyle(
                                fontSize: 12,
                                color: _isConnected ? const Color(0xFF047857) : Colors.red.shade600,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isConnected ? const Color(0xFFA7F3D0) : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(radius: 3, backgroundColor: _isConnected ? const Color(0xFF10B981) : Colors.red),
                            const SizedBox(width: 6),
                            Text(
                              _isConnected ? AppTranslations.text('status_live') : AppTranslations.text('status_offline'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _isConnected ? const Color(0xFF065F46) : Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // IP Input Section
                Text(
                  AppTranslations.text('web_dashboard_url'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ipController,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.dns_outlined, color: Colors.black45),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _openQrScanner,
                      icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF10B981)),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFECFDF5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  AppTranslations.text('url_hint'),
                  style: const TextStyle(color: Colors.black38, fontSize: 11),
                ),
                const SizedBox(height: 20),

                // Connect Button (above Current Operator)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isConnecting ? null : _connectToServer,
                  icon: _isConnecting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.wifi, color: Colors.white, size: 20),
                  label: Text(
                    _isConnecting ? AppTranslations.text('connecting_btn') : AppTranslations.text('connect_server_btn'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),

                // Operator Account Section (without username/password input fields)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFECFDF5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person, color: Color(0xFF10B981), size: 20),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppTranslations.text('current_operator'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                  ),
                                  Text(
                                    AppTranslations.text('operator_account_sub'),
                                    style: const TextStyle(fontSize: 10.5, color: Colors.black45),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              AppTranslations.text('operator_active'),
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Logged-in Operator User Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.badge, color: Color(0xFF10B981), size: 18),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppTranslations.text('logged_in_as'),
                                      style: const TextStyle(color: Colors.black45, fontSize: 10),
                                    ),
                                    Text(
                                      _usernameController.text.isNotEmpty ? _usernameController.text : "maria_santos",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (widget.onLogout != null)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: Colors.red.shade700,
                                ),
                                onPressed: () async {
                                  final nav = Navigator.of(context);
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.remove('access_token');
                                  if (mounted) {
                                    nav.pop();
                                    widget.onLogout!();
                                  }
                                },
                                icon: const Icon(Icons.logout, size: 14),
                                label: Text(AppTranslations.text('logout_btn'), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Update Notification Banner (if newer version detected)
                if (_availableUpdate != null && _availableUpdate!.hasUpdate) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.new_releases, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${AppTranslations.text('update_banner_title')}: v${_availableUpdate!.latestVersion}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF065F46)),
                              ),
                              Text(
                                AppTranslations.text('update_banner_sub'),
                                style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: () => UpdateService.showUpdateDialog(context, _availableUpdate!),
                          child: Text(
                            AppTranslations.text('update_now_btn'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Device Info & Pending Scans Table
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(AppTranslations.text('pending_sync_scans'), "$_pendingLogsCount local"),
                      const Divider(height: 1),
                      _buildInfoRow(AppTranslations.text('device_id'), "NYS-FIELD-0024"),
                      const Divider(height: 1),
                      _buildInfoRow(AppTranslations.text('app_version'), AppConfig.fullVersionString),
                      const Divider(height: 1),
                      _buildInfoRow(AppTranslations.text('model_engine'), AppConfig.modelEngine),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF059669),
                            side: const BorderSide(color: Color(0xFF6EE7B7)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            minimumSize: const Size.fromHeight(40),
                          ),
                          onPressed: _isCheckingUpdate ? null : _manualCheckForUpdate,
                          icon: _isCheckingUpdate
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669)))
                              : const Icon(Icons.sync, size: 18),
                          label: Text(
                            _isCheckingUpdate
                                ? AppTranslations.text('checking_update')
                                : AppTranslations.text('check_update_btn'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }
}