import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import 'server_config_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _ipController = TextEditingController(text: "192.168.1.26:8000");
  bool _isConnected = false; // Fixed: Defaults to false until real health check completes
  bool _isConnecting = false;
  int _pendingLogsCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    await _loadSavedServerUrl();
    await _loadPendingLogs();
    await _checkServerHealth(); // Performs real network ping on screen open
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

  // Health check ping to verify Django web server Uptime
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
            content: Text('Cannot reach $formattedUrl. Ensure Django is running on port 8000.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return;
    }

    // Save validated URL locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backend_base_url', formattedUrl);

    // Perform Authentication and Sequential Offline Sync
    final authService = AuthService(backendBaseUrl: formattedUrl);
    final syncService = SyncService(backendBaseUrl: formattedUrl);

    final String? token = await authService.login("aggregator1", "SecurePassword123!");

    if (token != null) {
      await syncService.performSequentialSync(token);
      await _loadPendingLogs();

      if (mounted) {
        setState(() => _isConnected = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected & synchronized with $formattedUrl'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } else {
      // Server is online, but auth credentials weren't recognized
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Server Configuration", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Connect to your NiyoSense web dashboard", style: TextStyle(color: Colors.black45, fontSize: 11)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                          _isConnected ? "Connected" : "Disconnected",
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
                          _isConnected ? "Live" : "Offline",
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
            const SizedBox(height: 24),

            // IP Input Section
            const Text("Web Dashboard URL / IP Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
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
            const Text("e.g., 192.168.1.26:8000 or dashboard.niyosense.local", style: TextStyle(color: Colors.black38, fontSize: 11)),
            const SizedBox(height: 20),

            // Connect Button
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
              label: Text(_isConnecting ? "CONNECTING..." : "Connect to Server", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 28),

            // Device Info & Pending Scans Table
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildInfoRow("Pending Sync Scans", "$_pendingLogsCount scan(s) local"),
                  const Divider(height: 1),
                  _buildInfoRow("Device ID", "NYS-FIELD-0024"),
                  const Divider(height: 1),
                  _buildInfoRow("App Version", "NiyoSense Field v1.2.0"),
                  const Divider(height: 1),
                  _buildInfoRow("Model Engine", "Vision v2.4.1"),
                ],
              ),
            ),
          ],
        ),
      ),
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