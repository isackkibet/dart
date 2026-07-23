abstract interface class YohPalSignalingTransport {
  Stream<dynamic> get messages;
  Stream<Object> get errors;
  void send(String message);
  Future<void> close();
}
