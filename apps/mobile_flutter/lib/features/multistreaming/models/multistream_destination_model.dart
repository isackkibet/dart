class MultistreamDestinationModel {
  final String id;
  final String platform;
  final String rtmpUrl;
  final String streamKeyMasked;
  final String status;
  final String? error;

  const MultistreamDestinationModel({
    required this.id,
    required this.platform,
    required this.rtmpUrl,
    required this.streamKeyMasked,
    required this.status,
    this.error,
  });

  factory MultistreamDestinationModel.fromMap(Map<String, dynamic> map) {
    return MultistreamDestinationModel(
      id: map['id'] ?? '',
      platform: map['platform'] ?? '',
      rtmpUrl: map['rtmpUrl'] ?? '',
      streamKeyMasked: map['streamKeyMasked'] ?? '',
      status: map['status'] ?? 'pending',
      error: map['error'],
    );
  }
}
