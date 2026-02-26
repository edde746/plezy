import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../focus/focusable_button.dart';
import '../focus/focusable_wrapper.dart';
import '../i18n/strings.g.dart';
import '../services/plex_client.dart';
import '../utils/dialogs.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/app_icon.dart';
import '../widgets/plex_optimized_image.dart';

class ArtworkPickerDialog extends StatefulWidget {
  final PlexClient client;
  final String ratingKey;
  final String element; // "posters" or "arts"

  const ArtworkPickerDialog({
    super.key,
    required this.client,
    required this.ratingKey,
    required this.element,
  });

  @override
  State<ArtworkPickerDialog> createState() => _ArtworkPickerDialogState();
}

class _ArtworkPickerDialogState extends State<ArtworkPickerDialog> {
  List<Map<String, dynamic>>? _artworkList;
  bool _isLoading = true;
  bool _isApplying = false;

  bool get _isPosters => widget.element == 'posters';

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  Future<void> _loadArtwork() async {
    final artwork = await widget.client.getAvailableArtwork(widget.ratingKey, widget.element);
    if (!mounted) return;
    setState(() {
      _artworkList = artwork;
      _isLoading = false;
    });
  }

  Future<void> _selectArtwork(Map<String, dynamic> artwork) async {
    final key = artwork['key'] as String?;
    if (key == null || _isApplying) return;

    setState(() => _isApplying = true);

    final success = await widget.client.setArtworkFromUrl(widget.ratingKey, widget.element, key);

    if (!mounted) return;
    setState(() => _isApplying = false);

    if (success) {
      showSuccessSnackBar(context, t.metadataEdit.artworkUpdated);
      Navigator.pop(context, true);
    } else {
      showErrorSnackBar(context, t.metadataEdit.artworkUpdateFailed);
    }
  }

  Future<void> _addFromUrl() async {
    final url = await showTextInputDialog(
      context,
      title: t.metadataEdit.fromUrl,
      labelText: t.metadataEdit.imageUrl,
      hintText: t.metadataEdit.enterImageUrl,
    );

    if (url == null || url.isEmpty || !mounted) return;

    setState(() => _isApplying = true);

    final success = await widget.client.setArtworkFromUrl(widget.ratingKey, widget.element, url);

    if (!mounted) return;
    setState(() => _isApplying = false);

    if (success) {
      showSuccessSnackBar(context, t.metadataEdit.artworkUpdated);
      Navigator.pop(context, true);
    } else {
      showErrorSnackBar(context, t.metadataEdit.artworkUpdateFailed);
    }
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty || !mounted) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    setState(() => _isApplying = true);

    final success = await widget.client.uploadArtwork(widget.ratingKey, widget.element, bytes);

    if (!mounted) return;
    setState(() => _isApplying = false);

    if (success) {
      showSuccessSnackBar(context, t.metadataEdit.artworkUpdated);
      Navigator.pop(context, true);
    } else {
      showErrorSnackBar(context, t.metadataEdit.artworkUpdateFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isPosters ? t.metadataEdit.selectPoster : t.metadataEdit.selectBackground;

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 500,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : (_artworkList == null || _artworkList!.isEmpty)
                ? Center(child: Text(t.metadataEdit.noArtworkAvailable))
                : _buildGrid(),
      ),
      actions: [
        if (_isApplying)
          const Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        FocusableButton(
          onPressed: _addFromUrl,
          child: TextButton.icon(
            onPressed: _addFromUrl,
            icon: const AppIcon(Symbols.link_rounded, size: 18),
            label: Text(t.metadataEdit.fromUrl),
          ),
        ),
        FocusableButton(
          onPressed: _uploadFile,
          child: TextButton.icon(
            onPressed: _uploadFile,
            icon: const AppIcon(Symbols.upload_rounded, size: 18),
            label: Text(t.metadataEdit.uploadFile),
          ),
        ),
        FocusableButton(
          autofocus: true,
          onPressed: () => Navigator.pop(context),
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.common.cancel),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    final crossAxisCount = _isPosters ? 3 : 2;
    final aspectRatio = _isPosters ? 2.0 / 3.0 : 16.0 / 9.0;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: aspectRatio,
      ),
      itemCount: _artworkList!.length,
      itemBuilder: (context, index) {
        final artwork = _artworkList![index];
        final thumbUrl = artwork['thumb'] as String?;
        final isSelected = artwork['selected'] == true;

        return FocusableWrapper(
          borderRadius: 8,
          onSelect: () => _selectArtwork(artwork),
          child: GestureDetector(
            onTap: () => _selectArtwork(artwork),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: PlexOptimizedImage(
                      client: widget.client,
                      imagePath: thumbUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Symbols.check_rounded, size: 16, color: Theme.of(context).colorScheme.onPrimary),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
