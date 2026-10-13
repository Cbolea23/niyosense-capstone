import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../models/batch_session.dart';
import '../utils/app_translations.dart';
import '../utils/app_config.dart';

class BatchSessionScreen extends StatefulWidget {
  const BatchSessionScreen({super.key});

  @override
  State<BatchSessionScreen> createState() => _BatchSessionScreenState();
}

class _BatchSessionScreenState extends State<BatchSessionScreen> {
  BatchSession? _activeSession;
  BatchSummary? _activeSummary;
  List<BatchSession> _pastSessions = [];
  bool _isLoading = true;

  final TextEditingController _farmerController = TextEditingController();
  final TextEditingController _maturePriceController = TextEditingController(text: '12.00');
  final TextEditingController _prematurePriceController = TextEditingController(text: '7.00');
  final TextEditingController _rejectPriceController = TextEditingController(text: '0.00');

  @override
  void initState() {
    super.initState();
    _loadBatchData();
  }

  @override
  void dispose() {
    _farmerController.dispose();
    _maturePriceController.dispose();
    _prematurePriceController.dispose();
    _rejectPriceController.dispose();
    super.dispose();
  }

  String _formatPhp(double amount) {
    return '₱${amount.toStringAsFixed(2)}';
  }

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final twoDigitMonth = dt.month.toString().padLeft(2, '0');
      final twoDigitDay = dt.day.toString().padLeft(2, '0');
      final twoDigitHour = dt.hour.toString().padLeft(2, '0');
      final twoDigitMinute = dt.minute.toString().padLeft(2, '0');
      return '${dt.year}-$twoDigitMonth-$twoDigitDay $twoDigitHour:$twoDigitMinute';
    } catch (_) {
      return isoString;
    }
  }

  Future<void> _loadBatchData() async {
    setState(() => _isLoading = true);

    // Try fetching master owner prices from server if reachable
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('backend_base_url') ?? AppConfig.defaultServerUrl;
      String activeUrl = savedUrl.startsWith('http') ? savedUrl : 'http://$savedUrl';
      if (activeUrl.endsWith('/')) activeUrl = activeUrl.substring(0, activeUrl.length - 1);

      final res = await http.get(Uri.parse('$activeUrl/api/v1/pricing/current/')).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['mature_price'] != null) {
          _maturePriceController.text = data['mature_price'].toString();
          _prematurePriceController.text = data['premature_price'].toString();
          _rejectPriceController.text = data['reject_price'].toString();
        }
      }
    } catch (_) {}

    final active = await DatabaseHelper.instance.getActiveBatchSession();
    BatchSummary? summary;
    if (active != null) {
      summary = await DatabaseHelper.instance.getBatchSummary(active);
    }
    final all = await DatabaseHelper.instance.getAllBatchSessions();

    if (mounted) {
      setState(() {
        _activeSession = active;
        _activeSummary = summary;
        _pastSessions = all.where((s) => s.isClosed).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _startNewBatch() async {
    final farmerName = _farmerController.text.trim();
    if (farmerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.text('farmer_name_hint')),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final maturePrice = double.tryParse(_maturePriceController.text.trim()) ?? 12.0;
    final prematurePrice = double.tryParse(_prematurePriceController.text.trim()) ?? 7.0;
    final rejectPrice = double.tryParse(_rejectPriceController.text.trim()) ?? 0.0;

    final newSession = BatchSession(
      batchId: 'BATCH-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      farmerName: farmerName,
      maturePrice: maturePrice,
      prematurePrice: prematurePrice,
      rejectPrice: rejectPrice,
      createdAt: DateTime.now().toIso8601String(),
    );

    await DatabaseHelper.instance.createBatchSession(newSession);
    _farmerController.clear();
    await _loadBatchData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session started for ${newSession.farmerName}!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _closeCurrentBatch() async {
    if (_activeSession == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F2E23),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppTranslations.text('close_session'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppTranslations.text('close_session_confirm'),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppTranslations.text('back'), style: const TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppTranslations.text('close_session'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.closeBatchSession(_activeSession!.batchId);
      await _loadBatchData();
    }
  }

  void _shareReceiptText(BatchSummary summary) {
    final receipt = '''
========================================
NIYOSENSE COCONUT GRADING & PAYOUT VOUCHER
========================================
Batch ID    : ${summary.session.batchId}
Farmer      : ${summary.session.farmerName}
Date        : ${_formatDateTime(summary.session.createdAt)}

----------------------------------------
SUMMARY OF SCAN TALLY:
- Total Coconuts : ${summary.totalScans} pcs
- Mature (Niyog) : ${summary.matureCount} pcs (${summary.maturePercent.toStringAsFixed(1)}%) @ ₱${summary.session.maturePrice.toStringAsFixed(2)}
- Premature/Buko : ${summary.prematureCount} pcs (${summary.prematurePercent.toStringAsFixed(1)}%) @ ₱${summary.session.prematurePrice.toStringAsFixed(2)}
- Reject/Bungi   : ${summary.rejectCount} pcs (${summary.rejectPercent.toStringAsFixed(1)}%) @ ₱${summary.session.rejectPrice.toStringAsFixed(2)}

----------------------------------------
TOTAL PAYOUT DUE: ${_formatPhp(summary.totalPayout)}
========================================
Graded using NiyoSense Multimodal AI System
''';

    Clipboard.setData(ClipboardData(text: receipt));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppTranslations.text('receipt_copied')),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppTranslations.currentLang,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF081C15),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F2E23),
            elevation: 0,
            title: Text(
              AppTranslations.text('delivery_batch_title'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Active Session Card or Creation Form
                      if (_activeSession != null && _activeSummary != null)
                        _buildActiveSessionCard(_activeSummary!)
                      else
                        _buildNewSessionForm(),

                      const SizedBox(height: 28),

                      // Past Finalized Delivery Sessions
                      if (_pastSessions.isNotEmpty) ...[
                        const Text(
                          "Past Finalized Deliveries",
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        ..._pastSessions.map((session) => _buildPastSessionTile(session)),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildActiveSessionCard(BatchSummary summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2E23),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  summary.session.batchId,
                  style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade900.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: const [
                    CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                    SizedBox(width: 6),
                    Text("ACTIVE TALLY", style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            summary.session.farmerName,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDateTime(summary.session.createdAt),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const Divider(color: Colors.white12, height: 28),

          // Tally Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricColumn("Total Scans", "${summary.totalScans}", Colors.white),
              _buildMetricColumn("Mature", "${summary.matureCount}", const Color(0xFF10B981)),
              _buildMetricColumn("Premature", "${summary.prematureCount}", Colors.amber),
              _buildMetricColumn("Reject", "${summary.rejectCount}", Colors.redAccent),
            ],
          ),

          const Divider(color: Colors.white12, height: 28),

          // Total Payout Highlight
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.text('total_payout_due'),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatPhp(summary.totalPayout),
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _shareReceiptText(summary),
                  icon: const Icon(Icons.share, color: Color(0xFF10B981)),
                  tooltip: AppTranslations.text('share_receipt'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _shareReceiptText(summary),
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(AppTranslations.text('share_receipt'), style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _closeCurrentBatch,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(AppTranslations.text('close_session'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _buildNewSessionForm() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2E23),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_shopping_cart, color: Color(0xFF10B981), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.text('start_batch_btn'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      AppTranslations.text('no_active_batch'),
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Farmer Name Input
          Text(AppTranslations.text('farmer_name'), style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _farmerController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: AppTranslations.text('farmer_name_hint'),
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981))),
            ),
          ),
          const SizedBox(height: 18),

          // Master Rates Configuration (Locked - Set by Farm Owner)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppTranslations.text('rates_heading'), style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              Row(
                children: const [
                  Icon(Icons.lock_outline, color: Color(0xFF10B981), size: 12),
                  SizedBox(width: 4),
                  Text("Owner Set", style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildRateInput(AppTranslations.text('rate_mature'), _maturePriceController)),
              const SizedBox(width: 8),
              Expanded(child: _buildRateInput(AppTranslations.text('rate_premature'), _prematurePriceController)),
              const SizedBox(width: 8),
              Expanded(child: _buildRateInput(AppTranslations.text('rate_reject'), _rejectPriceController)),
            ],
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _startNewBatch,
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: Text(
              AppTranslations.text('start_session'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          readOnly: true, // Workers cannot tamper with prices; only owner sets rates
          enableInteractiveSelection: false,
          style: const TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.black45,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
          ),
        ),
      ],
    );
  }

  Widget _buildPastSessionTile(BatchSession session) {
    return FutureBuilder<BatchSummary>(
      future: DatabaseHelper.instance.getBatchSummary(session),
      builder: (context, snapshot) {
        final summary = snapshot.data;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.farmerName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${session.batchId} • ${summary?.totalScans ?? 0} pcs",
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    summary != null ? _formatPhp(summary.totalPayout) : '...',
                    style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (summary != null)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.share, color: Colors.white38, size: 18),
                      onPressed: () => _shareReceiptText(summary),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
