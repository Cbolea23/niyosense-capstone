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
  final TextEditingController _ipController = TextEditingController(text: "192.168.1.26:8000");
  bool _isTesting = false;
  bool _hasProcessedScan = false;
  bool _showManualInput = false; // Scanner opens directly on screen launch

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
        title: Text(_showManualInput ? 'Manual IP Connection' : 'Scan Dashboard QR Code'),
        backgroundColor: const Color(0xFF121212),
        actions: [
          IconButton(
            icon: Icon(_showManualInput ? Icons.qr_code_scanner : Icons.keyboard, color: const Color(0xFF10B981)),
            onPressed: () {
              setState(() => _showManualInput = !_showManualInput);
            },
            tooltip: _showManualInput ? "Switch to Scanner" : "Manual IP Entry",
          )
        ],
      ),
      body: SafeArea(
        child: _showManualInput
            ? _buildManualInputView()
            : _buildCameraScannerView(),
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
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => setState(() => _showManualInput = true),
                  child: const Text(
                    "Or tap here to enter IP manually",
                    style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualInputView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.dns_outlined, size: 56, color: Color(0xFF10B981)),
          const SizedBox(height: 16),
          const Text(
            "Manual Server Configuration",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _ipController,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
            decoration: InputDecoration(
              labelText: "Dashboard IP / URL",
              labelStyle: const TextStyle(color: Color(0xFF10B981)),
              hintText: "192.168.1.26:8000",
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.grey.shade900,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.wifi, color: Color(0xFF10B981)),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isTesting ? null : () => _saveAndConnect(_ipController.text),
            icon: _isTesting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.link, color: Colors.white),
            label: Text(_isTesting ? "CONNECTING..." : "CONNECT VIA IP", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF10B981),
              side: const BorderSide(color: Color(0xFF10B981)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => setState(() => _showManualInput = false),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text("SWITCH TO QR SCANNER"),
          ),
        ],
      ),
    );
  }
}