import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../data/live_chat_repository.dart';
import '../domain/chat_message.dart';

class LiveChatController extends ChangeNotifier {
  LiveChatController({
    required LiveChatRepository repository,
    required String currentUserId,
    required String currentUserName,
  })  : _repository = repository,
        _currentUserId = currentUserId,
        _currentUserName = currentUserName;

  final LiveChatRepository _repository;
  final String _currentUserId;
  final String _currentUserName;

  StreamSubscription<List<ChatMessage>>? _messagesSub;
  StreamSubscription<ChatMessage?>? _pinnedSub;

  List<ChatMessage> _messages = const [];
  ChatMessage? _pinnedMessage;
  AppFailure? _failure;
  bool _isSending = false;
  bool _isMuted = false;

  // ── Rate-limit guard (1 msg/sec client-side) ──────────────────────────────
  DateTime? _lastSentAt;
  static const _minInterval = Duration(seconds: 1);

  // ── Per-message action loading states ─────────────────────────────────────
  final Map<String, bool> _loadingIds = {};

  List<ChatMessage> get messages => _messages;
  ChatMessage? get pinnedMessage => _pinnedMessage;
  AppFailure? get failure => _failure;
  bool get isSending => _isSending;
  bool get isMuted => _isMuted;
  String get currentUserId => _currentUserId;
  bool isLoading(String id) => _loadingIds[id] ?? false;

  // ── Start watching ─────────────────────────────────────────────────────────

  void startWatching(String sessionId) {
    _messagesSub?.cancel();
    _pinnedSub?.cancel();

    _messagesSub = _repository
        .watchMessages(sessionId)
        .listen(
          (msgs) {
            _messages = msgs;
            _failure = null;
            notifyListeners();
          },
          onError: (Object err) {
            _failure = AppFailure(
              message: err.toString(),
              code: 'chat_stream_error',
            );
            notifyListeners();
          },
        );

    _pinnedSub = _repository.watchPinnedMessage(sessionId).listen(
      (msg) {
        _pinnedMessage = msg;
        notifyListeners();
      },
    );
  }

  // ── Send message ───────────────────────────────────────────────────────────

  Future<Result<void>> sendMessage(String sessionId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const Failure(
          AppFailure(message: 'Message cannot be empty.', code: 'empty_message'));
    }
    if (_isMuted) {
      return const Failure(
          AppFailure(message: 'You are muted in this session.', code: 'user_muted'));
    }

    // Client-side rate limit
    final now = DateTime.now();
    if (_lastSentAt != null && now.difference(_lastSentAt!) < _minInterval) {
      return const Failure(AppFailure(
        message: 'You are sending messages too fast.',
        code: 'rate_limited',
      ));
    }

    _isSending = true;
    _failure = null;
    notifyListeners();

    final result = await _repository.sendMessage(
      sessionId: sessionId,
      text: trimmed,
    );

    _isSending = false;
    if (result is Success<void>) {
      _lastSentAt = now;
    } else if (result is Failure<void>) {
      _failure = result.failure;
      // If server returns muted error, set local muted flag
      if (result.failure.code == 'user_muted') _isMuted = true;
    }
    notifyListeners();
    return result;
  }

  // ── Pin message ────────────────────────────────────────────────────────────

  Future<void> pinMessage(String sessionId, String messageId) async {
    _setLoading(messageId, true);
    final result = await _repository.pinMessage(
      sessionId: sessionId,
      messageId: messageId,
    );
    _setLoading(messageId, false);
    if (result is Failure<void>) _failure = result.failure;
    notifyListeners();
  }

  // ── Delete message ─────────────────────────────────────────────────────────

  Future<void> deleteMessage(String sessionId, String messageId) async {
    _setLoading(messageId, true);
    final result = await _repository.deleteMessage(
      sessionId: sessionId,
      messageId: messageId,
    );
    _setLoading(messageId, false);
    if (result is Failure<void>) _failure = result.failure;
    notifyListeners();
  }

  // ── Mute user ──────────────────────────────────────────────────────────────

  Future<void> muteUser(String sessionId, String userId) async {
    _setLoading(userId, true);
    final result = await _repository.muteUser(
      sessionId: sessionId,
      userId: userId,
    );
    _setLoading(userId, false);
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
    _messagesSub?.cancel();
    _pinnedSub?.cancel();
    super.dispose();
  }
}
