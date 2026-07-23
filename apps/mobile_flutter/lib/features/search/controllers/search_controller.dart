import 'package:flutter/foundation.dart';
import '../../auth/session_cleanup_service.dart';
import '../models/search_result_model.dart';
import '../services/search_service.dart';

class YohPalSearchController extends ChangeNotifier
    implements SessionScopedState {
  final SearchService service;

  YohPalSearchController({required this.service});

  bool loading = false;
  String? error;
  String query = '';
  Map<String, List<SearchResultModel>> results = {
    'videos': [],
    'creators': [],
    'live': [],
    'businesses': [],
  };

  /// Drops the previous account's query text and results so the next
  /// account doesn't briefly see what the last account searched for.
  @override
  Future<void> clearSession() async {
    query = '';
    error = null;
    results = {
      'videos': [],
      'creators': [],
      'live': [],
      'businesses': [],
    };
    notifyListeners();
  }

  Future<void> runSearch({
    required String userId,
    required String value,
  }) async {
    query = value.trim();
    if (query.isEmpty) {
      results = {
        'videos': [],
        'creators': [],
        'live': [],
        'businesses': [],
      };
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      results = await service.searchAll(query);
      await service.saveRecentSearch(userId: userId, query: query);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
