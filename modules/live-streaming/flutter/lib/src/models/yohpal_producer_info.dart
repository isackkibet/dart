class YohPalProducerInfo {
  final String producerId;
  final String kind;
  final String? peerId;

  const YohPalProducerInfo({
    required this.producerId,
    required this.kind,
    this.peerId,
  });

  factory YohPalProducerInfo.fromMap(Map<String, dynamic> map) {
    return YohPalProducerInfo(
      producerId: map['producerId'] as String? ?? '',
      kind: map['kind'] as String? ?? '',
      peerId: map['peerId'] as String?,
    );
  }
}
