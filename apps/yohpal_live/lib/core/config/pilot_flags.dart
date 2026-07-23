class PilotFlags {
  static const bool multistreamPilot =
      bool.fromEnvironment(
        'YOHPAL_MULTISTREAM_PILOT',
        defaultValue: false,
      );
  static const bool giftsEnabled =
      bool.fromEnvironment(
        'YOHPAL_GIFTS_ENABLED',
        defaultValue: false,
      );
  static const bool ffmpegEnabled =
      bool.fromEnvironment(
        'YOHPAL_FFMPEG_ENABLED',
        defaultValue: false,
      );
}
