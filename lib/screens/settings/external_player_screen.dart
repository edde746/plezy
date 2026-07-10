import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/widgets/app_icon.dart';

import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../models/external_player_models.dart';
import '../../services/settings_service.dart';
import '../../utils/dialogs.dart';
import '../../widgets/expressive_button_group.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_builder.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_section.dart';

class ExternalPlayerScreen extends StatelessWidget {
  const ExternalPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final knownPlayers = KnownPlayers.getForCurrentPlatform();
    return SettingsPage(
      title: Text(t.externalPlayer.title),
      children: [
        SettingsGroup(
          children: [
            SettingSwitchTile(
              pref: SettingsService.useExternalPlayer,
              icon: Symbols.open_in_new_rounded,
              title: t.externalPlayer.useExternalPlayer,
              subtitle: t.externalPlayer.useExternalPlayerDescription,
            ),
          ],
        ),
        SettingsBuilder(
          prefs: [
            SettingsService.useExternalPlayer,
            SettingsService.selectedExternalPlayer,
            SettingsService.customExternalPlayers,
          ],
          builder: (context) {
            final svc = SettingsService.instance;
            if (!svc.read(SettingsService.useExternalPlayer)) return const SizedBox.shrink();
            final selected = svc.read(SettingsService.selectedExternalPlayer);
            final custom = svc.read(SettingsService.customExternalPlayers);
            return Column(
              children: [
                SettingsGroup(
                  title: t.externalPlayer.selectPlayer,
                  children: [for (final p in knownPlayers) _PlayerTile(player: p, selectedId: selected.id)],
                ),
                SettingsGroup(
                  title: t.externalPlayer.customPlayers,
                  children: [
                    for (final p in custom) _PlayerTile(player: p, selectedId: selected.id, isCustom: true),
                    ListTile(
                      leading: const AppIcon(Symbols.add_rounded, fill: 1),
                      title: Text(t.externalPlayer.addCustomPlayer),
                      onTap: () => _showAddCustomPlayerDialog(context),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final ExternalPlayer player;
  final String selectedId;
  final bool isCustom;

  const _PlayerTile({required this.player, required this.selectedId, this.isCustom = false});

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedId == player.id;
    final svc = SettingsService.instance;

    Widget leading;
    if (player.iconAsset != null) {
      leading = ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        child: player.iconAsset!.endsWith('.svg')
            ? SvgPicture.asset(player.iconAsset!, width: 32, height: 32)
            : Image.asset(
                player.iconAsset!,
                width: 32,
                height: 32,
                errorBuilder: (_, _, _) => const AppIcon(Symbols.play_circle_rounded, fill: 1, size: 32),
              ),
      );
    } else if (player.id == 'system_default') {
      leading = const AppIcon(Symbols.open_in_new_rounded, fill: 1, size: 32);
    } else {
      leading = const AppIcon(Symbols.play_circle_rounded, fill: 1, size: 32);
    }

    return ListTile(
      leading: leading,
      title: Text(player.id == 'system_default' ? t.externalPlayer.systemDefault : player.name),
      trailing: Row(
        mainAxisSize: .min,
        children: [
          if (isCustom)
            IconButton(
              icon: const AppIcon(Symbols.delete_rounded, fill: 1, size: 20),
              onPressed: () => svc.removeCustomExternalPlayer(player.id),
            ),
          AppIcon(
            isSelected ? Symbols.radio_button_checked_rounded : Symbols.radio_button_unchecked_rounded,
            fill: 1,
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
        ],
      ),
      onTap: () => svc.write(SettingsService.selectedExternalPlayer, player),
    );
  }
}

typedef _CustomPlayerDialogResult = ({String name, String value, CustomPlayerType type});

Future<void> _showAddCustomPlayerDialog(BuildContext context) async {
  final result = await showScopedDialog<_CustomPlayerDialogResult>(
    context: context,
    builder: (_) => const _AddCustomPlayerDialog(),
  );
  if (result == null) return;

  final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
  final newPlayer = ExternalPlayer.custom(id: id, name: result.name, value: result.value, type: result.type);

  final svc = SettingsService.instance;
  await svc.write(SettingsService.customExternalPlayers, [
    ...svc.read(SettingsService.customExternalPlayers),
    newPlayer,
  ]);
}

class _AddCustomPlayerDialog extends StatefulWidget {
  const _AddCustomPlayerDialog();

  @override
  State<_AddCustomPlayerDialog> createState() => _AddCustomPlayerDialogState();
}

class _AddCustomPlayerDialogState extends State<_AddCustomPlayerDialog> {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _valueFocusNode = FocusNode(debugLabel: 'CustomExternalPlayerValue');
  final _saveFocusNode = FocusNode(debugLabel: 'CustomExternalPlayerSave');
  CustomPlayerType _selectedType = CustomPlayerType.command;

  @override
  void dispose() {
    _valueFocusNode.dispose();
    _saveFocusNode.dispose();
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final value = _valueController.text.trim();
    if (name.isEmpty || value.isEmpty) return;
    Navigator.pop(context, (name: name, value: value, type: _selectedType));
  }

  ({String label, String hint}) get _valueFieldInfo {
    if (_selectedType == CustomPlayerType.urlScheme) {
      return (label: t.externalPlayer.playerUrlScheme, hint: 'myplayer://play?url=');
    }
    if (Platform.isAndroid) {
      return (label: t.externalPlayer.playerPackage, hint: 'com.example.player');
    }
    return (label: t.externalPlayer.playerCommand, hint: Platform.isMacOS ? 'mpv' : '/usr/bin/player');
  }

  @override
  Widget build(BuildContext context) {
    final (:label, :hint) = _valueFieldInfo;
    return AlertDialog(
      title: Text(t.externalPlayer.addCustomPlayer),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: .min,
          children: [
            FocusableTextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: t.externalPlayer.playerName,
                hintText: t.externalPlayer.playerNameHint,
              ),
              autofocus: true,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _valueFocusNode.requestFocus(),
            ),
            const SizedBox(height: 16),
            ExpressiveButtonGroup<CustomPlayerType>(
              segments: [
                ButtonSegment(
                  value: CustomPlayerType.command,
                  label: Text(Platform.isAndroid ? t.externalPlayer.playerPackage : t.externalPlayer.playerCommand),
                ),
                ButtonSegment(value: CustomPlayerType.urlScheme, label: Text(t.externalPlayer.playerUrlScheme)),
              ],
              selected: _selectedType,
              onChanged: (value) => setState(() => _selectedType = value),
            ),
            const SizedBox(height: 16),
            FocusableTextField(
              controller: _valueController,
              focusNode: _valueFocusNode,
              decoration: InputDecoration(labelText: label, hintText: hint),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveFocusNode.requestFocus(),
            ),
          ],
        ),
      ),
      actions: [
        FocusableButton(
          onPressed: () => Navigator.pop(context),
          child: TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel)),
        ),
        FocusableButton(
          focusNode: _saveFocusNode,
          onPressed: _submit,
          child: FilledButton(onPressed: _submit, child: Text(t.common.save)),
        ),
      ],
    );
  }
}
