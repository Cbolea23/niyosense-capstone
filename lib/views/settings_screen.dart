import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../services/sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _unsyncedCount = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadUnsyncedCount();
  }

  Future<void> _loadUnsyncedCount() async {
    final logs = await DatabaseHelper.instance.getUnsyncedLogs();
    setState(() {
      _unsyncedCount = logs.length;
    });
  }

  Future<void> _triggerManualSync() async {
    setState(() {
      _isSyncing = true;
    });

    final syncService = SyncService(backendBaseUrl: "http://127.0.0.1:8000");
    await syncService.performSequentialSync("MOCK_JWT_TOKEN");

    await _loadUnsyncedCount();
    setState(() {
      _isSyncing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline sync process completed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('App Settings & Sync'),
        backgroundColor: const Color(0xFF121212),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              color: Colors.grey.shade900,
              child: ListTile(
                leading: const Icon(Icons.sd_card, color: Color(0xFF008080)),
                title: const Text("Pending Offline Scans", style: TextStyle(color: Colors.white)),
                subtitle: Text("$_unsyncedCount scan(s) waiting to sync to Django", style: const TextStyle(color: Colors.grey)),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadUnsyncedCount,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.grey.shade900,
              child: const ListTile(
                leading: Icon(Icons.phone_android, color: Color(0xFF008080)),
                title: Text("Device ID", style: TextStyle(color: Colors.white)),
                subtitle: Text("AGGREGATOR-FIELD-01", style: TextStyle(color: Colors.grey)),
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
              label: Text(_isSyncing ? "SYNCING..." : "SYNC NOW TO SERVER", style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}