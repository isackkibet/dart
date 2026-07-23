import 'dart:convert';
import 'package:http/http.dart' as http;

class AiCreatorApiService {
  final String baseUrl;

  AiCreatorApiService({required this.baseUrl});

  Future<void> requestJobProcessing({
    required String jobId,
    required String userId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/processAiVideoJob'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'jobId': jobId, 'userId': userId}),
    );
    if (response.statusCode >= 400) {
      throw Exception('AI job request failed: ${response.body}');
    }
  }
}
