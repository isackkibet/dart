class DefaultVideoStoragePaths {
  const DefaultVideoStoragePaths._();

  static String rawVideoPath({
    required String baseDirectory,
    required String fileName,
  }) {
    return '$baseDirectory/raw_videos/$fileName';
  }
}
