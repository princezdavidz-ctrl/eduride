import 'package:flutter/material.dart';

import 'drawer_page_shell.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DrawerPageShell(
      title: 'Messages',
      description:
          'Messages from your school or transport team will appear here when messaging is enabled.',
      items: [],
      emptyMessage: 'There are no messages available.',
    );
  }
}
