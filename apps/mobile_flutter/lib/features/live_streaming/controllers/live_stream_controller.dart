import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import '../models/live_session_model.dart';
import '../repositories/live_repository.dart';
import '../services/live_token_service.dart';

enum LiveConnectionState { connected, reconnecting, disconnected }

enum LiveConnectionStatus { connected, reconnecting }

class LiveConnectionSupervisor {
  final StreamController<LiveConnectionStatus> _controller =
      StreamController<LiveConnectionStatus>.broadcast();

  Stream<LiveConnectionStatus> get status => _controller.stream;

  void connected() => _controller.add(LiveConnectionStatus.connected);

  Future<void> disconnected(
      {required Future<void> Function() reconnect}) async {
    _controller.add(LiveConnectionStatus.reconnecting);
    await reconnect();
  }

  void dispose() {
    _controller.close();
  }
}

class _JoinParams {
  const _JoinParams({
    required this.roomName,
    required this.identity,
    required this.role,
    required this.isHost,
  });

  final String roomName;
  final String identity;
  final String role;
  final bool isHost;
}

class LiveStreamController extends ChangeNotifier {
  final LiveRepository repository;
  final LiveTokenService tokenService;
  final String liveKitUrl;

  LiveStreamController({
    required this.repository,
    required this.tokenService,
    required this.liveKitUrl,
  });

  Room? room;
  LiveSessionModel? activeSession;
  bool loading = false;
  String? error;
  LiveConnectionState connectionState = LiveConnectionState.disconnected;

  final LiveConnectionSupervisor connectionSupervisor =
      LiveConnectionSupervisor();
  LiveConnectionStatus connectionStatus = LiveConnectionStatus.connected;

  StreamSubscription<LiveConnectionStatus>? _connectionStatusSub;
  EventsListener<RoomEvent>? _roomListener;
  _JoinParams? _lastJoin;
  bool _intentionalDisconnect = false;

  Future<void> startLive({
    required String creatorId,
    required String title,
    required String description,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final session = await repository.createLiveSession(
        creatorId: creatorId,
        title: title,
        description: description,
      );
      activeSession = session;

      final token = await tokenService.createToken(
        roomName: session.roomName,
        identity: creatorId,
        role: 'host',
      );

      final liveRoom = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
        ),
      );
      await liveRoom.connect(liveKitUrl, token);
      await liveRoom.localParticipant?.setMicrophoneEnabled(true);
      await liveRoom.localParticipant?.setCameraEnabled(true);
      room = liveRoom;
      _lastJoin = _JoinParams(
        roomName: session.roomName,
        identity: creatorId,
        role: 'host',
        isHost: true,
      );
      _attachRoomLifecycle(liveRoom);
      await repository.markLive(session.id);
    } catch (e) {
      error = e.toString();
      connectionState = LiveConnectionState.disconnected;
      final session = activeSession;
      if (session != null) {
        await repository.markFailed(
          sessionId: session.id,
          reason: e.toString(),
        );
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> joinLive({
    required LiveSessionModel session,
    required String viewerId,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final token = await tokenService.createToken(
        roomName: session.roomName,
        identity: viewerId,
        role: 'viewer',
      );

      final liveRoom = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
        ),
      );
      await liveRoom.connect(liveKitUrl, token);
      room = liveRoom;
      activeSession = session;
      _lastJoin = _JoinParams(
        roomName: session.roomName,
        identity: viewerId,
        role: 'viewer',
        isHost: false,
      );
      _attachRoomLifecycle(liveRoom);
      await repository.incrementViewerCount(session.id);
    } catch (e) {
      error = e.toString();
      connectionState = LiveConnectionState.disconnected;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> endLive() async {
    _intentionalDisconnect = true;
    final session = activeSession;
    await room?.disconnect();
    if (session != null) {
      await repository.endLive(session.id);
    }
    room = null;
    activeSession = null;
    _teardownConnectionState();
    notifyListeners();
  }

  Future<void> leaveLive() async {
    _intentionalDisconnect = true;
    final session = activeSession;
    await room?.disconnect();
    if (session != null) {
      await repository.decrementViewerCount(session.id);
    }
    room = null;
    activeSession = null;
    _teardownConnectionState();
    notifyListeners();
  }

  /// Subscribes to the room's own reconnect lifecycle and, only when the room
  /// reports itself fully disconnected without us having asked for that,
  /// hands off to [connectionSupervisor] to rebuild the room from scratch.
  void _attachRoomLifecycle(Room liveRoom) {
    _intentionalDisconnect = false;

    _connectionStatusSub?.cancel();
    _connectionStatusSub = connectionSupervisor.status.listen((status) {
      connectionStatus = status;
      notifyListeners();
    });

    _roomListener?.dispose();
    final listener = liveRoom.createListener();
    _roomListener = listener;
    listener
      ..on<RoomReconnectingEvent>((_) {
        connectionState = LiveConnectionState.reconnecting;
        connectionStatus = LiveConnectionStatus.reconnecting;
        notifyListeners();
      })
      ..on<RoomReconnectedEvent>((_) {
        connectionState = LiveConnectionState.connected;
        connectionSupervisor.connected();
      })
      ..on<RoomDisconnectedEvent>((_) {
        if (_intentionalDisconnect) return;
        unawaited(connectionSupervisor.disconnected(reconnect: _reconnect));
      });
  }

  Future<void> _reconnect() async {
    final join = _lastJoin;
    if (join == null) throw StateError('No active session to reconnect to.');

    final token = await tokenService.createToken(
      roomName: join.roomName,
      identity: join.identity,
      role: join.role,
    );

    final newRoom = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
      ),
    );
    await newRoom.connect(liveKitUrl, token);
    if (join.isHost) {
      await newRoom.localParticipant?.setMicrophoneEnabled(true);
      await newRoom.localParticipant?.setCameraEnabled(true);
    }
    room = newRoom;
    _attachRoomLifecycle(newRoom);
    notifyListeners();
  }

  void _teardownConnectionState() {
    _connectionStatusSub?.cancel();
    _connectionStatusSub = null;
    _roomListener?.dispose();
    _roomListener = null;
    _lastJoin = null;
    connectionState = LiveConnectionState.disconnected;
    connectionStatus = LiveConnectionStatus.connected;
  }

  @override
  void dispose() {
    connectionSupervisor.dispose();
    _connectionStatusSub?.cancel();
    _roomListener?.dispose();
    super.dispose();
  }
}
