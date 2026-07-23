import 'dart:convert';
import 'package:http/http.dart' as http;

class MultistreamService {
  final String functionsBaseUrl;

  MultistreamService({required this.functionsBaseUrl});

  Future<void> startFanOut({
    required String multistreamSessionId,
    required String liveSessionId,
  }) async {
    final response = await http.post(
      Uri.parse('$functionsBaseUrl/startMultistreamFanOut'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'multistreamSessionId': multistreamSessionId,
        'liveSessionId': liveSessionId,
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to start multistream: ${response.body}');
    }
  }

  Future<void> stopFanOut({required String multistreamSessionId}) async {
    final response = await http.post(
      Uri.parse('$functionsBaseUrl/stopMultistreamFanOut'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'multistreamSessionId': multistreamSessionId}),
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to stop multistream: ${response.body}');
    }
  }

  Future<void> retryDestination({
    required String multistreamSessionId,
    required String destinationId,
  }) async {
    final response = await http.post(
      Uri.parse('$functionsBaseUrl/retryMultistreamDestination'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'multistreamSessionId': multistreamSessionId,
        'destinationId': destinationId,
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to retry destination: ${response.body}');
    }
  }
}
