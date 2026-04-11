import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../models/plex_file_info.dart';
import '../i18n/strings.g.dart';
import '../utils/scroll_utils.dart';
import 'bottom_sheet_header.dart';

class FileInfoBottomSheet extends StatefulWidget {
  final PlexFileInfo fileInfo;
  final String title;

  const FileInfoBottomSheet({super.key, required this.fileInfo, required this.title});

  @override
  State<FileInfoBottomSheet> createState() => _FileInfoBottomSheetState();
}

class _FileInfoBottomSheetState extends State<FileInfoBottomSheet> {
  late final FocusNode _initialFocusNode;

  @override
  void initState() {
    super.initState();
    _initialFocusNode = FocusNode(debugLabel: 'FileInfoBottomSheetInitialFocus');
  }

  @override
  void dispose() {
    _initialFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        BottomSheetHeader(
          title: t.fileInfo.title,
          icon: Symbols.info_rounded,
          closeFocusNode: _initialFocusNode,
        ),
        // Content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Title
              if (widget.title.isNotEmpty) ...[
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
              ],

              // Video Section
              _buildSectionHeader(t.fileInfo.video),
              const SizedBox(height: 8),
              _buildInfoRow(t.fileInfo.codec, widget.fileInfo.videoCodec ?? t.common.unknown),
              _buildInfoRow(t.fileInfo.resolution, widget.fileInfo.resolutionFormatted),
              if (widget.fileInfo.videoBitrate != null)
                _buildInfoRow(t.fileInfo.bitrate, widget.fileInfo.videoBitrateFormatted),
              _buildInfoRow(t.fileInfo.frameRate, widget.fileInfo.frameRateFormatted),
              _buildInfoRow(t.fileInfo.aspectRatio, widget.fileInfo.aspectRatioFormatted),
              if (widget.fileInfo.videoProfile != null)
                _buildInfoRow(t.fileInfo.profile, widget.fileInfo.videoProfile!),
              if (widget.fileInfo.bitDepth != null)
                _buildInfoRow(t.fileInfo.bitDepth, '${widget.fileInfo.bitDepth} bit'),
              if (widget.fileInfo.colorSpace != null) _buildInfoRow(t.fileInfo.colorSpace, widget.fileInfo.colorSpace!),
              if (widget.fileInfo.colorRange != null) _buildInfoRow(t.fileInfo.colorRange, widget.fileInfo.colorRange!),
              if (widget.fileInfo.colorPrimaries != null)
                _buildInfoRow(t.fileInfo.colorPrimaries, widget.fileInfo.colorPrimaries!),
              if (widget.fileInfo.chromaSubsampling != null)
                _buildInfoRow(t.fileInfo.chromaSubsampling, widget.fileInfo.chromaSubsampling!),
              const SizedBox(height: 20),

              // Audio Section
              _buildSectionHeader(t.fileInfo.audio),
              const SizedBox(height: 8),
              if (widget.fileInfo.audioTracks.isNotEmpty)
                for (int i = 0; i < widget.fileInfo.audioTracks.length; i++)
                  _buildInfoRow('${i + 1}', widget.fileInfo.audioTracks[i].label),
              if (widget.fileInfo.audioTracks.isEmpty) ...[
                _buildInfoRow(t.fileInfo.codec, widget.fileInfo.audioCodec ?? t.common.unknown),
                _buildInfoRow(t.fileInfo.channels, widget.fileInfo.audioChannelsFormatted),
                if (widget.fileInfo.audioProfile != null)
                  _buildInfoRow(t.fileInfo.profile, widget.fileInfo.audioProfile!),
              ],
              const SizedBox(height: 20),

              // Subtitles Section
              if (widget.fileInfo.subtitleTracks.isNotEmpty) ...[
                _buildSectionHeader(t.fileInfo.subtitles),
                const SizedBox(height: 8),
                for (int i = 0; i < widget.fileInfo.subtitleTracks.length; i++)
                  _buildInfoRow('${i + 1}', widget.fileInfo.subtitleTracks[i].label),
                const SizedBox(height: 20),
              ],

              // File Section
              _buildSectionHeader(t.fileInfo.file),
              const SizedBox(height: 8),
              if (widget.fileInfo.filePath != null)
                _buildInfoRow(t.fileInfo.path, widget.fileInfo.filePath!, isMonospace: true),
              _buildInfoRow(t.fileInfo.size, widget.fileInfo.fileSizeFormatted),
              _buildInfoRow(t.fileInfo.container, widget.fileInfo.container ?? t.common.unknown),
              _buildInfoRow(t.fileInfo.duration, widget.fileInfo.durationFormatted),
              _buildInfoRow(t.fileInfo.overallBitrate, widget.fileInfo.bitrateFormatted),
              const SizedBox(height: 20),

              // Advanced Section
              _buildSectionHeader(t.fileInfo.advanced),
              const SizedBox(height: 8),
              _buildInfoRow(
                t.fileInfo.optimizedForStreaming,
                widget.fileInfo.optimizedForStreaming == true ? t.common.yes : t.common.no,
              ),
              _buildInfoRow(
                t.fileInfo.has64bitOffsets,
                widget.fileInfo.has64bitOffsets == true ? t.common.yes : t.common.no,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMonospace = false}) {
    return _FocusableInfoRow(label: label, value: value, isMonospace: isMonospace);
  }
}

class _FocusableInfoRow extends StatefulWidget {
  final String label;
  final String value;
  final bool isMonospace;

  const _FocusableInfoRow({required this.label, required this.value, this.isMonospace = false});

  @override
  State<_FocusableInfoRow> createState() => _FocusableInfoRowState();
}

class _FocusableInfoRowState extends State<_FocusableInfoRow> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      scrollContextToCenter(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(widget.label, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14)),
            ),
            Expanded(
              child: Text(
                widget.value,
                style: TextStyle(fontSize: 14, fontFamily: widget.isMonospace ? 'monospace' : null),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
