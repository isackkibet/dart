class YohPalSignalMessage {
  final String action;
  final String? requestId;
  final Map<String, dynamic> data;

  const YohPalSignalMessage({
    required this.action,
    required this.requestId,
    required this.data,
  });

  factory YohPalSignalMessage.fromMap(Map<String, dynamic> map) {
    return YohPalSignalMessage(
      action: map['action'] as String? ?? 'unknown',
      requestId: map['requestId'] as String?,
      data:
          (map['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'requestId': requestId,
      'data': data,
    };
  }
}
