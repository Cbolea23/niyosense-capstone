import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'database/db_helper.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'utils/app_translations.dart';
import 'views/visual_scan_screen.dart';
import 'views/settings_screen.dart';

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

class NiyoSenseApp extends StatelessWidget {
  const NiyoSenseApp({super.key});

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
          home: const HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _pendingLogsCount = 0;
  bool _isSyncing = false;
  bool _isServerOnline = false;
  String _serverBaseUrl = "http://192.168.1.26:8000";

  @override
  void initState() {
    super.initState();
    _loadHomeScreenData();
  }

  // Reloads IP settings, checks pending SQLite logs, and pings server
  Future<void> _loadHomeScreenData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('backend_base_url');
    final unsyncedLogs = await DatabaseHelper.instance.getUnsyncedLogs();

    String activeUrl = (savedUrl != null && savedUrl.isNotEmpty) ? savedUrl : "http://192.168.1.26:8000";

    if (!activeUrl.startsWith("http://") && !activeUrl.startsWith("https://")) {
      activeUrl = "http://$activeUrl";
    }

    bool online = await _pingServer(activeUrl);

    if (mounted) {
      setState(() {
        _serverBaseUrl = activeUrl;
        _pendingLogsCount = unsyncedLogs.length;
        _isServerOnline = online;
      });
    }
  }

  Future<bool> _pingServer(String baseUrl) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/admin/login/'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200 || response.statusCode == 302 || response.statusCode == 404;
    } catch (_) {
      return false;
    }
  }

  // Trigger sequential sync directly from Home Screen
  Future<void> _triggerHomeSync() async {
    if (_pendingLogsCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All local logs are already synced!')),
      );
      return;
    }

    setState(() => _isSyncing = true);

    final authService = AuthService(backendBaseUrl: _serverBaseUrl);
    final syncService = SyncService(backendBaseUrl: _serverBaseUrl);

    final String? token = await authService.login("aggregator1", "SecurePassword123!");

    if (token != null) {
      await syncService.performSequentialSync(token);
      await _loadHomeScreenData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synchronization complete! Logs updated in PostgreSQL.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: Cannot connect to $_serverBaseUrl'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }

    if (mounted) setState(() => _isSyncing = false);
  }

  @override
  Widget build(BuildContext context) {
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
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "NiyoSense Field",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              "Small-Scale Aggregator",
                              style: TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Navigation to Settings Screen
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white70, size: 26),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                        _loadHomeScreenData(); // Reload after coming back from Settings
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

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
                                _isServerOnline ? "Server Live" : "Server Offline",
                                style: TextStyle(
                                  color: _isServerOnline ? const Color(0xFF10B981) : Colors.red.shade300,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _serverBaseUrl.replaceAll('http://', ''),
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
                                  "$_pendingLogsCount Pending Scans",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const Text(
                                  "Stored in local SQLite database",
                                  style: TextStyle(color: Colors.white54, fontSize: 11),
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
                          _isSyncing ? "SYNCING TO HOST..." : "SYNC NOW TO SERVER",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

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
                      const Text(
                        "Coconut Maturity Profiling",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Dual-Modality Visual & Acoustic Field Profiler",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 12),
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
                        label: const Text(
                          "START NEW SCAN",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
                        child: const Row(
                          children: [
                            Icon(Icons.sd_card_outlined, color: Color(0xFF10B981), size: 20),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Storage", style: TextStyle(color: Colors.white38, fontSize: 10)),
                                Text("Local SQLite", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
                        child: const Row(
                          children: [
                            Icon(Icons.memory, color: Color(0xFF10B981), size: 20),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("AI Model", style: TextStyle(color: Colors.white38, fontSize: 10)),
                                Text("TFLite Ready", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
  }
}