class LiveProductModel {
  final String id;
  final String sessionId;
  final String sellerId;
  final String name;
  final String description;
  final String price;
  final String currency;
  final String imageUrl;
  final String phone;
  final String location;
  final int quantity;
  final String status;
  final bool pinned;

  const LiveProductModel({
    required this.id,
    required this.sessionId,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.imageUrl,
    required this.phone,
    required this.location,
    required this.quantity,
    required this.status,
    required this.pinned,
  });

  factory LiveProductModel.fromMap(Map<String, dynamic> map) {
    return LiveProductModel(
      id: map['id'] ?? '',
      sessionId: map['sessionId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: '${map['price'] ?? 0}',
      currency: map['currency'] ?? 'KES',
      imageUrl: map['imageUrl'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      quantity: map['quantity'] ?? 0,
      status: map['status'] ?? 'available',
      pinned: map['pinned'] ?? false,
    );
  }
}
