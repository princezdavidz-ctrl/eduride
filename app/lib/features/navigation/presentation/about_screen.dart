import 'package:flutter/material.dart';

import 'drawer_page_shell.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DrawerPageShell(
      title: 'About Edu Ride',
      description:
          'Edu Ride is the school transport companion installed on this device.',
      emptyMessage: 'No additional app information is available.',
    );
  }
}
