import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  static const routeName = '/terms-and-conditions';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final bodyStyle = TextStyle(
      color: onSurface.withValues(alpha: 0.85),
      fontSize: 14.5,
      height: 1.5,
    );
    final headingStyle = TextStyle(
      color: onSurface,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    Widget section(String title, String body) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: headingStyle),
            const SizedBox(height: 8),
            Text(body, style: bodyStyle),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Terms & Conditions'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Last updated: July 2026',
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            section(
              '1. Acceptance of terms',
              'By creating a YohPal Live account, you agree to be bound by these '
                  'Terms & Conditions and our Privacy Policy. If you do not agree, '
                  'you should not create an account or use the app.',
            ),
            section(
              '2. Your account',
              'You are responsible for the accuracy of the information you '
                  'provide and for keeping your login credentials secure. You must '
                  'be at least 13 years old to use YohPal Live, or the minimum age '
                  'required in your country.',
            ),
            section(
              '3. Content & conduct',
              'You retain ownership of the videos and content you upload. By '
                  'posting content, you grant YohPal Live a license to host, '
                  'display, and distribute it within the app. You agree not to '
                  'upload content that is illegal, infringing, or violates the '
                  'rights of others, and to follow community guidelines during '
                  'live streams and chat.',
            ),
            section(
              '4. Wallet, gifts & payments',
              'Wallet top-ups, withdrawals, gifting, and subscriptions are '
                  'processed through YohPal Web and associated payment partners. '
                  'Gift and reward values are set by YohPal Live and may change. '
                  'You are responsible for any charges incurred through your '
                  'account.',
            ),
            section(
              '5. Live streaming',
              'When you go live, your video and audio are broadcast to other '
                  'users in real time. You are responsible for what you say and '
                  'show while live, including compliance with local law.',
            ),
            section(
              '6. Termination',
              'We may suspend or terminate your account if you violate these '
                  'terms, engage in fraudulent activity, or misuse the platform. '
                  'You may stop using YohPal Live and request account deletion at '
                  'any time.',
            ),
            section(
              '7. Changes to these terms',
              'We may update these Terms & Conditions from time to time. '
                  'Continued use of YohPal Live after a change takes effect means '
                  'you accept the updated terms.',
            ),
            section(
              '8. Contact us',
              'If you have questions about these terms, contact YohPal Live '
                  'support from within the app.',
            ),
          ],
        ),
      ),
    );
  }
}
