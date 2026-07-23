import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../controllers/video_upload_controller.dart';
import '../services/video_draft_service.dart';
import 'video_processing_status_screen.dart';

/// Reviews a recorded/picked video and collects the publish form (title,
/// caption, hashtags) in a persistent bottom sheet before publishing it
/// through the existing upload pipeline.
class VideoPreviewScreen extends StatefulWidget {
  final File file;
  final String initialTitle;
  final String initialCaption;
  final List<String> initialHashtags;

  const VideoPreviewScreen({
    super.key,
    required this.file,
    this.initialTitle = '',
    this.initialCaption = '',
    this.initialHashtags = const [],
  });

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late final VideoPlayerController _player;
  final _draftService = VideoDraftService();
  late final TextEditingController _title;
  late final TextEditingController _caption;
  late final TextEditingController _hashtags;
  String? _validationError;
  bool _published = false;

  @override
  void initState() {
    super.initState();
    // This screen owns a fresh file; don't inherit error/success state from
    // an unrelated earlier upload attempt (VideoUploadController is a
    // singleton for the app's lifetime).
    context.read<VideoUploadController>().reset();
    _title = TextEditingController(text: widget.initialTitle);
    _caption = TextEditingController(text: widget.initialCaption);
    _hashtags = TextEditingController(text: widget.initialHashtags.join(', '));
    _player = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _player
          ..setLooping(true)
          ..play();
      });
  }

  @override
  void dispose() {
    _player.dispose();
    _title.dispose();
    _caption.dispose();
    _hashtags.dispose();
    super.dispose();
  }

  List<String> get _hashtagList => _hashtags.text
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .map((t) => t.startsWith('#') ? t.substring(1) : t)
      .toList();

  Future<void> _saveDraftIfUnpublished() async {
    if (_published) return;
    await _draftService.save(
      VideoDraft(
        localFilePath: widget.file.path,
        title: _title.text,
        caption: _caption.text,
        hashtags: _hashtagList,
        savedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _publish() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_title.text.trim().isEmpty) {
      setState(() => _validationError = 'Title is required.');
      return;
    }
    setState(() => _validationError = null);

    final controller = context.read<VideoUploadController>();
    await controller.uploadVideo(
      file: widget.file,
      userId: user.uid,
      title: _title.text.trim(),
      caption: _caption.text.trim(),
      hashtags: _hashtagList,
    );

    if (!mounted) return;
    if (controller.uploadedVideoId != null) {
      _published = true;
      await _draftService.clear();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VideoProcessingStatusScreen(
            videoId: controller.uploadedVideoId!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final upload = context.watch<VideoUploadController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _saveDraftIfUnpublished();
        if (!context.mounted) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF050816),
        appBar: AppBar(
          backgroundColor: const Color(0xFF050816),
          title: const Text('Preview'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _saveDraftIfUnpublished();
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Center(
          child: _player.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _player.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      VideoPlayer(_player),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _player.value.isPlaying
                                ? _player.pause()
                                : _player.play();
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: _player.value.isPlaying
                              ? null
                              : const Icon(Icons.play_arrow,
                                  color: Colors.white70, size: 64),
                        ),
                      ),
                      VideoProgressIndicator(
                        _player,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Color(0xFF00D9FF),
                          bufferedColor: Colors.white24,
                          backgroundColor: Colors.white10,
                        ),
                      ),
                    ],
                  ),
                )
              : const CircularProgressIndicator(color: Color(0xFF00D9FF)),
        ),
        bottomSheet: _buildPublishSheet(upload),
      ),
    );
  }

  Widget _buildPublishSheet(VideoUploadController upload) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF101527),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            TextField(
              controller: _title,
              enabled: !upload.uploading,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Title',
                errorText: _validationError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _caption,
              enabled: !upload.uploading,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Caption'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hashtags,
              enabled: !upload.uploading,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Hashtags',
                hintText: 'e.g. dance, comedy, yohpal',
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 18),
            if (upload.uploading) ...[
              LinearProgressIndicator(value: upload.progress),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(upload.progress * 100).toStringAsFixed(0)}% uploading…',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  TextButton(
                    onPressed: () => upload.cancelUpload(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ] else if (upload.error != null) ...[
              Text(
                upload.error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => upload.retryUpload(),
                  child: const Text('Retry'),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _publish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D9FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Publish'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
