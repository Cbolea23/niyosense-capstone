import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ServerConfigScreen extends StatefulWidget {
  final VoidCallback onConfigComplete;

  const ServerConfigScreen({super.key, required this.onConfigComplete});

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final TextEditingController _ipController = TextEditingController(text: "http://192.168.1.26:8000");
  bool _isScanning = false;
  bool _isTesting = false;

  Future<void> _saveAndConnect(String url) async {
    setState(() => _isTesting = true);

    String cleanUrl = url.trim();
    if (!cleanUrl.startsWith("http://") && !cleanUrl.startsWith("https://")) {
      cleanUrl = "http://$cleanUrl";
    }

    try {
      final response = await http.get(Uri.parse('$cleanUrl/admin/login/')).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 302) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('backend_base_url', cleanUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully paired with $cleanUrl')),
          );
          widget.onConfigComplete();
        }
      } else {
        _showError('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      _showError('Cannot connect to $cleanUrl.');
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Connect to NiyoSense Server'),
        backgroundColor: const Color(0xFF121212),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.qr_code_scanner, size: 64, color: Color(0xFF008080)),
            const SizedBox(height: 16),
            const Text(
              "Pair Device with Web Dashboard",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Scan the QR code displayed on the Web Dashboard Settings page, or type your PC's IP address.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 32),

            if (_isScanning)
              SizedBox(
                height: 250,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MobileScanner(
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null) {
                          setState(() => _isScanning = false);
                          _saveAndConnect(barcode.rawValue!);
                          break;
                        }
                      }
                    },
                  ),
                ),
              )
            else ...[
              TextField(
                controller: _ipController,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  labelText: "Dashboard IP / URL",
                  labelStyle: const TextStyle(color: Color(0xFF008080)),
                  hintText: "http://192.168.1.26:8000",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade900,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.wifi, color: Color(0xFF008080)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008080),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isTesting ? null : () => _saveAndConnect(_ipController.text),
                icon: _isTesting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.link, color: Colors.white),
                label: Text(_isTesting ? "CONNECTING..." : "CONNECT VIA MANUAL IP", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF008080),
                  side: const BorderSide(color: Color(0xFF008080)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => setState(() => _isScanning = true),
                icon: const Icon(Icons.camera_alt),
                label: const Text("SCAN QR CODE FROM DASHBOARD"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}