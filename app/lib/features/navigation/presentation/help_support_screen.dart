import 'package:flutter/material.dart';

import 'drawer_page_shell.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DrawerPageShell(
      title: 'Help & support',
      description: 'Find answers or contact the Edu Ride support team.',
      items: [
        DrawerPageItem(
          title: 'Getting started',
          subtitle: 'Set up children, stops, and notifications',
          icon: Icons.play_circle_outline_rounded,
        ),
      ],
    );
  }
}
