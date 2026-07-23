import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../data/autonomy_repository.dart';
import '../domain/autonomy_decision.dart';
import '../domain/autonomy_policy.dart';

class AutonomyController extends ChangeNotifier {
  AutonomyController({
    required AutonomyRepository repository,
  }) : _repository = repository;

  final AutonomyRepository _repository;
  StreamSubscription<List<AutonomyPolicy>>? _policySub;
  StreamSubscription<List<AutonomyDecision>>? _decisionSub;
  List<AutonomyPolicy> _policies = const [];
  List<AutonomyDecision> _decisions = const [];
  bool _isLoading = true;
  AppFailure? _failure;

  List<AutonomyPolicy> get policies => _policies;
  List<AutonomyDecision> get decisions => _decisions;
  bool get isLoading => _isLoading;
  AppFailure? get failure => _failure;

  void watch(String creatorId) {
    _policySub?.cancel();
    _decisionSub?.cancel();
    _isLoading = true;
    notifyListeners();
    _policySub = _repository.watchPolicies(creatorId).listen(
      (items) {
        _policies = items;
        _isLoading = false;
        _failure = null;
        notifyListeners();
      },
      onError: (Object error) {
        _failure = AppFailure(
          message: 'Failed to watch autonomy policies.',
          code: 'autonomy_policy_watch_failed',
          details: error,
        );
        _isLoading = false;
        notifyListeners();
      },
    );
    _decisionSub = _repository.watchDecisions(creatorId).listen(
      (items) {
        _decisions = items;
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object error) {
        _failure = AppFailure(
          message: 'Failed to watch autonomy decisions.',
          code: 'autonomy_decision_watch_failed',
          details: error,
        );
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<Result<void>> savePolicy(AutonomyPolicy policy) {
    return _repository.upsertPolicy(policy);
  }

  Future<Result<void>> approveDecision(String decisionId, String actorId) {
    return _repository.approveDecision(
      decisionId: decisionId,
      actorId: actorId,
    );
  }

  Future<Result<void>> rejectDecision(String decisionId, String actorId) {
    return _repository.rejectDecision(
      decisionId: decisionId,
      actorId: actorId,
    );
  }

  @override
  void dispose() {
    _policySub?.cancel();
    _decisionSub?.cancel();
    super.dispose();
  }
}
