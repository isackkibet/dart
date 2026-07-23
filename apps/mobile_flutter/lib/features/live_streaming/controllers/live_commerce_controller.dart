import 'package:flutter/foundation.dart';
import '../repositories/live_commerce_repository.dart';

class LiveCommerceController extends ChangeNotifier {
  final LiveCommerceRepository repository;

  LiveCommerceController({required this.repository});

  bool loading = false;
  String? error;

  Future<void> addProduct({
    required String sessionId,
    required String sellerId,
    required String name,
    required String description,
    required num price,
    required String currency,
    required String imageUrl,
    required String phone,
    required String location,
    required int quantity,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await repository.addProduct(
        sessionId: sessionId,
        sellerId: sellerId,
        name: name,
        description: description,
        price: price,
        currency: currency,
        imageUrl: imageUrl,
        phone: phone,
        location: location,
        quantity: quantity,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> pinProduct({
    required String sessionId,
    required String productId,
  }) async {
    await repository.pinProduct(
      sessionId: sessionId,
      productId: productId,
    );
  }

  Future<void> unpinProduct({
    required String sessionId,
    required String productId,
  }) async {
    await repository.unpinProduct(
      sessionId: sessionId,
      productId: productId,
    );
  }
}
