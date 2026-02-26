import 'package:flutter/material.dart';

Route<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    opaque: false,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 500),
    reverseTransitionDuration: const Duration(milliseconds: 500),
  );
}
