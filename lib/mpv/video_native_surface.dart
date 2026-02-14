/// Native video surface - returns empty SizedBox.
/// Native platforms use Texture widget or VideoRectSupport,
/// which is handled in the main Video widget.
library;

import 'package:flutter/material.dart';

import 'player/player.dart';

Widget buildVideoSurface(Player player) {
  return const SizedBox.expand();
}
