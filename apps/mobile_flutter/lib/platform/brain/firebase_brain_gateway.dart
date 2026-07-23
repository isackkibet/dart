import 'package:cloud_functions/cloud_functions.dart';
import 'yohpal_brain_gateway.dart';

class FirebaseBrainGateway implements YohPalBrainGateway {
  final FirebaseFunctions _functions;

  FirebaseBrainGateway({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  @override
  Future<Map<String, dynamic>> execute({
    required String agent,
    required String task,
    required Map<String, dynamic> input,
    String? userId,
    String? module,
  }) async {
    final result =
        await _functions.httpsCallable('executeYohPalBrainTask').call({
      'agent': agent,
      'task': task,
      'input': input,
      if (userId != null) 'userId': userId,
      if (module != null) 'module': module,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }
}
