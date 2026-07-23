import 'yohpal_module_migration_adapter.dart';

class YohPalEcosystemMigrationRegistry {
  final List<YohPalModuleMigrationAdapter> modules;

  YohPalEcosystemMigrationRegistry(this.modules);

  List<String> get migratedModules =>
      modules.map((m) => m.moduleName).toList();

  bool get allRequiredModulesRegistered {
    const required = {'hustle', 'jobs', 'market', 'wallet', 'brain', 'ycios'};
    return required.every(migratedModules.contains);
  }
}
