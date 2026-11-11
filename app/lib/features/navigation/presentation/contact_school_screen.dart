import 'package:flutter/material.dart';

import 'drawer_page_shell.dart';

class ContactSchoolScreen extends StatelessWidget {
  const ContactSchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DrawerDataPage(
      path: '/schools',
      title: 'Contact school',
      description:
          'School directory data available from your transport service.',
      emptyMessage: 'No school contact details have been published.',
      mapRecords: (records) => records
          .map(
            (record) => DrawerPageItem(
              title: record['name']?.toString() ?? 'School',
              subtitle: record['address']?.toString(),
              icon: Icons.school_outlined,
            ),
          )
          .toList(),
    );
  }
}
