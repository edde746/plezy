import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:io';

import '../services/download_service.dart';
import '../models/download_item.dart';
import '../widgets/plex_optimized_image.dart';
import '../utils/video_player_navigation.dart';
import '../utils/provider_extensions.dart';
import '../theme/theme_helper.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  @override
  void initState() {
    super.initState();
    // Keep screen awake while on this screen to monitor downloads
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final downloadService = context.watch<DownloadService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: Builder(
        builder: (context) {
          if (downloadService.downloadItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_outlined,
                    size: 64,
                    color: t.text.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No downloads',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: t.text.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: downloadService.downloadItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = downloadService.downloadItems[index];
              return _DownloadItemTile(item: item);
            },
          );
        },
      ),
    );
  }
}

class _DownloadItemTile extends StatelessWidget {
  final DownloadItem item;

  const _DownloadItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final isCompleted = item.status == DownloadStatus.completed;
    final isDownloading = item.status == DownloadStatus.downloading;
    final isFailed = item.status == DownloadStatus.failed;
    final isPending = item.status == DownloadStatus.pending;

    String titleText = item.metadata.title;
    String? subtitleText = item.metadata.year?.toString();

    if (item.metadata.type == 'episode') {
      final showTitle = item.metadata.grandparentTitle ?? 'Unknown Show';
      final s = item.metadata.parentIndex ?? 0;
      final e = item.metadata.index ?? 0;
      titleText = '$showTitle S${s}E$e';
      subtitleText = item.metadata.title;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isCompleted && item.localPath != null
            ? () {
                navigateToVideoPlayer(
                  context,
                  metadata: item.metadata,
                  fileOverride: item.localPath,
                );
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              SizedBox(
                width: 80,
                height: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: _buildThumbnail(context),
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleText,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitleText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitleText,
                        style: TextStyle(color: t.textMuted, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),

                    if (isDownloading || isPending) ...[
                      LinearProgressIndicator(value: item.progress),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isPending
                                ? 'Pending...'
                                : 'Downloading... ${(item.progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(color: t.textMuted, fontSize: 12),
                          ),
                          if (item.downloadSpeed > 0)
                            Text(
                              _formatSpeed(item.downloadSpeed),
                              style: TextStyle(
                                color: t.textMuted,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],

                    if (isFailed) ...[
                      Text(
                        item.error ?? 'Error',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],

                    if (isCompleted)
                      FutureBuilder<int?>(
                        future: item.localPath != null
                            ? File(
                                item.localPath!,
                              ).length().catchError((_) => 0)
                            : null,
                        builder: (context, snapshot) {
                          final size = snapshot.data;
                          if (size == null) {
                            return const Text(
                              'Downloaded',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            );
                          }
                          return Text(
                            _formatBytes(size),
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              // Actions
              Column(
                children: [
                  if (isDownloading || isPending)
                    IconButton(
                      icon: const Icon(Icons.cancel),
                      onPressed: () {
                        context.read<DownloadService>().delete(item.id);
                      },
                    ),
                  if (isFailed)
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Retry',
                      onPressed: () {
                        try {
                          final client = context.getClientForServer(
                            item.metadata.serverId!,
                          );
                          context.read<DownloadService>().retry(
                            item.id,
                            client,
                          );
                        } catch (_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Cannot retry: Server not found or offline',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  if (isCompleted || isFailed)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        context.read<DownloadService>().delete(item.id);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    try {
      final client = context.getClientForServer(item.metadata.serverId!);

      // Use show poster for episodes, otherwise default thumb
      String? imagePath = item.metadata.thumb;
      if (item.metadata.type == 'episode') {
        imagePath = item.metadata.grandparentThumb ?? item.metadata.thumb;
      }

      return PlexOptimizedImage.poster(
        client: client,
        imagePath: imagePath,
        width: 80,
        height: 120,
        fit: BoxFit.cover,
      );
    } catch (_) {
      return Container(
        color: Colors.grey[800],
        child: const Icon(Icons.movie, size: 32),
      );
    }
  }

  String _formatSpeed(int bytesPerSecond) {
    if (bytesPerSecond < 1024) return '$bytesPerSecond B/s';
    if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
