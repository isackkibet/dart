class YohPalConsumerInfo {
  final String consumerId;
  final String producerId;
  final String kind;
  final Map<String, dynamic> rtpParameters;

  const YohPalConsumerInfo({
    required this.consumerId,
    required this.producerId,
    required this.kind,
    required this.rtpParameters,
  });

  factory YohPalConsumerInfo.fromMap(Map<String, dynamic> map) {
    return YohPalConsumerInfo(
      consumerId: map['consumerId'] as String? ?? '',
      producerId: map['producerId'] as String? ?? '',
      kind: map['kind'] as String? ?? '',
      rtpParameters:
          (map['rtpParameters'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }
}
