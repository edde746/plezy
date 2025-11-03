import 'package:flutter/material.dart';
import '../models/plex_file_info.dart';

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
                        'File Info',
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
                    _buildSectionHeader('Video'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Codec', fileInfo.videoCodec ?? 'Unknown'),
                    _buildInfoRow('Resolution', fileInfo.resolutionFormatted),
                    _buildInfoRow('Bitrate', fileInfo.bitrateFormatted),
                    _buildInfoRow('Frame Rate', fileInfo.frameRateFormatted),
                    _buildInfoRow('Aspect Ratio', fileInfo.aspectRatioFormatted),
                    if (fileInfo.videoProfile != null)
                      _buildInfoRow('Profile', fileInfo.videoProfile!),
                    if (fileInfo.bitDepth != null)
                      _buildInfoRow('Bit Depth', '${fileInfo.bitDepth} bit'),
                    if (fileInfo.colorSpace != null)
                      _buildInfoRow('Color Space', fileInfo.colorSpace!),
                    if (fileInfo.colorRange != null)
                      _buildInfoRow('Color Range', fileInfo.colorRange!),
                    if (fileInfo.colorPrimaries != null)
                      _buildInfoRow('Color Primaries', fileInfo.colorPrimaries!),
                    if (fileInfo.chromaSubsampling != null)
                      _buildInfoRow('Chroma Subsampling', fileInfo.chromaSubsampling!),
                    const SizedBox(height: 20),

                    // Audio Section
                    _buildSectionHeader('Audio'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Codec', fileInfo.audioCodec ?? 'Unknown'),
                    _buildInfoRow('Channels', fileInfo.audioChannelsFormatted),
                    if (fileInfo.audioProfile != null)
                      _buildInfoRow('Profile', fileInfo.audioProfile!),
                    const SizedBox(height: 20),

                    // File Section
                    _buildSectionHeader('File'),
                    const SizedBox(height: 8),
                    if (fileInfo.filePath != null)
                      _buildInfoRow('Path', fileInfo.filePath!, isMonospace: true),
                    _buildInfoRow('Size', fileInfo.fileSizeFormatted),
                    _buildInfoRow('Container', fileInfo.container ?? 'Unknown'),
                    _buildInfoRow('Duration', fileInfo.durationFormatted),
                    const SizedBox(height: 20),

                    // Advanced Section
                    _buildSectionHeader('Advanced'),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Optimized for Streaming',
                      fileInfo.optimizedForStreaming == true ? 'Yes' : 'No',
                    ),
                    _buildInfoRow(
                      '64-bit Offsets',
                      fileInfo.has64bitOffsets == true ? 'Yes' : 'No',
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
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
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
