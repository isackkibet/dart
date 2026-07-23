import '../models/search_result_model.dart';
import '../repositories/search_repository.dart';

class SearchService {
  final SearchRepository repository;

  SearchService({required this.repository});

  Future<Map<String, List<SearchResultModel>>> searchAll(String query) async {
    final results = await Future.wait([
      repository.searchVideos(query),
      repository.searchCreators(query),
      repository.searchLive(query),
      repository.searchBusinesses(query),
    ]);
    return {
      'videos': results[0],
      'creators': results[1],
      'live': results[2],
      'businesses': results[3],
    };
  }

  Future<void> saveRecentSearch({
    required String userId,
    required String query,
  }) {
    return repository.saveRecentSearch(userId: userId, query: query);
  }
}
