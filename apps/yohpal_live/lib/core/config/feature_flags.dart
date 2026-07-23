import 'app_environment.dart';

class FeatureFlags {
  const FeatureFlags({
    required this.multistreaming,
    required this.trafficFunnel,
    required this.autonomy,
    required this.creatorGrowth,
    required this.commandCenter,
    required this.revenueEngine,
    required this.enableAIStudio,
    required this.enableCreatorMarketplace,
    required this.enableWalletRewards,
    required this.enableExperimentalFeedRanking,
    required this.enableLiveCommerce,
    required this.enableContextActions,
    required this.enablePredictiveExperience,
  });

  final bool multistreaming;
  final bool trafficFunnel;
  final bool autonomy;
  final bool creatorGrowth;
  final bool commandCenter;
  final bool revenueEngine;
  final bool enableAIStudio;
  final bool enableCreatorMarketplace;
  final bool enableWalletRewards;
  final bool enableExperimentalFeedRanking;
  final bool enableLiveCommerce;
  final bool enableContextActions;
  final bool enablePredictiveExperience;

  factory FeatureFlags.fromEnvironment(AppEnvironmentConfig config) {
    return FeatureFlags(
      multistreaming: config.enableMultistreaming,
      trafficFunnel: config.enableMultistreaming,
      autonomy: config.enableAutonomy,
      creatorGrowth: config.enableAutonomy,
      commandCenter: config.enableCommandCenter,
      revenueEngine: config.enableRevenueEngine,
      enableAIStudio: const bool.fromEnvironment(
        'enableAIStudio',
        defaultValue: false,
      ),
      enableCreatorMarketplace: const bool.fromEnvironment(
        'enableCreatorMarketplace',
        defaultValue: false,
      ),
      enableWalletRewards: const bool.fromEnvironment(
        'enableWalletRewards',
        defaultValue: false,
      ),
      enableExperimentalFeedRanking: const bool.fromEnvironment(
        'enableExperimentalFeedRanking',
        defaultValue: false,
      ),
      enableLiveCommerce: const bool.fromEnvironment(
        'enableLiveCommerce',
        defaultValue: false,
      ),
      enableContextActions: const bool.fromEnvironment(
        'enableContextActions',
        defaultValue: false,
      ),
      enablePredictiveExperience: const bool.fromEnvironment(
        'enablePredictiveExperience',
        defaultValue: false,
      ),
    );
  }
}
