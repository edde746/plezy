/// Web video surface using HtmlElementView.
///
/// Renders the HTML5 <video> element inside Flutter's web view.
library;

import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import 'player/player.dart';
import 'player/player_web.dart';

/// Set of already-registered view IDs to avoid duplicate registration.
final _registeredViews = <String>{};

Widget buildVideoSurface(Player player) {
  if (player is! PlayerWeb) {
    return const SizedBox.expand();
  }

  final viewId = player.viewId;
  final videoElement = player.videoElement;

  if (viewId == null || videoElement == null) {
    return const SizedBox.expand();
  }

  // Register the platform view factory (only once per viewId)
  if (!_registeredViews.contains(viewId)) {
    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int id) => videoElement,
    );
    _registeredViews.add(viewId);
  }

  return HtmlElementView(viewType: viewId);
}
