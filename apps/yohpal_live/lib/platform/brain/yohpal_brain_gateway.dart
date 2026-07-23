abstract class YohPalBrainGateway {
  Future<Map<String, dynamic>> execute({
    required String agent,
    required String task,
    required Map<String, dynamic> input,
    String? userId,
    String? module,
  });
}
