import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/widgets/app_icon.dart';

import '../../focus/focusable_button.dart';
import '../../i18n/strings.g.dart';
import '../../models/external_player_models.dart';
import '../../services/settings_service.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_builder.dart';
import '../../widgets/settings_section.dart';

class ExternalPlayerScreen extends StatelessWidget {
  const ExternalPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final knownPlayers = KnownPlayers.getForCurrentPlatform();
    return FocusedScrollScaffold(
      title: Text(t.externalPlayer.title),
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            SettingSwitchTile(
              pref: SettingsService.useExternalPlayer,
              icon: Symbols.open_in_new_rounded,
              title: t.externalPlayer.useExternalPlayer,
              subtitle: t.externalPlayer.useExternalPlayerDescription,
            ),
            SettingsBuilder(
              prefs: [
                SettingsService.useExternalPlayer,
                SettingsService.selectedExternalPlayer,
                SettingsService.customExternalPlayers,
              ],
              builder: (context) {
                final svc = SettingsService.instanceOrNull!;
                if (!svc.read(SettingsService.useExternalPlayer)) return const SizedBox.shrink();
                final selected = svc.read(SettingsService.selectedExternalPlayer);
                final custom = svc.read(SettingsService.customExternalPlayers);
                return Column(
                  children: [
                    SettingsSectionHeader(t.externalPlayer.selectPlayer),
                    ...knownPlayers.map((p) => _PlayerTile(player: p, selectedId: selected.id)),
                    SettingsSectionHeader(t.externalPlayer.customPlayers),
                    ...custom.map((p) => _PlayerTile(player: p, selectedId: selected.id, isCustom: true)),
                    ListTile(
                      leading: const AppIcon(Symbols.add_rounded, fill: 1),
                      title: Text(t.externalPlayer.addCustomPlayer),
                      onTap: () => _showAddCustomPlayerDialog(context),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
          ]),
        ),
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
    final svc = SettingsService.instanceOrNull!;

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
        mainAxisSize: MainAxisSize.min,
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

Future<void> _showAddCustomPlayerDialog(BuildContext context) async {
  final nameController = TextEditingController();
  final valueController = TextEditingController();
  final valueFocusNode = FocusNode();
  final saveFocusNode = FocusNode();
  var selectedType = CustomPlayerType.command;
  String? playerName;
  String? playerValue;

  try {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isUrlScheme = selectedType == CustomPlayerType.urlScheme;
          final String fieldLabel;
          final String fieldHint;
          if (isUrlScheme) {
            fieldLabel = t.externalPlayer.playerUrlScheme;
            fieldHint = 'myplayer://play?url=';
          } else if (Platform.isAndroid) {
            fieldLabel = t.externalPlayer.playerPackage;
            fieldHint = 'com.example.player';
          } else {
            fieldLabel = t.externalPlayer.playerCommand;
            fieldHint = Platform.isMacOS ? 'mpv' : '/usr/bin/player';
          }

          return AlertDialog(
            title: Text(t.externalPlayer.addCustomPlayer),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: t.externalPlayer.playerName, hintText: 'My Player'),
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => primaryFocus?.nextFocus(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<CustomPlayerType>(
                      segments: [
                        ButtonSegment(
                          value: CustomPlayerType.command,
                          label: Text(
                            Platform.isAndroid ? t.externalPlayer.playerPackage : t.externalPlayer.playerCommand,
                          ),
                        ),
                        ButtonSegment(value: CustomPlayerType.urlScheme, label: Text(t.externalPlayer.playerUrlScheme)),
                      ],
                      selected: {selectedType},
                      onSelectionChanged: (value) => setDialogState(() => selectedType = value.first),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: valueController,
                    focusNode: valueFocusNode,
                    decoration: InputDecoration(labelText: fieldLabel, hintText: fieldHint),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => saveFocusNode.requestFocus(),
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
                focusNode: saveFocusNode,
                onPressed: () {
                  if (nameController.text.isNotEmpty && valueController.text.isNotEmpty) {
                    Navigator.pop(context, true);
                  }
                },
                child: FilledButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty && valueController.text.isNotEmpty) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: Text(t.common.save),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (result != true) return;
    playerName = nameController.text;
    playerValue = valueController.text;
  } finally {
    nameController.dispose();
    valueController.dispose();
    valueFocusNode.dispose();
    saveFocusNode.dispose();
  }

  final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
  final newPlayer = ExternalPlayer.custom(id: id, name: playerName, value: playerValue, type: selectedType);

  final svc = SettingsService.instanceOrNull!;
  await svc.write(SettingsService.customExternalPlayers, [
    ...svc.read(SettingsService.customExternalPlayers),
    newPlayer,
  ]);
}
