import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../data/search_repository.dart';
import '../domain/search_result.dart';

class SearchController extends ChangeNotifier {
  SearchController({required SearchRepository repository})
      : _repository = repository;

  final SearchRepository _repository;

  String _query = '';
  String get query => _query;

  String _activeTab = 'videos'; // 'videos' | 'creators'
  String get activeTab => _activeTab;

  List<VideoSearchResult> _videoResults = const [];
  List<VideoSearchResult> get videoResults => _videoResults;

  List<CreatorSearchResult> _creatorResults = const [];
  List<CreatorSearchResult> get creatorResults => _creatorResults;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  AppFailure? _failure;
  AppFailure? get failure => _failure;

  Timer? _debounceTimer;

  void setActiveTab(String tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();
  }

  void onQueryChanged(String newQuery) {
    _query = newQuery;
    _debounceTimer?.cancel();

    if (newQuery.trim().length < 2) {
      clear();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      search(newQuery);
    });
  }

  Future<void> search(String queryText) async {
    _query = queryText;
    final trimmed = queryText.trim();
    if (trimmed.length < 2) {
      clear();
      return;
    }

    _isSearching = true;
    _failure = null;
    notifyListeners();

    final result = await _repository.searchAll(trimmed);

    _isSearching = false;
    if (result is Success<SearchAllResult>) {
      _videoResults = result.data.videos;
      _creatorResults = result.data.creators;
    } else if (result is Failure<SearchAllResult>) {
      _failure = result.failure;
    }

    notifyListeners();
  }

  void clear() {
    _debounceTimer?.cancel();
    _query = '';
    _videoResults = const [];
    _creatorResults = const [];
    _isSearching = false;
    _failure = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
