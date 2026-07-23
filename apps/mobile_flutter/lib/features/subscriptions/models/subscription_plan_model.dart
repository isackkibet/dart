class SubscriptionPlanModel {
  final String id;
  final String creatorId;
  final String title;
  final String description;
  final num price;
  final String currency;
  final String status;

  const SubscriptionPlanModel({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.status,
  });

  factory SubscriptionPlanModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlanModel(
      id: map['id'] ?? '',
      creatorId: map['creatorId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: map['price'] ?? 0,
      currency: map['currency'] ?? 'KES',
      status: map['status'] ?? 'active',
    );
  }
}
