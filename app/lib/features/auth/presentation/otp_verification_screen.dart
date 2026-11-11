import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_config.dart';
import '../../family/presentation/child_setup_screen.dart';
import '../../trips/presentation/home_screen.dart';
import 'auth_widgets.dart';

enum OtpPurpose { signIn, signUp, passwordReset }

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    required this.email,
    required this.purpose,
    super.key,
  });

  final String email;
  final OtpPurpose purpose;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const _demoCode = '123456';
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String get _title => switch (widget.purpose) {
    OtpPurpose.signIn => 'Verify your sign in',
    OtpPurpose.signUp => 'Verify your email',
    OtpPurpose.passwordReset => 'Verify your email',
  };

  String get _subtitle => switch (widget.purpose) {
    OtpPurpose.signIn => 'Enter the verification code to continue to Edu Ride.',
    OtpPurpose.signUp => 'Confirm your email to finish creating your account.',
    OtpPurpose.passwordReset =>
      'Confirm your email to continue password recovery.',
  };

  void _verify() {
    if (!_formKey.currentState!.validate()) return;
    if (!AppConfig.isDemoMode || _codeController.text != _demoCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That verification code is not correct.')),
      );
      return;
    }

    switch (widget.purpose) {
      case OtpPurpose.signIn:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
        return;
      case OtpPurpose.signUp:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ChildSetupScreen()),
        );
        return;
      case OtpPurpose.passwordReset:
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).popUntil((route) => route.isFirst);
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Email verified. Password reset is not connected to a server yet.',
            ),
          ),
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: _title,
      subtitle: 'Verify ${widget.email}.\n$_subtitle',
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FieldLabel(label: '6-digit code'),
            TextFormField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              validator: (value) => value == null || value.length != 6
                  ? 'Enter the 6-digit code'
                  : null,
              decoration: const InputDecoration(
                hintText: AppConfig.isDemoMode ? '123456' : 'Enter your code',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                AppConfig.isDemoMode
                    ? 'Demo mode: use code 123456. Connect an OTP service before production use.'
                    : 'OTP verification service is not configured for this build.',
                style: const TextStyle(color: Color(0xFF174A9C)),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: AppConfig.isDemoMode ? _verify : null,
                child: const Text('Verify code'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: AppConfig.isDemoMode
                    ? () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Demo code: 123456')),
                      )
                    : null,
                child: const Text('Resend code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
