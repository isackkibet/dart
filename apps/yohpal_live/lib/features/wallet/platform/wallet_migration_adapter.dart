import '../../../platform/migration/yohpal_module_migration_adapter.dart';
import '../../../platform/platform_provider.dart';

class WalletMigrationAdapter implements YohPalModuleMigrationAdapter {
  @override
  String get moduleName => 'wallet';
  @override
  Future<void> validateSharedIdentity(YohPalPlatformProvider platform) async {
    await platform.identity.getCurrentIdentity();
  }
  @override
  Future<void> validateSharedWallet(YohPalPlatformProvider platform) async {
    final identity = await platform.identity.getCurrentIdentity();
    if (identity != null) {
      await platform.wallet.getBalance(identity.uid);
    }
  }
  @override
  Future<void> validateSharedBrain(YohPalPlatformProvider platform) async {
    await platform.brain.execute(
      agent: 'wallet',
      task: 'health_check',
      input: {'source': 'phase16'},
      module: moduleName,
    );
  }
  @override
  Future<void> validateSharedAnalytics(YohPalPlatformProvider platform) async {
    await platform.analytics.track(
      event: 'module_migration_validated',
      module: moduleName,
    );
  }
  @override
  Future<void> validateSharedDeepLinks(YohPalPlatformProvider platform) async {
    final link = platform.deepLinks.build(
      module: 'wallet',
      entity: 'transaction',
      id: 'test',
    );
    final parsed = platform.deepLinks.parse(link);
    if (parsed?.module != 'wallet') {
      throw StateError('Wallet deep link validation failed.');
    }
  }
}
