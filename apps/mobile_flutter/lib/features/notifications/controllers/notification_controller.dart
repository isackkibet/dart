import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../auth/session_cleanup_service.dart';
import '../models/app_notification_payload.dart';
import '../services/notification_service.dart';

class NotificationController extends ChangeNotifier
    implements SessionScopedState {
  final NotificationService service;

  NotificationController({required this.service});

  bool _initialized = false;
  String? token;
  RemoteMessage? latestForegroundMessage;

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _tapSub;

  /// Safe to call from build() — guard ensures setup runs exactly once per
  /// signed-in account. clearSession() resets the guard on logout so the
  /// next account's FCM token actually gets saved — previously the token
  /// was only ever bound to whichever account was signed in first.
  Future<void> initializeForUser({
    required String uid,
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    if (_initialized) return;
    _initialized = true;

    await service.requestPermission();
    // Auto-init is disabled in AndroidManifest to silence the pre-permission
    // DEVELOPER_ERROR from GMS. Enable it now that permission has been granted.
    try { await FirebaseMessaging.instance.setAutoInitEnabled(true); } catch (_) {}
    token = await service.getToken();
    try {
      await service.saveTokenForUser(uid);
    } catch (_) {
      // Auth token may not have propagated to Firestore yet on first sign-in.
      // Token will be saved on next app open once auth is stable.
    }

    _foregroundSub = service.foregroundMessages().listen((message) {
      latestForegroundMessage = message;
      notifyListeners();
    });

    _tapSub = service.notificationTaps().listen((message) {
      _handlePayload(
        AppNotificationPayload.fromMap(message.data),
        navigatorKey,
      );
    });

    final initialPayload = await service.getInitialPayload();
    if (initialPayload != null) {
      _handlePayload(initialPayload, navigatorKey);
    }
  }

  @override
  Future<void> clearSession() async {
    await _foregroundSub?.cancel();
    await _tapSub?.cancel();
    _foregroundSub = null;
    _tapSub = null;
    _initialized = false;
    token = null;
    latestForegroundMessage = null;
    notifyListeners();
  }

  void _handlePayload(
    AppNotificationPayload payload,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    if (payload.type == 'video' && payload.videoId != null) {
      navigator.pushNamed('/', arguments: payload.videoId);
      return;
    }
    if (payload.type == 'live' && payload.liveSessionId != null) {
      navigator.pushNamed('/live-viewer', arguments: payload.liveSessionId);
      return;
    }
    if (payload.type == 'chat' && payload.chatId != null) {
      navigator.pushNamed('/chat-room', arguments: payload.chatId);
      return;
    }
    if (payload.type == 'poll') {
      final target = payload.pollId ?? payload.videoId;
      if (target != null) {
        navigator.pushNamed('/poll', arguments: target);
      }
      return;
    }
  }
}
