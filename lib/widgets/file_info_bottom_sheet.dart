import 'package:flutter/material.dart';
import '../models/plex_file_info.dart';
import '../i18n/strings.g.dart';

class FileInfoBottomSheet extends StatelessWidget {
  final PlexFileInfo fileInfo;
  final String title;

  const FileInfoBottomSheet({
    super.key,
    required this.fileInfo,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    const Icon(
                      Icons.info_outline,
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
                      icon: const Icon(Icons.close, color: Colors.white),
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
                    if (title.isNotEmpty) ...[
                      Text(
                        title,
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
                      fileInfo.videoCodec ?? t.common.unknown,
                    ),
                    _buildInfoRow(
                      t.fileInfo.resolution,
                      fileInfo.resolutionFormatted,
                    ),
                    _buildInfoRow(
                      t.fileInfo.bitrate,
                      fileInfo.bitrateFormatted,
                    ),
                    _buildInfoRow(
                      t.fileInfo.frameRate,
                      fileInfo.frameRateFormatted,
                    ),
                    _buildInfoRow(
                      t.fileInfo.aspectRatio,
                      fileInfo.aspectRatioFormatted,
                    ),
                    if (fileInfo.videoProfile != null)
                      _buildInfoRow(t.fileInfo.profile, fileInfo.videoProfile!),
                    if (fileInfo.bitDepth != null)
                      _buildInfoRow(
                        t.fileInfo.bitDepth,
                        '${fileInfo.bitDepth} bit',
                      ),
                    if (fileInfo.colorSpace != null)
                      _buildInfoRow(
                        t.fileInfo.colorSpace,
                        fileInfo.colorSpace!,
                      ),
                    if (fileInfo.colorRange != null)
                      _buildInfoRow(
                        t.fileInfo.colorRange,
                        fileInfo.colorRange!,
                      ),
                    if (fileInfo.colorPrimaries != null)
                      _buildInfoRow(
                        t.fileInfo.colorPrimaries,
                        fileInfo.colorPrimaries!,
                      ),
                    if (fileInfo.chromaSubsampling != null)
                      _buildInfoRow(
                        t.fileInfo.chromaSubsampling,
                        fileInfo.chromaSubsampling!,
                      ),
                    const SizedBox(height: 20),

                    // Audio Section
                    _buildSectionHeader(t.fileInfo.audio),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      t.fileInfo.codec,
                      fileInfo.audioCodec ?? t.common.unknown,
                    ),
                    _buildInfoRow(
                      t.fileInfo.channels,
                      fileInfo.audioChannelsFormatted,
                    ),
                    if (fileInfo.audioProfile != null)
                      _buildInfoRow(t.fileInfo.profile, fileInfo.audioProfile!),
                    const SizedBox(height: 20),

                    // File Section
                    _buildSectionHeader(t.fileInfo.file),
                    const SizedBox(height: 8),
                    if (fileInfo.filePath != null)
                      _buildInfoRow(
                        t.fileInfo.path,
                        fileInfo.filePath!,
                        isMonospace: true,
                      ),
                    _buildInfoRow(t.fileInfo.size, fileInfo.fileSizeFormatted),
                    _buildInfoRow(
                      t.fileInfo.container,
                      fileInfo.container ?? t.common.unknown,
                    ),
                    _buildInfoRow(
                      t.fileInfo.duration,
                      fileInfo.durationFormatted,
                    ),
                    const SizedBox(height: 20),

                    // Advanced Section
                    _buildSectionHeader(t.fileInfo.advanced),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      t.fileInfo.optimizedForStreaming,
                      fileInfo.optimizedForStreaming == true
                          ? t.common.yes
                          : t.common.no,
                    ),
                    _buildInfoRow(
                      t.fileInfo.has64bitOffsets,
                      fileInfo.has64bitOffsets == true
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
