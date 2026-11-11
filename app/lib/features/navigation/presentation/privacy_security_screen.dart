import 'package:flutter/material.dart';

import 'drawer_page_shell.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DrawerPageShell(
      title: 'Privacy & security',
      description:
          'Edu Ride stores your sign-in session using the device secure-storage service.',
      emptyMessage: 'There are no additional privacy controls available.',
    );
  }
}
