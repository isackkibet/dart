import 'package:flutter/foundation.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../data/command_center_repository.dart';
import '../domain/auto_response_rule.dart';
import '../domain/command_center_incident.dart';
import '../domain/safe_mode_toggle.dart';
import '../domain/system_health.dart';

class CommandCenterController extends ChangeNotifier {
  CommandCenterController({
    required CommandCenterRepository repository,
  }) : _repository = repository;

  final CommandCenterRepository _repository;
  SystemHealth? _health;
  List<CommandCenterIncident> _incidents = const [];
  List<SafeModeToggle> _safeModeToggles = const [];
  List<AutoResponseRule> _rules = const [];
  bool _isLoading = false;
  AppFailure? _failure;

  SystemHealth? get health => _health;
  List<CommandCenterIncident> get incidents => _incidents;
  List<SafeModeToggle> get safeModeToggles => _safeModeToggles;
  List<AutoResponseRule> get rules => _rules;
  bool get isLoading => _isLoading;
  AppFailure? get failure => _failure;

  Future<void> load() async {
    _isLoading = true;
    _failure = null;
    notifyListeners();
    final healthResult = await _repository.getSystemHealth();
    final incidentResult = await _repository.getIncidents();
    final safeModeResult = await _repository.getSafeModeToggles();
    final ruleResult = await _repository.getAutoResponseRules();
    if (healthResult is Success<SystemHealth>) {
      _health = healthResult.data;
    } else if (healthResult is Failure<SystemHealth>) {
      _failure = healthResult.failure;
    }
    if (incidentResult is Success<List<CommandCenterIncident>>) {
      _incidents = incidentResult.data;
    } else if (incidentResult is Failure<List<CommandCenterIncident>>) {
      _failure = incidentResult.failure;
    }
    if (safeModeResult is Success<List<SafeModeToggle>>) {
      _safeModeToggles = safeModeResult.data;
    }
    if (ruleResult is Success<List<AutoResponseRule>>) {
      _rules = ruleResult.data;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> resolveIncident(String incidentId) async {
    await _repository.updateIncidentStatus(
      incidentId: incidentId,
      status: 'resolved',
    );
    await load();
  }

  Future<void> setSafeMode({
    required String key,
    required bool enabled,
    required String reason,
  }) async {
    await _repository.setSafeMode(
      key: key,
      enabled: enabled,
      reason: reason,
    );
    await load();
  }
}
