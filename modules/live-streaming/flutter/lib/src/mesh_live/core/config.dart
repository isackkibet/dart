class AppConfig {
  static const apiBaseUrl=String.fromEnvironment('API_BASE_URL',defaultValue:'http://10.0.2.2:8080');

  static Map<String,dynamic> get defaultIceServers => {
    'iceServers': [
      {'urls': ['stun:stun.l.google.com:19302']},
    ],
  };
}
