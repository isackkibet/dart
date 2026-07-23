import 'dart:convert';
import 'package:http/http.dart' as http;

class TranscodingService {
  final String functionsBaseUrl;

  TranscodingService({required this.functionsBaseUrl});

  Future<void> triggerTranscoding({
    required String videoId,
    required String userId,
  }) async {
    final response = await http.post(
      Uri.parse('$functionsBaseUrl/videos/complete-upload'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'videoId': videoId, 'userId': userId}),
    );
    if (response.statusCode >= 400) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to trigger transcoding');
    }
  }
}
