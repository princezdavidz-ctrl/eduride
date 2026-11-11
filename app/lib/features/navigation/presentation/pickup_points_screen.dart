import 'package:flutter/material.dart';

import 'drawer_page_shell.dart';

class PickupPointsScreen extends StatelessWidget {
  const PickupPointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DrawerDataPage(
      path: '/routes',
      title: 'Pickup & drop-off points',
      description: 'Stops reported for routes in your transport service.',
      emptyMessage: 'No pickup or drop-off stops are available.',
      mapRecords: (records) => [
        for (final route in records)
          if (route['stops'] is List)
            for (final stop in (route['stops'] as List))
              DrawerPageItem(
                title: stop.toString(),
                subtitle: route['name']?.toString(),
                icon: Icons.location_on_outlined,
              ),
      ],
    );
  }
}
