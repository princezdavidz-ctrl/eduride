import 'package:flutter/material.dart';

import 'app_drawer_navigation.dart';

class DrawerPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DrawerPageAppBar({
    required this.title,
    required this.backgroundColor,
    this.actions,
    super.key,
  });

  final String title;
  final Color backgroundColor;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    leading: IconButton(
      tooltip: 'Open navigation menu',
      onPressed: () => openAppDrawer(context),
      icon: const Icon(Icons.menu_rounded),
    ),
    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    backgroundColor: backgroundColor,
    actions: actions,
  );
}
