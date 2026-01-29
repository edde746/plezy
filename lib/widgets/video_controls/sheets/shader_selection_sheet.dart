import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../i18n/strings.g.dart';
import '../../../models/shader_preset.dart';
import '../../../providers/shader_provider.dart';
import '../../../services/shader_service.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/focusable_bottom_sheet.dart';
import '../../../widgets/focusable_list_tile.dart';
import 'base_video_control_sheet.dart';
import 'video_control_sheet_launcher.dart';

/// Bottom sheet for selecting shader presets during video playback
class ShaderSelectionSheet extends StatefulWidget {
  final ShaderService shaderService;
  final VoidCallback? onPresetChanged;

  const ShaderSelectionSheet({
    super.key,
    required this.shaderService,
    this.onPresetChanged,
  });

  static void show({
    required BuildContext context,
    required ShaderService shaderService,
    VoidCallback? onPresetChanged,
    VoidCallback? onOpen,
    VoidCallback? onClose,
  }) {
    VideoControlSheetLauncher.show(
      context: context,
      onOpen: onOpen,
      onClose: onClose,
      builder: (context) => ShaderSelectionSheet(
        shaderService: shaderService,
        onPresetChanged: onPresetChanged,
      ),
    );
  }

  @override
  State<ShaderSelectionSheet> createState() => _ShaderSelectionSheetState();
}

class _ShaderSelectionSheetState extends State<ShaderSelectionSheet> {
  late final FocusNode _initialFocusNode;

  @override
  void initState() {
    super.initState();
    _initialFocusNode = FocusNode(debugLabel: 'ShaderSelectionInitialFocus');
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
      child: Consumer<ShaderProvider>(
        builder: (context, shaderProvider, _) {
          final currentPreset = widget.shaderService.currentPreset;
          final presets = ShaderPreset.allPresets;

          return BaseVideoControlSheet(
            title: t.shaders.title,
            icon: Symbols.auto_fix_high_rounded,
            iconColor: currentPreset.isEnabled ? Colors.amber : null,
            child: ListView.builder(
              itemCount: presets.length,
              itemBuilder: (context, index) {
                final preset = presets[index];
                final isSelected = preset.id == currentPreset.id;
                final shouldFocus = index == 0;

                return _buildPresetTile(
                  preset: preset,
                  isSelected: isSelected,
                  focusNode: shouldFocus ? _initialFocusNode : null,
                  onTap: () async {
                    await widget.shaderService.applyPreset(preset);
                    await shaderProvider.setPreset(preset);
                    widget.onPresetChanged?.call();
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPresetTile({
    required ShaderPreset preset,
    required bool isSelected,
    required VoidCallback onTap,
    FocusNode? focusNode,
  }) {
    final subtitle = _getPresetSubtitle(preset);

    return FocusableListTile(
      focusNode: focusNode,
      title: Text(
        preset.name,
        style: TextStyle(color: isSelected ? Colors.amber : Colors.white),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12))
          : null,
      trailing: isSelected ? const AppIcon(Symbols.check_rounded, fill: 1, color: Colors.amber) : null,
      onTap: onTap,
    );
  }

  String? _getPresetSubtitle(ShaderPreset preset) {
    switch (preset.type) {
      case ShaderPresetType.none:
        return t.shaders.noShaderDescription;
      case ShaderPresetType.nvscaler:
        return t.shaders.nvscalerDescription;
      case ShaderPresetType.anime4k:
        if (preset.anime4kConfig != null) {
          final quality = preset.anime4kConfig!.quality == Anime4KQuality.fast ? t.shaders.qualityFast : t.shaders.qualityHQ;
          final mode = preset.modeDisplayName;
          return '$quality - ${t.shaders.mode} $mode';
        }
        return null;
    }
  }
}
