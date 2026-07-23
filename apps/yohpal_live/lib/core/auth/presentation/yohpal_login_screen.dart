import 'package:flutter/material.dart';
import '../../../shared/widgets/yohpal_loading.dart';
import '../yohpal_auth_scope.dart';

class YohPalLoginScreen extends StatefulWidget {
  const YohPalLoginScreen({
    super.key,
    this.onLoggedIn,
  });

  final VoidCallback? onLoggedIn;

  @override
  State<YohPalLoginScreen> createState() => _YohPalLoginScreenState();
}

class _YohPalLoginScreenState extends State<YohPalLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = YohPalAuthScope.read(context);
    final result = await auth.login(
      email: _email.text.trim(),
      password: _password.text,
    );
    if (!mounted) return;
    if (result.isSuccess) {
      widget.onLoggedIn?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.failureOrNull?.message ?? 'Login failed.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = YohPalAuthScope.of(context);
    if (auth.isLoading) {
      return const YohPalLoading(message: 'Signing in...');
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login to YohPal Live'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                Text(
                  'YohPal Live Creator Access',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Login to manage multistreaming, creator growth, revenue, and command center access.',
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                        ),
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return 'Enter a valid email.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _submit,
                          child: const Text('Login'),
                        ),
                      ),
                    ],
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
