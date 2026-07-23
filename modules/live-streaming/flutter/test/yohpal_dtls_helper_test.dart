import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_streaming/src/rtc/yohpal_dtls_helper.dart';

void main() {
  test('extractDtlsParametersFromSdp parses fingerprint', () {
    const sdp = '''
v=0
a=fingerprint:sha-256 AB:CD:EF:12
''';
    final params = YohPalDtlsHelper.extractDtlsParametersFromSdp(sdp);
    expect(params['role'], 'auto');
    final fingerprints = params['fingerprints'] as List;
    expect(fingerprints.first['algorithm'], 'sha-256');
    expect(fingerprints.first['value'], 'AB:CD:EF:12');
  });

  test('extractDtlsParametersFromSdp throws when fingerprint missing', () {
    expect(
      () => YohPalDtlsHelper.extractDtlsParametersFromSdp('v=0'),
      throwsStateError,
    );
  });
}
