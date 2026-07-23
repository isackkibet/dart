import 'package:flutter/material.dart';

class AiPublishChecklist extends StatelessWidget {
  final bool captionsGenerated;
  final bool hooksGenerated;
  final bool hashtagsGenerated;
  final bool thumbnailSelected;
  final bool viralScoreReviewed;

  const AiPublishChecklist({
    super.key,
    required this.captionsGenerated,
    required this.hooksGenerated,
    required this.hashtagsGenerated,
    required this.thumbnailSelected,
    required this.viralScoreReviewed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF101527),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Publishing Checklist',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            _item('AI Captions generated', captionsGenerated),
            _item('AI Hooks generated', hooksGenerated),
            _item('AI Hashtags generated', hashtagsGenerated),
            _item('Thumbnail idea selected', thumbnailSelected),
            _item('Viral score reviewed', viralScoreReviewed),
          ],
        ),
      ),
    );
  }

  Widget _item(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? const Color(0xFF22c55e) : Colors.white38,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: done ? Colors.white : Colors.white54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
