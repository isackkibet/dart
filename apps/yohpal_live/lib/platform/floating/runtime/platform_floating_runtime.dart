import '../context/floating_context.dart';
import '../runtime/floating_runtime.dart';
import '../../../features/pip/yohpal_ios_pip_service.dart';

class PlatformFloatingRuntime implements FloatingRuntime {
  final YohPalIosPipService _iosPipService = YohPalIosPipService();
  @override
  Future<bool> isSupported() async {
    return await _iosPipService.isSupported();
  }
  @override
  Future<bool> start(FloatingContext context) async {
    if (context.mediaUrl == null) return false;
    final prepared = await _iosPipService.prepare(
      videoUrl: context.mediaUrl!,
      isLive: context.isLive,
    );
    if (!prepared) return false;
    return await _iosPipService.start();
  }
  @override
  Future<void> stop() async {
    await _iosPipService.stop();
  }
  @override
  Future<void> restore() async {
    await _iosPipService.stop();
  }
}
