import 'package:flutter/material.dart';
import '../../../core/auth/yohpal_auth_service.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../application/ads_engine_controller.dart';
import '../data/ads_engine_repository.dart';
import '../domain/ad_campaign.dart';

class AdvertiserCampaignsScreen extends StatefulWidget {
  const AdvertiserCampaignsScreen({super.key});

  @override
  State<AdvertiserCampaignsScreen> createState() =>
      _AdvertiserCampaignsScreenState();
}

class _AdvertiserCampaignsScreenState
    extends State<AdvertiserCampaignsScreen> {
  late final AdsEngineController _controller;

  @override
  void initState() {
    super.initState();
    final env = AppEnvironmentConfig.fromDartDefines();
    final auth = YohPalAuthService();
    _controller = AdsEngineController(
      repository: AdsEngineRepository(
        apiClient: ApiClient(
          baseUrl: env.apiBaseUrl,
          tokenProvider: auth.getIdToken,
        ),
      ),
    );
    _controller.watchCampaigns(auth.currentUserId ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _statusColor(String status) => switch (status) {
        'active' => Colors.green,
        'paused' => Colors.orange,
        'draft' => Colors.blue,
        'completed' => Colors.grey,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ad Campaigns'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final auth = YohPalAuthService();
              _controller.watchCampaigns(auth.currentUserId ?? '');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New Campaign'),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.campaigns.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.campaign_outlined,
                      size: 56, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No campaigns yet.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap "New Campaign" to get started.'),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: _controller.campaigns.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final campaign = _controller.campaigns[i];
              return _CampaignCard(
                campaign: campaign,
                controller: _controller,
                statusColor: _statusColor(campaign.status),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateCampaignSheet(controller: _controller),
    );
  }
}

// ── Campaign Card ─────────────────────────────────────────────────────────────

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.campaign,
    required this.controller,
    required this.statusColor,
  });

  final AdCampaign campaign;
  final AdsEngineController controller;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final isLoading = controller.isLoading(campaign.id);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Expanded(
                  child: Text(campaign.title,
                      style: theme.textTheme.titleMedium),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    campaign.statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${campaign.creativeTypeLabel} · ${campaign.impressionCount} impressions · CTR ${campaign.ctr.toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            // Budget bar
            Row(
              children: [
                Text('Budget', style: theme.textTheme.labelSmall),
                const Spacer(),
                Text(
                  '${campaign.spentDisplay} / ${campaign.budgetDisplay}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: campaign.budgetUsedPercent / 100,
              backgroundColor:
                  theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(statusColor),
              borderRadius: BorderRadius.circular(4),
              minHeight: 6,
            ),
            const SizedBox(height: 12),
            // Actions
            Row(
              children: [
                if (campaign.isActive)
                  OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => controller.pauseCampaign(campaign.id),
                    icon: isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.pause, size: 16),
                    label: const Text('Pause'),
                  ),
                if (campaign.isPaused)
                  FilledButton.tonalIcon(
                    onPressed: isLoading
                        ? null
                        : () => controller.resumeCampaign(campaign.id),
                    icon: isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Resume'),
                  ),
                const Spacer(),
                Text(
                  campaign.isActive
                      ? '${campaign.remainingBudgetCents ~/ 100} remaining'
                      : campaign.isDraft
                          ? 'Draft — not live'
                          : campaign.isCompleted
                              ? 'Campaign ended'
                              : '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create Campaign Sheet ─────────────────────────────────────────────────────

class _CreateCampaignSheet extends StatefulWidget {
  const _CreateCampaignSheet({required this.controller});
  final AdsEngineController controller;

  @override
  State<_CreateCampaignSheet> createState() => _CreateCampaignSheetState();
}

class _CreateCampaignSheetState extends State<_CreateCampaignSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _creativeRefCtrl = TextEditingController();
  final _ctaLabelCtrl = TextEditingController(text: 'Learn More');
  final _ctaUrlCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  double _budgetDollars = 50.0;
  double _cpmCents = 200.0; // $2.00 CPM
  String _creativeType = 'banner';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _creativeRefCtrl.dispose();
    _ctaLabelCtrl.dispose();
    _ctaUrlCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final result = await widget.controller.createCampaign(
      title: _titleCtrl.text.trim(),
      budgetCents: (_budgetDollars * 100).round(),
      cpmCents: _cpmCents.round(),
      creativeType: _creativeType,
      creativeRef: _creativeRefCtrl.text.trim(),
      ctaLabel: _ctaLabelCtrl.text.trim(),
      ctaUrl: _ctaUrlCtrl.text.trim(),
      targetingTags: tags,
    );

    if (!mounted) return;
    if (result.isSuccess) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campaign created successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.controller.failure?.message ??
                'Failed to create campaign.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Text('New Campaign',
                        style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Campaign Title',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Title is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _creativeType,
                        decoration:
                            const InputDecoration(labelText: 'Creative Type'),
                        items: const [
                          DropdownMenuItem(
                              value: 'banner', child: Text('Banner')),
                          DropdownMenuItem(
                              value: 'overlay', child: Text('Overlay')),
                        ],
                        onChanged: (v) =>
                            setState(() => _creativeType = v ?? 'banner'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _creativeRefCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Ad Copy / Creative Text',
                          hintText: 'Short compelling text for your ad...',
                        ),
                        maxLength: 100,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Ad copy is required'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _ctaLabelCtrl,
                        decoration: const InputDecoration(
                            labelText: 'CTA Button Label'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'CTA label is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ctaUrlCtrl,
                        decoration: const InputDecoration(
                          labelText: 'CTA URL',
                          hintText: 'https://example.com',
                        ),
                        keyboardType: TextInputType.url,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'CTA URL is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tagsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Targeting Tags (comma-separated)',
                          hintText: 'e.g. gaming, music, cooking',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Budget: \$${_budgetDollars.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Slider(
                        value: _budgetDollars,
                        min: 10,
                        max: 1000,
                        divisions: 99,
                        label: '\$${_budgetDollars.toStringAsFixed(0)}',
                        onChanged: (v) =>
                            setState(() => _budgetDollars = v),
                      ),
                      Text(
                        'CPM: \$${(_cpmCents / 100).toStringAsFixed(2)} per 1,000 impressions',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Slider(
                        value: _cpmCents,
                        min: 50,
                        max: 1000,
                        divisions: 19,
                        label:
                            '\$${(_cpmCents / 100).toStringAsFixed(2)}',
                        onChanged: (v) =>
                            setState(() => _cpmCents = v),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: widget.controller.isCreating
                              ? null
                              : _submit,
                          child: widget.controller.isCreating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Text('Create Campaign'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
