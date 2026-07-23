import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkClass { wifi, fiveG, fourG, threeG, constrained, offline, unknown }

/// Combines connectivity type with a lightweight RTT probe on mobile connections
/// to distinguish 3G / 4G / 5G, as required by the 1.0H zero-wait spec.
///
/// RTT thresholds (latency-only proxy for throughput classification):
///   < 90 ms   → 5G / high-throughput
///   90–300 ms → 4G
///   300–800 ms → 3G
///   > 800 ms or probe timeout → constrained
///
/// WiFi is detected by connectivity type alone (not probed).
class SmartNetworkProfiler {
  SmartNetworkProfiler({
    Connectivity? connectivity,
    String probeHost = 'connectivitycheck.gstatic.com',
    int probePort = 80,
  })  : _connectivity = connectivity ?? Connectivity(),
        _probeHost = probeHost,
        _probePort = probePort;

  final Connectivity _connectivity;
  final String _probeHost;
  final int _probePort;

  NetworkClass current = NetworkClass.unknown;

  Future<NetworkClass> currentClass() async {
    final results = await _connectivity.checkConnectivity();
    current = await _classify(results);
    return current;
  }

  Stream<NetworkClass> watchClass() {
    return _connectivity.onConnectivityChanged.asyncMap((results) async {
      current = await _classify(results);
      return current;
    });
  }

  int preloadAheadFor(NetworkClass network) {
    return switch (network) {
      NetworkClass.wifi || NetworkClass.fiveG => 7,
      NetworkClass.fourG => 5,
      NetworkClass.threeG => 3,
      NetworkClass.constrained => 1,
      _ => 1,
    };
  }

  bool shouldFetch(NetworkClass network) => network != NetworkClass.offline;

  Future<NetworkClass> _classify(List<ConnectivityResult> results) async {
    if (results.contains(ConnectivityResult.wifi)) return NetworkClass.wifi;
    if (results.contains(ConnectivityResult.none)) return NetworkClass.offline;
    if (!results.contains(ConnectivityResult.mobile)) {
      return NetworkClass.unknown;
    }
    // On mobile, probe RTT to classify network generation.
    final rttMs = await _probeRttMs();
    if (rttMs == null) return NetworkClass.constrained;
    if (rttMs < 90) return NetworkClass.fiveG;
    if (rttMs < 300) return NetworkClass.fourG;
    if (rttMs < 800) return NetworkClass.threeG;
    return NetworkClass.constrained;
  }

  /// Opens a TCP socket to [_probeHost]:[_probePort] and measures round-trip time.
  /// Returns null if the probe fails or times out.
  Future<int?> _probeRttMs() async {
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        _probeHost,
        _probePort,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      return null;
    }
  }
}
