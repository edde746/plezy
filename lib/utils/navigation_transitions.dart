import 'package:flutter/material.dart';

import 'layout_constants.dart';

Route<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    opaque: false,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: AppDurations.animSlow,
    reverseTransitionDuration: AppDurations.animSlow,
  );
}
