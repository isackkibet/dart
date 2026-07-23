import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../data/poll_overlay_repository.dart';
import '../domain/live_poll.dart';

class PollOverlayController extends ChangeNotifier {
  PollOverlayController({
    required PollOverlayRepository repository,
    required String viewerId,
  })  : _repository = repository,
        _viewerId = viewerId;

  final PollOverlayRepository _repository;
  final String _viewerId;

  StreamSubscription<List<LivePoll>>? _subscription;

  List<LivePoll> _polls = const [];
  AppFailure? _failure;
  bool _isCreating = false;

  /// IDs of polls the local viewer has already voted in.
  final Set<String> _votedPollIds = {};

  /// Per-poll loading states (vote / close / delete).
  final Map<String, bool> _loadingMap = {};

  List<LivePoll> get polls => _polls;
  AppFailure? get failure => _failure;
  bool get isCreating => _isCreating;

  List<LivePoll> get openPolls =>
      _polls.where((p) => p.isOpen).toList();

  List<LivePoll> get closedPolls =>
      _polls.where((p) => p.isClosed).toList();

  bool hasVoted(String pollId) => _votedPollIds.contains(pollId);
  bool isLoading(String pollId) => _loadingMap[pollId] ?? false;

  // ── Stream ──────────────────────────────────────────────────────────────────

  void startWatching(String sessionId) {
    _subscription?.cancel();
    _subscription = _repository.watchSessionPolls(sessionId).listen(
      (polls) {
        _polls = polls;
        _failure = null;
        notifyListeners();
      },
      onError: (Object error) {
        _failure = AppFailure(
          message: error.toString(),
          code: 'poll_stream_error',
        );
        notifyListeners();
      },
    );
  }

  // ── Create ──────────────────────────────────────────────────────────────────

  Future<Result<LivePoll>> createPoll({
    required String sessionId,
    required String question,
    required List<String> options,
    int durationSeconds = 30,
    bool allowMultipleVotes = false,
  }) async {
    _isCreating = true;
    _failure = null;
    notifyListeners();

    final result = await _repository.createPoll(
      sessionId: sessionId,
      question: question,
      options: options,
      durationSeconds: durationSeconds,
      allowMultipleVotes: allowMultipleVotes,
    );

    _isCreating = false;
    if (result is Failure<LivePoll>) _failure = result.failure;
    notifyListeners();
    return result;
  }

  // ── Vote ────────────────────────────────────────────────────────────────────

  Future<Result<void>> castVote({
    required String pollId,
    required String sessionId,
    required List<String> optionIds,
  }) async {
    if (_votedPollIds.contains(pollId)) {
      return const Failure(AppFailure(
        message: 'You have already voted in this poll.',
        code: 'already_voted',
      ));
    }
    _setLoading(pollId, true);
    _failure = null;
    notifyListeners();

    final result = await _repository.castVote(
      pollId: pollId,
      sessionId: sessionId,
      optionIds: optionIds,
    );

    _setLoading(pollId, false);
    if (result is Success<void>) {
      _votedPollIds.add(pollId);
    } else if (result is Failure<void>) {
      _failure = result.failure;
    }
    notifyListeners();
    return result;
  }

  // ── Close ───────────────────────────────────────────────────────────────────

  Future<Result<void>> closePoll(String pollId) async {
    _setLoading(pollId, true);
    _failure = null;
    notifyListeners();

    final result = await _repository.closePoll(pollId);
    _setLoading(pollId, false);
    if (result is Failure<void>) _failure = result.failure;
    notifyListeners();
    return result;
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  Future<Result<void>> deletePoll(String pollId) async {
    _setLoading(pollId, true);
    _failure = null;
    notifyListeners();

    final result = await _repository.deletePoll(pollId);
    _setLoading(pollId, false);
    if (result is Failure<void>) _failure = result.failure;
    notifyListeners();
    return result;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _setLoading(String pollId, bool value) {
    if (value) {
      _loadingMap[pollId] = true;
    } else {
      _loadingMap.remove(pollId);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
