import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live/platform/migration/yohpal_ecosystem_migration_registry.dart';
import 'package:yohpal_live/platform/migration/yohpal_module_migration_adapter.dart';

class FakeAdapter implements YohPalModuleMigrationAdapter {
  @override
  final String moduleName;
  FakeAdapter(this.moduleName);
  @override
  Future<void> validateSharedIdentity(platform) async {}
  @override
  Future<void> validateSharedWallet(platform) async {}
  @override
  Future<void> validateSharedBrain(platform) async {}
  @override
  Future<void> validateSharedAnalytics(platform) async {}
  @override
  Future<void> validateSharedDeepLinks(platform) async {}
}

void main() {
  test('all required ecosystem modules are registered', () {
    final registry = YohPalEcosystemMigrationRegistry([
      FakeAdapter('hustle'),
      FakeAdapter('jobs'),
      FakeAdapter('market'),
      FakeAdapter('wallet'),
      FakeAdapter('brain'),
      FakeAdapter('ycios'),
    ]);
    expect(registry.allRequiredModulesRegistered, true);
  });
}
