import '../../../core/models/result.dart';
import '../../../core/network/api_client.dart';
import '../domain/search_result.dart';

class SearchRepository {
  SearchRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Result<List<VideoSearchResult>>> searchVideos(
    String query, {
    int limit = 20,
  }) async {
    final result = await _apiClient.getJson(
      '/search?q=${Uri.encodeComponent(query)}&type=videos&limit=$limit',
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }

    final data = result.dataOrNull?['data'] as Map<String, dynamic>?;
    final videoList = data?['videos'] as List?;
    if (videoList == null) {
      return const Success([]);
    }

    final videos = videoList
        .whereType<Map<String, dynamic>>()
        .map(VideoSearchResult.fromMap)
        .toList();

    return Success(videos);
  }

  Future<Result<List<CreatorSearchResult>>> searchCreators(
    String query, {
    int limit = 20,
  }) async {
    final result = await _apiClient.getJson(
      '/search?q=${Uri.encodeComponent(query)}&type=creators&limit=$limit',
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }

    final data = result.dataOrNull?['data'] as Map<String, dynamic>?;
    final creatorList = data?['creators'] as List?;
    if (creatorList == null) {
      return const Success([]);
    }

    final creators = creatorList
        .whereType<Map<String, dynamic>>()
        .map(CreatorSearchResult.fromMap)
        .toList();

    return Success(creators);
  }

  Future<Result<SearchAllResult>> searchAll(
    String query, {
    int limit = 20,
  }) async {
    final result = await _apiClient.getJson(
      '/search?q=${Uri.encodeComponent(query)}&type=all&limit=$limit',
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }

    final data = result.dataOrNull?['data'] as Map<String, dynamic>?;
    final videoList = data?['videos'] as List? ?? [];
    final creatorList = data?['creators'] as List? ?? [];

    final videos = videoList
        .whereType<Map<String, dynamic>>()
        .map(VideoSearchResult.fromMap)
        .toList();

    final creators = creatorList
        .whereType<Map<String, dynamic>>()
        .map(CreatorSearchResult.fromMap)
        .toList();

    return Success(SearchAllResult(videos: videos, creators: creators));
  }
}

class SearchAllResult {
  const SearchAllResult({
    required this.videos,
    required this.creators,
  });

  final List<VideoSearchResult> videos;
  final List<CreatorSearchResult> creators;
}
