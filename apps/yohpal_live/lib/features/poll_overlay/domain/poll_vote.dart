class PollVote {
  const PollVote({
    required this.id,
    required this.pollId,
    required this.sessionId,
    required this.voterId,
    required this.optionIds,
    required this.votedAt,
  });

  final String id;
  final String pollId;
  final String sessionId;
  final String voterId;

  /// One or more option IDs selected by this voter.
  final List<String> optionIds;

  final DateTime? votedAt;

  factory PollVote.fromMap(String id, Map<String, dynamic> map) {
    final rawOptions = map['optionIds'];
    final List<String> optionIds;
    if (rawOptions is List) {
      optionIds = rawOptions.map((e) => e.toString()).toList();
    } else {
      optionIds = const [];
    }

    return PollVote(
      id: id,
      pollId: map['pollId']?.toString() ?? '',
      sessionId: map['sessionId']?.toString() ?? '',
      voterId: map['voterId']?.toString() ?? '',
      optionIds: optionIds,
      votedAt: _readDate(map['votedAt']),
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
