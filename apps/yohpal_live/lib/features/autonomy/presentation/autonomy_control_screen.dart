import 'package:flutter/material.dart';
import '../../../core/auth/yohpal_auth_scope.dart';
import '../../../shared/widgets/yohpal_error_view.dart';
import '../../../shared/widgets/yohpal_loading.dart';
import '../application/autonomy_controller.dart';
import '../data/autonomy_repository.dart';
import '../domain/autonomy_policy.dart';

class AutonomyControlScreen extends StatefulWidget {
  const AutonomyControlScreen({super.key});

  @override
  State<AutonomyControlScreen> createState() => _AutonomyControlScreenState();
}

class _AutonomyControlScreenState extends State<AutonomyControlScreen> {
  late final AutonomyController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AutonomyController(repository: AutonomyRepository());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = YohPalAuthScope.read(context).user;
      if (user != null) {
        _controller.watch(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _createPolicy() async {
    final user = YohPalAuthScope.read(context).user;
    if (user == null) return;
    final input = await showDialog<_PolicyInput>(
      context: context,
      builder: (_) => const _PolicyDialog(),
    );
    if (input == null) return;
    await _controller.savePolicy(
      AutonomyPolicy(
        id: '',
        creatorId: user.uid,
        domain: input.domain,
        name: input.name,
        description: input.description,
        mode: input.mode,
        enabled: true,
        maxActionsPerHour: input.maxActionsPerHour,
        requiresApproval: true,
        createdAt: null,
        updatedAt: null,
      ),
    );
  }

  Future<void> _approve(String decisionId) async {
    final user = YohPalAuthScope.read(context).user;
    if (user == null) return;
    await _controller.approveDecision(decisionId, user.uid);
  }

  Future<void> _reject(String decisionId) async {
    final user = YohPalAuthScope.read(context).user;
    if (user == null) return;
    await _controller.rejectDecision(decisionId, user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('AI Autonomy Control'),
            actions: [
              IconButton(
                onPressed: _createPolicy,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: _controller.isLoading
              ? const YohPalLoading(message: 'Loading autonomy controls...')
              : _controller.failure != null
                  ? YohPalErrorView(message: _controller.failure!.message)
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Autonomy Policies',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (_controller.policies.isEmpty)
                          const Text('No autonomy policies configured yet.'),
                        for (final policy in _controller.policies)
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.policy),
                              title: Text(policy.name),
                              subtitle: Text(
                                '${policy.domain} • ${policy.mode} • max ${policy.maxActionsPerHour}/hr',
                              ),
                              trailing: Icon(
                                policy.enabled
                                    ? Icons.check_circle
                                    : Icons.cancel,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        Text(
                          'AI Decisions',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (_controller.decisions.isEmpty)
                          const Text('No AI decisions yet.'),
                        for (final decision in _controller.decisions)
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.psychology),
                              title: Text(decision.recommendation),
                              subtitle: Text(
                                '${decision.domain} • confidence ${(decision.confidence * 100).toStringAsFixed(0)}%\n${decision.reason}',
                              ),
                              isThreeLine: true,
                              trailing: decision.status == 'proposed'
                                  ? Wrap(
                                      spacing: 4,
                                      children: [
                                        IconButton(
                                          onPressed: () => _approve(decision.id),
                                          icon: const Icon(Icons.check),
                                        ),
                                        IconButton(
                                          onPressed: () => _reject(decision.id),
                                          icon: const Icon(Icons.close),
                                        ),
                                      ],
                                    )
                                  : Chip(label: Text(decision.status)),
                            ),
                          ),
                      ],
                    ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _createPolicy,
            icon: const Icon(Icons.add),
            label: const Text('Policy'),
          ),
        );
      },
    );
  }
}

class _PolicyInput {
  const _PolicyInput({
    required this.name,
    required this.description,
    required this.domain,
    required this.mode,
    required this.maxActionsPerHour,
  });
  final String name;
  final String description;
  final String domain;
  final String mode;
  final int maxActionsPerHour;
}

class _PolicyDialog extends StatefulWidget {
  const _PolicyDialog();

  @override
  State<_PolicyDialog> createState() => _PolicyDialogState();
}

class _PolicyDialogState extends State<_PolicyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _domain = 'growth';
  String _mode = 'assisted';
  int _maxActionsPerHour = 3;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _PolicyInput(
        name: _name.text.trim(),
        description: _description.text.trim(),
        domain: _domain,
        mode: _mode,
        maxActionsPerHour: _maxActionsPerHour,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Autonomy Policy'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Policy name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              DropdownButtonFormField<String>(
                value: _domain,
                decoration: const InputDecoration(labelText: 'Domain'),
                items: const [
                  DropdownMenuItem(value: 'growth', child: Text('Growth')),
                  DropdownMenuItem(
                    value: 'monetisation',
                    child: Text('Monetisation'),
                  ),
                  DropdownMenuItem(value: 'scaling', child: Text('Scaling')),
                  DropdownMenuItem(
                    value: 'moderation',
                    child: Text('Moderation'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _domain = value);
                },
              ),
              DropdownButtonFormField<String>(
                value: _mode,
                decoration: const InputDecoration(labelText: 'Mode'),
                items: const [
                  DropdownMenuItem(value: 'inform', child: Text('Inform only')),
                  DropdownMenuItem(value: 'assisted', child: Text('Assisted')),
                  DropdownMenuItem(
                    value: 'controlled',
                    child: Text('Controlled autonomy'),
                  ),
                  DropdownMenuItem(value: 'disabled', child: Text('Disabled')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _mode = value);
                },
              ),
              DropdownButtonFormField<int>(
                value: _maxActionsPerHour,
                decoration: const InputDecoration(
                  labelText: 'Max actions per hour',
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1')),
                  DropdownMenuItem(value: 3, child: Text('3')),
                  DropdownMenuItem(value: 5, child: Text('5')),
                  DropdownMenuItem(value: 10, child: Text('10')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _maxActionsPerHour = value);
                  }
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
