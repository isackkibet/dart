import 'package:flutter/foundation.dart';
import '../models/poll_model.dart';
import '../repositories/poll_repository.dart';

class PollController extends ChangeNotifier {
  final PollRepository repository;

  PollController({required this.repository});

  bool loading = false;
  String? error;

  Future<void> vote({
    required PollModel poll,
    required String userId,
    required String option,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await repository.vote(
        poll: poll,
        userId: userId,
        option: option,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
