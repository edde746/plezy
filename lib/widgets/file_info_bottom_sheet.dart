import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../media/media_file_info.dart';
import '../i18n/strings.g.dart';
import '../utils/scroll_utils.dart';
import 'bottom_sheet_header.dart';

class FileInfoBottomSheet extends StatefulWidget {
  final MediaFileInfo fileInfo;
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
    final info = widget.fileInfo;
    final hasAdvanced = info.optimizedForStreaming != null || info.has64bitOffsets != null;
    return Column(
      children: [
        // Header
        BottomSheetHeader(title: t.fileInfo.title, icon: Symbols.info_rounded, closeFocusNode: _initialFocusNode),
        // Content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Title
              if (widget.title.isNotEmpty) ...[
                Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),
              ],

              // Video Section
              _buildSectionHeader(t.fileInfo.video),
              const SizedBox(height: 8),
              if (info.videoCodec != null) _buildInfoRow(t.fileInfo.codec, info.videoCodec!),
              if (info.resolutionFormatted != null) _buildInfoRow(t.fileInfo.resolution, info.resolutionFormatted!),
              if (info.videoBitrateFormatted != null) _buildInfoRow(t.fileInfo.bitrate, info.videoBitrateFormatted!),
              if (info.frameRateFormatted != null) _buildInfoRow(t.fileInfo.frameRate, info.frameRateFormatted!),
              if (info.aspectRatioFormatted != null) _buildInfoRow(t.fileInfo.aspectRatio, info.aspectRatioFormatted!),
              if (info.videoProfile != null) _buildInfoRow(t.fileInfo.profile, info.videoProfile!),
              if (info.bitDepth != null) _buildInfoRow(t.fileInfo.bitDepth, '${info.bitDepth} bit'),
              if (info.colorSpace != null) _buildInfoRow(t.fileInfo.colorSpace, info.colorSpace!),
              if (info.colorRange != null) _buildInfoRow(t.fileInfo.colorRange, info.colorRange!),
              if (info.colorPrimaries != null) _buildInfoRow(t.fileInfo.colorPrimaries, info.colorPrimaries!),
              if (info.chromaSubsampling != null) _buildInfoRow(t.fileInfo.chromaSubsampling, info.chromaSubsampling!),
              const SizedBox(height: 20),

              // Audio Section
              _buildSectionHeader(t.fileInfo.audio),
              const SizedBox(height: 8),
              if (info.audioTracks.isNotEmpty)
                for (int i = 0; i < info.audioTracks.length; i++) _buildInfoRow('${i + 1}', info.audioTracks[i].label),
              if (info.audioTracks.isEmpty) ...[
                if (info.audioCodec != null) _buildInfoRow(t.fileInfo.codec, info.audioCodec!),
                if (info.audioChannelsFormatted != null)
                  _buildInfoRow(t.fileInfo.channels, info.audioChannelsFormatted!),
                if (info.audioProfile != null) _buildInfoRow(t.fileInfo.profile, info.audioProfile!),
              ],
              const SizedBox(height: 20),

              // Subtitles Section
              if (info.subtitleTracks.isNotEmpty) ...[
                _buildSectionHeader(t.fileInfo.subtitles),
                const SizedBox(height: 8),
                for (int i = 0; i < info.subtitleTracks.length; i++)
                  _buildInfoRow('${i + 1}', info.subtitleTracks[i].label),
                const SizedBox(height: 20),
              ],

              // File Section
              _buildSectionHeader(t.fileInfo.file),
              const SizedBox(height: 8),
              if (info.filePath != null) _buildInfoRow(t.fileInfo.path, info.filePath!, isMonospace: true),
              if (info.fileSizeFormatted != null) _buildInfoRow(t.fileInfo.size, info.fileSizeFormatted!),
              if (info.container != null) _buildInfoRow(t.fileInfo.container, info.container!),
              if (info.durationFormatted != null) _buildInfoRow(t.fileInfo.duration, info.durationFormatted!),
              if (info.bitrateFormatted != null) _buildInfoRow(t.fileInfo.overallBitrate, info.bitrateFormatted!),
              if (hasAdvanced) ...[
                const SizedBox(height: 20),

                // Advanced Section
                _buildSectionHeader(t.fileInfo.advanced),
                const SizedBox(height: 8),
                if (info.optimizedForStreaming != null)
                  _buildInfoRow(
                    t.fileInfo.optimizedForStreaming,
                    info.optimizedForStreaming! ? t.common.yes : t.common.no,
                  ),
                if (info.has64bitOffsets != null)
                  _buildInfoRow(t.fileInfo.has64bitOffsets, info.has64bitOffsets! ? t.common.yes : t.common.no),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
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
              child: Text(
                widget.label,
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14),
              ),
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
