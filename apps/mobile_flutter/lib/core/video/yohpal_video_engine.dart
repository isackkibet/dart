import 'package:media_kit/media_kit.dart';
import 'yohpal_video_source.dart';

class YohPalVideoEngine {
  final Player player;
  YohPalVideoSource? source;

  YohPalVideoEngine() : player = Player();

  Future<void> load({
    required YohPalVideoSource video,
    required bool isWifi,
    required bool lowDataMode,
    bool hlsEnabled = false,
    bool playImmediately = false,
  }) async {
    source = video;
    final url = video.bestUrl(
      isWifi: isWifi,
      lowDataMode: lowDataMode,
      hlsEnabled: hlsEnabled,
    );
    await player.open(
      Media(url, httpHeaders: video.headers),
      play: playImmediately,
    );
  }

  Future<void> play() => player.play();
  Future<void> pause() => player.pause();
  Future<void> stop() => player.stop();
  Future<void> dispose() => player.dispose();
}
