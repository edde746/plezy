import 'package:flutter/material.dart';

bool? mobileSkipZoneForTap({required Offset position, required Size size}) {
  final dimensions = _mobileSkipZoneDimensions(size);
  final inVerticalRange = position.dy > dimensions.topExclude && position.dy < (size.height - dimensions.bottomExclude);
  if (!inVerticalRange) return null;
  if (position.dx < dimensions.leftZoneWidth) return false;
  if (position.dx > (size.width - dimensions.leftZoneWidth)) return true;
  return null;
}

({double topExclude, double bottomExclude, double leftZoneWidth}) _mobileSkipZoneDimensions(Size size) {
  return (topExclude: size.height * 0.15, bottomExclude: size.height * 0.15, leftZoneWidth: size.width * 0.35);
}

class MobileSkipZones extends StatelessWidget {
  final void Function(bool isForward) onTapInSkipZone;
  final GestureLongPressStartCallback onLongPressStart;
  final GestureLongPressEndCallback onLongPressEnd;
  final VoidCallback onLongPressCancel;

  const MobileSkipZones({
    super.key,
    required this.onTapInSkipZone,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.onLongPressCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final dimensions = _mobileSkipZoneDimensions(size);

          return Stack(
            children: [
              Positioned(
                left: 0,
                top: dimensions.topExclude,
                bottom: dimensions.bottomExclude,
                width: dimensions.leftZoneWidth,
                child: GestureDetector(
                  onTap: () => onTapInSkipZone(false),
                  onLongPressStart: onLongPressStart,
                  onLongPressEnd: onLongPressEnd,
                  onLongPressCancel: onLongPressCancel,
                  behavior: HitTestBehavior.opaque,
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),
              Positioned(
                right: 0,
                top: dimensions.topExclude,
                bottom: dimensions.bottomExclude,
                width: dimensions.leftZoneWidth,
                child: GestureDetector(
                  onTap: () => onTapInSkipZone(true),
                  onLongPressStart: onLongPressStart,
                  onLongPressEnd: onLongPressEnd,
                  onLongPressCancel: onLongPressCancel,
                  behavior: HitTestBehavior.opaque,
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
