import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../../../core/network/api_client.dart';
import '../domain/auto_response_rule.dart';
import '../domain/command_center_incident.dart';
import '../domain/safe_mode_toggle.dart';
import '../domain/system_health.dart';

class CommandCenterRepository {
  CommandCenterRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Result<SystemHealth>> getSystemHealth() async {
    final result = await _apiClient.getJson('/command-center/health');
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    final data = result.dataOrNull?['data'];
    if (data is! Map<String, dynamic>) {
      return const Failure(
        AppFailure(
          message: 'Invalid command center health response.',
          code: 'invalid_command_center_health',
        ),
      );
    }
    return Success(SystemHealth.fromMap(data));
  }

  Future<Result<List<CommandCenterIncident>>> getIncidents() async {
    final result = await _apiClient.getJson('/command-center/incidents');
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    final data = result.dataOrNull?['data'];
    final items = data is Map<String, dynamic> ? data['incidents'] : null;
    if (items is! List) return const Success([]);
    return Success(
      items
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => CommandCenterIncident.fromMap(
              item['id']?.toString() ?? '',
              item,
            ),
          )
          .toList(),
    );
  }

  Future<Result<List<SafeModeToggle>>> getSafeModeToggles() async {
    final result = await _apiClient.getJson('/command-center/safe-mode');
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    final data = result.dataOrNull?['data'];
    final items = data is Map<String, dynamic> ? data['toggles'] : null;
    if (items is! List) return const Success([]);
    return Success(
      items
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => SafeModeToggle.fromMap(
              item['id']?.toString() ?? '',
              item,
            ),
          )
          .toList(),
    );
  }

  Future<Result<List<AutoResponseRule>>> getAutoResponseRules() async {
    final result = await _apiClient.getJson('/command-center/auto-response-rules');
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    final data = result.dataOrNull?['data'];
    final items = data is Map<String, dynamic> ? data['rules'] : null;
    if (items is! List) return const Success([]);
    return Success(
      items
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => AutoResponseRule.fromMap(
              item['id']?.toString() ?? '',
              item,
            ),
          )
          .toList(),
    );
  }

  Future<Result<void>> updateIncidentStatus({
    required String incidentId,
    required String status,
  }) async {
    final result = await _apiClient.patchJson(
      '/command-center/incidents/$incidentId',
      body: {'status': status},
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    return const Success(null);
  }

  Future<Result<void>> setSafeMode({
    required String key,
    required bool enabled,
    required String reason,
  }) async {
    final result = await _apiClient.postJson(
      '/command-center/safe-mode/$key',
      body: {
        'enabled': enabled,
        'reason': reason,
      },
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    return const Success(null);
  }

  Future<Result<void>> createIncident({
    required String title,
    required String description,
    required String severity,
    required String affectedService,
  }) async {
    final result = await _apiClient.postJson(
      '/command-center/incidents',
      body: {
        'title': title,
        'description': description,
        'severity': severity,
        'affectedService': affectedService,
      },
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    return const Success(null);
  }
}
