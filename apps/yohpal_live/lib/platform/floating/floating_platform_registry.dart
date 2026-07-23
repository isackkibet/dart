import 'floating_platform.dart';
import 'adapters/live_floating_adapter.dart';
import 'adapters/jobs_floating_adapter.dart';
import 'adapters/market_floating_adapter.dart';
import 'runtime/platform_floating_runtime.dart';

final platformFloatingRuntime = PlatformFloatingRuntime();

final floatingPlatform = FloatingPlatform(
  runtime: platformFloatingRuntime,
);

void registerFloatingAdapters() {
  floatingPlatform.register(LiveFloatingAdapter());
  floatingPlatform.register(JobsFloatingAdapter());
  floatingPlatform.register(MarketFloatingAdapter());
}
