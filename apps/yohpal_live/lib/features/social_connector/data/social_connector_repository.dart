import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../../../core/network/api_client.dart';
import '../domain/connector_health.dart';
import '../domain/social_connector.dart';

class SocialConnectorRepository {
  SocialConnectorRepository({
    required ApiClient apiClient,
    FirebaseFirestore? firestore,
  })  : _apiClient = apiClient,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final ApiClient _apiClient;
  final FirebaseFirestore _firestore;

  /// Real-time stream of all social connectors for a creator.
  Stream<List<SocialConnector>> watchConnectors(String creatorId) {
    return _firestore
        .collection('socialConnectors')
        .where('creatorId', isEqualTo: creatorId)
        .orderBy('connectedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => SocialConnector.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  /// Fetch OAuth authorization URL for a given platform.
  Future<Result<String>> getOAuthUrl(String platform) async {
    final result = await _apiClient.postJson(
      '/social-connectors/connectors/$platform/oauth-url',
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    final url = result.dataOrNull?['data']?['authUrl']?.toString();
    if (url == null || url.isEmpty) {
      return const Failure(
        AppFailure(
          message: 'No OAuth URL returned from server.',
          code: 'missing_oauth_url',
        ),
      );
    }
    return Success(url);
  }

  /// Trigger a health check for a connector.
  Future<Result<ConnectorHealth>> checkHealth(String connectorId) async {
    final result = await _apiClient.postJson(
      '/social-connectors/connectors/$connectorId/health',
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    final data = result.dataOrNull?['data'];
    if (data is! Map<String, dynamic>) {
      return const Failure(
        AppFailure(
          message: 'Invalid health check response.',
          code: 'invalid_health_response',
        ),
      );
    }
    return Success(ConnectorHealth.fromMap(data));
  }

  /// Disconnect (revoke) a social connector.
  Future<Result<void>> disconnectConnector(String connectorId) async {
    final result = await _apiClient.deleteJson(
      '/social-connectors/connectors/$connectorId',
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    return const Success(null);
  }
}
