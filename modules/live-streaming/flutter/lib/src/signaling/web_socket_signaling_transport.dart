import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'yohpal_signaling_transport.dart';

final class WebSocketSignalingTransport implements YohPalSignalingTransport {
  WebSocketSignalingTransport(this._uri);

  final Uri _uri;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final StreamController<String> _messageController =
      StreamController<String>.broadcast();
  final StreamController<Object> _errorController =
      StreamController<Object>.broadcast();

  @override
  Stream<dynamic> get messages => _messageController.stream;

  @override
  Stream<Object> get errors => _errorController.stream;

  void connect() {
    if (_channel != null) return;

    _channel = WebSocketChannel.connect(_uri);

    _subscription = _channel!.stream.listen(
      (dynamic raw) {
        _messageController.add(raw as String);
      },
      onDone: () {
        _errorController.add(
          StateError('WebSocket connection closed'),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        _errorController.add(error);
      },
    );
  }

  @override
  void send(String message) {
    _channel?.sink.add(message);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    await _messageController.close();
    await _errorController.close();
  }
}
