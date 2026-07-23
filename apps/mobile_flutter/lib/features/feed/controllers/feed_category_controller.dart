import 'package:flutter/foundation.dart';
import '../domain/feed_category.dart';

final class FeedCategoryController extends ChangeNotifier {
  FeedCategoryController({
    FeedCategory initial = FeedCategory.recommended,
  }) : _selected = initial;

  FeedCategory _selected;

  FeedCategory get selected => _selected;

  void select(FeedCategory category) {
    if (_selected == category) {
      return;
    }
    _selected = category;
    notifyListeners();
  }
}
