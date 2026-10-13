import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_config.dart';
import '../utils/app_translations.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final int latestBuildNumber;
  final String releaseTitle;
  final String releaseNotes;
  final String downloadUrl;
  final double fileSizeMb;

  UpdateInfo({
    required this.hasUpdate,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.releaseTitle,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.fileSizeMb,
  });
}

class UpdateService {
  static Future<String> _resolveServerBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('backend_base_url');
    String activeUrl = (savedUrl != null && savedUrl.isNotEmpty) ? savedUrl : AppConfig.defaultServerUrl;
    if (!activeUrl.startsWith("http://") && !activeUrl.startsWith("https://")) {
      activeUrl = "http://$activeUrl";
    }
    return activeUrl;
  }

  /// Checks server for newer version than current running AppConfig
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final baseUrl = await _resolveServerBaseUrl();
      final uri = Uri.parse('$baseUrl/api/v1/system/app-version/');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final payload = (data['data'] != null && data['data'] is Map<String, dynamic>)
            ? data['data']
            : data;

        final int serverBuild = payload['latest_build_number'] is int
            ? payload['latest_build_number']
            : int.tryParse(payload['latest_build_number']?.toString() ?? '0') ?? 0;
        final String serverVersion = payload['latest_version'] ?? '1.0.0';
        String rawDownloadUrl = payload['download_url'] ?? '';
        String downloadUrl;
        if (rawDownloadUrl.isNotEmpty && !rawDownloadUrl.contains('127.0.0.1') && !rawDownloadUrl.contains('localhost')) {
          downloadUrl = rawDownloadUrl;
        } else {
          downloadUrl = '$baseUrl/media/downloads/niyosense.apk';
        }
        final String releaseTitle = payload['release_title'] ?? 'NiyoSense Field Update';
        final String releaseNotes = payload['release_notes'] ?? '';
        final double fileSize = (payload['file_size_mb'] is num)
            ? (payload['file_size_mb'] as num).toDouble()
            : 0.0;

        // Check if server build or version is strictly newer
        bool isNewer = serverBuild > AppConfig.buildNumber;
        if (!isNewer && serverVersion != AppConfig.appVersion) {
          // Compare version strings "1.3.3" vs "1.3.2"
          isNewer = _isVersionStringNewer(serverVersion, AppConfig.appVersion);
        }

        return UpdateInfo(
          hasUpdate: isNewer,
          latestVersion: serverVersion,
          latestBuildNumber: serverBuild,
          releaseTitle: releaseTitle,
          releaseNotes: releaseNotes,
          downloadUrl: downloadUrl,
          fileSizeMb: fileSize,
        );
      }
    } catch (e) {
      debugPrint("Update check error: $e");
    }
    return null;
  }

  static bool _isVersionStringNewer(String remote, String current) {
    try {
      List<int> rParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      List<int> cParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      for (int i = 0; i < 3; i++) {
        int r = i < rParts.length ? rParts[i] : 0;
        int c = i < cParts.length ? cParts[i] : 0;
        if (r > c) return true;
        if (r < c) return false;
      }
    } catch (_) {}
    return false;
  }

  /// Opens the browser or download intent to fetch & install the APK
  static Future<bool> launchUpdateUrl(String downloadUrl) async {
    try {
      final uri = Uri.parse(downloadUrl);
      // Attempt 1: External application (system browser / downloader)
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) return true;
      } catch (e) {
        debugPrint("External launch failed, trying fallback: $e");
      }

      // Attempt 2: Platform default
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (launched) return true;
      } catch (e) {
        debugPrint("Platform default launch failed: $e");
      }

      // Attempt 3: In-app webview fallback if browser intent is blocked
      return await launchUrl(uri, mode: LaunchMode.inAppWebView);
    } catch (e) {
      debugPrint("Failed to launch download URL: $e");
    }
    return false;
  }

  /// Shows update dialog with notes and download button
  static void showUpdateDialog(BuildContext context, UpdateInfo updateInfo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF132821),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.system_update_alt, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.text('update_available_title'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    "v${updateInfo.latestVersion} (Build ${updateInfo.latestBuildNumber})",
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6EE7B7)),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.text('update_available_msg').replaceAll('{version}', updateInfo.latestVersion),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            if (updateInfo.fileSizeMb > 0) ...[
              const SizedBox(height: 6),
              Text(
                "Package Size: ~${updateInfo.fileSizeMb} MB",
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
            if (updateInfo.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  updateInfo.releaseNotes,
                  style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppTranslations.text('close'),
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await launchUpdateUrl(updateInfo.downloadUrl);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Opening install page: ${updateInfo.downloadUrl}"),
                    backgroundColor: Colors.amber.shade800,
                  ),
                );
              }
            },
            icon: const Icon(Icons.download, color: Colors.white, size: 18),
            label: Text(
              AppTranslations.text('update_now_btn'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
