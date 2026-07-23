import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../../../core/network/api_client.dart';
import '../domain/ad_campaign.dart';
import '../domain/ad_placement.dart';

class AdsEngineRepository {
  AdsEngineRepository({
    required ApiClient apiClient,
    FirebaseFirestore? firestore,
  })  : _apiClient = apiClient,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final ApiClient _apiClient;
  final FirebaseFirestore _firestore;

  // ── Ad serving ──────────────────────────────────────────────────────────────

  Future<Result<AdPlacement?>> fetchPlacement({
    required String sessionId,
    List<String> tags = const [],
  }) async {
    final tagParam = tags.isNotEmpty ? '&tags=${tags.join(',')}' : '';
    final result = await _apiClient.getJson(
      '/ads/serve?sessionId=$sessionId$tagParam',
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    final data = result.dataOrNull?['data'];
    if (data == null) return const Success(null);
    return Success(AdPlacement.fromMap(Map<String, dynamic>.from(data)));
  }

  // ── Impression / click recording ────────────────────────────────────────────

  Future<Result<void>> recordImpression({
    required String placementId,
    required String impressionToken,
    required String sessionId,
  }) async {
    final result = await _apiClient.postJson(
      '/ads/impressions',
      body: {
        'placementId': placementId,
        'impressionToken': impressionToken,
        'sessionId': sessionId,
      },
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    return const Success(null);
  }

  Future<Result<void>> recordClick({
    required String placementId,
    required String impressionToken,
    required String sessionId,
  }) async {
    final result = await _apiClient.postJson(
      '/ads/clicks',
      body: {
        'placementId': placementId,
        'impressionToken': impressionToken,
        'sessionId': sessionId,
      },
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    return const Success(null);
  }

  // ── Campaign stream ─────────────────────────────────────────────────────────

  Stream<List<AdCampaign>> watchCampaigns(String advertiserId) {
    return _firestore
        .collection('adCampaigns')
        .where('advertiserId', isEqualTo: advertiserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AdCampaign.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // ── Campaign CRUD ───────────────────────────────────────────────────────────

  Future<Result<AdCampaign>> createCampaign({
    required String title,
    required int budgetCents,
    required int cpmCents,
    required String creativeType,
    required String creativeRef,
    required String ctaLabel,
    required String ctaUrl,
    List<String> targetingTags = const [],
    String? startDate,
    String? endDate,
  }) async {
    final result = await _apiClient.postJson(
      '/ads/campaigns',
      body: {
        'title': title,
        'budgetCents': budgetCents,
        'cpmCents': cpmCents,
        'creativeType': creativeType,
        'creativeRef': creativeRef,
        'ctaLabel': ctaLabel,
        'ctaUrl': ctaUrl,
        'targetingTags': targetingTags,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      },
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    final data = result.dataOrNull?['data'];
    if (data == null) {
      return const Failure(AppFailure(
        message: 'Invalid response from server.',
        code: 'invalid_response',
      ));
    }
    final id = data['id']?.toString() ?? '';
    return Success(AdCampaign.fromMap(id, Map<String, dynamic>.from(data)));
  }

  Future<Result<void>> pauseCampaign(String campaignId) async {
    final result = await _apiClient.patchJson(
      '/ads/campaigns/$campaignId/pause',
      body: {},
    );
    if (result is Failure<Map<String, dynamic>>) return Failure(result.failure);
    return const Success(null);
  }

  Future<Result<void>> resumeCampaign(String campaignId) async {
    final result = await _apiClient.patchJson(
      '/ads/campaigns/$campaignId/resume',
      body: {},
    );
    if (result is Failure<Map<String, dynamic>>) return Failure(result.failure);
    return const Success(null);
  }
}
