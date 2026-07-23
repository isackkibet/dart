import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../design_system/tokens/yohpal_brand_colors.dart';
import '../../../design_system/widgets/yohpal_brand_mark.dart';
import '../controllers/auth_controller.dart';
import '../widgets/sso_button_row.dart';
import '../widgets/sso_divider.dart';
import 'terms_and_conditions_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  static const routeName = '/signup';

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  late final TapGestureRecognizer _termsTapRecognizer;

  String? _localError;
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _termsTapRecognizer = TapGestureRecognizer()..onTap = _openTerms;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _termsTapRecognizer.dispose();
    super.dispose();
  }

  void _openTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen()),
    );
  }

  Future<void> _submit() async {
    if (_password.text != _confirmPassword.text) {
      setState(() => _localError = 'Passwords do not match.');
      return;
    }
    if (!_acceptedTerms) {
      setState(
        () => _localError = 'You must accept the Terms & Conditions to continue.',
      );
      return;
    }
    setState(() => _localError = null);

    final displayName =
        '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim();

    final controller = context.read<AuthController>();
    final ok = await controller.signup(
      displayName: displayName,
      email: _email.text,
      password: _password.text,
    );
    if (ok && mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  InputDecoration _fieldDecoration(BuildContext context, String label) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: theme.cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: YohPalBrandColors.gold.withValues(alpha: 0.18),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: YohPalBrandColors.gold, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final displayError = _localError ?? auth.error;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: YohPalBrandMark()),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _firstName,
                        style: TextStyle(color: onSurface),
                        decoration: _fieldDecoration(context, 'First name'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _lastName,
                        style: TextStyle(color: onSurface),
                        decoration: _fieldDecoration(context, 'Last name'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: onSurface),
                  decoration: _fieldDecoration(context, 'Email'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  obscureText: true,
                  style: TextStyle(color: onSurface),
                  decoration: _fieldDecoration(context, 'Password'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmPassword,
                  obscureText: true,
                  style: TextStyle(color: onSurface),
                  decoration: _fieldDecoration(context, 'Confirm password'),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _acceptedTerms,
                      shape: const CircleBorder(),
                      onChanged: (value) =>
                          setState(() => _acceptedTerms = value ?? false),
                    ),
                    Expanded(
                      // Only the "Terms & Conditions" span carries a tap
                      // recognizer (opens the terms page) — the rest of the
                      // label is plain text. Wrapping the whole thing in a
                      // second, outer tap handler to also toggle the
                      // checkbox would put two recognizers in the same
                      // gesture arena and both would fire on a single tap.
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.75),
                            fontSize: 13,
                          ),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: const TextStyle(
                                color: YohPalBrandColors.gold,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: YohPalBrandColors.gold,
                              ),
                              recognizer: _termsTapRecognizer,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (displayError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    displayError,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: auth.loading ? null : _submit,
                    child: Text(auth.loading ? 'Creating...' : 'Create Account'),
                  ),
                ),
                const SizedBox(height: 22),
                const SsoDivider(),
                const SizedBox(height: 18),
                const SsoButtonRow(),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Already have an account? Sign in'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
