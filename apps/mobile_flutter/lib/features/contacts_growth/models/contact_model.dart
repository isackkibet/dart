class ContactModel {
  final String id;
  final String name;
  final String phone;
  final String normalizedPhone;
  final String? email;

  const ContactModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.normalizedPhone,
    this.email,
  });
}
