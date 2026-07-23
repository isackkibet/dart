import 'yohpal_video_engine.dart';

class YohPalPlayerPool {
  final int maxPlayers;
  final List<YohPalVideoEngine> _pool = [];

  YohPalPlayerPool({this.maxPlayers = 3});

  YohPalVideoEngine acquire() {
    if (_pool.length < maxPlayers) {
      final engine = YohPalVideoEngine();
      _pool.add(engine);
      return engine;
    }
    return _pool.first;
  }

  YohPalVideoEngine? getByIndex(int index) {
    if (index < 0 || index >= _pool.length) return null;
    return _pool[index];
  }

  Future<void> pauseAllExcept(YohPalVideoEngine active) async {
    for (final engine in _pool) {
      if (engine != active) await engine.pause();
    }
  }

  Future<void> disposeAll() async {
    for (final engine in _pool) {
      await engine.dispose();
    }
    _pool.clear();
  }
}
