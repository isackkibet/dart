import 'dart:convert';
import 'package:http/http.dart' as http;

class LiveTokenService {
  final String functionsBaseUrl;

  LiveTokenService({required this.functionsBaseUrl});

  Future<String> createToken({
    required String roomName,
    required String identity,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$functionsBaseUrl/createLiveKitToken'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'roomName': roomName,
        'identity': identity,
        'role': role,
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to create LiveKit token: ${response.body}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['token'] as String;
  }
}
