import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/ycios_controller.dart';
import '../models/ycios_asset_model.dart';
import '../models/ycios_project_model.dart';
import '../models/ycios_render_job_model.dart';
import '../repositories/ycios_repository.dart';

class YciosProjectDetailScreen extends StatelessWidget {
  static const routeName = '/ycios-project';

  final YciosProjectModel project;

  const YciosProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          title: Text(
            project.title,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor:
                theme.colorScheme.onSurface.withValues(alpha: 0.5),
            indicatorColor: theme.colorScheme.primary,
            tabs: [
              Tab(text: 'Assets'),
              Tab(text: 'Renders'),
              Tab(text: 'Agents'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: theme.colorScheme.primary,
          onPressed: () => _showAgentCommandBox(context),
          icon: Icon(Icons.auto_awesome, color: theme.colorScheme.onPrimary),
          label: Text('Ask Agent',
              style: TextStyle(color: theme.colorScheme.onPrimary)),
        ),
        body: TabBarView(
          children: [
            _AssetsTab(projectId: project.id, creatorId: project.creatorId),
            _RendersTab(projectId: project.id),
            _AgentsTab(project: project),
          ],
        ),
      ),
    );
  }

  Future<void> _showAgentCommandBox(BuildContext context) async {
    final theme = Theme.of(context);
    final promptCtrl = TextEditingController();
    String selectedAgent = 'CaptionAgent';
    const agents = [
      'CaptionAgent',
      'ThumbnailAgent',
      'StoryAgent',
      'DirectorAgent',
      'EditorAgent',
      'CommerceAgent',
      'GrowthAgent',
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Command an AI Agent',
                style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedAgent,
                dropdownColor: theme.colorScheme.surface,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Agent',
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                items: agents
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => selectedAgent = v ?? agents[0]),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: promptCtrl,
                maxLines: 3,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText:
                      '"Make this cinematic", "Generate captions", "Suggest products"…',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    fontSize: 12,
                  ),
                  labelText: 'Prompt',
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary),
                  icon: Icon(Icons.send,
                      color: theme.colorScheme.onPrimary, size: 18),
                  label: Text('Dispatch',
                      style: TextStyle(color: theme.colorScheme.onPrimary)),
                  onPressed: () async {
                    final prompt = promptCtrl.text.trim();
                    if (prompt.isEmpty) return;
                    final nav = Navigator.of(ctx);
                    await context.read<YciosController>().askAgent(
                          projectId: project.id,
                          agentType: selectedAgent,
                          prompt: prompt,
                        );
                    if (context.mounted) nav.pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    promptCtrl.dispose();
  }
}

// ── Assets Tab ────────────────────────────────────────────────────────────────

class _AssetsTab extends StatelessWidget {
  final String projectId;
  final String creatorId;
  const _AssetsTab({required this.projectId, required this.creatorId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<YciosAssetModel>>(
      stream: context.read<YciosRepository>().watchProjectAssets(
            creatorId: creatorId,
            projectId: projectId,
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final assets = snapshot.data ?? [];
        if (assets.isEmpty) {
          return const Center(
            child: Text(
              'No assets yet. Upload or link assets to this project.',
              style: TextStyle(color: Colors.white38),
              textAlign: TextAlign.center,
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: assets.length,
          itemBuilder: (_, i) => _AssetCard(asset: assets[i]),
        );
      },
    );
  }
}

class _AssetCard extends StatelessWidget {
  final YciosAssetModel asset;
  const _AssetCard({required this.asset});

  IconData get _icon {
    switch (asset.type) {
      case 'video':
        return Icons.videocam_outlined;
      case 'audio':
        return Icons.audiotrack_outlined;
      case 'image':
        return Icons.image_outlined;
      case 'prompt':
        return Icons.psychology_outlined;
      case 'template':
        return Icons.dashboard_customize_outlined;
      default:
        return Icons.auto_awesome_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12121F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_icon, color: const Color(0xFF6C3FF7), size: 32),
          const SizedBox(height: 8),
          Text(
            asset.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            asset.type,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ── Renders Tab ───────────────────────────────────────────────────────────────

class _RendersTab extends StatelessWidget {
  final String projectId;
  const _RendersTab({required this.projectId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF6C3FF7))),
              icon: const Icon(Icons.add, color: Color(0xFF6C3FF7)),
              label: const Text('Queue Render Job',
                  style: TextStyle(color: Color(0xFF6C3FF7))),
              onPressed: () async {
                await context.read<YciosRepository>().enqueueRenderJob(
                      projectId: projectId,
                      jobType: 'render',
                    );
              },
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<YciosRenderJobModel>>(
            stream: context.read<YciosRepository>().watchRenderJobs(user.uid),
            builder: (context, snapshot) {
              final jobs = (snapshot.data ?? [])
                  .where((j) => j.projectId == projectId)
                  .toList();
              if (jobs.isEmpty) {
                return const Center(
                  child: Text(
                    'No render jobs yet.',
                    style: TextStyle(color: Colors.white38),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: jobs.length,
                itemBuilder: (_, i) => _RenderJobCard(job: jobs[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RenderJobCard extends StatelessWidget {
  final YciosRenderJobModel job;
  const _RenderJobCard({required this.job});

  Color get _statusColor {
    switch (job.status) {
      case 'completed':
        return Colors.greenAccent;
      case 'failed':
        return Colors.redAccent;
      case 'processing':
        return const Color(0xFF3FBCFF);
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF12121F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job.status.toUpperCase(),
                style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                '${job.progress}%',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          if (job.isActive) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: job.progress / 100,
              backgroundColor: Colors.white12,
              color: const Color(0xFF6C3FF7),
            ),
          ],
          if (job.hasFailed && job.error.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              job.error,
              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Agents Tab ────────────────────────────────────────────────────────────────

class _AgentsTab extends StatelessWidget {
  final YciosProjectModel project;
  const _AgentsTab({required this.project});

  static const _agentDefs = [
    (
      'DirectorAgent',
      Icons.movie_outlined,
      'Plans shot lists & visual direction'
    ),
    (
      'ScriptwriterAgent',
      Icons.edit_note,
      'Writes hooks, scripts & narratives'
    ),
    ('EditorAgent', Icons.cut_outlined, 'Edit instructions & timeline cuts'),
    (
      'CaptionAgent',
      Icons.closed_caption_outlined,
      'Auto-captions & subtitles'
    ),
    (
      'ThumbnailAgent',
      Icons.image_outlined,
      'Thumbnail concepts & descriptions'
    ),
    (
      'CommerceAgent',
      Icons.shopping_bag_outlined,
      'Product discovery & tagging'
    ),
    ('GrowthAgent', Icons.trending_up, 'SEO, hashtags & growth tips'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _agentDefs.length,
      itemBuilder: (_, i) {
        final (name, icon, desc) = _agentDefs[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF12121F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF6C3FF7).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF6C3FF7), size: 20),
            ),
            title: Text(name,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text(desc,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
            trailing: const Icon(Icons.play_arrow,
                color: Color(0xFF6C3FF7), size: 20),
            onTap: () => _dispatchAgent(context, name),
          ),
        );
      },
    );
  }

  Future<void> _dispatchAgent(BuildContext context, String agentType) async {
    final promptCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(agentType, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: promptCtrl,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter your prompt…',
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C3FF7)),
            onPressed: () async {
              final prompt = promptCtrl.text.trim();
              if (prompt.isEmpty) return;
              final nav = Navigator.of(context);
              await context.read<YciosController>().askAgent(
                    projectId: project.id,
                    agentType: agentType,
                    prompt: prompt,
                  );
              if (context.mounted) nav.pop();
            },
            child:
                const Text('Dispatch', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    promptCtrl.dispose();
  }
}
