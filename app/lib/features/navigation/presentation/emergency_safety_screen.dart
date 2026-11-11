import 'package:flutter/material.dart';

import 'drawer_page_shell.dart';

class EmergencySafetyScreen extends StatelessWidget {
  const EmergencySafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DrawerDataPage(
      path: '/buses',
      title: 'Emergency & safety',
      description:
          'Current bus and route status. Emergency phone contacts are not configured.',
      emptyMessage: 'No current bus safety data is available.',
      mapRecords: (records) => records
          .map(
            (record) => DrawerPageItem(
              title:
                  'Bus ${record['id'] ?? '—'} · ${record['status'] ?? 'Status unavailable'}',
              subtitle: [
                if (record['route'] != null) record['route'].toString(),
                if (record['school'] != null) record['school'].toString(),
              ].join(' • '),
              icon: Icons.directions_bus_outlined,
            ),
          )
          .toList(),
    );
  }
}
