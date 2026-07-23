import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'yohpal_video_engine.dart';
import 'yohpal_video_source.dart';

class YohPalVideoController extends ChangeNotifier {
  final YohPalVideoEngine _engine;
  late final VideoController videoController;

  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _error;

  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get error => _error;
  Player get player => _engine.player;
  YohPalVideoSource? get source => _engine.source;

  YohPalVideoController(this._engine) {
    videoController = VideoController(_engine.player);
    _engine.player.stream.playing.listen((v) {
      _isPlaying = v;
      notifyListeners();
    });
    _engine.player.stream.buffering.listen((v) {
      _isBuffering = v;
      notifyListeners();
    });
    _engine.player.stream.position.listen((v) {
      _position = v;
      notifyListeners();
    });
    _engine.player.stream.duration.listen((v) {
      _duration = v;
      notifyListeners();
    });
    _engine.player.stream.error.listen((v) {
      _error = v;
      notifyListeners();
    });
  }

  Future<void> load({
    required YohPalVideoSource video,
    required bool isWifi,
    required bool lowDataMode,
    bool hlsEnabled = false,
    bool playImmediately = false,
  }) async {
    _error = null;
    await _engine.load(
      video: video,
      isWifi: isWifi,
      lowDataMode: lowDataMode,
      hlsEnabled: hlsEnabled,
      playImmediately: playImmediately,
    );
  }

  Future<void> play() => _engine.play();
  Future<void> pause() => _engine.pause();
  Future<void> stop() => _engine.stop();

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }
}
