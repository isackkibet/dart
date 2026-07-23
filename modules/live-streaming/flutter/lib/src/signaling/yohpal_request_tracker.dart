import 'dart:async';

import 'yohpal_signal_message.dart';

class YohPalRequestTracker {
  final Map<String, Completer<YohPalSignalMessage>> _pending = {};

  Future<YohPalSignalMessage> create(String requestId) {
    final completer = Completer<YohPalSignalMessage>();
    _pending[requestId] = completer;
    return completer.future;
  }

  bool resolve(YohPalSignalMessage message) {
    final requestId = message.requestId;
    if (requestId == null) {
      return false;
    }

    final completer = _pending.remove(requestId);
    if (completer == null) {
      return false;
    }

    if (!completer.isCompleted) {
      completer.complete(message);
    }
    return true;
  }

  void failAll(Object error) {
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }
    _pending.clear();
  }

  void cancel(String requestId) {
    _pending.remove(requestId);
  }

  int get pendingCount => _pending.length;
}
