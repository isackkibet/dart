enum YohPalFeedSlotType { previous, current, next }

class YohPalFeedPlayerSlot {
  final YohPalFeedSlotType type;
  int? videoIndex;
  String? videoId;

  YohPalFeedPlayerSlot({
    required this.type,
    this.videoIndex,
    this.videoId,
  });

  void assign({required int index, required String id}) {
    videoIndex = index;
    videoId = id;
  }

  void clear() {
    videoIndex = null;
    videoId = null;
  }
}
