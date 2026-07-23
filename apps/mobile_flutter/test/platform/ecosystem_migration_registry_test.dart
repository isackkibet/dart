import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/platform/migration/yohpal_ecosystem_migration_registry.dart';
import 'package:yohpal_live_v2/platform/migration/yohpal_module_migration_adapter.dart';
import 'package:yohpal_live_v2/platform/platform_provider.dart';

class _FakeAdapter implements YohPalModuleMigrationAdapter {
  @override
  final String moduleName;
  _FakeAdapter(this.moduleName);

  @override
  Future<void> validateSharedIdentity(YohPalPlatformProvider p) async {}
  @override
  Future<void> validateSharedWallet(YohPalPlatformProvider p) async {}
  @override
  Future<void> validateSharedBrain(YohPalPlatformProvider p) async {}
  @override
  Future<void> validateSharedAnalytics(YohPalPlatformProvider p) async {}
  @override
  Future<void> validateSharedDeepLinks(YohPalPlatformProvider p) async {}
}

void main() {
  group('YohPalEcosystemMigrationRegistry', () {
    test('allRequiredModulesRegistered is true when all 6 modules present', () {
      final registry = YohPalEcosystemMigrationRegistry([
        _FakeAdapter('hustle'),
        _FakeAdapter('jobs'),
        _FakeAdapter('market'),
        _FakeAdapter('wallet'),
        _FakeAdapter('brain'),
        _FakeAdapter('ycios'),
      ]);
      expect(registry.allRequiredModulesRegistered, true);
    });

    test('allRequiredModulesRegistered is false when a module is missing', () {
      final registry = YohPalEcosystemMigrationRegistry([
        _FakeAdapter('hustle'),
        _FakeAdapter('jobs'),
        _FakeAdapter('market'),
        _FakeAdapter('wallet'),
        _FakeAdapter('brain'),
        // ycios missing
      ]);
      expect(registry.allRequiredModulesRegistered, false);
    });

    test('migratedModules returns correct list of names', () {
      final registry = YohPalEcosystemMigrationRegistry([
        _FakeAdapter('hustle'),
        _FakeAdapter('ycios'),
      ]);
      expect(registry.migratedModules, containsAll(['hustle', 'ycios']));
      expect(registry.migratedModules.length, 2);
    });

    test('empty registry is not fully registered', () {
      final registry = YohPalEcosystemMigrationRegistry([]);
      expect(registry.allRequiredModulesRegistered, false);
    });

    test('extra modules beyond the required set still pass', () {
      final registry = YohPalEcosystemMigrationRegistry([
        _FakeAdapter('hustle'),
        _FakeAdapter('jobs'),
        _FakeAdapter('market'),
        _FakeAdapter('wallet'),
        _FakeAdapter('brain'),
        _FakeAdapter('ycios'),
        _FakeAdapter('live'), // extra — allowed
      ]);
      expect(registry.allRequiredModulesRegistered, true);
      expect(registry.migratedModules.length, 7);
    });
  });
}
