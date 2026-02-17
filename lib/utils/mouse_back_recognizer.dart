import 'package:flutter/gestures.dart';

// From here: https://github.com/flutter/flutter/issues/115641#issuecomment-2267579790
class MouseBackRecognizer extends BaseTapGestureRecognizer {
  GestureTapDownCallback? onTapDown;

  MouseBackRecognizer({super.debugOwner, super.supportedDevices, super.allowedButtonsFilter});

  @override
  void handleTapCancel({required PointerDownEvent down, PointerCancelEvent? cancel, required String reason}) {}

  @override
  void handleTapDown({required PointerDownEvent down}) {
    final TapDownDetails details = TapDownDetails(
      globalPosition: down.position,
      localPosition: down.localPosition,
      kind: getKindForPointer(down.pointer),
    );

    if (down.buttons == kBackMouseButton && onTapDown != null) {
      invokeCallback<void>('onTapDown', () => onTapDown!(details));
    }
  }

  @override
  void handleTapUp({required PointerDownEvent down, required PointerUpEvent up}) {}
}
