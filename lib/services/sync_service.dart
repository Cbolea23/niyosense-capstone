import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/db_helper.dart';
import '../models/grading_log.dart';

class SyncService {
  final String backendBaseUrl;

  SyncService({required this.backendBaseUrl});

  Future<void> performSequentialSync(String jwtToken) async {
    // Check network connectivity
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return; // Offline, exit gracefully
    }

    // Fetch logs where is_synced == 0
    List<GradingLog> unsyncedLogs = await DatabaseHelper.instance.getUnsyncedLogs();

    for (var log in unsyncedLogs) {
      bool success = await _uploadSingleLog(log, jwtToken);
      if (success) {
        // Mark as synced locally ONLY after receiving 200 OK
        await DatabaseHelper.instance.markAsSynced(log.uuid);
      } else {
        // Stop batch if internet drops mid-way to preserve order
        break;
      }
    }
  }

  Future<bool> _uploadSingleLog(GradingLog log, String token) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$backendBaseUrl/api/v1/sync/bulk-logs/'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['uuid'] = log.uuid;
      request.fields['visual_prediction'] = log.visualPred;
      request.fields['audio_prediction'] = log.audioPred;
      request.fields['final_maturity_stage'] = log.finalStage;
      request.fields['confidence_score'] = log.confidence.toString();
      request.fields['created_at'] = log.createdAt;

      // Attach local image and audio files
      if (File(log.imagePath).existsSync()) {
        request.files.add(await http.MultipartFile.fromPath('image', log.imagePath));
      }
      if (File(log.audioPath).existsSync()) {
        request.files.add(await http.MultipartFile.fromPath('audio_file', log.audioPath));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}