import 'package:flutter/material.dart';
import '../../../core/auth/yohpal_auth_scope.dart';
import '../../../core/models/result.dart';
import '../../../shared/widgets/yohpal_error_view.dart';
import '../../../shared/widgets/yohpal_loading.dart';
import '../application/creator_profile_controller.dart';
import '../data/creator_profile_repository.dart';
import '../domain/creator_profile.dart';

class CreatorProfileScreen extends StatefulWidget {
  const CreatorProfileScreen({super.key});

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  late final CreatorProfileController _controller;
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _handle = TextEditingController();
  final _category = TextEditingController();
  final _bio = TextEditingController();
  bool _initializedForm = false;

  @override
  void initState() {
    super.initState();
    _controller = CreatorProfileController(
      repository: CreatorProfileRepository(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = YohPalAuthScope.read(context).user;
      if (user != null) {
        _controller.load(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _displayName.dispose();
    _handle.dispose();
    _category.dispose();
    _bio.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _syncForm(CreatorProfile? profile) {
    if (_initializedForm || profile == null) return;
    _displayName.text = profile.displayName;
    _handle.text = profile.handle;
    _category.text = profile.category;
    _bio.text = profile.bio;
    _initializedForm = true;
  }

  Future<void> _save() async {
    final user = YohPalAuthScope.read(context).user;
    if (user == null) return;
    if (!_formKey.currentState!.validate()) return;
    final profile = CreatorProfile(
      id: _controller.profile?.id ?? '',
      uid: user.uid,
      displayName: _displayName.text.trim(),
      handle: _handle.text.trim(),
      category: _category.text.trim(),
      bio: _bio.text.trim(),
      verificationStatus: _controller.profile?.verificationStatus ?? 'pending',
      monetisationEnabled: _controller.profile?.monetisationEnabled ?? false,
      riskScore: _controller.profile?.riskScore ?? 0,
      createdAt: _controller.profile?.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
    final result = await _controller.save(profile);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (result is Success<CreatorProfile>) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Creator profile saved.')),
      );
    } else if (result is Failure<CreatorProfile>) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.failure.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isLoading && _controller.profile == null) {
          return const YohPalLoading(message: 'Loading creator profile...');
        }
        if (_controller.failure != null && _controller.profile == null) {
          return YohPalErrorView(
            message: _controller.failure!.message,
            onRetry: () {
              final user = YohPalAuthScope.read(context).user;
              if (user != null) _controller.load(user.uid);
            },
          );
        }
        _syncForm(_controller.profile);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Creator Profile'),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Set up your creator identity for YohPal Live.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _displayName,
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Display name is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _handle,
                        decoration: const InputDecoration(
                          labelText: 'Creator handle',
                          prefixText: '@',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Handle is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          hintText: 'Music, comedy, education, commerce...',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bio,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _controller.isLoading ? null : _save,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Profile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
