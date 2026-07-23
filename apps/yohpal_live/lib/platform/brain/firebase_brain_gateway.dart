import 'package:cloud_functions/cloud_functions.dart';
import 'yohpal_brain_gateway.dart';

class FirebaseBrainGateway implements YohPalBrainGateway {
  final FirebaseFunctions functions;
  FirebaseBrainGateway({FirebaseFunctions? functions})
      : functions = functions ?? FirebaseFunctions.instance;
  @override
  Future<Map<String, dynamic>> execute({
    required String agent,
    required String task,
    required Map<String, dynamic> input,
    String? userId,
    String? module,
  }) async {
    final result = await functions.httpsCallable('executeYohPalBrainTask').call({
      'agent': agent,
      'task': task,
      'input': input,
      'userId': userId,
      'module': module,
    });
    return Map<String, dynamic>.from(result.data);
  }
}
