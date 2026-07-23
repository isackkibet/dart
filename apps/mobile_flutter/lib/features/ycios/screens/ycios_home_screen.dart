import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../design_system/tokens/yohpal_brand_colors.dart';
import '../controllers/ycios_controller.dart';
import '../models/ycios_project_model.dart';
import '../repositories/ycios_repository.dart';
import 'ycios_project_detail_screen.dart';

class YciosHomeScreen extends StatelessWidget {
  const YciosHomeScreen({super.key});

  static const routeName = '/ycios';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Sign in to use YCIOS',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [YohPalBrandColors.gold, YohPalBrandColors.deepGold],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: YohPalBrandColors.black, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              'YCIOS Workspace',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.archive_outlined,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            tooltip: 'Archived projects',
            onPressed: () => Navigator.pushNamed(context, '/ycios-archived'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.colorScheme.primary,
        onPressed: () => _createProject(context),
        icon: Icon(Icons.add, color: theme.colorScheme.onPrimary),
        label: Text('New Project',
            style: TextStyle(color: theme.colorScheme.onPrimary)),
      ),
      body: StreamBuilder<List<YciosProjectModel>>(
        stream: context.read<YciosRepository>().watchProjects(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final projects = snapshot.data ?? [];
          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.movie_creation_outlined,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No YCIOS projects yet.',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create your first AI project.',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return _ProjectCard(
                project: project,
                onTap: () => Navigator.pushNamed(
                  context,
                  YciosProjectDetailScreen.routeName,
                  arguments: project,
                ),
                onArchive: () =>
                    context.read<YciosController>().archiveProject(project.id),
                onDuplicate: () => context
                    .read<YciosController>()
                    .duplicateProject(project.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _createProject(BuildContext context) async {
    final theme = Theme.of(context);
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'New YCIOS Project',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary),
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              final nav = Navigator.of(context);
              await context
                  .read<YciosController>()
                  .createProject(title, descCtrl.text.trim());
              if (context.mounted) nav.pop();
            },
            child: Text('Create',
                style: TextStyle(color: theme.colorScheme.onPrimary)),
          ),
        ],
      ),
    );
    titleCtrl.dispose();
    descCtrl.dispose();
  }
}

class _ProjectCard extends StatelessWidget {
  final YciosProjectModel project;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onDuplicate;

  const _ProjectCard({
    required this.project,
    required this.onTap,
    required this.onArchive,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [YohPalBrandColors.gold, YohPalBrandColors.deepGold],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.movie_creation_outlined,
              color: YohPalBrandColors.black, size: 22),
        ),
        title: Text(
          project.title,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600),
        ),
        subtitle: project.description.isNotEmpty
            ? Text(
                project.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              )
            : null,
        trailing: PopupMenuButton<String>(
          color: Theme.of(context).colorScheme.surface,
          icon: Icon(
            Icons.more_vert,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          onSelected: (value) {
            if (value == 'archive') onArchive();
            if (value == 'duplicate') onDuplicate();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
            PopupMenuItem(value: 'archive', child: Text('Archive')),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
