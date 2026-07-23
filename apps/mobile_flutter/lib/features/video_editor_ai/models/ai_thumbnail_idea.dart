class AiThumbnailIdea {
  final String title;
  final String description;
  final String visualDirection;
  final String textOverlay;

  const AiThumbnailIdea({
    required this.title,
    required this.description,
    required this.visualDirection,
    required this.textOverlay,
  });

  factory AiThumbnailIdea.fromText(String text) {
    final trimmed = text.trim();
    return AiThumbnailIdea(
      title: trimmed.length > 40 ? trimmed.substring(0, 40) : trimmed,
      description: trimmed,
      visualDirection: trimmed,
      textOverlay: trimmed.length > 24 ? trimmed.substring(0, 24) : trimmed,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'visualDirection': visualDirection,
        'textOverlay': textOverlay,
      };
}
