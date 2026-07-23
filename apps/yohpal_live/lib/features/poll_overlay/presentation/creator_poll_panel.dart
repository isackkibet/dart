import 'package:flutter/material.dart';
import '../application/poll_overlay_controller.dart';
import '../domain/live_poll.dart';

/// Creator-only bottom sheet for managing live polls.
class CreatorPollPanel extends StatefulWidget {
  const CreatorPollPanel({
    super.key,
    required this.sessionId,
    required this.controller,
  });

  final String sessionId;
  final PollOverlayController controller;

  static Future<void> show(
    BuildContext context, {
    required String sessionId,
    required PollOverlayController controller,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatorPollPanel(
        sessionId: sessionId,
        controller: controller,
      ),
    );
  }

  @override
  State<CreatorPollPanel> createState() => _CreatorPollPanelState();
}

class _CreatorPollPanelState extends State<CreatorPollPanel> {
  bool _showCreateForm = false;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.poll_outlined),
                    const SizedBox(width: 10),
                    Text(
                      'Poll Manager',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () =>
                          setState(() => _showCreateForm = !_showCreateForm),
                      icon: Icon(
                          _showCreateForm ? Icons.close : Icons.add, size: 18),
                      label: Text(_showCreateForm ? 'Cancel' : 'New Poll'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: AnimatedBuilder(
                  animation: widget.controller,
                  builder: (context, _) {
                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Create form
                        if (_showCreateForm)
                          _CreatePollForm(
                            sessionId: widget.sessionId,
                            controller: widget.controller,
                            onCreated: () =>
                                setState(() => _showCreateForm = false),
                          ),
                        // Active polls
                        if (widget.controller.openPolls.isNotEmpty) ...[
                          _SectionHeader('Active Polls',
                              count: widget.controller.openPolls.length),
                          const SizedBox(height: 8),
                          ...widget.controller.openPolls.map(
                            (p) => _PollManageCard(
                              poll: p,
                              controller: widget.controller,
                            ),
                          ),
                        ],
                        // Closed polls
                        if (widget.controller.closedPolls.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _SectionHeader('Closed Polls',
                              count: widget.controller.closedPolls.length),
                          const SizedBox(height: 8),
                          ...widget.controller.closedPolls.map(
                            (p) => _PollManageCard(
                              poll: p,
                              controller: widget.controller,
                            ),
                          ),
                        ],
                        if (widget.controller.polls.isEmpty &&
                            !_showCreateForm)
                          const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Center(
                              child: Text(
                                  'No polls yet. Tap "New Poll" to create one.'),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Create Form ───────────────────────────────────────────────────────────────

class _CreatePollForm extends StatefulWidget {
  const _CreatePollForm({
    required this.sessionId,
    required this.controller,
    required this.onCreated,
  });

  final String sessionId;
  final PollOverlayController controller;
  final VoidCallback onCreated;

  @override
  State<_CreatePollForm> createState() => _CreatePollFormState();
}

class _CreatePollFormState extends State<_CreatePollForm> {
  final _questionCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];
  double _durationSeconds = 30;
  bool _allowMultiVote = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (final c in _optionCtrls) c.dispose();
    super.dispose();
  }

  void _addOption() {
    if (_optionCtrls.length < 4) {
      setState(() => _optionCtrls.add(TextEditingController()));
    }
  }

  void _removeOption(int index) {
    if (_optionCtrls.length > 2) {
      setState(() {
        _optionCtrls[index].dispose();
        _optionCtrls.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final options = _optionCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final result = await widget.controller.createPoll(
      sessionId: widget.sessionId,
      question: _questionCtrl.text.trim(),
      options: options,
      durationSeconds: _durationSeconds.round(),
      allowMultipleVotes: _allowMultiVote,
    );

    if (!mounted) return;
    if (result.isSuccess) {
      widget.onCreated();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                widget.controller.failure?.message ?? 'Failed to create poll.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Poll',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                controller: _questionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  hintText: 'Ask your viewers something...',
                ),
                maxLength: 120,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Question is required' : null,
              ),
              const SizedBox(height: 10),
              ...List.generate(_optionCtrls.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _optionCtrls[i],
                          decoration: InputDecoration(
                            labelText: 'Option ${i + 1}',
                          ),
                          maxLength: 60,
                          validator: (v) => (i < 2 &&
                                  (v == null || v.trim().isEmpty))
                              ? 'At least 2 options required'
                              : null,
                        ),
                      ),
                      if (_optionCtrls.length > 2) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red),
                          onPressed: () => _removeOption(i),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              if (_optionCtrls.length < 4)
                TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Option'),
                ),
              const SizedBox(height: 10),
              Text(
                'Duration: ${_durationSeconds.round()}s',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Slider(
                value: _durationSeconds,
                min: 15,
                max: 120,
                divisions: 21,
                label: '${_durationSeconds.round()}s',
                onChanged: (v) => setState(() => _durationSeconds = v),
              ),
              SwitchListTile(
                title: const Text('Allow multiple vote selections'),
                value: _allowMultiVote,
                onChanged: (v) => setState(() => _allowMultiVote = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.controller.isCreating ? null : _submit,
                  child: widget.controller.isCreating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Launch Poll'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Poll Management Card ──────────────────────────────────────────────────────

class _PollManageCard extends StatelessWidget {
  const _PollManageCard({
    required this.poll,
    required this.controller,
  });

  final LivePoll poll;
  final PollOverlayController controller;

  @override
  Widget build(BuildContext context) {
    final total = poll.totalVotes;
    final isLoading = controller.isLoading(poll.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    poll.question,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: poll.isOpen
                        ? Colors.green.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    poll.isOpen ? 'OPEN' : 'CLOSED',
                    style: TextStyle(
                      color: poll.isOpen ? Colors.green : Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$total total vote${total == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            // Compact result bars
            ...poll.options.map((opt) {
              final pct = opt.percentage(total);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(opt.label,
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                        Text(
                          '${opt.voteCount} (${pct.toStringAsFixed(0)}%)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 5,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
            Row(
              children: [
                if (poll.isOpen)
                  FilledButton.tonal(
                    onPressed: isLoading
                        ? null
                        : () => controller.closePoll(poll.id),
                    child: isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Close Poll'),
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed:
                      isLoading ? null : () => controller.deletePoll(poll.id),
                  tooltip: 'Delete poll',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
