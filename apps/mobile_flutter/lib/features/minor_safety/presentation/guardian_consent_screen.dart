import 'package:flutter/material.dart';
import '../domain/guardian_consent.dart';

class GuardianConsentScreen extends StatefulWidget {
  static const routeName = '/guardian-consent';

  final String minorUid;
  final String minorDisplayName;
  final List<GuardianConsentScope> requestedScope;
  final Future<void> Function({
    required String guardianUid,
    required GuardianConsentStatus decision,
    required String notes,
  }) onDecision;

  const GuardianConsentScreen({
    super.key,
    required this.minorUid,
    required this.minorDisplayName,
    required this.requestedScope,
    required this.onDecision,
  });

  @override
  State<GuardianConsentScreen> createState() => _GuardianConsentScreenState();
}

class _GuardianConsentScreenState extends State<GuardianConsentScreen> {
  final _notesController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit(GuardianConsentStatus decision) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.onDecision(
        guardianUid: 'self',
        decision: decision,
        notes: _notesController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(decision);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Guardian Consent')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader('Account holder'),
            const SizedBox(height: 4),
            Text(
              widget.minorDisplayName,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _SectionHeader('Permissions requested'),
            const SizedBox(height: 8),
            ...widget.requestedScope.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 18, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(_scopeLabel(s)),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
            _SectionHeader('Legal notice'),
            const SizedBox(height: 8),
            Text(
              'By approving, you confirm that you are the legal guardian of '
              '${widget.minorDisplayName} and consent to their use of YohPal '
              'under the permitted features listed above. You may revoke '
              'consent at any time from the parental controls settings.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _SectionHeader('Notes (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add any notes or conditions',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            if (_submitting)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _submit(GuardianConsentStatus.denied),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error),
                      child: const Text('Deny'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _submit(GuardianConsentStatus.approved),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _scopeLabel(GuardianConsentScope scope) {
    switch (scope) {
      case GuardianConsentScope.accountCreation:
        return 'Create an account';
      case GuardianConsentScope.contentPublication:
        return 'Post videos and content';
      case GuardianConsentScope.advertising:
        return 'View targeted advertising';
      case GuardianConsentScope.directMessages:
        return 'Send and receive direct messages';
      case GuardianConsentScope.duet:
        return 'Participate in duets with other creators';
      case GuardianConsentScope.liveStreaming:
        return 'Host live streams';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.55),
          ),
    );
  }
}
