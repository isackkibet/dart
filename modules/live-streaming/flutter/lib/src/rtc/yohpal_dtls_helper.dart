class YohPalDtlsHelper {
  static Map<String, dynamic> extractDtlsParametersFromSdp(String sdp) {
    final fingerprintLine =
        sdp.split('\n').map((line) => line.trim()).firstWhere(
              (line) => line.startsWith('a=fingerprint:'),
              orElse: () => '',
            );
    if (fingerprintLine.isEmpty) {
      throw StateError('Client DTLS fingerprint not found in SDP.');
    }
    final parts = fingerprintLine.replaceFirst('a=fingerprint:', '').split(' ');
    if (parts.length < 2) {
      throw StateError('Invalid DTLS fingerprint line: $fingerprintLine');
    }
    return {
      'role': 'auto',
      'fingerprints': [
        {
          'algorithm': parts[0],
          'value': parts.sublist(1).join(' '),
        }
      ],
    };
  }
}
