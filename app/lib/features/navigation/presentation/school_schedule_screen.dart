import 'package:flutter/material.dart';

import 'drawer_page_shell.dart';

class SchoolScheduleScreen extends StatelessWidget {
  const SchoolScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DrawerDataPage(
      path: '/buses',
      title: 'School schedule',
      description: 'Current route and arrival information from your service.',
      emptyMessage: 'No active route information is available.',
      mapRecords: (records) => records
          .map(
            (record) => DrawerPageItem(
              title:
                  'Bus ${record['id'] ?? '—'} · ${record['school'] ?? 'School'}',
              subtitle: [
                if (record['route'] != null) record['route'].toString(),
                if (record['status'] != null) 'Status: ${record['status']}',
                if (record['etaMinutes'] != null)
                  'ETA: ${record['etaMinutes']} min',
              ].join(' • '),
              icon: Icons.directions_bus_outlined,
            ),
          )
          .toList(),
    );
  }
}
