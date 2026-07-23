import 'dart:async';
import 'package:flutter/foundation.dart';

class OverlayVisibilityController extends ChangeNotifier {
  OverlayVisibilityController({this.hideDelay = const Duration(seconds: 4)});

  final Duration hideDelay;
  bool _visible = true;
  Timer? _timer;

  bool get visible => _visible;

  void start() {
    _visible = true;
    notifyListeners();
    _scheduleHide();
  }

  void showTemporarily() {
    _visible = true;
    notifyListeners();
    _scheduleHide();
  }

  void toggle() {
    _visible = !_visible;
    notifyListeners();
    if (_visible) {
      _scheduleHide();
    } else {
      _timer?.cancel();
    }
  }

  void keepVisible() {
    _timer?.cancel();
    _visible = true;
    notifyListeners();
  }

  void hideImmediately() {
    _timer?.cancel();
    _visible = false;
    notifyListeners();
  }

  void _scheduleHide() {
    _timer?.cancel();
    _timer = Timer(hideDelay, () {
      _visible = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
