import 'package:flutter/material.dart';

import '../models/video_clip_edit.dart';

/// Bottom sheet for adjusting a clip's trim range. Returns the chosen
/// (startMs, endMs) pair, or null if the sheet was dismissed.
class TrimClipSheet extends StatefulWidget {
  const TrimClipSheet({super.key, required this.clip});

  final VideoClipEdit clip;

  static Future<(int, int)?> show(BuildContext context, VideoClipEdit clip) {
    return showModalBottomSheet<(int, int)>(
      context: context,
      backgroundColor: const Color(0xFF101527),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TrimClipSheet(clip: clip),
    );
  }

  @override
  State<TrimClipSheet> createState() => _TrimClipSheetState();
}

class _TrimClipSheetState extends State<TrimClipSheet> {
  late double _start;
  late double _end;

  @override
  void initState() {
    super.initState();
    _start = widget.clip.trimStartMs.toDouble();
    _end = widget.clip.trimEndMs.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.clip.sourceDurationMs.toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Trim Clip',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(_start / 1000).toStringAsFixed(1)}s – ${(_end / 1000).toStringAsFixed(1)}s '
            '(${((_end - _start) / 1000).toStringAsFixed(1)}s)',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          RangeSlider(
            values: RangeValues(_start, _end),
            min: 0,
            max: max,
            activeColor: const Color(0xFF00D9FF),
            inactiveColor: Colors.white24,
            onChanged: (values) {
              setState(() {
                _start = values.start;
                _end = values.end > values.start + 200
                    ? values.end
                    : (values.start + 200).clamp(0, max);
              });
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D9FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.pop(
                context,
                (_start.round(), _end.round()),
              ),
              child: const Text('Apply Trim'),
            ),
          ),
        ],
      ),
    );
  }
}
