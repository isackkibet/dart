class ContextActionModel {
  final String id;
  final String title;
  final String subtitle;
  final String type;
  final String route;
  final double priority;
  final Map<String, dynamic> arguments;

  const ContextActionModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.route,
    required this.priority,
    this.arguments = const {},
  });
}
