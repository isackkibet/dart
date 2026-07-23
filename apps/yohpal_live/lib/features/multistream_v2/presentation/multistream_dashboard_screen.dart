import 'package:flutter/material.dart';

import '../../../core/auth/yohpal_auth_scope.dart';
import '../../../core/models/result.dart';
import '../../../shared/widgets/yohpal_error_view.dart';
import '../../../shared/widgets/yohpal_loading.dart';
import '../../autonomy/presentation/autonomy_control_screen.dart';
import '../../clip_factory/presentation/clip_factory_screen.dart';
import '../../command_center/presentation/command_center_dashboard_screen.dart';
import '../../social_connector/presentation/social_connectors_screen.dart';
import '../../creator_growth/presentation/creator_growth_dashboard_screen.dart';
import '../../revenue_engine/presentation/creator_revenue_dashboard_screen.dart';
import '../../traffic_funnel/presentation/campaign_manager_screen.dart';
import '../../traffic_funnel/presentation/funnel_insights_screen.dart';
import '../application/live_sessions_controller.dart';
import '../data/live_session_repository.dart';
import '../domain/live_session.dart';
import 'session_destinations_screen.dart';
import 'stream_control_screen.dart';

class MultistreamDashboardScreen extends StatefulWidget {
  const MultistreamDashboardScreen({super.key});

  @override
  State<MultistreamDashboardScreen> createState() =>
      _MultistreamDashboardScreenState();
}

class _MultistreamDashboardScreenState
    extends State<MultistreamDashboardScreen> {
  late final LiveSessionsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LiveSessionsController(repository: LiveSessionRepository());
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

  Future<void> _createSession() async {
    final user = YohPalAuthScope.read(context).user;
    if (user == null) return;
    final result = await showDialog<_NewSessionInput>(
      context: context,
      builder: (_) => const _NewSessionDialog(),
    );
    if (result == null) return;
    final created = await _controller.create(
      creatorId: user.uid,
      title: result.title,
      description: result.description,
      category: result.category,
      streamMode: result.streamMode,
    );
    if (!mounted) return;
    if (created is Failure<LiveSession>) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(created.failure.message)));
    }
  }

  Future<void> _startSession(LiveSession session) async {
    final user = YohPalAuthScope.read(context).user;
    if (user == null) return;
    await _controller.start(session.id, user.uid);
  }

  Future<void> _endSession(LiveSession session) async {
    final user = YohPalAuthScope.read(context).user;
    if (user == null) return;
    await _controller.end(session.id, user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final user = YohPalAuthScope.of(context).user;
        return Scaffold(
          appBar: AppBar(
            title: const Text('AI Multistreaming'),
            actions: [
              if (user?.role.canViewCommandCenter == true)
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CommandCenterDashboardScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings),
                  tooltip: 'Command Center',
                ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SocialConnectorsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.link),
                tooltip: 'Social Connectors',
              ),
              IconButton(
                onPressed: _createSession,
                icon: const Icon(Icons.add),
                tooltip: 'Create live session',
              ),
            ],
          ),

          body: _buildBody(),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _createSession,
            icon: const Icon(Icons.add),
            label: const Text('New Live'),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const YohPalLoading(message: 'Loading live sessions...');
    }
    if (_controller.failure != null) {
      return YohPalErrorView(message: _controller.failure!.message);
    }
    if (_controller.sessions.isEmpty) {
      return const Center(
        child: Text('No live sessions yet. Create your first AI multistream.'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _controller.sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final session = _controller.sessions[index];
        return Card(
          child: ListTile(
            title: Text(session.title),
            subtitle: Text(
              '${session.category} • ${session.status} • ${session.streamMode}',
            ),
            leading: Icon(
              session.status == 'live'
                  ? Icons.radio_button_checked
                  : Icons.video_camera_front_outlined,
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'start') {
                  _startSession(session);
                }
                if (value == 'end') {
                  _endSession(session);
                }
                if (value == 'destinations') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          SessionDestinationsScreen(session: session),
                    ),
                  );
                }
                if (value == 'control') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StreamControlScreen(session: session),
                    ),
                  );
                }
                if (value == 'campaigns') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CampaignManagerScreen(session: session),
                    ),
                  );
                }
                if (value == 'funnel') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FunnelInsightsScreen(session: session),
                    ),
                  );
                }
                if (value == 'revenue') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreatorRevenueDashboardScreen(),
                    ),
                  );
                }
                if (value == 'growth') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreatorGrowthDashboardScreen(),
                    ),
                  );
                }
                if (value == 'autonomy') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AutonomyControlScreen(),
                    ),
                  );
                }
                if (value == 'clips') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ClipFactoryScreen(
                        sessionId: session.id,
                        sessionTitle: session.title,
                      ),
                    ),
                  );
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'destinations',
                  child: Text('Destinations'),
                ),
                const PopupMenuItem(
                  value: 'control',
                  child: Text('Stream Control'),
                ),
                const PopupMenuItem(
                  value: 'campaigns',
                  child: Text('Campaign Links'),
                ),
                const PopupMenuItem(
                  value: 'funnel',
                  child: Text('Funnel Insights'),
                ),
                const PopupMenuItem(
                  value: 'revenue',
                  child: Text('Revenue Dashboard'),
                ),
                const PopupMenuItem(
                  value: 'growth',
                  child: Text('Growth Autopilot'),
                ),
                const PopupMenuItem(
                  value: 'autonomy',
                  child: Text('AI Autonomy Control'),
                ),
                const PopupMenuItem(
                  value: 'clips',
                  child: Text('Clip Factory'),
                ),
                const PopupMenuItem(value: 'start', child: Text('Start')),
                const PopupMenuItem(value: 'end', child: Text('End')),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SessionDestinationsScreen(session: session),
                ),
              );
            },
          ),
        );
      },
    );
  }
}





class _NewSessionInput {
  const _NewSessionInput({
    required this.title,
    required this.description,
    required this.category,
    required this.streamMode,
  });

  final String title;
  final String description;
  final String category;
  final String streamMode;
}

class _NewSessionDialog extends StatefulWidget {
  const _NewSessionDialog();

  @override
  State<_NewSessionDialog> createState() => _NewSessionDialogState();
}

class _NewSessionDialogState extends State<_NewSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _category = TextEditingController(text: 'creator');
  String _streamMode = 'teaser';

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _category.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _NewSessionInput(
        title: _title.text.trim(),
        description: _description.text.trim(),
        category: _category.text.trim(),
        streamMode: _streamMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Live Session'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              DropdownButtonFormField<String>(
                value: _streamMode,
                decoration: const InputDecoration(labelText: 'Stream mode'),
                items: const [
                  DropdownMenuItem(value: 'full', child: Text('Full mirror')),
                  DropdownMenuItem(value: 'teaser', child: Text('Teaser')),
                  DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _streamMode = value);
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
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }
}
