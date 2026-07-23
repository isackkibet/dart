class PollModel {
  final String id;
  final String videoId;
  final String question;
  final List<String> options;
  final Map<String, dynamic> voteCounts;
  final String status;
  final bool visible;

  const PollModel({
    required this.id,
    required this.videoId,
    required this.question,
    required this.options,
    required this.voteCounts,
    required this.status,
    required this.visible,
  });

  factory PollModel.fromMap(Map<String, dynamic> map) {
    return PollModel(
      id: map['id'] ?? '',
      videoId: map['videoId'] ?? '',
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      voteCounts: Map<String, dynamic>.from(map['voteCounts'] ?? {}),
      status: map['status'] ?? 'active',
      visible: map['visible'] ?? true,
    );
  }

  int get totalVotes {
    return voteCounts.values.fold<int>(
      0,
      (acc, value) => acc + ((value ?? 0) as int),
    );
  }
}
