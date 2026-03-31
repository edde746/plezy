import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../focus/dpad_navigator.dart';
import '../focus/focusable_button.dart';
import '../i18n/strings.g.dart';
import '../widgets/app_icon.dart';
import '../widgets/focusable_list_tile.dart';

class TagEditDialog extends StatefulWidget {
  final String title;
  final List<String> initialTags;

  const TagEditDialog({super.key, required this.title, required this.initialTags});

  @override
  State<TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends State<TagEditDialog> {
  late final TextEditingController _controller;
  late final FocusNode _textFieldFocusNode;
  late final List<String> _tags;
  final _saveFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _textFieldFocusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (!event.isActionable) return KeyEventResult.ignored;
        if (event.logicalKey.isDownKey) {
          node.nextFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
    _tags = List.of(widget.initialTags);
  }

  @override
  void dispose() {
    _controller.dispose();
    _textFieldFocusNode.dispose();
    _saveFocusNode.dispose();
    super.dispose();
  }

  void _addTag() {
    final text = _controller.text.trim();
    if (text.isEmpty || _tags.contains(text)) return;
    setState(() {
      _tags.add(text);
      _controller.clear();
    });
    _textFieldFocusNode.requestFocus();
  }

  void _removeTag(int index) {
    setState(() => _tags.removeAt(index));
    _textFieldFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              focusNode: _textFieldFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                labelText: t.metadataEdit.addTag,
                suffixIcon: FocusableButton(
                  onPressed: _addTag,
                  child: IconButton(
                    icon: const AppIcon(Symbols.add_rounded),
                    onPressed: _addTag,
                  ),
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addTag(),
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _tags.length,
                  itemBuilder: (context, index) => FocusableListTile(
                    title: Text(_tags[index]),
                    trailing: const AppIcon(Symbols.close_rounded),
                    onTap: () => _removeTag(index),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        FocusableButton(
          onPressed: () => Navigator.pop(context),
          child: TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel)),
        ),
        FocusableButton(
          focusNode: _saveFocusNode,
          onPressed: () => Navigator.pop(context, _tags),
          child: TextButton(
            onPressed: () => Navigator.pop(context, _tags),
            child: Text(t.common.save),
          ),
        ),
      ],
    );
  }
}
