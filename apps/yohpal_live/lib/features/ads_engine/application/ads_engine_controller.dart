import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../data/ads_engine_repository.dart';
import '../domain/ad_campaign.dart';
import '../domain/ad_placement.dart';

class AdsEngineController extends ChangeNotifier {
  AdsEngineController({required AdsEngineRepository repository})
      : _repository = repository;

  final AdsEngineRepository _repository;

  StreamSubscription<List<AdCampaign>>? _campaignSubscription;

  // ── Placement state ─────────────────────────────────────────────────────────
  AdPlacement? _currentPlacement;
  bool _isLoadingPlacement = false;
  bool _impressionRecorded = false;

  // ── Campaign state ──────────────────────────────────────────────────────────
  List<AdCampaign> _campaigns = const [];
  bool _isCreating = false;
  final Map<String, bool> _loadingIds = {};
  AppFailure? _failure;

  // ── Getters ─────────────────────────────────────────────────────────────────
  AdPlacement? get currentPlacement => _currentPlacement;
  bool get hasPlacement => _currentPlacement != null;
  bool get isLoadingPlacement => _isLoadingPlacement;
  List<AdCampaign> get campaigns => _campaigns;
  bool get isCreating => _isCreating;
  AppFailure? get failure => _failure;
  bool isLoading(String id) => _loadingIds[id] ?? false;

  List<AdCampaign> get activeCampaigns =>
      _campaigns.where((c) => c.isActive).toList();
  List<AdCampaign> get draftCampaigns =>
      _campaigns.where((c) => c.isDraft).toList();

  // ── Ad serving ──────────────────────────────────────────────────────────────

  Future<void> loadPlacement(String sessionId,
      {List<String> tags = const []}) async {
    _isLoadingPlacement = true;
    _impressionRecorded = false;
    notifyListeners();

    final result = await _repository.fetchPlacement(
      sessionId: sessionId,
      tags: tags,
    );

    _isLoadingPlacement = false;
    if (result is Success<AdPlacement?>) {
      _currentPlacement = result.data;
    } else if (result is Failure<AdPlacement?>) {
      _failure = result.failure;
    }
    notifyListeners();
  }

  Future<void> handleImpression(String sessionId) async {
    final p = _currentPlacement;
    if (p == null || _impressionRecorded) return;
    _impressionRecorded = true;
    await _repository.recordImpression(
      placementId: p.placementId,
      impressionToken: p.impressionToken,
      sessionId: sessionId,
    );
  }

  Future<void> handleClick(String sessionId) async {
    final p = _currentPlacement;
    if (p == null) return;
    await _repository.recordClick(
      placementId: p.placementId,
      impressionToken: p.impressionToken,
      sessionId: sessionId,
    );
  }

  void dismissPlacement() {
    _currentPlacement = null;
    _impressionRecorded = false;
    notifyListeners();
  }

  // ── Campaign management ─────────────────────────────────────────────────────

  void watchCampaigns(String advertiserId) {
    _campaignSubscription?.cancel();
    _campaignSubscription =
        _repository.watchCampaigns(advertiserId).listen(
      (campaigns) {
        _campaigns = campaigns;
        _failure = null;
        notifyListeners();
      },
      onError: (Object error) {
        _failure = AppFailure(
          message: error.toString(),
          code: 'campaign_stream_error',
        );
        notifyListeners();
      },
    );
  }

  Future<Result<AdCampaign>> createCampaign({
    required String title,
    required int budgetCents,
    required int cpmCents,
    required String creativeType,
    required String creativeRef,
    required String ctaLabel,
    required String ctaUrl,
    List<String> targetingTags = const [],
  }) async {
    _isCreating = true;
    _failure = null;
    notifyListeners();

    final result = await _repository.createCampaign(
      title: title,
      budgetCents: budgetCents,
      cpmCents: cpmCents,
      creativeType: creativeType,
      creativeRef: creativeRef,
      ctaLabel: ctaLabel,
      ctaUrl: ctaUrl,
      targetingTags: targetingTags,
    );

    _isCreating = false;
    if (result is Failure<AdCampaign>) _failure = result.failure;
    notifyListeners();
    return result;
  }

  Future<void> pauseCampaign(String id) async {
    _setLoading(id, true);
    final result = await _repository.pauseCampaign(id);
    _setLoading(id, false);
    if (result is Failure<void>) _failure = result.failure;
    notifyListeners();
  }

  Future<void> resumeCampaign(String id) async {
    _setLoading(id, true);
    final result = await _repository.resumeCampaign(id);
    _setLoading(id, false);
    if (result is Failure<void>) _failure = result.failure;
    notifyListeners();
  }

  void _setLoading(String id, bool value) {
    if (value) {
      _loadingIds[id] = true;
    } else {
      _loadingIds.remove(id);
    }
  }

  @override
  void dispose() {
    _campaignSubscription?.cancel();
    super.dispose();
  }
}
