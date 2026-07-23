import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/web_handoff/yohpal_web_handoff.dart';
import '../../../design_system/tokens/yohpal_brand_colors.dart';
import '../models/live_product_model.dart';
import '../repositories/live_commerce_repository.dart';

class LiveProductCard extends StatelessWidget {
  final LiveProductModel product;
  final LiveCommerceRepository repository;

  const LiveProductCard({
    super.key,
    required this.product,
    required this.repository,
  });

  Future<void> payNow(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final intentId = await repository.createPurchaseIntent(
      sessionId: product.sessionId,
      productId: product.id,
      buyerId: user.uid,
      sellerId: product.sellerId,
      amount: product.price,
      currency: product.currency,
    );
    await repository.trackProductClick(
      sessionId: product.sessionId,
      productId: product.id,
      userId: user.uid,
      type: 'pay_now_click',
    );
    if (context.mounted) {
      await context
          .read<YohPalWebHandoff>()
          .openPaymentIntent(intentId: intentId);
    }
  }

  Future<void> openDetails(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await repository.trackProductClick(
        sessionId: product.sessionId,
        productId: product.id,
        userId: user.uid,
        type: 'product_details_click',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openDetails(context),
      child: Card(
        color: const Color(0xEE101527),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (product.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    product.imageUrl,
                    width: 74,
                    height: 74,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shopping_bag, color: Colors.white),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '${product.currency} ${product.price}',
                      style: const TextStyle(
                          color: YohPalBrandColors.gold,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${product.location} · ${product.phone}',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => payNow(context),
                child: const Text('Pay Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
