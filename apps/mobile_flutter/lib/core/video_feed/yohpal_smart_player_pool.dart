import '../video_native/yohpal_native_video_controller.dart';
import 'yohpal_feed_player_slot.dart';
import 'yohpal_feed_video_source.dart';
import 'yohpal_video_quality_selector.dart';

class YohPalSmartPlayerPool {
  final YohPalVideoQualitySelector qualitySelector;
  final YohPalNativeVideoController previousController;
  final YohPalNativeVideoController currentController;
  final YohPalNativeVideoController nextController;

  final YohPalFeedPlayerSlot previousSlot =
      YohPalFeedPlayerSlot(type: YohPalFeedSlotType.previous);
  final YohPalFeedPlayerSlot currentSlot =
      YohPalFeedPlayerSlot(type: YohPalFeedSlotType.current);
  final YohPalFeedPlayerSlot nextSlot =
      YohPalFeedPlayerSlot(type: YohPalFeedSlotType.next);

  YohPalSmartPlayerPool({
    required this.qualitySelector,
    required this.previousController,
    required this.currentController,
    required this.nextController,
  });

  Future<void> bindWindow({
    required List<YohPalFeedVideoSource> videos,
    required int currentIndex,
    required bool isWifi,
    required bool lowDataMode,
    required bool hlsEnabled,
  }) async {
    await _loadSlot(
      slot: previousSlot,
      controller: previousController,
      videos: videos,
      index: currentIndex - 1,
      isWifi: isWifi,
      lowDataMode: lowDataMode,
      hlsEnabled: hlsEnabled,
      autoplay: false,
    );
    await _loadSlot(
      slot: currentSlot,
      controller: currentController,
      videos: videos,
      index: currentIndex,
      isWifi: isWifi,
      lowDataMode: lowDataMode,
      hlsEnabled: hlsEnabled,
      autoplay: true,
    );
    await _loadSlot(
      slot: nextSlot,
      controller: nextController,
      videos: videos,
      index: currentIndex + 1,
      isWifi: isWifi,
      lowDataMode: lowDataMode,
      hlsEnabled: hlsEnabled,
      autoplay: false,
    );
  }

  Future<void> _loadSlot({
    required YohPalFeedPlayerSlot slot,
    required YohPalNativeVideoController controller,
    required List<YohPalFeedVideoSource> videos,
    required int index,
    required bool isWifi,
    required bool lowDataMode,
    required bool hlsEnabled,
    required bool autoplay,
  }) async {
    if (index < 0 || index >= videos.length) {
      slot.clear();
      await controller.pause();
      return;
    }
    final video = videos[index];
    if (slot.videoId == video.id) {
      if (autoplay) await controller.play();
      return;
    }
    final url = qualitySelector.selectUrl(
      source: video,
      isWifi: isWifi,
      lowDataMode: lowDataMode,
      hlsEnabled: hlsEnabled,
    );
    slot.assign(index: index, id: video.id);
    await controller.loadUrl(id: video.id, url: url, headers: video.headers);
    if (autoplay) {
      await controller.play();
    } else {
      await controller.pause();
    }
  }

  Future<void> pauseAll() async {
    await previousController.pause();
    await currentController.pause();
    await nextController.pause();
  }

  Future<void> disposeAll() async {
    await previousController.dispose();
    await currentController.dispose();
    await nextController.dispose();
  }
}
