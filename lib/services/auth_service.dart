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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Returns the real access token from your DRF SimpleJWT response
        return data['data']['access'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}