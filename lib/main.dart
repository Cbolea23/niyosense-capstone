import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'database/db_helper.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'services/update_service.dart';
import 'utils/app_translations.dart';
import 'utils/app_config.dart';
import 'utils/eula_modal.dart';
import 'views/visual_scan_screen.dart';
import 'views/settings_screen.dart';
import 'views/login_screen.dart';


List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTranslations.loadSavedLanguage();
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint("Camera initialization error: $e");
  }
  runApp(const NiyoSenseApp());
}

class NiyoSenseApp extends StatefulWidget {
  const NiyoSenseApp({super.key});

  @override
  State<NiyoSenseApp> createState() => _NiyoSenseAppState();
}

class _NiyoSenseAppState extends State<NiyoSenseApp> {
  bool _isCheckingAuth = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString('operator_username');
    final token = prefs.getString('access_token');
    if (mounted) {
      setState(() {
        _isLoggedIn = (user != null && user.isNotEmpty && token != null && token.isNotEmpty);
        _isCheckingAuth = false;
      });
    }
  }

  void _onLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  void _onLogout() {
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppTranslations.currentLang,
      builder: (context, lang, _) {
        return MaterialApp(
          title: 'NiyoSense Mobile',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF10B981),
            scaffoldBackgroundColor: const Color(0xFF091512),
          ),
          home: _isCheckingAuth
              ? const Scaffold(
                  backgroundColor: Color(0xFF081C15),
                  body: Center(
                    child: CircularProgressIndicator(color: Color(0xFF10B981)),
                  ),
                )
              : _isLoggedIn
                  ? HomeScreen(onLogout: _onLogout)
                  : LoginScreen(onLoginSuccess: _onLoginSuccess),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const HomeScreen({super.key, required this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _pendingLogsCount = 0;
  bool _isSyncing = false;
  bool _isServerOnline = false;
  String _serverBaseUrl = AppConfig.defaultServerUrl;
  String _currentOperator = "maria_santos";
  UpdateInfo? _availableUpdate;

  @override
  void initState() {
    super.initState();
    _loadHomeScreenData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkEulaAcceptance();
    });
  }

  Future<void> _checkEulaAcceptance() async {
    final accepted = await EulaModal.isAccepted();
    if (!accepted && mounted) {
      await EulaModal.show(context, requireAcceptance: true);
    }
  }

  // Reloads IP settings, checks pending SQLite logs, and pings server
  Future<void> _loadHomeScreenData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('backend_base_url');
    final savedUser = prefs.getString('operator_username');
    final unsyncedLogs = await DatabaseHelper.instance.getUnsyncedLogs();

    String activeUrl = (savedUrl != null && savedUrl.isNotEmpty)
        ? AppConfig.sanitizeServerUrl(savedUrl)
        : AppConfig.defaultServerUrl;

    if (savedUrl != null && savedUrl != activeUrl) {
      await prefs.setString('backend_base_url', activeUrl);
    }

    bool online = await _pingServer(activeUrl);
    UpdateInfo? updateInfo;
    if (online) {
      updateInfo = await UpdateService.checkForUpdate();
    }

    if (mounted) {
      setState(() {
        _serverBaseUrl = activeUrl;
        _pendingLogsCount = unsyncedLogs.length;
        _isServerOnline = online;
        if (savedUser != null && savedUser.isNotEmpty) {
          _currentOperator = savedUser;
        }
        _availableUpdate = (updateInfo != null && updateInfo.hasUpdate) ? updateInfo : null;
      });
    }
  }

  Future<bool> _pingServer(String baseUrl) async {
    try {
      final cleanUrl = AppConfig.sanitizeServerUrl(baseUrl);
      final response = await http
          .get(Uri.parse('$cleanUrl/api/v1/system/app-version/'))
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Trigger sequential sync directly from Home Screen
  Future<void> _triggerHomeSync() async {
    if (_pendingLogsCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTranslations.text('all_synced_msg'))),
      );
      return;
    }

    setState(() => _isSyncing = true);

    final prefs = await SharedPreferences.getInstance();
    final String? savedToken = prefs.getString('access_token');
    final String? username = prefs.getString('operator_username');
    final String? password = prefs.getString('operator_password');

    final authService = AuthService(backendBaseUrl: _serverBaseUrl);
    final syncService = SyncService(backendBaseUrl: _serverBaseUrl);

    String? token = savedToken;
    // If no token or if we have username/password, refresh session token
    if (username != null && password != null) {
      final freshToken = await authService.login(username, password);
      if (freshToken != null) {
        token = freshToken;
        await prefs.setString('access_token', freshToken);
      }
    }

    if (token != null) {
      final int syncedCount = await syncService.performSequentialSync(token);
      await _loadHomeScreenData();

      if (mounted) {
        if (syncedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${AppTranslations.text('sync_success_msg')} ($syncedCount scan(s))"),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${AppTranslations.text('sync_failed_msg')} (Sync rejected by server)"),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Authentication required: Please log in again to sync scans."),
            backgroundColor: Colors.amber.shade900,
          ),
        );
      }
    }

    if (mounted) setState(() => _isSyncing = false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppTranslations.currentLang,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF081C15),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadHomeScreenData,
              color: const Color(0xFF10B981),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Bar with Server Badge and Settings Navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/logo/logo.png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "N",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppTranslations.text('app_title'),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      "${AppTranslations.text('logged_in_as')}: $_currentOperator",
                                      style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Action Buttons: Settings & Logout
                        Row(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.settings, color: Colors.white70, size: 24),
                                  tooltip: "Settings",
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => SettingsScreen(onLogout: widget.onLogout)),
                                    );
                                    _loadHomeScreenData(); // Reload after coming back from Settings
                                  },
                                ),
                                if (_availableUpdate != null)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade400,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF081C15), width: 1.5),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Update Notification Alert Banner on Home Screen
                    if (_availableUpdate != null) ...[
                      GestureDetector(
                        onTap: () => UpdateService.showUpdateDialog(context, _availableUpdate!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber.shade900.withValues(alpha: 0.6), Colors.amber.shade800.withValues(alpha: 0.3)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.amber.shade400.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade400,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.system_update_alt, color: Colors.black87, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${AppTranslations.text('update_banner_title')} (v${_availableUpdate!.latestVersion})",
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      AppTranslations.text('update_banner_sub'),
                                      style: TextStyle(color: Colors.amber.shade200, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Server Status & Offline Sync Action Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2E23),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 4,
                                    backgroundColor: _isServerOnline ? const Color(0xFF10B981) : Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isServerOnline ? AppTranslations.text('server_live') : AppTranslations.text('server_offline'),
                                    style: TextStyle(
                                      color: _isServerOnline ? const Color(0xFF10B981) : Colors.red.shade300,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _serverBaseUrl.replaceAll('https://', '').replaceAll('http://', ''),
                                style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF10B981), size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "$_pendingLogsCount ${AppTranslations.text('pending_scans')}",
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      AppTranslations.text('stored_local_sqlite'),
                                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Direct Home Screen Sync Trigger Button
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              minimumSize: const Size(double.infinity, 46),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isSyncing ? null : _triggerHomeSync,
                            icon: _isSyncing
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                                : const Icon(Icons.sync, color: Colors.white, size: 20),
                            label: Text(
                              _isSyncing ? AppTranslations.text('syncing_button') : AppTranslations.text('sync_button'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),


                    // Central Start Scan Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 2),
                            ),
                            child: const Icon(Icons.center_focus_strong, size: 48, color: Color(0xFF10B981)),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            AppTranslations.text('maturity_profiling_title'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppTranslations.text('maturity_profiling_sub'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          const SizedBox(height: 28),

                          // Start New Scan Trigger
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              minimumSize: const Size(double.infinity, 54),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                            onPressed: () async {
                              if (cameras.isNotEmpty) {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VisualScanScreen(camera: cameras.first),
                                  ),
                                );
                                _loadHomeScreenData(); // Refresh unsynced count upon returning from scan
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No camera hardware detected on device.')),
                                );
                              }
                            },
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                            label: Text(
                              AppTranslations.text('start_scan'),
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Storage Info Footer Cards
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.sd_card_outlined, color: Color(0xFF10B981), size: 20),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(AppTranslations.text('storage_label'), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                    Text(AppTranslations.text('storage_val'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.memory, color: Color(0xFF10B981), size: 20),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(AppTranslations.text('model_label'), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                    Text(AppTranslations.text('model_val'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}