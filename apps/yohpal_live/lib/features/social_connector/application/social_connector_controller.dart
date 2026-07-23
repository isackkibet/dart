import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../data/social_connector_repository.dart';
import '../domain/connector_health.dart';
import '../domain/social_connector.dart';

class SocialConnectorController extends ChangeNotifier {
  SocialConnectorController({
    required SocialConnectorRepository repository,
    required String creatorId,
  })  : _repository = repository,
        _creatorId = creatorId;

  final SocialConnectorRepository _repository;
  final String _creatorId;

  StreamSubscription<List<SocialConnector>>? _subscription;
  List<SocialConnector> _connectors = const [];
  final Map<String, ConnectorHealth> _healthResults = {};
  final Set<String> _loadingHealthIds = {};
  final Set<String> _loadingDisconnectIds = {};
  AppFailure? _failure;
  bool _isLoadingOAuth = false;

  List<SocialConnector> get connectors => _connectors;
  Map<String, ConnectorHealth> get healthResults => _healthResults;
  AppFailure? get failure => _failure;
  bool get isLoadingOAuth => _isLoadingOAuth;

  bool isCheckingHealth(String connectorId) =>
      _loadingHealthIds.contains(connectorId);

  bool isDisconnecting(String connectorId) =>
      _loadingDisconnectIds.contains(connectorId);

  void startWatching() {
    _subscription?.cancel();
    _subscription = _repository.watchConnectors(_creatorId).listen(
      (connectors) {
        _connectors = connectors;
        _failure = null;
        notifyListeners();
      },
      onError: (Object error) {
        _failure = AppFailure(
          message: error.toString(),
          code: 'connector_stream_error',
        );
        notifyListeners();
      },
    );
  }

  Future<String?> getOAuthUrl(String platform) async {
    _isLoadingOAuth = true;
    _failure = null;
    notifyListeners();
    final result = await _repository.getOAuthUrl(platform);
    _isLoadingOAuth = false;
    if (result is Failure<String>) {
      _failure = result.failure;
      notifyListeners();
      return null;
    }
    notifyListeners();
    return result.dataOrNull;
  }

  Future<ConnectorHealth?> checkHealth(String connectorId) async {
    _loadingHealthIds.add(connectorId);
    _failure = null;
    notifyListeners();
    final result = await _repository.checkHealth(connectorId);
    _loadingHealthIds.remove(connectorId);
    if (result is Success<ConnectorHealth>) {
      _healthResults[connectorId] = result.data;
      notifyListeners();
      return result.data;
    } else if (result is Failure<ConnectorHealth>) {
      _failure = result.failure;
      notifyListeners();
    }
    return null;
  }

  Future<bool> disconnect(String connectorId) async {
    _loadingDisconnectIds.add(connectorId);
    _failure = null;
    notifyListeners();
    final result = await _repository.disconnectConnector(connectorId);
    _loadingDisconnectIds.remove(connectorId);
    if (result is Failure<void>) {
      _failure = result.failure;
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
