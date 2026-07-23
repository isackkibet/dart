import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/live_commerce_controller.dart';
import '../models/live_product_model.dart';
import '../repositories/live_commerce_repository.dart';

class LiveProductPinningPanel extends StatefulWidget {
  final String sessionId;

  const LiveProductPinningPanel({
    super.key,
    required this.sessionId,
  });

  @override
  State<LiveProductPinningPanel> createState() =>
      _LiveProductPinningPanelState();
}

class _LiveProductPinningPanelState extends State<LiveProductPinningPanel> {
  final name = TextEditingController();
  final description = TextEditingController();
  final price = TextEditingController();
  final imageUrl = TextEditingController();
  final phone = TextEditingController();
  final location = TextEditingController();
  final quantity = TextEditingController(text: '1');

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    price.dispose();
    imageUrl.dispose();
    phone.dispose();
    location.dispose();
    quantity.dispose();
    super.dispose();
  }

  Future<void> addProduct() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await context.read<LiveCommerceController>().addProduct(
          sessionId: widget.sessionId,
          sellerId: user.uid,
          name: name.text.trim(),
          description: description.text.trim(),
          price: num.tryParse(price.text) ?? 0,
          currency: 'KES',
          imageUrl: imageUrl.text.trim(),
          phone: phone.text.trim(),
          location: location.text.trim(),
          quantity: int.tryParse(quantity.text) ?? 1,
        );
    name.clear();
    description.clear();
    price.clear();
    imageUrl.clear();
    phone.clear();
    location.clear();
    quantity.text = '1';
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<LiveCommerceRepository>();
    final commerce = context.watch<LiveCommerceController>();
    return Card(
      color: const Color(0xFF101527),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text('Live Products',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Product name')),
            TextField(
                controller: description,
                decoration: const InputDecoration(labelText: 'Description')),
            TextField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price')),
            TextField(
                controller: imageUrl,
                decoration: const InputDecoration(labelText: 'Image URL')),
            TextField(
                controller: phone,
                decoration:
                    const InputDecoration(labelText: 'Seller phone')),
            TextField(
                controller: location,
                decoration: const InputDecoration(labelText: 'Location')),
            TextField(
                controller: quantity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity')),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: commerce.loading ? null : addProduct,
              child: Text(commerce.loading ? 'Adding...' : 'Add Product'),
            ),
            if (commerce.error != null)
              Text(commerce.error!,
                  style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 12),
            StreamBuilder<List<LiveProductModel>>(
              stream: repo.watchProducts(widget.sessionId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final products = snapshot.data!;
                if (products.isEmpty) {
                  return const Text('No products added',
                      style: TextStyle(color: Colors.white54));
                }
                return Column(
                  children: products
                      .map(
                        (p) => ListTile(
                          title: Text(p.name,
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text(
                            '${p.currency} ${p.price} · '
                            '${p.pinned ? 'Pinned' : 'Not pinned'}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          trailing: TextButton(
                            onPressed: () {
                              if (p.pinned) {
                                commerce.unpinProduct(
                                  sessionId: widget.sessionId,
                                  productId: p.id,
                                );
                              } else {
                                commerce.pinProduct(
                                  sessionId: widget.sessionId,
                                  productId: p.id,
                                );
                              }
                            },
                            child: Text(p.pinned ? 'Unpin' : 'Pin'),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
