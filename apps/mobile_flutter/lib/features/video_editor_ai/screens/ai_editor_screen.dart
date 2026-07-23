import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/ai_editor_controller.dart';
import '../models/ai_publish_status.dart';
import '../models/ai_thumbnail_idea.dart';
import '../models/ai_video_job.dart';
import '../repositories/ai_publish_repository.dart';
import '../widgets/ai_publish_checklist.dart';
import '../widgets/thumbnail_idea_selector.dart';

class AiEditorScreen extends StatefulWidget {
  final String videoId;

  static const routeName = '/ai-editor';

  const AiEditorScreen({super.key, required this.videoId});

  @override
  State<AiEditorScreen> createState() => _AiEditorScreenState();
}

class _AiEditorScreenState extends State<AiEditorScreen> {
  final _topic = TextEditingController();
  final _caption = TextEditingController();
  final _title = TextEditingController();
  final _description = TextEditingController();

  bool _captionsGenerated = false;
  bool _hooksGenerated = false;
  bool _hashtagsGenerated = false;
  bool _thumbnailSelected = false;
  bool _viralScoreReviewed = false;
  AiThumbnailIdea? _selectedThumbnail;

  @override
  void dispose() {
    _topic.dispose();
    _caption.dispose();
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  void _markDone(String jobType) {
    if (!mounted) return;
    setState(() {
      switch (jobType) {
        case 'captions':
          _captionsGenerated = true;
        case 'hooks':
          _hooksGenerated = true;
        case 'hashtags':
          _hashtagsGenerated = true;
        case 'viral_score':
          _viralScoreReviewed = true;
        case 'thumbnail_ideas':
          _thumbnailSelected =
              true; // auto-tick when ideas arrive; user can still pick one
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AiEditorController>();
    final allDone = _captionsGenerated &&
        _hooksGenerated &&
        _hashtagsGenerated &&
        _thumbnailSelected &&
        _viralScoreReviewed;

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        title: const Text('AI Creator Studio'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Enhance your video with AI before publishing.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          _field(_topic, 'Video topic'),
          const SizedBox(height: 12),
          _field(_caption, 'Draft caption'),
          const SizedBox(height: 12),
          _field(_title, 'Title'),
          const SizedBox(height: 12),
          _field(_description, 'Description', maxLines: 3),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _AiButton(
                label: 'AI Captions',
                loading: ctrl.loading,
                onPressed: () => ctrl.runCaptions(
                  userId: _uid,
                  videoId: widget.videoId,
                  language: 'en',
                ),
              ),
              _AiButton(
                label: 'AI Hooks',
                loading: ctrl.loading,
                onPressed: () => ctrl.runHooks(
                  userId: _uid,
                  videoId: widget.videoId,
                  topic: _topic.text,
                ),
              ),
              _AiButton(
                label: 'AI Hashtags',
                loading: ctrl.loading,
                onPressed: () => ctrl.runHashtags(
                  userId: _uid,
                  videoId: widget.videoId,
                  caption: _caption.text,
                ),
              ),
              _AiButton(
                label: 'Viral Score',
                loading: ctrl.loading,
                onPressed: () => ctrl.runViralScore(
                  userId: _uid,
                  videoId: widget.videoId,
                  title: _title.text,
                  description: _description.text,
                ),
              ),
              _AiButton(
                label: 'Thumbnail Ideas',
                loading: ctrl.loading,
                onPressed: () => ctrl.runThumbnailIdeas(
                  userId: _uid,
                  videoId: widget.videoId,
                  topic: _topic.text,
                ),
              ),
              _AiButton(
                label: 'Trim Suggestions',
                loading: ctrl.loading,
                onPressed: () => ctrl.runTrimSuggestions(
                  userId: _uid,
                  videoId: widget.videoId,
                  description: _description.text,
                ),
              ),
            ],
          ),
          if (ctrl.error != null) ...[
            const SizedBox(height: 12),
            Text(ctrl.error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 20),
          if (ctrl.activeJobId != null)
            StreamBuilder<AiVideoJob?>(
              stream: ctrl.watchActiveJob(),
              builder: (context, snap) {
                final job = snap.data;
                if (job == null) {
                  return const _JobCard(
                      child: _SpinnerRow('Waiting for AI job…'));
                }
                if (job.status == 'processing') {
                  return const _JobCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI is processing your request…',
                            style: TextStyle(color: Colors.white70)),
                        SizedBox(height: 10),
                        LinearProgressIndicator(),
                      ],
                    ),
                  );
                }
                if (job.status == 'failed') {
                  return _JobCard(
                    child: Text(
                      job.error ?? 'AI job failed',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                // Completed — mark checklist
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _markDone(job.type);
                });

                final items = List<String>.from(job.result['items'] ?? []);
                final score = job.result['score'];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _JobCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                job.type.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.check_circle,
                                  color: Color(0xFF22c55e), size: 16),
                              const SizedBox(width: 4),
                              const Text(
                                'completed',
                                style: TextStyle(
                                  color: Color(0xFF22c55e),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(color: Colors.white12),
                          if (score != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Viral Score: ',
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 12)),
                                Text(
                                  '$score / 100',
                                  style: const TextStyle(
                                    color: Color(0xFF00D9FF),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              job.result['explanation']?.toString() ?? '',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ] else if (job.type == 'thumbnail_ideas') ...[
                            const SizedBox(height: 8),
                            ThumbnailIdeaSelector(
                              ideas:
                                  items.map(AiThumbnailIdea.fromText).toList(),
                              selected: _selectedThumbnail,
                              onSelect: (idea) {
                                setState(() {
                                  _selectedThumbnail = idea;
                                  _thumbnailSelected = true;
                                });
                                ctrl.applyThumbnailToVideo(
                                  videoId: widget.videoId,
                                  thumbnailIdea: idea,
                                );
                              },
                            ),
                          ] else if (items.isNotEmpty)
                            ...items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '• $item',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13),
                                ),
                              ),
                            )
                          else
                            Text(
                              job.result['text']?.toString() ?? '${job.result}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                            ),
                        ],
                      ),
                    ),

                    // Apply buttons
                    const SizedBox(height: 10),
                    if (job.type == 'captions' && items.isNotEmpty)
                      _ApplyButton(
                        label: 'Apply Caption to Video',
                        loading: ctrl.loading,
                        onPressed: () => ctrl.applyCaptionToVideo(
                          videoId: widget.videoId,
                          caption: items.first,
                        ),
                      ),
                    if (job.type == 'hashtags' && items.isNotEmpty)
                      _ApplyButton(
                        label: 'Apply Hashtags to Video',
                        loading: ctrl.loading,
                        onPressed: () => ctrl.applyHashtagsToVideo(
                          videoId: widget.videoId,
                          hashtags: items,
                        ),
                      ),
                    if (job.type == 'viral_score' && score != null)
                      _ApplyButton(
                        label: 'Save Viral Score',
                        loading: ctrl.loading,
                        onPressed: () => ctrl.applyViralScoreToVideo(
                          videoId: widget.videoId,
                          score: score is int ? score : (score as num).toInt(),
                          explanation:
                              job.result['explanation']?.toString() ?? '',
                        ),
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: 24),
          AiPublishChecklist(
            captionsGenerated: _captionsGenerated,
            hooksGenerated: _hooksGenerated,
            hashtagsGenerated: _hashtagsGenerated,
            thumbnailSelected: _thumbnailSelected,
            viralScoreReviewed: _viralScoreReviewed,
          ),
          const SizedBox(height: 16),
          // Backed by the persisted aiPublishStatus field (not local widget
          // state) so this doesn't reset if the creator navigates away and
          // back — see PublishEligibility.
          StreamBuilder<AiPublishStatus>(
            stream: context
                .read<AiPublishRepository>()
                .watchAiPublishStatus(widget.videoId),
            builder: (context, snapshot) {
              final eligibility = PublishEligibility(
                aiPublishStatus: snapshot.data ?? AiPublishStatus.notReady,
              );
              final alreadyReady = eligibility.canPublish;
              final canMarkReady = allDone && !alreadyReady;

              return ElevatedButton.icon(
                icon: Icon(
                  alreadyReady
                      ? Icons.check_circle
                      : allDone
                          ? Icons.rocket_launch
                          : Icons.lock_outline,
                ),
                label: Text(
                  alreadyReady
                      ? 'Ready for Publishing'
                      : 'Mark Ready for Publishing',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: alreadyReady
                      ? const Color(0xFF22c55e)
                      : allDone
                          ? const Color(0xFF22c55e)
                          : Colors.white24,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: canMarkReady
                    ? () => ctrl.markReadyForPublishing(widget.videoId)
                    : null,
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF00D9FF)),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Widget child;
  const _JobCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF101527),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _SpinnerRow extends StatelessWidget {
  final String label;
  const _SpinnerRow(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _AiButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _AiButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00D9FF),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      onPressed: loading ? null : onPressed,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _ApplyButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.check, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF22c55e),
        side: const BorderSide(color: Color(0xFF22c55e)),
      ),
      onPressed: loading ? null : onPressed,
    );
  }
}
