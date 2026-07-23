import 'package:flutter/foundation.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../data/creator_growth_repository.dart';
import '../domain/creator_growth_score.dart';
import '../domain/growth_recommendation.dart';

class CreatorGrowthController extends ChangeNotifier {
  CreatorGrowthController({
    required CreatorGrowthRepository repository,
  }) : _repository = repository;

  final CreatorGrowthRepository _repository;
  CreatorGrowthScore? _score;
  List<GrowthRecommendation> _recommendations = const [];
  bool _isLoading = false;
  AppFailure? _failure;

  CreatorGrowthScore? get score => _score;
  List<GrowthRecommendation> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  AppFailure? get failure => _failure;

  Future<void> load(String creatorId) async {
    _isLoading = true;
    _failure = null;
    notifyListeners();
    final scoreResult = await _repository.getScore(creatorId);
    final recommendationResult = await _repository.getRecommendations(creatorId);
    if (scoreResult is Success<CreatorGrowthScore>) {
      _score = scoreResult.data;
    } else if (scoreResult is Failure<CreatorGrowthScore>) {
      _failure = scoreResult.failure;
    }
    if (recommendationResult is Success<List<GrowthRecommendation>>) {
      _recommendations = recommendationResult.data;
    } else if (recommendationResult is Failure<List<GrowthRecommendation>>) {
      _failure = recommendationResult.failure;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> generate(String creatorId) async {
    _isLoading = true;
    notifyListeners();
    final result = await _repository.generateRecommendations(creatorId);
    if (result is Failure<void>) {
      _failure = result.failure;
    }
    await load(creatorId);
  }
}
