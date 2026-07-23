class PollOption {
  const PollOption({
    required this.id,
    required this.label,
    required this.voteCount,
  });

  final String id;
  final String label;
  final int voteCount;

  double percentage(int total) =>
      total == 0 ? 0.0 : (voteCount / total * 100).clamp(0.0, 100.0);

  factory PollOption.fromMap(Map<String, dynamic> map) => PollOption(
        id: map['id']?.toString() ?? '',
        label: map['label']?.toString() ?? '',
        voteCount: (map['voteCount'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'voteCount': voteCount,
      };
}
