import 'dart:async';

import 'package:flutter/material.dart';

final appHomeScaffoldKey = GlobalKey<ScaffoldState>();

void openAppDrawer(BuildContext context) {
  final navigator = Navigator.of(context);
  if (!navigator.canPop()) {
    appHomeScaffoldKey.currentState?.openDrawer();
    return;
  }

  navigator.popUntil((route) => route.isFirst);
  Timer(const Duration(milliseconds: 350), () {
    appHomeScaffoldKey.currentState?.openDrawer();
  });
}
