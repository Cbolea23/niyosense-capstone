import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../models/grading_log.dart';
import '../database/db_helper.dart';

class SyncService {
  final String? backendBaseUrl;

  SyncService({this.backendBaseUrl});

  Future<int> performSequentialSync(String accessToken, [String? customServerUrl]) async {
    try {
      final db = DatabaseHelper.instance;
      final List<GradingLog> unsyncedLogs = await db.getUnsyncedLogs();

      if (unsyncedLogs.isEmpty) {
        print("ℹ️ No unsynced logs found in local SQLite database.");
        return 0;
      }

      print("🔄 Starting sequential sync for ${unsyncedLogs.length} offline log(s)...");
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

      print("🎉 Sequential sync complete: $syncedCount/${unsyncedLogs.length} logs synced.");
      return syncedCount;
    } catch (e) {
      print("❌ Exception during performSequentialSync: $e");
      return 0;
    }
  }

  Future<bool> syncSingleLog(GradingLog log, String accessToken, [String? customServerUrl]) async {
    try {
      String serverUrl = (customServerUrl ?? backendBaseUrl ?? '').trim();
      if (serverUrl.isEmpty) {
        print("❌ Sync Error: No backend server URL provided.");
        return false;
      }

      if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
        serverUrl = 'http://$serverUrl';
      }
      if (serverUrl.endsWith('/')) {
        serverUrl = serverUrl.substring(0, serverUrl.length - 1);
      }

      var uri = Uri.parse('$serverUrl/api/v1/sync/bulk-logs/');
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

      request.fields['uuid'] = dLog.uuid?.toString() ?? getProp(['uuid', 'id']);

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

      // Pass created_at timestamp
      String createdAt = '';
      try { createdAt = dLog.createdAt?.toIso8601String() ?? dLog.created_at?.toString() ?? ''; } catch (_) {}
      if (createdAt.isEmpty) createdAt = getProp(['created_at', 'createdAt']);
      request.fields['created_at'] = createdAt.isNotEmpty ? createdAt : DateTime.now().toIso8601String();

      // Attach Image File
      String? imgPath;
      try { imgPath = dLog.imagePath?.toString() ?? dLog.image_path?.toString() ?? dLog.image?.toString(); } catch (_) {}
      if (imgPath != null && imgPath.isNotEmpty) {
        File imgFile = File(imgPath);
        if (await imgFile.exists()) {
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            imgFile.path,
            filename: path.basename(imgFile.path),
          ));
          print("📸 Attached image: ${imgFile.path}");
        }
      }

      // Attach Audio File
      String? audPath;
      try { audPath = dLog.audioPath?.toString() ?? dLog.audio_path?.toString() ?? dLog.audioFile?.toString() ?? dLog.audio_file?.toString(); } catch (_) {}
      if (audPath != null && audPath.isNotEmpty) {
        File audioFile = File(audPath);
        if (await audioFile.exists()) {
          request.files.add(await http.MultipartFile.fromPath(
            'audio_file',
            audioFile.path,
            filename: path.basename(audioFile.path),
          ));
          print("🎵 Attached audio_file (${await audioFile.length()} bytes): ${audioFile.path}");
        } else {
          print("❌ Audio path recorded in SQLite but missing on disk: $audPath");
        }
      } else {
        print("⚠️ Audio path is empty/null for log UUID: ${request.fields['uuid']}");
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Sync successful for UUID: ${request.fields['uuid']}");
        return true;
      } else {
        print("❌ Sync failed (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Exception during syncSingleLog: $e");
      return false;
    }
  }
}