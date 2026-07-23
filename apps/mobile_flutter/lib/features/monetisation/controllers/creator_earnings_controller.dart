import 'package:flutter/foundation.dart';
import '../repositories/creator_earnings_repository.dart';

class CreatorEarningsController extends ChangeNotifier {
  final CreatorEarningsRepository repository;

  CreatorEarningsController({required this.repository});
}
