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
  bool _isTesting = false;
  bool _hasProcessedScan = false;

  Future<void> _saveAndConnect(String url) async {
    if (_isTesting) return;
    setState(() => _isTesting = true);

    String cleanUrl = url.trim();
    if (!cleanUrl.startsWith("http://") && !cleanUrl.startsWith("https://")) {
      cleanUrl = "http://$cleanUrl";
    }

    try {
      final response = await http
          .get(Uri.parse('$cleanUrl/admin/login/'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 302 || response.statusCode == 404) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('backend_base_url', cleanUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully paired with $cleanUrl'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          widget.onConfigComplete();
        }
      } else {
        _showError('Server returned status ${response.statusCode}');
        _hasProcessedScan = false;
      }
    } catch (e) {
      _showError('Cannot connect to $cleanUrl. Check network/IP.');
      _hasProcessedScan = false;
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
        title: const Text('Scan Dashboard QR Code'),
        backgroundColor: const Color(0xFF121212),
      ),
      body: SafeArea(
        child: _buildCameraScannerView(),
      ),
    );
  }

  Widget _buildCameraScannerView() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Camera opens immediately on screen load
        MobileScanner(
          onDetect: (capture) {
            if (_hasProcessedScan || _isTesting) return;
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                _hasProcessedScan = true;
                _saveAndConnect(barcode.rawValue!);
                break;
              }
            }
          },
        ),

        // Targeting reticle frame overlay
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF10B981), width: 3),
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // Bottom instruction badge
        Positioned(
          bottom: 30,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _isTesting
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text("Verifying pairing connection...", style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                )
                    : const Text(
                  "Align QR code from Web Dashboard within frame",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}