import 'package:flutter/material.dart';
import '../zero_wait/cache/warm_media_scheduler.dart';
import '../zero_wait/cache/yohpal_video_cache.dart';
import '../zero_wait/controllers/feed_inventory_coordinator.dart';
import '../zero_wait/controllers/zero_wait_playback_controller.dart'
    as zw_feed;
import '../zero_wait/data/zero_wait_feed_repository.dart';
import '../zero_wait/lifecycle/zero_wait_lifecycle_observer.dart';
import '../zero_wait/models/preload_video.dart';
import '../zero_wait/policy/zero_wait_buffer_policy.dart';
import '../zero_wait/profiling/device_capability_profiler.dart';
import '../zero_wait/profiling/smart_network_profiler.dart';
import '../zero_wait/storage/feed_inventory_store.dart';
import '../zero_wait/telemetry/zero_wait_telemetry.dart';

/// In-memory store used by the debug harness — avoids Hive init complexity.
final class _DebugStore implements FeedInventoryStore {
  List<PreloadVideo> _data = [];
  @override Future<void> initialize() async {}
  @override Future<List<PreloadVideo>> readAll() async => List.of(_data);
  @override Future<void> replaceAll(List<PreloadVideo> v) async => _data = List.of(v);
  @override Future<int> count() async => _data.length;
  @override Future<void> clear() async => _data = [];
}

/// Temporary on-device harness for the Zero-Wait 1.0H buffer-recovery spec.
///
/// Navigate to this screen to exercise the full real-Firestore stack and
/// measure inventory build time, policy resolution, and controller readiness.
/// This screen must NOT ship in a release build — guarded at the route level.
class ZeroWaitDebugScreen extends StatefulWidget {
  const ZeroWaitDebugScreen({super.key});

  @override
  State<ZeroWaitDebugScreen> createState() => _ZeroWaitDebugScreenState();
}

class _ZeroWaitDebugScreenState extends State<ZeroWaitDebugScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  _Phase _phase = _Phase.idle;
  String _status = 'Tap RUN to start the Zero-Wait warmup.';
  YohPalNetworkClass? _networkClass;
  YohPalDeviceClass? _deviceClass;
  BufferPolicy? _policy;
  List<PreloadVideo> _inventory = [];
  int _controllerCount = 0;
  final List<_PhaseResult> _results = [];
  Object? _error;

  // ── Owned objects (disposed on screen close) ────────────────────────────
  zw_feed.ZeroWaitPlaybackController? _playbackCtrl;
  ZeroWaitLifecycleObserver? _lifecycleObserver;

  // ── Timing ────────────────────────────────────────────────────────────────
  DateTime? _runStart;

  int get _elapsedMs =>
      _runStart == null
          ? 0
          : DateTime.now().difference(_runStart!).inMilliseconds;

  @override
  void dispose() {
    _lifecycleObserver?.unregister();
    _playbackCtrl?.dispose();
    super.dispose();
  }

  // ── Core test ─────────────────────────────────────────────────────────────

  Future<void> _run() async {
    if (_phase == _Phase.running) return;
    setState(() {
      _phase = _Phase.running;
      _results.clear();
      _error = null;
      _inventory = [];
      _controllerCount = 0;
      _runStart = DateTime.now();
      _status = 'Starting…';
    });

    try {
      // Phase 1 — classify
      _setStatus('Phase 1/5 — classifying network & device…');
      final t0 = DateTime.now();
      final profiler = SmartNetworkProfiler(
        probe: HttpNetworkProbe(
          probeUrl: Uri.parse(
              'https://connectivitycheck.gstatic.com/generate_204'),
        ),
      );
      final deviceProfiler = const DefaultDeviceCapabilityProfiler();
      final results = await Future.wait([
        profiler.currentClass(),
        deviceProfiler.classify(),
      ]);
      final network = results[0] as YohPalNetworkClass;
      final device = results[1] as YohPalDeviceClass;
      final policy = ZeroWaitBufferPolicy.resolve(network: network, device: device);
      final classifyMs = DateTime.now().difference(t0).inMilliseconds;

      setState(() {
        _networkClass = network;
        _deviceClass = device;
        _policy = policy;
      });
      _addResult('Classify', classifyMs,
          'network=${network.name} device=${device.name}');
      _addResult(
          'Policy',
          0,
          'hot=${policy.hotControllerCount} '
          'warm=${policy.warmMediaCount} '
          'target=${policy.targetInventory}');

      // Phase 2 — load cached inventory (in-memory for debug harness)
      _setStatus('Phase 2/5 — loading persisted inventory…');
      final t1 = DateTime.now();
      final repo = FirestoreZeroWaitFeedRepository();
      final store = _DebugStore();
      final coordinator = FeedInventoryCoordinator(store: store, repository: repo);
      // Attempt to load any cached records (store is empty for debug runs).
      final cachedCount = await store.count();
      _addResult('Cache load', DateTime.now().difference(t1).inMilliseconds,
          '$cachedCount videos from store');

      // Phase 3 — fetch from Firestore to reach 100
      _setStatus('Phase 3/5 — fetching 100-video inventory from Firestore…');
      final t2 = DateTime.now();
      await coordinator.ensureRunway(
        currentIndex: 0,
        minimumAhead: 100,
        targetInventory: 100,
      );
      final fetchMs = DateTime.now().difference(t2).inMilliseconds;
      setState(() => _inventory = coordinator.inventory);
      _addResult(
          'Firestore fetch', fetchMs, '${coordinator.length} videos ready');

      // Phase 4 — warm first hot-tier controllers
      _setStatus('Phase 4/5 — warming hot-tier controllers…');
      final t3 = DateTime.now();
      final cache = YohPalVideoCache();
      final scheduler = WarmMediaScheduler(cache: cache);
      final telemetry = FirebaseZeroWaitTelemetry();
      final playback = zw_feed.ZeroWaitPlaybackController(
        cache: cache,
        scheduler: scheduler,
        telemetry: telemetry,
      );
      _playbackCtrl = playback;
      final observer = ZeroWaitLifecycleObserver(controller: playback);
      _lifecycleObserver = observer;
      observer.register();

      playback.configure(policy);
      await playback.setInventory(coordinator.inventory);

      // Poll controller count for up to 8 seconds.
      for (int i = 0; i < 16; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        final ready =
            coordinator.inventory.where((v) => playback.isReady(v.id)).length;
        setState(() => _controllerCount = ready);
        if (ready >= 1) break;
      }
      final ctrlMs = DateTime.now().difference(t3).inMilliseconds;
      _addResult('Hot-tier warm', ctrlMs,
          '$_controllerCount controllers initialized');

      // Phase 5 — runway verification
      _setStatus('Phase 5/5 — verifying 100-video runway…');
      final runway = coordinator.length;
      final firstVideoReady =
          coordinator.length > 0 && playback.isReady(coordinator[0]!.id);
      _addResult('Runway', 0,
          '$runway videos prepared, firstVideoReady=$firstVideoReady');

      await telemetry.event(ZeroWaitTelemetry.startupComplete, {
        'inventory_size': runway,
        'network_class': network.name,
        'device_class': device.name,
        'total_ms': _elapsedMs,
      });

      setState(() {
        _phase = runway >= 100 ? _Phase.pass : _Phase.fail;
        _status = runway >= 100
            ? '✓ PASS — $runway videos ready in ${_elapsedMs}ms'
            : '✗ FAIL — only $runway/100 videos ready';
      });
    } catch (e, st) {
      debugPrint('ZeroWaitDebug error: $e\n$st');
      setState(() {
        _error = e;
        _phase = _Phase.fail;
        _status = 'ERROR: $e';
      });
    }
  }

  void _setStatus(String s) => setState(() => _status = s);

  void _addResult(String label, int ms, String detail) {
    setState(() => _results.add(_PhaseResult(label, ms, detail)));
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text('Zero-Wait 1.0H Debug',
            style: TextStyle(color: Colors.white, fontSize: 15)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _phase == _Phase.running ? null : _run,
            child: Text(
              'RUN',
              style: TextStyle(
                color: _phase == _Phase.running
                    ? Colors.white38
                    : const Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard(phase: _phase, status: _status, elapsedMs: _elapsedMs),
          if (_networkClass != null) ...[
            const SizedBox(height: 12),
            _MetricsGrid(
              network: _networkClass!,
              device: _deviceClass!,
              policy: _policy!,
              inventoryCount: _inventory.length,
              controllerCount: _controllerCount,
            ),
          ],
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 12),
            _PhaseTable(results: _results),
          ],
          if (_inventory.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InventoryPreview(inventory: _inventory, playback: _playbackCtrl),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorCard(error: _error!),
          ],
        ],
      ),
    );
  }
}

// ── Phase enum ──────────────────────────────────────────────────────────────

enum _Phase { idle, running, pass, fail }

// ── Data ─────────────────────────────────────────────────────────────────────

class _PhaseResult {
  const _PhaseResult(this.label, this.ms, this.detail);
  final String label;
  final int ms;
  final String detail;
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard(
      {required this.phase, required this.status, required this.elapsedMs});
  final _Phase phase;
  final String status;
  final int elapsedMs;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (phase) {
      _Phase.idle    => (const Color(0xFF1A1A2E), Colors.white70),
      _Phase.running => (const Color(0xFF1A1A2E), const Color(0xFFFFD700)),
      _Phase.pass    => (const Color(0xFF0D2B1A), const Color(0xFF4CAF50)),
      _Phase.fail    => (const Color(0xFF2B0D0D), const Color(0xFFEF5350)),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (phase == _Phase.running)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFFFFD700)),
                )
              else
                Icon(
                  phase == _Phase.pass
                      ? Icons.check_circle
                      : phase == _Phase.fail
                          ? Icons.error
                          : Icons.play_circle_outline,
                  color: fg,
                  size: 18,
                ),
              const SizedBox(width: 8),
              Text('STATUS',
                  style: TextStyle(
                      color: fg,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
              const Spacer(),
              if (phase == _Phase.running)
                Text('${elapsedMs}ms',
                    style:
                        TextStyle(color: fg.withValues(alpha: 0.6), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(status, style: TextStyle(color: fg, fontSize: 13)),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.network,
    required this.device,
    required this.policy,
    required this.inventoryCount,
    required this.controllerCount,
  });
  final YohPalNetworkClass network;
  final YohPalDeviceClass device;
  final BufferPolicy policy;
  final int inventoryCount;
  final int controllerCount;

  @override
  Widget build(BuildContext context) {
    final cells = [
      ('Network', network.name, _netColor(network)),
      ('Device', device.name, Colors.blueAccent),
      ('Hot slots', '${policy.hotControllerCount}', Colors.orange),
      ('Warm slots', '${policy.warmMediaCount}', Colors.purple),
      (
        'Inventory',
        '$inventoryCount / ${policy.targetInventory}',
        inventoryCount >= policy.targetInventory
            ? const Color(0xFF4CAF50)
            : const Color(0xFFFFD700)
      ),
      (
        'Controllers',
        '$controllerCount initialized',
        controllerCount >= 1 ? const Color(0xFF4CAF50) : Colors.orange
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.6,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8),
      itemCount: cells.length,
      itemBuilder: (_, i) {
        final (label, value, color) = cells[i];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF111122),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 10)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }

  Color _netColor(YohPalNetworkClass n) => switch (n) {
        YohPalNetworkClass.wifiStrong  => const Color(0xFF4CAF50),
        YohPalNetworkClass.wifiWeak    => Colors.lightGreen,
        YohPalNetworkClass.fiveG       => const Color(0xFF4CAF50),
        YohPalNetworkClass.fourG       => const Color(0xFFFFD700),
        YohPalNetworkClass.threeG      => Colors.orange,
        YohPalNetworkClass.constrained => Colors.deepOrange,
        YohPalNetworkClass.offline     => Colors.red,
      };
}

class _PhaseTable extends StatelessWidget {
  const _PhaseTable({required this.results});
  final List<_PhaseResult> results;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text('PHASE RESULTS',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold)),
          ),
          ...results.map((r) => _PhaseRow(result: r)),
        ],
      ),
    );
  }
}

class _PhaseRow extends StatelessWidget {
  const _PhaseRow({required this.result});
  final _PhaseResult result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 14),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(result.label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          if (result.ms > 0)
            Text('${result.ms}ms  ',
                style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 11,
                    fontFeatures: [FontFeature.tabularFigures()])),
          Expanded(
            child: Text(result.detail,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _InventoryPreview extends StatelessWidget {
  const _InventoryPreview({required this.inventory, required this.playback});
  final List<PreloadVideo> inventory;
  final zw_feed.ZeroWaitPlaybackController? playback;

  @override
  Widget build(BuildContext context) {
    final preview = inventory.take(10).toList();
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text(
                'INVENTORY PREVIEW (${inventory.length} total, showing first 10)',
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold)),
          ),
          ...preview.map((v) {
            final ready = playback?.isReady(v.id) ?? false;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '#${v.feedIndex}',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ready ? const Color(0xFF4CAF50) : Colors.white24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      v.id,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (ready)
                    const Text('HOT',
                        style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2B0D0D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Text('$error',
          style: const TextStyle(color: Color(0xFFEF5350), fontSize: 11)),
    );
  }
}
