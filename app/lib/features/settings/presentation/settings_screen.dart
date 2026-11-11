import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/navigation/drawer_page_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../family/presentation/parent_profile_screen.dart';
import '../../navigation/presentation/help_support_screen.dart';
import '../../navigation/presentation/drawer_page_shell.dart';
import '../../navigation/presentation/pickup_points_screen.dart';
import '../../navigation/presentation/privacy_security_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Map<String, dynamic>? _profile;
  bool? _tripUpdates;
  bool? _arrivalAlerts;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final api = ref.read(authApiClientProvider);
      final responses = await Future.wait([
        api.get('/profile'),
        api.get('/preferences'),
      ]);
      final profile = responses[0]['profile'];
      final preferences = responses[1]['preferences'];
      if (profile is! Map<String, dynamic> ||
          preferences is! Map<String, dynamic>) {
        throw const FormatException('The server returned invalid settings.');
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _tripUpdates = preferences['tripUpdates'] == true;
        _arrivalAlerts = preferences['arrivalAlerts'] == true;
        _loadError = null;
        _isLoading = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Unable to load account settings: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreference(String field, bool value) async {
    setState(() => _isSaving = true);
    try {
      final response = await ref
          .read(authApiClientProvider)
          .patch('/preferences', body: {field: value});
      final preferences = response['preferences'];
      if (preferences is! Map<String, dynamic>) {
        throw const FormatException('The server returned invalid preferences.');
      }
      if (!mounted) return;
      setState(() {
        _tripUpdates = preferences['tripUpdates'] == true;
        _arrivalAlerts = preferences['arrivalAlerts'] == true;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save preference: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    void open(Widget page) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const DrawerPageAppBar(
        title: 'Settings',
        backgroundColor: AppTheme.background,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        children: [
          Text(
            'Your preferences',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Keep your family connection up to date.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_loadError != null)
            DrawerErrorState(message: _loadError!, onRetry: _loadSettings)
          else
            _SettingsCard(
              child: ListTile(
                leading: const CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.blueTint,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: AppTheme.blue,
                  ),
                ),
                title: Text(
                  (_profile?['name'] ?? 'Account profile').toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  (_profile?['email'] ?? '').toString().isEmpty
                      ? 'Profile details'
                      : _profile!['email'].toString(),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => open(const ParentProfileScreen()),
              ),
            ),
          const _SectionTitle(title: 'Notifications'),
          if (_tripUpdates == null || _arrivalAlerts == null)
            _SettingsCard(
              child: DrawerErrorState(
                message: 'Notification preferences are unavailable.',
                onRetry: _loadSettings,
              ),
            )
          else
            _SettingsCard(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Trip updates'),
                    subtitle: const Text('Departure and route changes'),
                    value: _tripUpdates!,
                    onChanged: _isSaving
                        ? null
                        : (value) => _savePreference('tripUpdates', value),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Arrival alerts'),
                    subtitle: const Text(
                      'When your child arrives at school or home',
                    ),
                    value: _arrivalAlerts!,
                    onChanged: _isSaving
                        ? null
                        : (value) => _savePreference('arrivalAlerts', value),
                  ),
                ],
              ),
            ),
          _SettingsCard(
            child: Column(
              children: [
                _SettingsLink(
                  icon: Icons.location_on_outlined,
                  title: 'Pickup and drop-off',
                  onTap: () => open(const PickupPointsScreen()),
                ),
                _SettingsLink(
                  icon: Icons.lock_outline_rounded,
                  title: 'Password and security',
                  onTap: () => open(const PrivacySecurityScreen()),
                ),
              ],
            ),
          ),
          const _SectionTitle(title: 'Support'),
          _SettingsCard(
            child: _SettingsLink(
              icon: Icons.help_outline_rounded,
              title: 'Help center',
              onTap: () => open(const HelpSupportScreen()),
            ),
          ),
          const SizedBox(height: 18),
          _SettingsCard(
            child: ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFE58A24),
              ),
              title: const Text(
                'Log out',
                style: TextStyle(
                  color: Color(0xFFE58A24),
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () async {
                await ref.read(authControllerProvider).signOut();
                if (!context.mounted) return;
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.border),
    ),
    child: child,
  );
}

class _SettingsLink extends StatelessWidget {
  const _SettingsLink({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppTheme.blue),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 5),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF1769E0),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    ),
  );
}
