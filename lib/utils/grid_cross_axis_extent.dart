import 'package:flutter/material.dart';
import '../services/settings_service.dart';

/// Calculates the max cross-axis extent for grid items, accounting for outer padding.
double getMaxCrossAxisExtentWithPadding(
  BuildContext context,
  LibraryDensity density,
  double horizontalPadding,
) {
  final screenWidth = MediaQuery.of(context).size.width;
  final availableWidth = screenWidth - horizontalPadding;

  if (screenWidth >= 900) {
    // Wide screens (desktop/large tablet landscape): Responsive division
    double divisor;
    double maxItemWidth;

    switch (density) {
      case LibraryDensity.comfortable:
        divisor = 6.5;
        maxItemWidth = 280;
        break;
      case LibraryDensity.normal:
        divisor = 8.0;
        maxItemWidth = 200;
        break;
      case LibraryDensity.compact:
        divisor = 10.0;
        maxItemWidth = 160;
        break;
    }

    return (availableWidth / divisor).clamp(0, maxItemWidth);
  } else if (screenWidth >= 600) {
    // Medium screens (tablets): Fixed 4-5-6 items
    int targetItemCount = switch (density) {
      LibraryDensity.comfortable => 4,
      LibraryDensity.normal => 5,
      LibraryDensity.compact => 6,
    };
    return availableWidth / targetItemCount;
  } else {
    // Small screens (phones): Fixed 2-3-4 items
    int targetItemCount = switch (density) {
      LibraryDensity.comfortable => 2,
      LibraryDensity.normal => 3,
      LibraryDensity.compact => 4,
    };
    return availableWidth / targetItemCount;
  }
}
