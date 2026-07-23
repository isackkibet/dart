import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/features/creator_profile/repositories/creator_profile_repository.dart';

void main() {
  group('CreatorProfileRepository', () {
    test('can be instantiated', () {
      final repository = CreatorProfileRepository();
      expect(repository, isNotNull);
    });
  });
}
