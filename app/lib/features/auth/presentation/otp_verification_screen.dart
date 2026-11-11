import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP verification is not configured yet. Please contact school support.'),
      ),
    );
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
                hintText: 'Verification code unavailable',
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
                'OTP verification is not configured for this build. Please contact school support.',
                style: const TextStyle(color: Color(0xFF174A9C)),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: null,
                child: const Text('Verify code'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: null,
                child: const Text('Resend code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
