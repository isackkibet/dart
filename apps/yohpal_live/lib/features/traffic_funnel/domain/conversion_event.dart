class ConversionEvent {
  const ConversionEvent({
    required this.id,
    required this.sessionId,
    required this.creatorId,
    required this.sourcePlatform,
    required this.conversionType,
    required this.valueAmount,
    required this.currency,
    required this.userId,
    required this.anonymousId,
    required this.campaignCode,
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final String creatorId;
  final String sourcePlatform;
  final String conversionType;
  final double valueAmount;
  final String currency;
  final String? userId;
  final String anonymousId;
  final String? campaignCode;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'creatorId': creatorId,
      'sourcePlatform': sourcePlatform,
      'conversionType': conversionType,
      'valueAmount': valueAmount,
      'currency': currency,
      'userId': userId,
      'anonymousId': anonymousId,
      'campaignCode': campaignCode,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
