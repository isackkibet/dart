/// A controller that holds state scoped to the signed-in account and must
/// be reset before a different account can safely reuse the same widget
/// tree — this app's providers are created once at startup, not per login,
/// so without this a second account on the same device would keep seeing
/// the first account's cached feed, search results, and notification
/// binding after logout.
abstract interface class SessionScopedState {
  Future<void> clearSession();
}

final class YohPalSessionCleanupService {
  const YohPalSessionCleanupService({required this.stores});

  final List<SessionScopedState> stores;

  Future<void> clearAll() async {
    final failures = <Object>[];
    for (final store in stores) {
      try {
        await store.clearSession();
      } catch (error) {
        failures.add(error);
      }
    }
    if (failures.isNotEmpty) {
      throw StateError('Failed to clear ${failures.length} session store(s).');
    }
  }
}
