import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/creator_profile_repository.dart';
import '../services/creator_avatar_service.dart';

class EditCreatorProfileScreen extends StatefulWidget {
  final String creatorUid;

  const EditCreatorProfileScreen({
    super.key,
    required this.creatorUid,
  });

  static const routeName = '/creator-profile/edit';

  @override
  State<EditCreatorProfileScreen> createState() =>
      _EditCreatorProfileScreenState();
}

class _EditCreatorProfileScreenState extends State<EditCreatorProfileScreen> {
  final _displayName = TextEditingController();
  final _bio = TextEditingController();
  final _avatarService = CreatorAvatarService();
  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _avatarUrl;
  String? _error;

  Future<void> _pickAndUploadAvatar() async {
    setState(() {
      _uploadingAvatar = true;
      _error = null;
    });
    try {
      final url = await _avatarService.pickAndUpload();
      if (url != null && mounted) {
        setState(() => _avatarUrl = url);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<CreatorProfileRepository>().updateProfile(
            uid: widget.creatorUid,
            displayName: _displayName.text.trim(),
            bio: _bio.text.trim(),
            photoUrl: _avatarUrl ?? '',
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _displayName.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        title: const Text('Edit Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: _displayName,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Display name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bio,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Bio'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white12,
                backgroundImage:
                    _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                child: _avatarUrl == null
                    ? const Icon(Icons.person, color: Colors.white38, size: 36)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _uploadingAvatar ? null : _pickAndUploadAvatar,
                  icon: _uploadingAvatar
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_camera_outlined),
                  label: Text(
                    _uploadingAvatar ? 'Uploading...' : 'Change avatar',
                  ),
                ),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.redAccent)),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save Profile'),
          ),
        ],
      ),
    );
  }
}
