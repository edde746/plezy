import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/widgets/app_icon.dart';

import '../../../i18n/strings.g.dart';
import '../../../media/media_version.dart';
import '../../../models/transcode_quality_preset.dart';
import '../../../utils/quality_preset_labels.dart';
import '../../../utils/scroll_utils.dart';
import '../../../widgets/focusable_list_tile.dart';
import '../../../widgets/overlay_sheet.dart';
import 'base_video_control_sheet.dart';
import 'sheet_column_header.dart';

/// Combined sheet for selecting the media [version] (left) and transcode
/// [quality] preset (right). The version column is hidden when there is only
/// one version so the quality list gets the full width. If the server doesn't
/// support video transcoding, only [TranscodeQualityPreset.original] is
/// enabled in the quality column.
class VersionQualitySheet extends StatelessWidget {
  final List<MediaVersion> availableVersions;
  final int selectedMediaIndex;
  final TranscodeQualityPreset selectedQualityPreset;
  final bool serverSupportsTranscoding;
  final int? sourceDurationMs;
  final ValueChanged<int> onVersionSelected;
  final ValueChanged<TranscodeQualityPreset> onQualitySelected;

  const VersionQualitySheet({
    super.key,
    required this.availableVersions,
    required this.selectedMediaIndex,
    required this.selectedQualityPreset,
    required this.serverSupportsTranscoding,
    required this.onVersionSelected,
    required this.onQualitySelected,
    this.sourceDurationMs,
  });

  @override
  Widget build(BuildContext context) {
    final showVersions = availableVersions.length > 1;
    // Quality presets only do something useful when the server can transcode
    // — otherwise non-Original options are disabled and the column degenerates
    // into a single tappable row. Hide it entirely in that case so the
    // versions list (when present) gets the full sheet.
    final showQuality = serverSupportsTranscoding;
    final title = showQuality
        ? (showVersions ? t.videoControls.versionQualityButton : t.videoControls.qualityColumnHeader)
        : t.videoControls.versionColumnHeader;

    final qualityColumn = FocusTraversalGroup(
      child: _QualityColumn(
        selected: selectedQualityPreset,
        enabledForTranscoding: serverSupportsTranscoding,
        sourceBitrateKbps: _sourceBitrateKbps(),
        sourceDurationMs: sourceDurationMs,
        sourceSizeBytes: _sourceSizeBytes(),
        onSelected: (preset) {
          OverlaySheetController.of(context).close();
          onQualitySelected(preset);
        },
        showHeader: showVersions,
      ),
    );

    final versionColumn = FocusTraversalGroup(
      child: _VersionColumn(
        versions: availableVersions,
        selectedIndex: selectedMediaIndex,
        onSelected: (index) {
          OverlaySheetController.of(context).close();
          onVersionSelected(index);
        },
        showHeader: showQuality,
      ),
    );

    final Widget body;
    if (showVersions && showQuality) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: versionColumn),
          VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
          Expanded(child: qualityColumn),
        ],
      );
    } else if (showVersions) {
      body = versionColumn;
    } else {
      body = qualityColumn;
    }

    return BaseVideoControlSheet(title: title, icon: Symbols.high_quality_rounded, child: body);
  }

  int? _sourceBitrateKbps() {
    if (selectedMediaIndex < 0 || selectedMediaIndex >= availableVersions.length) {
      return null;
    }
    final b = availableVersions[selectedMediaIndex].bitrate;
    if (b == null || b <= 0) return null;
    return b;
  }

  int? _sourceSizeBytes() {
    if (selectedMediaIndex < 0 || selectedMediaIndex >= availableVersions.length) {
      return null;
    }
    final parts = availableVersions[selectedMediaIndex].parts;
    if (parts.isEmpty) return null;
    var total = 0;
    for (final p in parts) {
      final s = p.sizeBytes;
      if (s == null || s <= 0) return null;
      total += s;
    }
    return total > 0 ? total : null;
  }
}

class _VersionColumn extends StatefulWidget {
  final List<MediaVersion> versions;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool showHeader;

  const _VersionColumn({
    required this.versions,
    required this.selectedIndex,
    required this.onSelected,
    required this.showHeader,
  });

  @override
  State<_VersionColumn> createState() => _VersionColumnState();
}

class _VersionColumnState extends State<_VersionColumn> {
  final _initialScroll = InitialItemScrollController();

  @override
  void dispose() {
    _initialScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _initialScroll.maybeScrollTo(widget.selectedIndex);

    return Column(
      children: [
        if (widget.showHeader) SheetColumnHeader(label: t.videoControls.versionColumnHeader),
        Expanded(
          child: ListView.builder(
            controller: _initialScroll.controller,
            itemCount: widget.versions.length,
            itemBuilder: (context, index) {
              final version = widget.versions[index];
              final isSelected = index == widget.selectedIndex;
              return _SelectionTile(
                key: index == 0 ? _initialScroll.firstItemKey : null,
                label: version.displayLabel,
                isSelected: isSelected,
                onTap: () => widget.onSelected(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QualityColumn extends StatefulWidget {
  final TranscodeQualityPreset selected;
  final bool enabledForTranscoding;
  final int? sourceBitrateKbps;
  final int? sourceDurationMs;
  final int? sourceSizeBytes;
  final ValueChanged<TranscodeQualityPreset> onSelected;
  final bool showHeader;

  const _QualityColumn({
    required this.selected,
    required this.enabledForTranscoding,
    required this.sourceBitrateKbps,
    required this.sourceDurationMs,
    required this.sourceSizeBytes,
    required this.onSelected,
    required this.showHeader,
  });

  @override
  State<_QualityColumn> createState() => _QualityColumnState();
}

class _QualityColumnState extends State<_QualityColumn> {
  final _initialScroll = InitialItemScrollController();

  @override
  void dispose() {
    _initialScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presets = TranscodeQualityPreset.displayOrder;
    final selectedIndex = presets.indexOf(widget.selected);

    _initialScroll.maybeScrollTo(selectedIndex);

    return Column(
      children: [
        if (widget.showHeader) SheetColumnHeader(label: t.videoControls.qualityColumnHeader),
        Expanded(
          child: ListView.builder(
            controller: _initialScroll.controller,
            itemCount: presets.length,
            itemBuilder: (context, index) {
              final preset = presets[index];
              final isSelected = preset == widget.selected;
              final isOriginal = preset.isOriginal;
              final enabled = isOriginal || widget.enabledForTranscoding;

              final trailing = qualityPresetSizeEstimate(
                preset: preset,
                sourceBitrateKbps: widget.sourceBitrateKbps,
                sourceDurationMs: widget.sourceDurationMs,
                sourceSizeBytes: widget.sourceSizeBytes,
              );

              return _SelectionTile(
                key: index == 0 ? _initialScroll.firstItemKey : null,
                label: qualityPresetLabel(preset),
                trailingText: trailing,
                isSelected: isSelected,
                enabled: enabled,
                onTap: enabled ? () => widget.onSelected(preset) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final String label;
  final String? trailingText;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  const _SelectionTile({
    super.key,
    required this.label,
    this.trailingText,
    required this.isSelected,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final disabledColor = scheme.onSurface.withValues(alpha: 0.38);
    final titleColor = !enabled ? disabledColor : (isSelected ? primary : null);
    final trailingColor = !enabled ? disabledColor : scheme.onSurfaceVariant;

    final hasText = trailingText != null && trailingText!.isNotEmpty;
    final trailing = (hasText || isSelected)
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasText) Text(trailingText!, style: TextStyle(color: trailingColor)),
              if (hasText && isSelected) const SizedBox(width: 8),
              if (isSelected) AppIcon(Symbols.check_rounded, fill: 1, color: primary),
            ],
          )
        : null;

    return FocusableListTile(
      title: Text(label, style: TextStyle(color: titleColor)),
      trailing: trailing,
      enabled: enabled,
      onTap: onTap,
    );
  }
}
