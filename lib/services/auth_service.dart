import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String backendBaseUrl;

  AuthService({required this.backendBaseUrl});

  Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/v1/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle both standardized custom wrapper {"data": {"access": "..."}} and direct DRF JWT {"access": "..."}
        if (data is Map<String, dynamic>) {
          if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
            return data['data']['access'] as String?;
          }
          if (data.containsKey('access')) {
            return data['access'] as String?;
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}