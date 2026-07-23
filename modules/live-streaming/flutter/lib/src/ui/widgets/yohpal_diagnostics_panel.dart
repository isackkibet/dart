import 'package:flutter/material.dart';

import '../../models/yohpal_streaming_state.dart';
import '../yohpal_live_theme.dart';

class YohPalDiagnosticsPanel extends StatelessWidget {
  final YohPalStreamingState state;

  const YohPalDiagnosticsPanel({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: YohPalLiveTheme.panelDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Diagnostics',
            style: TextStyle(
              color: YohPalLiveTheme.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _row('Phase', state.phase.name),
          _row('Message', state.message ?? 'None'),
          _row('Viewers', state.viewerCount.toString()),
          _row('Error', state.error?.toString() ?? 'None'),
          const SizedBox(height: 10),
          _row('Is Live', state.isLive.toString()),
          _row('Is Busy', state.isBusy.toString()),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: YohPalLiveTheme.muted,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: YohPalLiveTheme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
