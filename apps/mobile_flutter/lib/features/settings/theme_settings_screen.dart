import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/observability/crashlytics_verification_service.dart';
import '../../core/release/qa_release_identity.dart';
import '../../design_system/theme/yohpal_theme_controller.dart';

/// Lets the user pick System Default / Day Mode / Night Mode for the
/// global YohPal brand theme (gold + black, ivory in Day mode).
class ThemeSettingsScreen extends StatefulWidget {
  static const routeName = '/theme-settings';

  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  bool _devSectionRevealed = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<YohPalThemeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Theme Settings')),
      body: ListView(
        children: [
          RadioGroup<ThemeMode>(
            groupValue: controller.themeMode,
            onChanged: (mode) {
              switch (mode) {
                case ThemeMode.system:
                  controller.setSystem();
                  break;
                case ThemeMode.light:
                  controller.setDay();
                  break;
                case ThemeMode.dark:
                  controller.setNight();
                  break;
                case null:
                  break;
              }
            },
            child: Column(
              children: const [
                RadioListTile<ThemeMode>(
                  title: Text('System Default'),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Day Mode'),
                  subtitle: Text('Bright white and gold experience'),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Night Mode'),
                  subtitle: Text('Black and gold premium experience'),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          // Hidden release-certification entry point — long-press to reveal.
          // Not gated behind kDebugMode: Crashlytics evidence for release
          // certification has to come from an actual release build, which
          // this deliberately stays reachable in. Remove once that evidence
          // has been captured.
          GestureDetector(
            onLongPress: () => setState(() => _devSectionRevealed = true),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Text(
                'YohPal Live',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
          if (_devSectionRevealed) const _CrashlyticsVerificationSection(),
          if (_devSectionRevealed) const SizedBox(height: 16),
          if (_devSectionRevealed) const _QaReleaseIdentityDetails(),
        ],
      ),
    );
  }
}

class _CrashlyticsVerificationSection extends StatelessWidget {
  const _CrashlyticsVerificationSection();

  static const _service = CrashlyticsVerificationService();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Release certification — Crashlytics proof',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              await _service.sendNonFatalVerification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Non-fatal verification event sent.'),
                  ),
                );
              }
            },
            child: const Text('Send non-fatal verification event'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _service.triggerFatalVerification(),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Trigger fatal verification crash'),
          ),
        ],
      ),
    );
  }
}

class _QaReleaseIdentityDetails extends StatelessWidget {
  const _QaReleaseIdentityDetails();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RC2 QA release identity',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _QaDetailRow(label: 'Release tag', value: QaReleaseIdentity.releaseTag),
          _QaDetailRow(label: 'Commit hash', value: QaReleaseIdentity.commitHash),
          _QaDetailRow(label: 'Build ID', value: QaReleaseIdentity.buildId),
          _QaDetailRow(label: 'Environment', value: QaReleaseIdentity.environment),
        ],
      ),
    );
  }
}

class _QaDetailRow extends StatelessWidget {
  const _QaDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'unset' : value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
