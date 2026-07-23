class YohPalTransportInfo {
  final String id;
  final String direction;
  final Map<String, dynamic> iceParameters;
  final List<dynamic> iceCandidates;
  final Map<String, dynamic> dtlsParameters;

  const YohPalTransportInfo({
    required this.id,
    required this.direction,
    required this.iceParameters,
    required this.iceCandidates,
    required this.dtlsParameters,
  });

  factory YohPalTransportInfo.fromSignal(Map<String, dynamic> map) {
    return YohPalTransportInfo(
      id: map['id'] as String? ?? '',
      direction: map['direction'] as String? ?? '',
      iceParameters:
          (map['iceParameters'] as Map?)?.cast<String, dynamic>() ?? {},
      iceCandidates: (map['iceCandidates'] as List?) ?? const [],
      dtlsParameters:
          (map['dtlsParameters'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }
}
