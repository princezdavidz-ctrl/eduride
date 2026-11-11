import 'package:flutter/material.dart';

import 'drawer_page_shell.dart';

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DrawerDataPage(
      path: '/journeys',
      title: 'Trip history',
      description: 'Journey records received from your transport service.',
      emptyMessage: 'No journey records are available for your account.',
      mapRecords: (records) => records
          .map(
            (record) => DrawerPageItem(
              title:
                  'Bus ${record['busId'] ?? '—'} · ${record['route'] ?? 'Route'}',
              subtitle: [
                if (record['status'] != null) 'Status: ${record['status']}',
                if (record['departureAt'] != null)
                  'Departure: ${record['departureAt']}',
                if (record['arrivalAt'] != null)
                  'Arrival: ${record['arrivalAt']}',
              ].join(' • '),
              icon: Icons.directions_bus_outlined,
            ),
          )
          .toList(),
    );
  }
}
