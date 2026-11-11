import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_provider.dart';
import 'auth_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestPasswordReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final controller = ref.read(authControllerProvider);
    final available = await controller.requestPasswordReset(
      email: _emailController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final message = available == true
        ? 'If an account exists, password reset instructions will be sent.'
        : available == false
        ? 'Password reset is not configured yet. Please contact support.'
        : controller.state.errorMessage ?? 'Unable to request password reset.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Reset your password',
      subtitle: 'Enter your email to verify your password reset request.',
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FieldLabel(label: 'Email address'),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: (value) => value == null || !value.contains('@')
                  ? 'Enter a valid email address'
                  : null,
              decoration: const InputDecoration(hintText: 'you@example.com'),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _requestPasswordReset,
                child: Text(
                  _isSubmitting
                      ? 'Sending request...'
                      : 'Request password reset',
                ),
              ),
            ),
            const SizedBox(height: 22),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to sign in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
