import 'package:flutter/material.dart';
import '../domain/minor_content_classification.dart';

class MinorContentDisclosureForm extends StatefulWidget {
  const MinorContentDisclosureForm({
    required this.onSubmit,
    this.initialType = MinorContentType.none,
    this.initialRating = VideoAgeRating.general,
    super.key,
  });

  final Future<void> Function({
    required MinorContentType contentType,
    required VideoAgeRating ageRating,
    required bool containsIdentifiableMinor,
    required bool guardianConsentRequired,
  }) onSubmit;

  final MinorContentType initialType;
  final VideoAgeRating initialRating;

  @override
  State<MinorContentDisclosureForm> createState() =>
      _MinorContentDisclosureFormState();
}

class _MinorContentDisclosureFormState
    extends State<MinorContentDisclosureForm> {
  late MinorContentType _contentType;
  late VideoAgeRating _ageRating;
  bool _containsIdentifiableMinor = false;
  bool _guardianConsentRequired = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _contentType = widget.initialType;
    _ageRating = widget.initialRating;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        contentType: _contentType,
        ageRating: _ageRating,
        containsIdentifiableMinor: _containsIdentifiableMinor,
        guardianConsentRequired: _guardianConsentRequired,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Minor Content Disclosure',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Required before publishing content involving or directed at minors.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 20),
          _Label('Content classification'),
          const SizedBox(height: 8),
          DropdownButtonFormField<MinorContentType>(
            initialValue: _contentType,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: MinorContentType.values
                .map((t) => DropdownMenuItem(value: t, child: Text(_typeLabel(t))))
                .toList(),
            onChanged: (v) => setState(() => _contentType = v!),
          ),
          const SizedBox(height: 16),
          _Label('Age rating'),
          const SizedBox(height: 8),
          DropdownButtonFormField<VideoAgeRating>(
            initialValue: _ageRating,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: VideoAgeRating.values
                .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                .toList(),
            onChanged: (v) => setState(() => _ageRating = v!),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('This video contains an identifiable minor'),
            value: _containsIdentifiableMinor,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() {
              _containsIdentifiableMinor = v!;
              if (!v) _guardianConsentRequired = false;
            }),
          ),
          if (_containsIdentifiableMinor)
            CheckboxListTile(
              title: const Text('Guardian consent is required'),
              value: _guardianConsentRequired,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) =>
                  setState(() => _guardianConsentRequired = v!),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save disclosure'),
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(MinorContentType t) {
    switch (t) {
      case MinorContentType.none:
        return 'None — no minor content';
      case MinorContentType.incidentalMinorAppearance:
        return 'Incidental minor appearance';
      case MinorContentType.minorParticipant:
        return 'Minor is a participant';
      case MinorContentType.minorCreator:
        return 'Minor is the creator';
      case MinorContentType.directedToChildren:
        return 'Directed to children';
      case MinorContentType.educationalForMinors:
        return 'Educational content for minors';
      case MinorContentType.advertisingToMinors:
        return 'Advertising targeting minors';
    }
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.1,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.55),
          ),
    );
  }
}
