import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../data/live_session_repository.dart';
import '../domain/live_session.dart';

class LiveSessionsController extends ChangeNotifier {
  LiveSessionsController({required LiveSessionRepository repository})
    : _repository = repository;

  final LiveSessionRepository _repository;
  StreamSubscription<List<LiveSession>>? _subscription;
  List<LiveSession> _sessions = const [];
  bool _isLoading = true;
  AppFailure? _failure;

  List<LiveSession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  AppFailure? get failure => _failure;

  void watch(String creatorId) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();
    _subscription = _repository
        .watchCreatorSessions(creatorId)
        .listen(
          (sessions) {
            _sessions = sessions;
            _isLoading = false;
            _failure = null;
            notifyListeners();
          },
          onError: (Object error) {
            _isLoading = false;
            _failure = AppFailure(
              message: 'Failed to watch live sessions.',
              code: 'live_sessions_watch_failed',
              details: error,
            );
            notifyListeners();
          },
        );
  }

  Future<Result<LiveSession>> create({
    required String creatorId,
    required String title,
    required String description,
    required String category,
    required String streamMode,
  }) {
    return _repository.create(
      LiveSession(
        id: '',
        creatorId: creatorId,
        title: title,
        description: description,
        category: category,
        status: 'draft',
        streamMode: streamMode,
        createdAt: null,
        updatedAt: null,
      ),
    );
  }

  Future<Result<void>> start(String sessionId, String actorId) {
    return _repository.updateStatus(
      sessionId: sessionId,
      status: 'live',
      actorId: actorId,
    );
  }

  Future<Result<void>> end(String sessionId, String actorId) {
    return _repository.updateStatus(
      sessionId: sessionId,
      status: 'ended',
      actorId: actorId,
    );
  }

  Future<Result<void>> delete(String sessionId) {
    return _repository.delete(sessionId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
