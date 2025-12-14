import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../models/plex_file_info.dart';
import '../i18n/strings.g.dart';
import 'focusable_bottom_sheet.dart';

class FileInfoBottomSheet extends StatefulWidget {
  final PlexFileInfo fileInfo;
  final String title;

  const FileInfoBottomSheet({
    super.key,
    required this.fileInfo,
    required this.title,
  });

  @override
  State<FileInfoBottomSheet> createState() => _FileInfoBottomSheetState();
}

class _FileInfoBottomSheetState extends State<FileInfoBottomSheet> {
  late final FocusNode _initialFocusNode;

  @override
  void initState() {
    super.initState();
    _initialFocusNode = FocusNode(
      debugLabel: 'FileInfoBottomSheetInitialFocus',
    );
  }

  @override
  void dispose() {
    _initialFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableBottomSheet(
      initialFocusNode: _initialFocusNode,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const AppIcon(
                        Symbols.info_rounded,
                        fill: 1,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.fileInfo.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        focusNode: _initialFocusNode,
                        icon: const AppIcon(
                          Symbols.close_rounded,
                          fill: 1,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.grey, height: 1),
                // Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Title
                      if (widget.title.isNotEmpty) ...[
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Video Section
                      _buildSectionHeader(t.fileInfo.video),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        t.fileInfo.codec,
                        widget.fileInfo.videoCodec ?? t.common.unknown,
                      ),
                      _buildInfoRow(
                        t.fileInfo.resolution,
                        widget.fileInfo.resolutionFormatted,
                      ),
                      _buildInfoRow(
                        t.fileInfo.bitrate,
                        widget.fileInfo.bitrateFormatted,
                      ),
                      _buildInfoRow(
                        t.fileInfo.frameRate,
                        widget.fileInfo.frameRateFormatted,
                      ),
                      _buildInfoRow(
                        t.fileInfo.aspectRatio,
                        widget.fileInfo.aspectRatioFormatted,
                      ),
                      if (widget.fileInfo.videoProfile != null)
                        _buildInfoRow(
                          t.fileInfo.profile,
                          widget.fileInfo.videoProfile!,
                        ),
                      if (widget.fileInfo.bitDepth != null)
                        _buildInfoRow(
                          t.fileInfo.bitDepth,
                          '${widget.fileInfo.bitDepth} bit',
                        ),
                      if (widget.fileInfo.colorSpace != null)
                        _buildInfoRow(
                          t.fileInfo.colorSpace,
                          widget.fileInfo.colorSpace!,
                        ),
                      if (widget.fileInfo.colorRange != null)
                        _buildInfoRow(
                          t.fileInfo.colorRange,
                          widget.fileInfo.colorRange!,
                        ),
                      if (widget.fileInfo.colorPrimaries != null)
                        _buildInfoRow(
                          t.fileInfo.colorPrimaries,
                          widget.fileInfo.colorPrimaries!,
                        ),
                      if (widget.fileInfo.chromaSubsampling != null)
                        _buildInfoRow(
                          t.fileInfo.chromaSubsampling,
                          widget.fileInfo.chromaSubsampling!,
                        ),
                      const SizedBox(height: 20),

                      // Audio Section
                      _buildSectionHeader(t.fileInfo.audio),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        t.fileInfo.codec,
                        widget.fileInfo.audioCodec ?? t.common.unknown,
                      ),
                      _buildInfoRow(
                        t.fileInfo.channels,
                        widget.fileInfo.audioChannelsFormatted,
                      ),
                      if (widget.fileInfo.audioProfile != null)
                        _buildInfoRow(
                          t.fileInfo.profile,
                          widget.fileInfo.audioProfile!,
                        ),
                      const SizedBox(height: 20),

                      // File Section
                      _buildSectionHeader(t.fileInfo.file),
                      const SizedBox(height: 8),
                      if (widget.fileInfo.filePath != null)
                        _buildInfoRow(
                          t.fileInfo.path,
                          widget.fileInfo.filePath!,
                          isMonospace: true,
                        ),
                      _buildInfoRow(
                        t.fileInfo.size,
                        widget.fileInfo.fileSizeFormatted,
                      ),
                      _buildInfoRow(
                        t.fileInfo.container,
                        widget.fileInfo.container ?? t.common.unknown,
                      ),
                      _buildInfoRow(
                        t.fileInfo.duration,
                        widget.fileInfo.durationFormatted,
                      ),
                      const SizedBox(height: 20),

                      // Advanced Section
                      _buildSectionHeader(t.fileInfo.advanced),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        t.fileInfo.optimizedForStreaming,
                        widget.fileInfo.optimizedForStreaming == true
                            ? t.common.yes
                            : t.common.no,
                      ),
                      _buildInfoRow(
                        t.fileInfo.has64bitOffsets,
                        widget.fileInfo.has64bitOffsets == true
                            ? t.common.yes
                            : t.common.no,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: isMonospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
