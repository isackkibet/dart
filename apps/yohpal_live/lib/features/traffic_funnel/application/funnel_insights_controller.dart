import 'package:flutter/foundation.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../data/funnel_summary_repository.dart';
import '../domain/funnel_summary.dart';

class FunnelInsightsController extends ChangeNotifier {
  FunnelInsightsController({
    required FunnelSummaryRepository repository,
  }) : _repository = repository;

  final FunnelSummaryRepository _repository;
  FunnelSummary? _summary;
  bool _isLoading = false;
  AppFailure? _failure;

  FunnelSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  AppFailure? get failure => _failure;

  Future<void> load(String sessionId) async {
    _isLoading = true;
    _failure = null;
    notifyListeners();
    final result = await _repository.getSessionSummary(sessionId);
    _isLoading = false;
    if (result is Success<FunnelSummary>) {
      _summary = result.data;
    } else if (result is Failure<FunnelSummary>) {
      _failure = result.failure;
    }
    notifyListeners();
  }
}
