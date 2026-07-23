class YohPalStreamingConfig {
  final String wsUrl;
  final String roomId;
  final String jwtToken;
  final String lanIp;
  final String turnUsername;
  final String turnPassword;

  const YohPalStreamingConfig({
    required this.wsUrl,
    required this.roomId,
    required this.jwtToken,
    required this.lanIp,
    required this.turnUsername,
    required this.turnPassword,
  });

  YohPalStreamingConfig copyWith({
    String? wsUrl,
    String? roomId,
    String? jwtToken,
    String? lanIp,
    String? turnUsername,
    String? turnPassword,
  }) {
    return YohPalStreamingConfig(
      wsUrl: wsUrl ?? this.wsUrl,
      roomId: roomId ?? this.roomId,
      jwtToken: jwtToken ?? this.jwtToken,
      lanIp: lanIp ?? this.lanIp,
      turnUsername: turnUsername ?? this.turnUsername,
      turnPassword: turnPassword ?? this.turnPassword,
    );
  }
}
