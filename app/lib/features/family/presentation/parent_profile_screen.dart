import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/drawer_page_app_bar.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../navigation/presentation/drawer_page_shell.dart';

class ParentProfileScreen extends ConsumerStatefulWidget {
  const ParentProfileScreen({this.children = const [], super.key});

  final List<List<String>> children;

  @override
  ConsumerState<ParentProfileScreen> createState() =>
      _ParentProfileScreenState();
}

class _ParentProfileScreenState extends ConsumerState<ParentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nationalIdController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await ref.read(authApiClientProvider).get('/profile');
      final profile = response['profile'];
      if (profile is! Map<String, dynamic>) {
        throw const FormatException('The server returned an invalid profile.');
      }
      if (!mounted) return;
      setState(() {
        _fullNameController.text = (profile['name'] ?? '').toString();
        _phoneController.text = (profile['phone'] ?? '').toString();
        _emailController.text = (profile['email'] ?? '').toString();
        _nationalIdController.text = (profile['nationalId'] ?? '').toString();
        _loadError = null;
        _isLoading = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Unable to load your profile: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final response = await ref
          .read(authApiClientProvider)
          .patch(
            '/profile',
            body: {
              'name': _fullNameController.text.trim(),
              'phone': _phoneController.text.trim(),
              'nationalId': _nationalIdController.text.trim(),
            },
          );
      if (response['profile'] is! Map<String, dynamic>) {
        throw const FormatException('The server returned an invalid profile.');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved.')));
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save your profile: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: const DrawerPageAppBar(
        title: 'My profile',
        backgroundColor: Color(0xFFF7F9FC),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? DrawerErrorState(message: _loadError!, onRetry: _loadProfile)
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Color(0xFFEAF2FF),
                      child: Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: Color(0xFF1769E0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Account profile',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Update the contact details saved to your account.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  const _ProfileLabel(label: 'Full names'),
                  TextFormField(
                    controller: _fullNameController,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your full names'
                        : null,
                    decoration: const InputDecoration(hintText: 'Full name'),
                  ),
                  const SizedBox(height: 18),
                  const _ProfileLabel(label: 'Phone number'),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        value == null || value.trim().length < 7
                        ? 'Enter a valid phone number'
                        : null,
                    decoration: const InputDecoration(hintText: 'Phone number'),
                  ),
                  const SizedBox(height: 18),
                  const _ProfileLabel(label: 'Email address'),
                  TextFormField(
                    controller: _emailController,
                    readOnly: true,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value == null || !value.contains('@')
                        ? 'Enter a valid email address'
                        : null,
                    decoration: const InputDecoration(
                      hintText: 'Email address',
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _ProfileLabel(label: 'National ID / passport number'),
                  TextFormField(
                    controller: _nationalIdController,
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your ID number'
                        : null,
                    decoration: const InputDecoration(hintText: 'ID number'),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      child: Text(_isSaving ? 'Saving...' : 'Save profile'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileLabel extends StatelessWidget {
  const _ProfileLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}
