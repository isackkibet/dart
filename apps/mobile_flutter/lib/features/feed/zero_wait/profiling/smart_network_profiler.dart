import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../policy/zero_wait_buffer_policy.dart';

/// Measured network sample combining download throughput, latency, and failure rate.
final class NetworkMeasurement {
  const NetworkMeasurement({
    required this.downloadMbps,
    required this.latencyMs,
    required this.failureRate,
  });

  final double downloadMbps;
  final int latencyMs;
  final double failureRate;
}

/// Pluggable probe interface for network measurement.
abstract interface class NetworkProbe {
  Future<NetworkMeasurement> measure();
}

/// Downloads a small file to measure real throughput and latency.
final class HttpNetworkProbe implements NetworkProbe {
  const HttpNetworkProbe({required this.probeUrl});
  final Uri probeUrl;

  @override
  Future<NetworkMeasurement> measure() async {
    final sw = Stopwatch()..start();
    try {
      final client = HttpClient();
      try {
        final request = await client.getUrl(probeUrl)
            .timeout(const Duration(seconds: 5));
        final response = await request.close()
            .timeout(const Duration(seconds: 5));
        int bytes = 0;
        await for (final chunk in response) {
          bytes += chunk.length;
        }
        sw.stop();
        final seconds = sw.elapsedMilliseconds / 1000.0;
        final mbps = seconds > 0 ? (bytes * 8) / (seconds * 1e6) : 0.0;
        return NetworkMeasurement(
          downloadMbps: mbps,
          latencyMs: sw.elapsedMilliseconds,
          failureRate: 0.0,
        );
      } finally {
        client.close();
      }
    } catch (_) {
      sw.stop();
      return const NetworkMeasurement(
        downloadMbps: 0,
        latencyMs: 9999,
        failureRate: 1.0,
      );
    }
  }
}

/// Classifies the current network into [YohPalNetworkClass].
///
/// WiFi is measured to distinguish strong (≥ 10 Mbps) vs weak (< 10 Mbps).
/// Mobile connections are classified by download speed:
///   offline     → downloadMbps ≤ 0 or no connectivity
///   constrained → < 0.6 Mbps OR latency > 900 ms OR failure > 20%
///   threeG      → < 2 Mbps OR latency > 500 ms
///   fourG       → < 12 Mbps OR latency > 160 ms
///   fiveG       → ≥ 12 Mbps, latency ≤ 160 ms
class SmartNetworkProfiler {
  SmartNetworkProfiler({
    Connectivity? connectivity,
    required NetworkProbe probe,
  })  : _connectivity = connectivity ?? Connectivity(),
        _probe = probe;

  final Connectivity _connectivity;
  final NetworkProbe _probe;

  Future<YohPalNetworkClass> currentClass() async {
    final results = await _connectivity.checkConnectivity();
    return _classify(results);
  }

  Stream<YohPalNetworkClass> watchClass() =>
      _connectivity.onConnectivityChanged.asyncMap(_classify);

  Future<YohPalNetworkClass> _classify(List<ConnectivityResult> results) async {
    if (results.contains(ConnectivityResult.none) ||
        results.isEmpty) {
      return YohPalNetworkClass.offline;
    }

    if (results.contains(ConnectivityResult.wifi)) {
      final m = await _probe.measure();
      if (m.downloadMbps <= 0 || m.failureRate >= 1.0) {
        return YohPalNetworkClass.offline;
      }
      return m.downloadMbps >= 10.0
          ? YohPalNetworkClass.wifiStrong
          : YohPalNetworkClass.wifiWeak;
    }

    if (!results.contains(ConnectivityResult.mobile)) {
      return YohPalNetworkClass.constrained;
    }

    final m = await _probe.measure();
    return _classifyMobile(m);
  }

  static YohPalNetworkClass _classifyMobile(NetworkMeasurement m) {
    if (m.downloadMbps <= 0) return YohPalNetworkClass.offline;
    if (m.downloadMbps < 0.6 ||
        m.latencyMs > 900 ||
        m.failureRate > 0.20) {
      return YohPalNetworkClass.constrained;
    }
    if (m.downloadMbps < 2 || m.latencyMs > 500) return YohPalNetworkClass.threeG;
    if (m.downloadMbps < 12 || m.latencyMs > 160) return YohPalNetworkClass.fourG;
    return YohPalNetworkClass.fiveG;
  }
}
