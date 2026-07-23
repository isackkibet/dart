import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/auth/yohpal_auth_scope.dart';
import '../../../shared/widgets/yohpal_loading.dart';
import '../data/live_destination_repository.dart';
import '../domain/live_destination.dart';
import '../domain/live_session.dart';

class SessionDestinationsScreen extends StatefulWidget {
  const SessionDestinationsScreen({
    super.key,
    required this.session,
  });

  final LiveSession session;

  @override
  State<SessionDestinationsScreen> createState() =>
      _SessionDestinationsScreenState();
}

class _SessionDestinationsScreenState extends State<SessionDestinationsScreen> {
  final _repository = LiveDestinationRepository();
  StreamSubscription<List<LiveDestination>>? _subscription;
  List<LiveDestination> _destinations = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _subscription =
        _repository.watchSessionDestinations(widget.session.id).listen(
      (items) {
        setState(() {
          _destinations = items;
          _loading = false;
        });
      },
      onError: (_) {
        setState(() => _loading = false);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _addDestination() async {
    final user = YohPalAuthScope.read(context).user;
    if (user == null) return;
    final input = await showDialog<_DestinationInput>(
      context: context,
      builder: (_) => const _DestinationDialog(),
    );
    if (input == null) return;
    await _repository.create(
      LiveDestination(
        id: '',
        sessionId: widget.session.id,
        creatorId: user.uid,
        platform: input.platform,
        destinationName: input.destinationName,
        streamMode: input.streamMode,
        status: 'enabled',
        ctaEnabled: input.ctaEnabled,
        delaySeconds: input.delaySeconds,
        createdAt: null,
        updatedAt: null,
      ),
    );
  }

  Future<void> _deleteDestination(LiveDestination destination) async {
    await _repository.delete(destination.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.session.title} Destinations'),
      ),
      body: _loading
          ? const YohPalLoading(message: 'Loading destinations...')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Route this live session to external platforms while keeping YohPal as the main monetisation and conversion destination.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (_destinations.isEmpty)
                  const Text('No destinations configured yet.'),
                for (final destination in _destinations)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.hub_outlined),
                      title: Text(destination.platform.toUpperCase()),
                      subtitle: Text(
                        '${destination.destinationName} • ${destination.streamMode} • delay ${destination.delaySeconds}s',
                      ),
                      trailing: IconButton(
                        onPressed: () => _deleteDestination(destination),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDestination,
        icon: const Icon(Icons.add),
        label: const Text('Add Destination'),
      ),
    );
  }
}

class _DestinationInput {
  const _DestinationInput({
    required this.platform,
    required this.destinationName,
    required this.streamMode,
    required this.ctaEnabled,
    required this.delaySeconds,
  });

  final String platform;
  final String destinationName;
  final String streamMode;
  final bool ctaEnabled;
  final int delaySeconds;
}

class _DestinationDialog extends StatefulWidget {
  const _DestinationDialog();

  @override
  State<_DestinationDialog> createState() => _DestinationDialogState();
}

class _DestinationDialogState extends State<_DestinationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _destinationName = TextEditingController();
  String _platform = 'youtube';
  String _streamMode = 'teaser';
  bool _ctaEnabled = true;
  int _delaySeconds = 20;

  @override
  void dispose() {
    _destinationName.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _DestinationInput(
        platform: _platform,
        destinationName: _destinationName.text.trim(),
        streamMode: _streamMode,
        ctaEnabled: _ctaEnabled,
        delaySeconds: _delaySeconds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Destination'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _platform,
                decoration: const InputDecoration(labelText: 'Platform'),
                items: const [
                  DropdownMenuItem(value: 'youtube', child: Text('YouTube')),
                  DropdownMenuItem(value: 'facebook', child: Text('Facebook')),
                  DropdownMenuItem(value: 'tiktok', child: Text('TikTok')),
                  DropdownMenuItem(value: 'instagram', child: Text('Instagram')),
                  DropdownMenuItem(value: 'x', child: Text('X')),
                  DropdownMenuItem(value: 'twitch', child: Text('Twitch')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _platform = value);
                },
              ),
              TextFormField(
                controller: _destinationName,
                decoration: const InputDecoration(
                  labelText: 'Destination name',
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              DropdownButtonFormField<String>(
                value: _streamMode,
                decoration: const InputDecoration(labelText: 'Mode'),
                items: const [
                  DropdownMenuItem(value: 'full', child: Text('Full mirror')),
                  DropdownMenuItem(value: 'teaser', child: Text('Teaser')),
                  DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _streamMode = value);
                },
              ),
              SwitchListTile(
                value: _ctaEnabled,
                title: const Text('Enable YohPal CTA overlay'),
                onChanged: (value) => setState(() => _ctaEnabled = value),
              ),
              DropdownButtonFormField<int>(
                value: _delaySeconds,
                decoration: const InputDecoration(labelText: 'Delay seconds'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('0 seconds')),
                  DropdownMenuItem(value: 10, child: Text('10 seconds')),
                  DropdownMenuItem(value: 20, child: Text('20 seconds')),
                  DropdownMenuItem(value: 30, child: Text('30 seconds')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _delaySeconds = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}