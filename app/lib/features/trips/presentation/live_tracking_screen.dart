import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/app_config.dart';
import '../../../core/navigation/drawer_page_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import 'providers/bus_provider.dart';

class LiveTrackingScreen extends ConsumerWidget {
  const LiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buses = ref.watch(busesProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const DrawerPageAppBar(
        title: 'Bus tracking',
        backgroundColor: AppTheme.background,
      ),
      body: buses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _TrackingMessage(
          icon: Icons.cloud_off_rounded,
          title: 'Tracking is unavailable',
          message: 'We could not load the latest bus location. Check your connection and try again.',
          action: OutlinedButton.icon(
            onPressed: () => ref.invalidate(busesProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _TrackingMessage(
              icon: Icons.directions_bus_outlined,
              title: 'No bus assigned yet',
              message: 'When your school assigns a bus to your family, its latest location and journey status will appear here.',
            );
          }

          final bus = items.first;
          final status = switch (bus.status) {
            'on_route' => 'On the way',
            'at_school' => 'At school',
            'idle' => 'Not moving',
            '' => 'Status unavailable',
            _ => bus.status.replaceAll('_', ' '),
          };

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(busesProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
              children: [
                Text(
                  'Your child’s journey',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Location and status reflect the latest update returned by the server. Pull down to refresh.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: SizedBox(
                    height: 310,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: fm.FlutterMap(
                            options: fm.MapOptions(
                              initialCenter: LatLng(bus.latitude, bus.longitude),
                              initialZoom: 14,
                              interactionOptions: const fm.InteractionOptions(
                                flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
                              ),
                            ),
                            children: [
                              fm.TileLayer(
                                urlTemplate: AppConfig.mapTileUrl,
                                userAgentPackageName: AppConfig.mapUserAgentPackageName,
                              ),
                              fm.MarkerLayer(
                                markers: [
                                  fm.Marker(
                                    point: LatLng(bus.latitude, bus.longitude),
                                    width: 58,
                                    height: 58,
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
                            ],
                          ),
                        ),
                        Positioned(
                          top: 14,
                          left: 14,
                          child: _MapBadge(
                            icon: Icons.school_outlined,
                            label: bus.school.isEmpty ? 'School not listed' : bus.school,
                          ),
                        ),
                        Positioned(
                          bottom: 14,
                          left: 14,
                          child: _MapBadge(
                            icon: Icons.route_rounded,
                            label: bus.route.isEmpty ? 'Route not listed' : bus.route,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Bus ${bus.id}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                            decoration: BoxDecoration(
                              color: bus.isMoving ? AppTheme.successTint : AppTheme.blueTint,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: bus.isMoving ? AppTheme.success : AppTheme.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, color: AppTheme.blue),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('Estimated arrival', style: Theme.of(context).textTheme.bodyMedium),
                          ),
                          Text(
                            '${bus.etaMinutes} min',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.blue),
                          ),
                        ],
                      ),
                      if (bus.route.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(Icons.alt_route_rounded, color: AppTheme.muted),
                            const SizedBox(width: 10),
                            Expanded(child: Text(bus.route, style: Theme.of(context).textTheme.bodyMedium)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppTheme.muted, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The map shows the latest reported bus position. It does not guarantee arrival time; allow for traffic and network delays.',
                        style: TextStyle(color: AppTheme.muted, fontSize: 12, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MapBadge extends StatelessWidget {
  const _MapBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 250),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(13),
      boxShadow: const [
        BoxShadow(color: Color(0x120F2B46), blurRadius: 12, offset: Offset(0, 4)),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.blue),
        const SizedBox(width: 7),
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

class _TrackingMessage extends StatelessWidget {
  const _TrackingMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.blueTint,
              child: Icon(icon, color: AppTheme.blue, size: 30),
            ),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    ),
  );
}
