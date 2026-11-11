import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../family/presentation/child_setup_screen.dart';
import '../../trips/presentation/home_screen.dart';
import 'auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  static const _rememberMeKey = 'auth_remember_me';
  static const _rememberedEmailKey = 'auth_remembered_email';

  bool _isSignUp = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _restoreRememberedEmail();
  }

  Future<void> _restoreRememberedEmail() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;

    final remembered = preferences.getBool(_rememberMeKey) ?? false;
    final email = preferences.getString(_rememberedEmailKey);
    setState(() {
      _rememberMe = remembered;
      if (remembered && email != null && email.isNotEmpty) {
        _emailController.text = email;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider);
    final email = _emailController.text.trim();
    final session = _isSignUp
        ? await controller.signUp(
            name: _nameController.text.trim(),
            email: email,
            password: _passwordController.text,
          )
        : await controller.signIn(
            email: email,
            password: _passwordController.text,
          );

    if (!mounted) return;

    if (session != null) {
      if (!_isSignUp) {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setBool(_rememberMeKey, _rememberMe);
        if (_rememberMe) {
          await preferences.setString(_rememberedEmailKey, email);
        } else {
          await preferences.remove(_rememberedEmailKey);
        }
      }
      if (!mounted) return;

      final destination = _isSignUp
          ? const ChildSetupScreen()
          : const HomeScreen();
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => destination));
      return;
    }

    final message =
        controller.state.errorMessage ??
        (_isSignUp
            ? 'Unable to create your account.'
            : 'Unable to sign in right now.');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showGoogleSignInNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google sign-in is not configured for this app yet.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = ref.watch(authControllerProvider).state.isSubmitting;
    return AuthLayout(
      title: _isSignUp ? 'Create your account' : 'Welcome Back',
      subtitle: _isSignUp
          ? 'A steadier rhythm starts here.'
          : 'Sign in to continue your school journey.',
      footer: _isSignUp ? null : _buildGoogleSignInButton(),
      header: _AuthModeToggle(
        isSignUp: _isSignUp,
        onChanged: (isSignUp) {
          setState(() {
            _isSignUp = isSignUp;
            _formKey.currentState?.reset();
          });
        },
      ),
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isSignUp) ...[
              const FieldLabel(label: 'Your name'),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    _isSignUp && (value == null || value.trim().isEmpty)
                    ? 'Please enter your name'
                    : null,
                decoration: const InputDecoration(hintText: 'Alex Morgan'),
              ),
              const SizedBox(height: 18),
            ],
            const FieldLabel(label: 'Email'),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) => value == null || !value.contains('@')
                  ? 'Enter a valid email address'
                  : null,
              decoration: const InputDecoration(hintText: 'parent@example.com'),
            ),
            const SizedBox(height: 18),
            const FieldLabel(label: 'Password'),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              validator: (value) => value == null ||
                      (_isSignUp ? value.length < 12 : value.isEmpty)
                  ? (_isSignUp
                      ? 'Use at least 12 characters'
                      : 'Enter your password')
                  : null,
              decoration: InputDecoration(
                hintText: _isSignUp ? 'At least 12 characters' : 'Enter your password',
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            if (_isSignUp)
              _buildSignUpActions(isBusy)
            else
              _buildSignInActions(isBusy),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpActions(bool isBusy) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: isBusy ? null : _submit,
          child: isBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Create account',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }

  Widget _buildSignInActions(bool isBusy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            alignment: constraints.maxWidth < 300
                ? WrapAlignment.start
                : WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 0,
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) =>
                          setState(() => _rememberMe = value ?? false),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      activeColor: const Color(0xFF1769E0),
                    ),
                    const Text(
                      'Remember me',
                      style: TextStyle(
                        color: Color(0xFF34443B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot password?',
                  softWrap: true,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: isBusy ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1769E0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Sign in',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(child: Divider()),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: _showGoogleSignInNotice,
            icon: Image.asset(
              'assets/images/google.png',
              width: 20,
              height: 20,
            ),
            label: const Text('Sign in with Google'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF34443B),
              side: const BorderSide(color: Color(0xFFD0D5DD)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthModeToggle extends StatelessWidget {
  const _AuthModeToggle({required this.isSignUp, required this.onChanged});

  final bool isSignUp;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _AuthModeButton(
            label: 'Sign in',
            selected: !isSignUp,
            onTap: () => onChanged(false),
          ),
          _AuthModeButton(
            label: 'Sign up',
            selected: isSignUp,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _AuthModeButton extends StatelessWidget {
  const _AuthModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: selected ? Colors.white : Colors.transparent,
          foregroundColor: selected
              ? const Color(0xFF1769E0)
              : const Color(0xFF667085),
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
