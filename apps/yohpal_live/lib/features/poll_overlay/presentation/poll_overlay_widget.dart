import 'dart:async';
import 'package:flutter/material.dart';
import '../application/poll_overlay_controller.dart';
import '../domain/live_poll.dart';
import '../domain/poll_option.dart';

/// Floating poll overlay shown during a live session.
/// Mount this as a Stack child over the video view.
class PollOverlayWidget extends StatefulWidget {
  const PollOverlayWidget({
    super.key,
    required this.poll,
    required this.sessionId,
    required this.controller,
  });

  final LivePoll poll;
  final String sessionId;
  final PollOverlayController controller;

  @override
  State<PollOverlayWidget> createState() => _PollOverlayWidgetState();
}

class _PollOverlayWidgetState extends State<PollOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Timer? _countdownTimer;
  int _secondsLeft = 0;
  String? _selectedOptionId;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.poll.secondsRemaining ?? widget.poll.durationSeconds;

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    if (widget.poll.isOpen) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _countdownTimer?.cancel();
        }
      });
    });
  }

  Future<void> _vote(String optionId) async {
    if (widget.controller.hasVoted(widget.poll.id)) return;
    setState(() => _selectedOptionId = optionId);
    await widget.controller.castVote(
      pollId: widget.poll.id,
      sessionId: widget.sessionId,
      optionIds: [optionId],
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poll = widget.poll;
    final hasVoted = widget.controller.hasVoted(poll.id);
    final total = poll.totalVotes;
    final isLoading = widget.controller.isLoading(poll.id);
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.82),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: poll.isOpen
                            ? Colors.green.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: poll.isOpen ? Colors.green : Colors.grey,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        poll.isOpen ? 'LIVE POLL' : 'POLL ENDED',
                        style: TextStyle(
                          color: poll.isOpen ? Colors.green : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (poll.isOpen && _secondsLeft > 0)
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              color: Colors.white60, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${_secondsLeft}s',
                            style: TextStyle(
                              color: _secondsLeft <= 5
                                  ? Colors.red
                                  : Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    if (total > 0) ...[
                      const SizedBox(width: 12),
                      Text(
                        '$total vote${total == 1 ? '' : 's'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // Question
                Text(
                  poll.question,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                // Options
                ...poll.options.map((option) =>
                    _OptionBar(
                      option: option,
                      total: total,
                      isSelected: _selectedOptionId == option.id,
                      hasVoted: hasVoted,
                      isLoading: isLoading && _selectedOptionId == option.id,
                      canVote: poll.isOpen && !hasVoted,
                      onTap: () => _vote(option.id),
                    )),
                if (hasVoted)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.greenAccent, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Your vote has been counted!',
                          style: TextStyle(
                            color: Colors.greenAccent.shade100,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionBar extends StatelessWidget {
  const _OptionBar({
    required this.option,
    required this.total,
    required this.isSelected,
    required this.hasVoted,
    required this.isLoading,
    required this.canVote,
    required this.onTap,
  });

  final PollOption option;
  final int total;
  final bool isSelected;
  final bool hasVoted;
  final bool isLoading;
  final bool canVote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = option.percentage(total);
    final showResults = hasVoted;

    return GestureDetector(
      onTap: canVote ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepPurple.withOpacity(0.35)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.deepPurpleAccent
                : Colors.white.withOpacity(0.12),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Progress fill
              if (showResults)
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  widthFactor: pct / 100,
                  child: Container(
                    height: double.infinity,
                    color: isSelected
                        ? Colors.deepPurple.withOpacity(0.4)
                        : Colors.white.withOpacity(0.08),
                  ),
                ),
              // Label + percentage
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    if (isLoading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else if (isSelected)
                      const Icon(Icons.check_circle,
                          color: Colors.deepPurpleAccent, size: 16)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        option.label,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (showResults)
                      Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
