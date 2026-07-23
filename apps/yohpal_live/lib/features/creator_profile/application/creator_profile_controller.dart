import 'package:flutter/foundation.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../data/creator_profile_repository.dart';
import '../domain/creator_profile.dart';

class CreatorProfileController extends ChangeNotifier {
  CreatorProfileController({
    required CreatorProfileRepository repository,
  }) : _repository = repository;

  final CreatorProfileRepository _repository;
  CreatorProfile? _profile;
  bool _isLoading = false;
  AppFailure? _failure;

  CreatorProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  AppFailure? get failure => _failure;

  Future<void> load(String uid) async {
    _isLoading = true;
    _failure = null;
    notifyListeners();
    final result = await _repository.getByUid(uid);
    _isLoading = false;
    if (result is Success<CreatorProfile?>) {
      _profile = result.data;
    } else if (result is Failure<CreatorProfile?>) {
      _failure = result.failure;
    }
    notifyListeners();
  }

  Future<Result<CreatorProfile>> save(CreatorProfile profile) async {
    _isLoading = true;
    _failure = null;
    notifyListeners();
    final result = await _repository.createOrUpdate(profile);
    _isLoading = false;
    if (result is Success<CreatorProfile>) {
      _profile = result.data;
    } else if (result is Failure<CreatorProfile>) {
      _failure = result.failure;
    }
    notifyListeners();
    return result;
  }
}
