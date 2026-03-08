import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../i18n/strings.g.dart';
import '../models/download_settings.dart';
import '../providers/download_provider.dart';
import '../services/auto_download_service.dart';
import '../services/plex_client.dart';
import '../services/settings_service.dart';
import '../utils/dialogs.dart';
import '../utils/platform_detector.dart';
import '../utils/snackbar_helper.dart';
import 'tv_number_spinner.dart';

const _buttonPadding = EdgeInsets.symmetric(horizontal: 18, vertical: 14);
const _buttonShape = StadiumBorder();

const _qualityPresets = [
  null, // Original
  '1080p',
  '720p',
  '480p',
  '360p',
];

/// Shows the download settings dialog for a series or movie.
/// Returns the saved [DownloadSettings] or null if cancelled.
///
/// If [downloadProvider] and [client] are provided, changing the transcode
/// quality will prompt the user to confirm re-downloading existing content.
Future<DownloadSettings?> showDownloadSettingsDialog(
  BuildContext context, {
  required String ratingKey,
  required String title,
  required bool isSeries,
  DownloadProvider? downloadProvider,
  PlexClient? client,
}) async {
  final settingsService = await SettingsService.getInstance();
  final existing = settingsService.getDownloadSettings(ratingKey);
  final initial = existing ?? settingsService.getLastUsedDownloadSettings() ?? const DownloadSettings();

  if (!context.mounted) return null;

  final result = await showDialog<DownloadSettings>(
    context: context,
    builder: (dialogContext) => _DownloadSettingsDialog(
      title: title,
      isSeries: isSeries,
      initial: initial,
    ),
  );

  if (result != null) {
    final settingsChanged = existing != null && result != existing;
    final qualityChanged = existing != null && result.transcodeQuality != existing.transcodeQuality;

    // Check if there are downloads that need re-encoding
    bool hasDownloads = false;
    if (qualityChanged && downloadProvider != null) {
      if (isSeries) {
        hasDownloads = downloadProvider.getDownloadedEpisodesForShow(ratingKey).isNotEmpty;
      } else {
        final movieGlobalKey = downloadProvider.findGlobalKeyForRatingKey(ratingKey);
        hasDownloads = movieGlobalKey != null && downloadProvider.isDownloaded(movieGlobalKey);
      }
    }

    if (qualityChanged && hasDownloads) {
      if (!context.mounted) return null;
      final confirmed = await showConfirmDialog(
        context,
        title: t.downloads.quality,
        message: t.downloads.qualityChangeWarning,
        confirmText: t.common.confirm,
        isDestructive: true,
      );
      if (!confirmed || !context.mounted) return null;
    }

    // Save settings BEFORE re-queueing so queueDownload reads the new quality
    await settingsService.setDownloadSettings(ratingKey, result);

    if (qualityChanged && hasDownloads && downloadProvider != null && client != null) {
      await downloadProvider.redownloadAtNewQuality(ratingKey, isSeries, client);
      if (context.mounted) {
        showSuccessSnackBar(context, t.downloads.settingsSaved);
      }
    } else if (settingsChanged && isSeries && downloadProvider != null && client != null) {
      // Any setting changed (episode count, retention, etc.) — refresh to apply
      final showGlobalKey = downloadProvider.findGlobalKeyForRatingKey(ratingKey);
      if (showGlobalKey != null) {
        final showMeta = downloadProvider.getMetadata(showGlobalKey);
        if (showMeta != null) {
          await AutoDownloadService.instance.refreshShow(showMeta, client, downloadProvider);
        }
      }
    }
  }

  return result;
}

class _DownloadSettingsDialog extends StatefulWidget {
  final String title;
  final bool isSeries;
  final DownloadSettings initial;

  const _DownloadSettingsDialog({
    required this.title,
    required this.isSeries,
    required this.initial,
  });

  @override
  State<_DownloadSettingsDialog> createState() => _DownloadSettingsDialogState();
}

class _DownloadSettingsDialogState extends State<_DownloadSettingsDialog> {
  late bool _downloadAllEpisodes;
  late int _episodeCount;
  late DeleteRetentionMode _deleteMode;
  late int _retentionDays;
  late int _retentionWeeks;
  late String? _transcodeQuality;

  final _episodeCountController = TextEditingController();
  final _retentionValueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _downloadAllEpisodes = widget.initial.downloadAllEpisodes;
    _episodeCount = widget.initial.episodeCount;
    _deleteMode = widget.initial.deleteMode;
    // Initialize each retention value from settings based on active mode
    _retentionDays = widget.initial.deleteMode == DeleteRetentionMode.afterDays
        ? widget.initial.retentionValue
        : 7;
    _retentionWeeks = widget.initial.deleteMode == DeleteRetentionMode.afterWeeks
        ? widget.initial.retentionValue
        : 4;
    _transcodeQuality = widget.initial.transcodeQuality;
    _episodeCountController.text = _episodeCount.toString();
    _retentionValueController.text = _activeRetentionValue.toString();
  }

  int get _activeRetentionValue =>
      _deleteMode == DeleteRetentionMode.afterWeeks ? _retentionWeeks : _retentionDays;

  @override
  void dispose() {
    _episodeCountController.dispose();
    _retentionValueController.dispose();
    super.dispose();
  }

  DownloadSettings _buildSettings() {
    return DownloadSettings(
      downloadAllEpisodes: _downloadAllEpisodes,
      episodeCount: _episodeCount,
      deleteMode: _deleteMode,
      retentionValue: _activeRetentionValue,
      transcodeQuality: _transcodeQuality,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTV = PlatformDetector.isTV();

    return AlertDialog(
      title: Text(
        '${t.downloads.downloadSettings}: ${widget.title}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isSeries) ...[
              // EPISODES section
              Text(t.downloads.episodes, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.downloads.downloadAllEpisodes),
                value: _downloadAllEpisodes,
                onChanged: (v) => setState(() => _downloadAllEpisodes = v),
              ),
              AnimatedOpacity(
                opacity: _downloadAllEpisodes ? 0.4 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: _downloadAllEpisodes,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Row(
                      children: [
                        Expanded(child: Text(t.downloads.keepLastNUnwatched(count: _episodeCount))),
                        const SizedBox(width: 8),
                        if (isTV)
                          SizedBox(
                            width: 160,
                            child: TvNumberSpinner(
                              value: _episodeCount,
                              min: 1,
                              max: 100,
                              onChanged: (v) => setState(() => _episodeCount = v),
                            ),
                          )
                        else
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: _episodeCountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              textAlign: TextAlign.center,
                              onChanged: (v) {
                                final parsed = int.tryParse(v);
                                if (parsed != null && parsed >= 1) {
                                  setState(() => _episodeCount = parsed);
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 24),

              // RETENTION section
              Text(
                t.downloads.retention,
                style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 4),
              Text(t.downloads.retentionDescription, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              RadioListTile<DeleteRetentionMode>(
                contentPadding: EdgeInsets.zero,
                title: Text(t.downloads.onNextRefresh),
                value: DeleteRetentionMode.onNextRefresh,
                groupValue: _deleteMode,
                onChanged: (v) => setState(() => _deleteMode = v!),
              ),
              RadioListTile<DeleteRetentionMode>(
                contentPadding: EdgeInsets.zero,
                title: _buildRetentionRow(
                  t.downloads.afterDays(count: _retentionDays),
                  DeleteRetentionMode.afterDays,
                  isTV,
                ),
                value: DeleteRetentionMode.afterDays,
                groupValue: _deleteMode,
                onChanged: (v) => setState(() {
                  _deleteMode = v!;
                  _retentionValueController.text = _retentionDays.toString();
                }),
              ),
              RadioListTile<DeleteRetentionMode>(
                contentPadding: EdgeInsets.zero,
                title: _buildRetentionRow(
                  t.downloads.afterWeeks(count: _retentionWeeks),
                  DeleteRetentionMode.afterWeeks,
                  isTV,
                ),
                value: DeleteRetentionMode.afterWeeks,
                groupValue: _deleteMode,
                onChanged: (v) => setState(() {
                  _deleteMode = v!;
                  _retentionValueController.text = _retentionWeeks.toString();
                }),
              ),
              const Divider(height: 24),
            ],

            // QUALITY section (for both series and movies)
            Text(t.downloads.quality, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: 8),
            ..._qualityPresets.map((preset) {
              final label = preset ?? t.downloads.original;
              return RadioListTile<String?>(
                contentPadding: EdgeInsets.zero,
                title: Text(label),
                value: preset,
                groupValue: _transcodeQuality,
                onChanged: (v) => setState(() => _transcodeQuality = v),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(padding: _buttonPadding, shape: _buttonShape),
          child: Text(t.common.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _buildSettings()),
          child: Text(t.common.save),
        ),
      ],
    );
  }

  Widget _buildRetentionRow(String label, DeleteRetentionMode mode, bool isTV) {
    if (_deleteMode != mode) return Text(label);

    return Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 8),
        if (isTV)
          SizedBox(
            width: 160,
            child: TvNumberSpinner(
              value: _activeRetentionValue,
              min: 1,
              max: mode == DeleteRetentionMode.afterDays ? 365 : 52,
              onChanged: (v) => setState(() {
                if (mode == DeleteRetentionMode.afterWeeks) {
                  _retentionWeeks = v;
                } else {
                  _retentionDays = v;
                }
                _retentionValueController.text = v.toString();
              }),
            ),
          )
        else
          SizedBox(
            width: 60,
            child: TextField(
              controller: _retentionValueController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              onChanged: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null && parsed >= 1) {
                  setState(() {
                    if (mode == DeleteRetentionMode.afterWeeks) {
                      _retentionWeeks = parsed;
                    } else {
                      _retentionDays = parsed;
                    }
                  });
                }
              },
            ),
          ),
      ],
    );
  }
}
