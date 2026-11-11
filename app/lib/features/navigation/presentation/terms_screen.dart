import 'package:flutter/material.dart';

import 'drawer_page_shell.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DrawerPageShell(
      title: 'Terms & conditions',
      description: 'Terms for Edu Ride will be shown here when published.',
      emptyMessage: 'Terms and conditions have not been published yet.',
    );
  }
}
