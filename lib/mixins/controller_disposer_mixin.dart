import 'package:flutter/widgets.dart';

/// Owns [TextEditingController] instances created by a [State] and disposes
/// them automatically from the state's `dispose` chain.
mixin ControllerDisposerMixin<T extends StatefulWidget> on State<T> {
  final List<TextEditingController> _textEditingControllers = [];

  TextEditingController createTextEditingController({String? text, TextEditingValue? value}) {
    assert(text == null || value == null, 'Provide either text or value, not both.');
    final controller = value == null ? TextEditingController(text: text) : TextEditingController.fromValue(value);
    _textEditingControllers.add(controller);
    return controller;
  }

  TextEditingController registerTextEditingController(TextEditingController controller) {
    _textEditingControllers.add(controller);
    return controller;
  }

  @override
  void dispose() {
    for (final controller in _textEditingControllers.reversed) {
      controller.dispose();
    }
    _textEditingControllers.clear();
    super.dispose();
  }
}
