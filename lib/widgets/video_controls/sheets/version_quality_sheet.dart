import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/widgets/app_icon.dart';

import '../../../i18n/strings.g.dart';
import '../../../media/media_version.dart';
import '../../../models/transcode_quality_preset.dart';
import '../../../utils/quality_preset_labels.dart';
import '../../../widgets/focusable_list_tile.dart';
import '../../../widgets/overlay_sheet.dart';
import 'sheet_selection_column.dart';
import 'sheet_split_columns.dart';

String versionQualityPickerTitle({required bool showVersions, required bool showQuality}) {
  return showQuality
      ? (showVersions ? t.videoControls.versionQualityButton : t.videoControls.qualityColumnHeader)
      : t.videoControls.versionColumnHeader;
}

/// Combined picker for selecting the media [version] (left) and transcode
/// [quality] preset (right). The version column is hidden when there is only
/// one version so the quality list gets the full width. If the server doesn't
/// support video transcoding, the quality column is hidden entirely.
class VersionQualityPicker extends StatelessWidget {
  final List<MediaVersion> availableVersions;
  final int selectedMediaIndex;
  final TranscodeQualityPreset selectedQualityPreset;
  final bool serverSupportsTranscoding;
  final int? sourceDurationMs;
  final ValueChanged<int> onVersionSelected;
  final ValueChanged<TranscodeQualityPreset> onQualitySelected;

  const VersionQualityPicker({
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
    final showQuality = serverSupportsTranscoding;

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

    if (showVersions && showQuality) {
      return SheetSplitColumns(start: versionColumn, end: qualityColumn);
    } else if (showVersions) {
      return versionColumn;
    } else {
      return qualityColumn;
    }
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

class _VersionColumn extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SheetSelectionColumn(
      headerLabel: showHeader ? t.videoControls.versionColumnHeader : null,
      itemCount: versions.length,
      initialIndex: selectedIndex,
      itemBuilder: (context, index, scope) {
        final version = versions[index];
        final isSelected = index == selectedIndex;
        return _SelectionTile(
          key: scope.keyFor(index),
          label: version.displayLabel,
          isSelected: isSelected,
          onTap: () => onSelected(index),
        );
      },
    );
  }
}

class _QualityColumn extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final presets = TranscodeQualityPreset.displayOrder;

    return SheetSelectionColumn(
      headerLabel: showHeader ? t.videoControls.qualityColumnHeader : null,
      itemCount: presets.length,
      initialIndex: presets.indexOf(selected),
      itemBuilder: (context, index, scope) {
        final preset = presets[index];
        final isSelected = preset == selected;
        final isOriginal = preset.isOriginal;
        final enabled = isOriginal || enabledForTranscoding;

        final trailing = qualityPresetSizeEstimate(
          preset: preset,
          sourceBitrateKbps: sourceBitrateKbps,
          sourceDurationMs: sourceDurationMs,
          sourceSizeBytes: sourceSizeBytes,
        );

        return _SelectionTile(
          key: scope.keyFor(index),
          label: qualityPresetLabel(preset),
          trailingText: trailing,
          isSelected: isSelected,
          enabled: enabled,
          onTap: enabled ? () => onSelected(preset) : null,
        );
      },
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
            mainAxisSize: .min,
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
