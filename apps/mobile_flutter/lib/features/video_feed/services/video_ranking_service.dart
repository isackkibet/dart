import '../models/video_model.dart';

class VideoRankingService {
  List<VideoModel> rank(List<VideoModel> videos, {Set<String> interests = const {}}) {
    final copy = [...videos];
    copy.sort((a, b) => _score(b, interests).compareTo(_score(a, interests)));
    return copy;
  }

  double _score(VideoModel v, Set<String> interests) {
    final interestMatch = v.tags.where(interests.contains).length * 20;
    return v.views * 0.01 + v.likes * 0.25 + interestMatch;
  }
}
