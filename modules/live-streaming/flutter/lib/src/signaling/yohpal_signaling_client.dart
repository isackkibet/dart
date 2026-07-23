import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'yohpal_request_tracker.dart';
import 'yohpal_signal_message.dart';
import 'yohpal_signaling_transport.dart';

class YohPalSignalingClient {
  final YohPalSignalingTransport _transport;
  final YohPalRequestTracker _tracker = YohPalRequestTracker();

  StreamSubscription<dynamic>? _messagesSub;
  StreamSubscription<Object>? _errorsSub;

  final StreamController<YohPalSignalMessage> _events =
      StreamController<YohPalSignalMessage>.broadcast();

  bool _connected = false;

  YohPalSignalingClient({
    required YohPalSignalingTransport transport,
  }) : _transport = transport;

  Stream<YohPalSignalMessage> get events => _events.stream;

  bool get isConnected => _connected;

  int get pendingRequestCount => _tracker.pendingCount;

  void connect() {
    if (_connected) return;
    _connected = true;

    _messagesSub = _transport.messages.listen(
      (dynamic raw) {
        try {
          final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
          final message = YohPalSignalMessage.fromMap(decoded);
          final resolved = _tracker.resolve(message);
          if (!resolved) {
            _events.add(message);
          }
        } catch (error) {
          _events.add(
            YohPalSignalMessage(
              action: 'error',
              requestId: null,
              data: {
                'message': error.toString(),
              },
            ),
          );
        }
      },
    );

    _errorsSub = _transport.errors.listen((Object error) {
      _tracker.failAll(error);
      _events.add(
        YohPalSignalMessage(
          action: 'error',
          requestId: null,
          data: {
            'message': error.toString(),
          },
        ),
      );
    });
  }

  Future<YohPalSignalMessage> request(
    String action,
    Map<String, dynamic> data, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    final requestId = _requestId();
    final future = _tracker.create(requestId);

    final message = YohPalSignalMessage(
      action: action,
      requestId: requestId,
      data: data,
    );

    _transport.send(jsonEncode(message.toMap()));
    return future.timeout(
      timeout,
      onTimeout: () {
        _tracker.cancel(requestId);
        throw TimeoutException(
          'Signaling request timed out: $action',
          timeout,
        );
      },
    );
  }

  Future<void> close() async {
    await _messagesSub?.cancel();
    await _errorsSub?.cancel();
    await _transport.close();
    await _events.close();
    _connected = false;
  }

  String _requestId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(1 << 30);
    return '$now-$rand';
  }
}
