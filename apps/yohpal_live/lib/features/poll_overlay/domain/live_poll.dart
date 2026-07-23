import 'poll_option.dart';

class LivePoll {
  const LivePoll({
    required this.id,
    required this.sessionId,
    required this.creatorId,
    required this.question,
    required this.options,
    required this.status,
    required this.durationSeconds,
    required this.allowMultipleVotes,
    required this.createdAt,
    this.closedAt,
  });

  final String id;
  final String sessionId;
  final String creatorId;
  final String question;
  final List<PollOption> options;

  /// 'open' | 'closed' | 'archived'
  final String status;

  final int durationSeconds;
  final bool allowMultipleVotes;
  final DateTime? createdAt;
  final DateTime? closedAt;

  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';

  int get totalVotes => options.fold(0, (sum, o) => sum + o.voteCount);

  PollOption? get winningOption {
    if (options.isEmpty) return null;
    return options.reduce(
        (a, b) => a.voteCount >= b.voteCount ? a : b);
  }

  /// Seconds remaining since creation (null if poll is closed).
  int? get secondsRemaining {
    if (!isOpen || createdAt == null) return null;
    final elapsed =
        DateTime.now().toUtc().difference(createdAt!.toUtc()).inSeconds;
    final remaining = durationSeconds - elapsed;
    return remaining.clamp(0, durationSeconds);
  }

  factory LivePoll.fromMap(String id, Map<String, dynamic> map) {
    final rawOptions = map['options'];
    final List<PollOption> options;
    if (rawOptions is List) {
      options = rawOptions
          .whereType<Map<String, dynamic>>()
          .map(PollOption.fromMap)
          .toList();
    } else {
      options = const [];
    }

    return LivePoll(
      id: id,
      sessionId: map['sessionId']?.toString() ?? '',
      creatorId: map['creatorId']?.toString() ?? '',
      question: map['question']?.toString() ?? '',
      options: options,
      status: map['status']?.toString() ?? 'open',
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 30,
      allowMultipleVotes: map['allowMultipleVotes'] == true,
      createdAt: _readDate(map['createdAt']),
      closedAt: _readDate(map['closedAt']),
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
