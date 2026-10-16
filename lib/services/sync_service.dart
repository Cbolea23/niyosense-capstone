import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../models/grading_log.dart';
import '../database/db_helper.dart';
import '../utils/app_config.dart';

class SyncService {
  final String? backendBaseUrl;

  SyncService({this.backendBaseUrl});

  Future<void> syncBatchSessions(String accessToken, [String? customServerUrl]) async {
    try {
      final db = DatabaseHelper.instance;
      final sessions = await db.getAllBatchSessions();
      if (sessions.isEmpty) return;

      final serverUrl = AppConfig.sanitizeServerUrl(customServerUrl ?? backendBaseUrl);
      final uri = Uri.parse('$serverUrl/api/v1/sync/batch-session/');

      for (final s in sessions) {
        try {
          await http.post(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'batch_id': s.batchId,
              'farmer_name': s.farmerName,
              'mature_price': s.maturePrice,
              'premature_price': s.prematurePrice,
              'reject_price': s.rejectPrice,
              'is_closed': s.isClosed,
              'created_at': s.createdAt,
            }),
          ).timeout(const Duration(seconds: 10));
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<int> performSequentialSync(String accessToken, [String? customServerUrl]) async {
    try {
      final db = DatabaseHelper.instance;

      // Sync delivery batch sessions first so foreign keys link cleanly on the server
      await syncBatchSessions(accessToken, customServerUrl);

      final List<GradingLog> unsyncedLogs = await db.getUnsyncedLogs();

      if (unsyncedLogs.isEmpty) {
        debugPrint("ℹ️ No unsynced logs found in local SQLite database.");
        return 0;
      }

      debugPrint("🔄 Starting sequential sync for ${unsyncedLogs.length} offline log(s)...");
      int syncedCount = 0;

      for (var log in unsyncedLogs) {
        bool success = await syncSingleLog(log, accessToken, customServerUrl);
        if (success) {
          dynamic dLog = log;
          String logUuid = dLog.uuid?.toString() ?? '';
          if (logUuid.isNotEmpty) {
            await db.markAsSynced(logUuid);
          }
          syncedCount++;
        }
      }

      debugPrint("🎉 Sequential sync complete: $syncedCount/${unsyncedLogs.length} logs synced.");
      return syncedCount;
    } catch (e) {
      debugPrint("❌ Exception during performSequentialSync: $e");
      return 0;
    }
  }

  Future<bool> syncSingleLog(GradingLog log, String accessToken, [String? customServerUrl]) async {
    final String rawUrl = (customServerUrl ?? backendBaseUrl ?? '').trim();
    if (rawUrl.isEmpty) {
      debugPrint("❌ Sync Error: No backend server URL provided.");
      return false;
    }
    final String serverUrl = AppConfig.sanitizeServerUrl(rawUrl);
    final Uri uri = Uri.parse('$serverUrl/api/v1/sync/bulk-logs/');

    // Retry up to 3 times with backoff so simultaneous multi-device syncs never drop
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        var request = http.MultipartRequest('POST', uri);
        request.headers['Authorization'] = 'Bearer $accessToken';

        dynamic dLog = log;

        String getProp(List<String> keys) {
          try {
            Map<String, dynamic>? map;
            try { map = dLog.toMap(); } catch (_) {
              try { map = dLog.toJson(); } catch (_) {}
            }
            if (map != null) {
              for (var k in keys) {
                if (map.containsKey(k) && map[k] != null) return map[k].toString();
              }
            }
          } catch (_) {}
          return '';
        }

        final String logUuid = dLog.uuid?.toString() ?? getProp(['uuid', 'id']);
        request.fields['uuid'] = logUuid;

        String visual = '';
        try { visual = dLog.visualPrediction?.toString() ?? dLog.visual_prediction?.toString() ?? dLog.visualPred?.toString() ?? dLog.visual_pred?.toString() ?? ''; } catch (_) {}
        if (visual.isEmpty) visual = getProp(['visual_prediction', 'visualPrediction', 'visual_pred', 'visual_result']);
        request.fields['visual_prediction'] = visual;

        String audio = '';
        try { audio = dLog.audioPrediction?.toString() ?? dLog.audio_prediction?.toString() ?? dLog.audioPred?.toString() ?? dLog.audio_pred?.toString() ?? ''; } catch (_) {}
        if (audio.isEmpty) audio = getProp(['audio_prediction', 'audioPrediction', 'audio_pred', 'audio_result']);
        request.fields['audio_prediction'] = audio;

        String maturity = '';
        try { maturity = dLog.finalMaturityStage?.toString() ?? dLog.final_maturity_stage?.toString() ?? dLog.finalStage?.toString() ?? dLog.final_stage?.toString() ?? ''; } catch (_) {}
        if (maturity.isEmpty) maturity = getProp(['final_maturity_stage', 'finalMaturityStage', 'final_stage', 'finalStage']);
        request.fields['final_maturity_stage'] = maturity;

        String confidence = '';
        try { confidence = dLog.confidenceScore?.toString() ?? dLog.confidence_score?.toString() ?? dLog.confidence?.toString() ?? ''; } catch (_) {}
        if (confidence.isEmpty) confidence = getProp(['confidence_score', 'confidenceScore', 'confidence']);
        request.fields['confidence_score'] = confidence;

        String createdAt = '';
        try { createdAt = dLog.createdAt?.toIso8601String() ?? dLog.created_at?.toString() ?? ''; } catch (_) {}
        if (createdAt.isEmpty) createdAt = getProp(['created_at', 'createdAt']);
        request.fields['created_at'] = createdAt.isNotEmpty ? createdAt : DateTime.now().toIso8601String();

        String batchId = '';
        try { batchId = dLog.batchId?.toString() ?? dLog.batch_id?.toString() ?? ''; } catch (_) {}
        if (batchId.isEmpty) batchId = getProp(['batch_id', 'batchId']);
        if (batchId.isNotEmpty) request.fields['batch_id'] = batchId;

        String deviceId = '';
        try { deviceId = dLog.deviceId?.toString() ?? dLog.device_id?.toString() ?? ''; } catch (_) {}
        if (deviceId.isEmpty) deviceId = getProp(['device_id', 'deviceId']);
        if (deviceId.isNotEmpty) request.fields['device_id'] = deviceId;

        String bunchCount = '';
        try { bunchCount = dLog.bunchCount?.toString() ?? dLog.bunch_count?.toString() ?? ''; } catch (_) {}
        if (bunchCount.isEmpty) bunchCount = getProp(['bunch_count', 'bunchCount']);
        request.fields['bunch_count'] = bunchCount.isNotEmpty ? bunchCount : '1';

        final String safePrefix = logUuid.length >= 8 ? logUuid.substring(0, 8) : logUuid;

        // Attach Image File with UUID prefix to prevent multi-device filename collisions
        String? imgPath;
        try { imgPath = dLog.imagePath?.toString() ?? dLog.image_path?.toString() ?? dLog.image?.toString(); } catch (_) {}
        if (imgPath != null && imgPath.isNotEmpty) {
          File imgFile = File(imgPath);
          if (await imgFile.exists()) {
            request.files.add(await http.MultipartFile.fromPath(
              'image',
              imgFile.path,
              filename: '${safePrefix}_${path.basename(imgFile.path)}',
            ));
          }
        }

        // Attach Audio File with UUID prefix to prevent multi-device filename collisions
        String? audPath;
        try { audPath = dLog.audioPath?.toString() ?? dLog.audio_path?.toString() ?? dLog.audioFile?.toString() ?? dLog.audio_file?.toString(); } catch (_) {}
        if (audPath != null && audPath.isNotEmpty) {
          File audioFile = File(audPath);
          if (await audioFile.exists()) {
            request.files.add(await http.MultipartFile.fromPath(
              'audio_file',
              audioFile.path,
              filename: '${safePrefix}_${path.basename(audioFile.path)}',
            ));
          }
        }

        var streamedResponse = await request.send().timeout(const Duration(seconds: 25));
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint("✅ Sync successful for UUID: $logUuid");
          return true;
        } else if (response.statusCode >= 500 && attempt < 3) {
          debugPrint("⚠️ Server busy (${response.statusCode}), retrying attempt ${attempt + 1}/3...");
          await Future.delayed(Duration(milliseconds: 400 * attempt));
          continue;
        } else {
          debugPrint("❌ Sync failed (${response.statusCode}): ${response.body}");
          return false;
        }
      } catch (e) {
        if (attempt < 3) {
          await Future.delayed(Duration(milliseconds: 400 * attempt));
          continue;
        }
        debugPrint("❌ Exception during syncSingleLog: $e");
        return false;
      }
    }
    return false;
  }
}