import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class MeshApi {
  MeshApi({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;
  final FirebaseAuth _auth;

  Future<Map<String, String>> _headers() async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) throw StateError('Authentication required');
    return {'content-type': 'application/json', 'authorization': 'Bearer $token'};
  }

  Future<Map<String,dynamic>> createProduction(String title) async {
    final r=await http.post(Uri.parse('${AppConfig.apiBaseUrl}/v1/productions'),headers:await _headers(),body:jsonEncode({'title':title}));return _json(r);
  }
  Future<Map<String,dynamic>> pairingToken(String id,{required String role,required String label,String? venue,String? participantId}) async {
    final r=await http.post(Uri.parse('${AppConfig.apiBaseUrl}/v1/productions/$id/pairing-token'),headers:await _headers(),body:jsonEncode({'role':role,'label':label,'venue':venue,'participantId':participantId}));return _json(r);
  }
  Future<Map<String,dynamic>> setLayout(String id,String layout,List<String> cameras) async {
    final r=await http.post(Uri.parse('${AppConfig.apiBaseUrl}/v1/productions/$id/layout'),headers:await _headers(),body:jsonEncode({'layout':layout,'cameraIds':cameras}));return _json(r);
  }
  Map<String,dynamic> _json(http.Response r){final decoded=jsonDecode(r.body);final b=decoded is Map<String,dynamic>?decoded:<String,dynamic>{'data':decoded};if(r.statusCode>=400)throw Exception(b['error']??'Request failed');return b;}

  Future<Map<String,dynamic>> fetchIceConfig(String productionId) async {
    try {
      final r = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/v1/productions/$productionId/ice-configuration'),
        headers: await _headers(),
      );
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String,dynamic>;
    } catch (_) {}
    return AppConfig.defaultIceServers;
  }
}
