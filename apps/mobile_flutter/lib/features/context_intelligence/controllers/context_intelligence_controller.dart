import 'package:flutter/material.dart';
import '../models/context_action_model.dart';
import '../models/context_snapshot_model.dart';
import '../repositories/context_analytics_repository.dart';
import '../services/context_action_engine.dart';
import '../services/context_intelligence_engine.dart';

class ContextIntelligenceController extends ChangeNotifier {
  final ContextIntelligenceEngine intelligenceEngine;
  final ContextActionEngine actionEngine;
  final ContextAnalyticsRepository analyticsRepository;

  ContextIntelligenceController({
    required this.intelligenceEngine,
    required this.actionEngine,
    required this.analyticsRepository,
  });

  List<ContextActionModel> actions = [];

  Future<void> updateContext(ContextSnapshotModel snapshot) async {
    try {
      actions = intelligenceEngine.evaluate(snapshot);
      for (final action in actions) {
        await analyticsRepository.record(
          userId: snapshot.userId,
          actionId: action.id,
          eventType: 'impression',
          metadata: {
            'screen': snapshot.currentScreen,
            'videoId': snapshot.videoId,
            'creatorId': snapshot.creatorId,
            'type': action.type,
          },
        );
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> executeAction({
    required BuildContext context,
    required String userId,
    required ContextActionModel action,
  }) async {
    // Capture navigator before any await to avoid cross-async-gap BuildContext use.
    final navigator = Navigator.of(context);
    await analyticsRepository.record(
      userId: userId,
      actionId: action.id,
      eventType: 'acceptance',
      metadata: {
        'type': action.type,
        'route': action.route,
      },
    );
    await actionEngine.executeWithNavigator(navigator, action);
  }

  Future<void> dismissAction({
    required String userId,
    required ContextActionModel action,
  }) async {
    actions = actions.where((item) => item.id != action.id).toList();
    await analyticsRepository.record(
      userId: userId,
      actionId: action.id,
      eventType: 'dismissal',
      metadata: {
        'type': action.type,
      },
    );
    notifyListeners();
  }
}
