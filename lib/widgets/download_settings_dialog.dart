import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../i18n/strings.g.dart';
import '../models/download_settings.dart';
import '../services/settings_service.dart';
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
Future<DownloadSettings?> showDownloadSettingsDialog(
  BuildContext context, {
  required String ratingKey,
  required String title,
  required bool isSeries,
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
    await settingsService.setDownloadSettings(ratingKey, result);
    if (context.mounted) {
      showSuccessSnackBar(context, t.downloads.settingsSaved);
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
  late int _retentionValue;
  late String? _transcodeQuality;

  final _episodeCountController = TextEditingController();
  final _retentionValueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _downloadAllEpisodes = widget.initial.downloadAllEpisodes;
    _episodeCount = widget.initial.episodeCount;
    _deleteMode = widget.initial.deleteMode;
    _retentionValue = widget.initial.retentionValue;
    _transcodeQuality = widget.initial.transcodeQuality;
    _episodeCountController.text = _episodeCount.toString();
    _retentionValueController.text = _retentionValue.toString();
  }

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
      retentionValue: _retentionValue,
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
                  t.downloads.afterDays(count: _retentionValue),
                  DeleteRetentionMode.afterDays,
                  isTV,
                ),
                value: DeleteRetentionMode.afterDays,
                groupValue: _deleteMode,
                onChanged: (v) => setState(() => _deleteMode = v!),
              ),
              RadioListTile<DeleteRetentionMode>(
                contentPadding: EdgeInsets.zero,
                title: _buildRetentionRow(
                  t.downloads.afterWeeks(count: _retentionValue),
                  DeleteRetentionMode.afterWeeks,
                  isTV,
                ),
                value: DeleteRetentionMode.afterWeeks,
                groupValue: _deleteMode,
                onChanged: (v) => setState(() => _deleteMode = v!),
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
              value: _retentionValue,
              min: 1,
              max: mode == DeleteRetentionMode.afterDays ? 365 : 52,
              onChanged: (v) => setState(() {
                _retentionValue = v;
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
                  setState(() => _retentionValue = parsed);
                }
              },
            ),
          ),
      ],
    );
  }
}
