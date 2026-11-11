import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/routes.dart';
import '../../../core/config/app_config.dart';
import '../../../core/navigation/app_drawer_navigation.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../family/presentation/children_screen.dart';
import '../../family/presentation/parent_profile_screen.dart';
import '../../navigation/presentation/about_screen.dart';
import '../../navigation/presentation/contact_school_screen.dart';
import '../../navigation/presentation/emergency_safety_screen.dart';
import '../../navigation/presentation/help_support_screen.dart';
import '../../navigation/presentation/messages_screen.dart';
import '../../navigation/presentation/pickup_points_screen.dart';
import '../../navigation/presentation/privacy_security_screen.dart';
import '../../navigation/presentation/school_schedule_screen.dart';
import '../../navigation/presentation/terms_screen.dart';
import '../../navigation/presentation/trip_history_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'live_tracking_screen.dart';
import 'providers/bus_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: appHomeScaffoldKey,
      backgroundColor: AppTheme.background,
      drawer: const _AppDrawer(),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: const [HomeDashboard(), ChildrenScreen()],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: Image.asset(
              'assets/icons/overview.png',
              width: 24,
              height: 24,
            ),
            selectedIcon: Image.asset(
              'assets/icons/overview.png',
              width: 24,
              height: 24,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Image.asset(
              'assets/icons/managechildren.png',
              width: 24,
              height: 24,
            ),
            selectedIcon: Image.asset(
              'assets/icons/managechildren.png',
              width: 24,
              height: 24,
            ),
            label: 'Children',
          ),
        ],
      ),
    );
  }
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void open(Widget page) {
      Navigator.of(context).pop();
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }

    Future<void> logout() async {
      await ref.read(authControllerProvider).signOut();
      if (!context.mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    }

    return Drawer(
      backgroundColor: const Color(0xFFF7F9FC),
      child: SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/logo.jpeg',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                AppConfig.appName,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('Parent dashboard'),
            ),
            const Divider(),
            ListTile(
              leading: _DrawerAssetIcon('assets/icons/overview.png'),
              title: const Text('Overview'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.location_searching_rounded, color: AppTheme.blue),
              title: const Text('Bus tracking'),
              onTap: () => open(const LiveTrackingScreen()),
            ),
            ListTile(
              leading: _DrawerAssetIcon('assets/icons/managechildren.png'),
              title: const Text('Manage children'),
              onTap: () => open(const ChildrenScreen()),
            ),
            ListTile(
              leading: _DrawerAssetIcon('assets/icons/myprofile.png'),
              title: const Text('My profile'),
              onTap: () => open(const ParentProfileScreen()),
            ),
            ListTile(
              leading: _DrawerAssetIcon('assets/icons/notifications.png'),
              title: const Text('Notifications'),
              onTap: () => open(const NotificationsScreen()),
            ),
            ListTile(
              leading: _DrawerAssetIcon('assets/icons/messages.png'),
              title: const Text('Messages'),
              onTap: () => open(const MessagesScreen()),
            ),
            ListTile(
              leading: _DrawerAssetIcon('assets/icons/settings.png'),
              title: const Text('Settings'),
              onTap: () => open(const SettingsScreen()),
            ),
            const Divider(),
            ListTile(
              leading: _DrawerAssetIcon('assets/icons/history.png'),
              title: const Text('Trip history'),
              onTap: () => open(const TripHistoryScreen()),
            ),
            ListTile(
              leading: _DrawerAssetIcon('assets/icons/schoolschedule.png'),
              title: const Text('School schedule'),
              onTap: () => open(const SchoolScheduleScreen()),
            ),
            ListTile(
              leading: _DrawerAssetIcon('assets/icons/pickup.png'),
              title: const Text('Pickup & drop-off points'),
              onTap: () => open(const PickupPointsScreen()),
            ),
            ListTile(
              leading: _DrawerAssetIcon('assets/icons/contactschool.png'),
              title: const Text('Contact school'),
              onTap: () => open(const ContactSchoolScreen()),
            ),
            ListTile(
              leading: _DrawerAssetIcon('assets/icons/emegency.png'),
              title: const Text('Emergency & safety'),
              onTap: () => open(const EmergencySafetyScreen()),
            ),
            ListTile(
              leading: _DrawerAssetIcon('assets/icons/help.png'),
              title: const Text('Help & support'),
              onTap: () => open(const HelpSupportScreen()),
            ),
            const Divider(),
            ListTile(
              leading: _DrawerAssetIcon('assets/icons/privacy.png'),
              title: const Text('Privacy & security'),
              onTap: () => open(const PrivacySecurityScreen()),
            ),
            ListTile(
              leading: _DrawerAssetIcon('assets/icons/info.png'),
              title: const Text('About Edu Ride'),
              onTap: () => open(const AboutScreen()),
            ),
            ListTile(
              leading: _DrawerAssetIcon('assets/icons/terms.png'),
              title: const Text('Terms & conditions'),
              onTap: () => open(const TermsScreen()),
            ),
            const Divider(),
            ListTile(
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
              onTap: logout,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerAssetIcon extends StatelessWidget {
  const _DrawerAssetIcon(this.assetPath);

  final String assetPath;

  @override
  Widget build(BuildContext context) =>
      Image.asset(assetPath, width: 24, height: 24, fit: BoxFit.contain);
}

class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({super.key});

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard> {
  final _mapController = fm.MapController();
  StreamSubscription<Position>? _locationSubscription;
  Position? _userPosition;
  String _locationStatus = 'Finding your location...';
  bool _hasCenteredOnUser = false;
  String? _centeredBusId;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocation() async {
    if (mounted) {
      setState(() => _locationStatus = 'Finding your location...');
    }

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _setLocationStatus('Turn on device location to see your position');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _setLocationStatus('Allow location access to see your position');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _setLocationStatus('Enable location access in device settings');
        return;
      }

      _locationSubscription ??=
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen(
            _updateUserLocation,
            onError: (Object error) {
              debugPrint('Live location stream failed: $error');
              _setLocationStatus(
                'Live location unavailable; check device settings',
              );
            },
          );

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _updateUserLocation(position);
    } on Exception catch (error) {
      debugPrint('Could not get the current location: $error');
      _setLocationStatus('Location unavailable; check permissions or settings');
    }
  }

  void _updateUserLocation(Position position) {
    if (!mounted) return;
    setState(() {
      _userPosition = position;
      _locationStatus = 'Your location ±${position.accuracy.round()} m';
    });

    final assignedBus = ref.read(busesProvider).valueOrNull?.firstOrNull;
    if (!_hasCenteredOnUser && assignedBus == null) {
      _hasCenteredOnUser = true;
      _mapController.move(LatLng(position.latitude, position.longitude), 15);
    }
  }

  void _setLocationStatus(String status) {
    if (mounted) setState(() => _locationStatus = status);
  }

  void _showMyProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ParentProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final busesAsync = ref.watch(busesProvider);
    final bus = busesAsync.valueOrNull?.firstOrNull;
    final eta = bus?.etaMinutes ?? 0;
    final busAvailable = bus != null;
    if (bus != null && _centeredBusId != bus.id) {
      _centeredBusId = bus.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(LatLng(bus.latitude, bus.longitude), 13);
        }
      });
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          child: Row(
            children: [
              Builder(
                builder: (context) => Material(
                  color: AppTheme.blueTint,
                  borderRadius: BorderRadius.circular(15),
                  child: IconButton(
                    tooltip: 'Open menu',
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(Icons.menu_rounded, color: AppTheme.blue),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SCHOOL JOURNEY',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.blue,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Track your child’s bus',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: AppTheme.surface,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Refresh journey information',
                  onPressed: () => ref.invalidate(busesProvider),
                  icon: const Icon(Icons.refresh_rounded, color: AppTheme.blue),
                ),
              ),
              const SizedBox(width: 4),
              Material(
                color: AppTheme.surface,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'My profile',
                  onPressed: _showMyProfile,
                  icon: const Icon(Icons.account_circle_outlined, color: AppTheme.navy),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  fm.FlutterMap(
                    mapController: _mapController,
                    options: const fm.MapOptions(
                      initialCenter: LatLng(0, 0),
                      initialZoom: 2.5,
                      interactionOptions: fm.InteractionOptions(
                        flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      fm.TileLayer(
                        urlTemplate: AppConfig.mapTileUrl,
                        userAgentPackageName: AppConfig.mapUserAgentPackageName,
                      ),
                      if (busAvailable)
                        fm.MarkerLayer(
                          markers: [
                            fm.Marker(
                              point: LatLng(bus.latitude, bus.longitude),
                              width: 56,
                              height: 56,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x300F2B46),
                                      blurRadius: 14,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.directions_bus_filled_rounded,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (_userPosition case final position?)
                        fm.MarkerLayer(
                          markers: [
                            fm.Marker(
                              point: LatLng(position.latitude, position.longitude),
                              width: 42,
                              height: 42,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.blue.withValues(alpha: 0.16),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    right: 66,
                    child: _MapLabel(
                      icon: Icons.school_outlined,
                      label: bus?.school ??
                          (busesAsync.hasError
                              ? 'School information unavailable'
                              : 'Waiting for route information'),
                    ),
                  ),
                  Positioned(
                    top: 64,
                    left: 14,
                    child: _MapLabel(
                      icon: Icons.my_location_rounded,
                      label: _locationStatus,
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      elevation: 2,
                      child: IconButton(
                        tooltip: 'Show my location',
                        onPressed: () {
                          final position = _userPosition;
                          if (position == null) {
                            _loadUserLocation();
                            return;
                          }
                          _mapController.move(
                            LatLng(position.latitude, position.longitude),
                            15,
                          );
                        },
                        icon: const Icon(
                          Icons.my_location_rounded,
                          color: AppTheme.blue,
                        ),
                      ),
                    ),
                  ),
                  if (!busAvailable)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.all(28),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.directions_bus_outlined,
                                  color: AppTheme.blue,
                                  size: 34,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  busesAsync.hasError
                                      ? 'Bus details unavailable'
                                      : 'Waiting for your bus',
                                  style: const TextStyle(
                                    color: AppTheme.ink,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  busesAsync.hasError
                                      ? 'Pull down to refresh your journey information.'
                                      : 'Your school’s latest route information will appear here.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppTheme.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080F2B46),
                blurRadius: 20,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          busAvailable ? 'BUS ${bus.id}' : 'YOUR JOURNEY',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.muted,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          busAvailable
                              ? (bus.status.isEmpty
                                  ? 'Route in progress'
                                  : bus.status == 'on_route'
                                  ? 'On the way'
                                  : bus.status.replaceAll('_', ' '))
                              : (busesAsync.hasError
                                  ? 'Unable to load bus status'
                                  : 'Waiting for bus assignment'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 19,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                    decoration: BoxDecoration(
                      color: busAvailable ? AppTheme.successTint : AppTheme.warningTint,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          busAvailable ? Icons.directions_bus_outlined : Icons.schedule_rounded,
                          size: 15,
                          color: busAvailable ? AppTheme.success : AppTheme.warning,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          busAvailable ? 'ASSIGNED' : 'PENDING',
                          style: TextStyle(
                            color: busAvailable ? AppTheme.success : AppTheme.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: AppTheme.blue, size: 19),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      busAvailable ? 'Estimated arrival' : 'Arrival estimate',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    busAvailable ? '$eta min' : '—',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.blue,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              if (busAvailable && bus.school.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.school_outlined, color: AppTheme.muted, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bus.school,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MapLabel extends StatelessWidget {
  const _MapLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: (MediaQuery.sizeOf(context).width - 152)
            .clamp(120, 420)
            .toDouble(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1769E0)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
