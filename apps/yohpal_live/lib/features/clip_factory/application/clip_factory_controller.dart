import 'package:flutter/foundation.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../data/clip_factory_repository.dart';
import '../domain/clip_segment.dart';
import '../domain/session_replay.dart';

class ClipFactoryController extends ChangeNotifier {
  ClipFactoryController({
    required ClipFactoryRepository repository,
    required String sessionId,
  })  : _repository = repository,
        _sessionId = sessionId;

  final ClipFactoryRepository _repository;
  final String _sessionId;
  SessionReplay? _replay;
  List<ClipSegment> _clips = const [];
  bool _isLoading = false;
  bool _isGenerating = false;
  AppFailure? _failure;

  SessionReplay? get replay => _replay;
  List<ClipSegment> get clips => _clips;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  AppFailure? get failure => _failure;

  Future<void> load() async {
    _isLoading = true;
    _failure = null;
    notifyListeners();
    final replayResult = await _repository.getSessionReplay(_sessionId);
    final clipsResult = await _repository.getClipSegments(_sessionId);
    if (replayResult is Success<SessionReplay?>) {
      _replay = replayResult.data;
    } else if (replayResult is Failure<SessionReplay?>) {
      _failure = replayResult.failure;
    }
    if (clipsResult is Success<List<ClipSegment>>) {
      _clips = clipsResult.data;
    } else if (clipsResult is Failure<List<ClipSegment>>) {
      _failure = clipsResult.failure;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> generate() async {
    _isGenerating = true;
    _failure = null;
    notifyListeners();
    final result = await _repository.generateClips(_sessionId);
    if (result is Failure<void>) {
      _failure = result.failure;
    }
    _isGenerating = false;
    await load();
  }

  Future<Result<void>> approveClip(String clipId) async {
    final result = await _repository.updateClipStatus(
      sessionId: _sessionId,
      clipId: clipId,
      status: 'approved',
    );
    if (result is Success<void>) {
      await load();
    }
    return result;
  }

  Future<Result<void>> rejectClip(String clipId) async {
    final result = await _repository.updateClipStatus(
      sessionId: _sessionId,
      clipId: clipId,
      status: 'rejected',
    );
    if (result is Success<void>) {
      await load();
    }
    return result;
  }

  Future<Result<void>> distributeClip(String clipId) async {
    final result = await _repository.distributeClip(
      sessionId: _sessionId,
      clipId: clipId,
    );
    if (result is Success<void>) {
      await load();
    }
    return result;
  }
}
