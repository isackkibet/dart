enum YohPalStreamingPhase {
  idle,
  preparing,
  connecting,
  live,
  reconnecting,
  ending,
  ended,
  failed,
}

final class YohPalStreamingState {
  const YohPalStreamingState({
    required this.phase,
    this.message,
    this.viewerCount = 0,
    this.error,
  });

  const YohPalStreamingState.idle()
      : phase = YohPalStreamingPhase.idle,
        message = null,
        viewerCount = 0,
        error = null;

  final YohPalStreamingPhase phase;
  final String? message;
  final int viewerCount;
  final Object? error;

  bool get isLive => phase == YohPalStreamingPhase.live;

  bool get isBusy =>
      phase == YohPalStreamingPhase.preparing ||
      phase == YohPalStreamingPhase.connecting ||
      phase == YohPalStreamingPhase.reconnecting ||
      phase == YohPalStreamingPhase.ending;

  YohPalStreamingState copyWith({
    YohPalStreamingPhase? phase,
    String? message,
    int? viewerCount,
    Object? error,
    bool clearError = false,
  }) {
    return YohPalStreamingState(
      phase: phase ?? this.phase,
      message: message ?? this.message,
      viewerCount: viewerCount ?? this.viewerCount,
      error: clearError ? null : error ?? this.error,
    );
  }
}
