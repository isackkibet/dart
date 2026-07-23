import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/auth/yohpal_auth_scope.dart';
import '../../../shared/widgets/yohpal_loading.dart';
import '../../multistream_v2/domain/live_session.dart';
import '../data/traffic_funnel_repository.dart';
import '../domain/traffic_campaign.dart';

class CampaignManagerScreen extends StatefulWidget {
  const CampaignManagerScreen({
    super.key,
    required this.session,
  });

  final LiveSession session;

  @override
  State<CampaignManagerScreen> createState() => _CampaignManagerScreenState();
}

class _CampaignManagerScreenState extends State<CampaignManagerScreen> {
  final _repository = TrafficFunnelRepository();
  StreamSubscription<List<TrafficCampaign>>? _subscription;
  List<TrafficCampaign> _campaigns = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final user = YohPalAuthScope.read(context).user;
    if (user != null) {
      _subscription = _repository.watchCampaigns(user.uid).listen((items) {
        setState(() {
          _campaigns =
              items.where((item) => item.sessionId == widget.session.id).toList();
          _loading = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _createCampaign() async {
    final user = YohPalAuthScope.read(context).user;
    if (user == null) return;
    final input = await showDialog<_CampaignInput>(
      context: context,
      builder: (_) => const _CampaignDialog(),
    );
    if (input == null) return;
    await _repository.createCampaign(
      TrafficCampaign(
        id: '',
        creatorId: user.uid,
        sessionId: widget.session.id,
        name: input.name,
        sourcePlatform: input.sourcePlatform,
        campaignCode:
            '${input.sourcePlatform}_${DateTime.now().millisecondsSinceEpoch}',
        status: 'active',
        createdAt: null,
        updatedAt: null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const baseWatchUrl = 'https://yohpal.live/watch';
    return Scaffold(
      appBar: AppBar(title: Text('Campaigns: ${widget.session.title}')),
      body: _loading
          ? const YohPalLoading(message: 'Loading campaigns...')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Create campaign links for each external platform. These links help YohPal track which platform sends traffic and conversions back into YohPal Live.',
                ),
                const SizedBox(height: 16),
                if (_campaigns.isEmpty) const Text('No campaigns yet.'),
                for (final campaign in _campaigns)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.link),
                      title: Text(campaign.name),
                      subtitle: SelectableText(
                        campaign.buildAttributionUrl(
                          baseWatchUrl: baseWatchUrl,
                        ),
                      ),
                      trailing: Chip(
                        label: Text(campaign.sourcePlatform),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCampaign,
        icon: const Icon(Icons.add_link),
        label: const Text('New Campaign'),
      ),
    );
  }
}

class _CampaignInput {
  const _CampaignInput({
    required this.name,
    required this.sourcePlatform,
  });
  final String name;
  final String sourcePlatform;
}

class _CampaignDialog extends StatefulWidget {
  const _CampaignDialog();

  @override
  State<_CampaignDialog> createState() => _CampaignDialogState();
}

class _CampaignDialogState extends State<_CampaignDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _sourcePlatform = 'tiktok';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _CampaignInput(
        name: _name.text.trim(),
        sourcePlatform: _sourcePlatform,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Traffic Campaign'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Campaign name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              DropdownButtonFormField<String>(
                value: _sourcePlatform,
                decoration: const InputDecoration(labelText: 'Source platform'),
                items: const [
                  DropdownMenuItem(value: 'tiktok', child: Text('TikTok')),
                  DropdownMenuItem(value: 'youtube', child: Text('YouTube')),
                  DropdownMenuItem(value: 'facebook', child: Text('Facebook')),
                  DropdownMenuItem(value: 'instagram', child: Text('Instagram')),
                  DropdownMenuItem(value: 'x', child: Text('X')),
                  DropdownMenuItem(value: 'twitch', child: Text('Twitch')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _sourcePlatform = value);
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
          child: const Text('Create'),
        ),
      ],
    );
  }
}
