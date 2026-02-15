import '../../utils/platform_helper.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../i18n/strings.g.dart';
import '../../models/external_player_models.dart';
import '../../services/settings_service.dart';
import '../../widgets/desktop_app_bar.dart';

class ExternalPlayerScreen extends StatefulWidget {
  const ExternalPlayerScreen({super.key});

  @override
  State<ExternalPlayerScreen> createState() => _ExternalPlayerScreenState();
}

class _ExternalPlayerScreenState extends State<ExternalPlayerScreen> {
  late SettingsService _settingsService;
  bool _isLoading = true;

  bool _useExternalPlayer = false;
  ExternalPlayer _selectedPlayer = KnownPlayers.systemDefault;
  List<ExternalPlayer> _customPlayers = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsService = await SettingsService.getInstance();

    setState(() {
      _useExternalPlayer = _settingsService.getUseExternalPlayer();
      _selectedPlayer = _settingsService.getSelectedExternalPlayer();
      _customPlayers = _settingsService.getCustomExternalPlayers();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final knownPlayers = KnownPlayers.getForCurrentPlatform();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomAppBar(title: Text(t.externalPlayer.title), pinned: true),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Card(
                  child: SwitchListTile(
                    secondary: const AppIcon(Symbols.open_in_new_rounded, fill: 1),
                    title: Text(t.externalPlayer.useExternalPlayer),
                    subtitle: Text(t.externalPlayer.useExternalPlayerDescription),
                    value: _useExternalPlayer,
                    onChanged: (value) async {
                      setState(() => _useExternalPlayer = value);
                      await _settingsService.setUseExternalPlayer(value);
                    },
                  ),
                ),
                if (_useExternalPlayer) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            t.externalPlayer.selectPlayer,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        // Known players
                        ...knownPlayers.map((player) => _buildPlayerTile(player)),
                        // Custom players
                        if (_customPlayers.isNotEmpty) const Divider(),
                        ..._customPlayers.map((player) => _buildPlayerTile(player, isCustom: true)),
                        // Add custom player button
                        const Divider(),
                        ListTile(
                          leading: const AppIcon(Symbols.add_rounded, fill: 1),
                          title: Text(t.externalPlayer.addCustomPlayer),
                          onTap: _showAddCustomPlayerDialog,
                        ),
                      ],
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTile(ExternalPlayer player, {bool isCustom = false}) {
    final isSelected = _selectedPlayer.id == player.id;

    Widget leading;
    if (player.iconAsset != null) {
      leading = ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: player.iconAsset!.endsWith('.svg')
            ? SvgPicture.asset(player.iconAsset!, width: 32, height: 32)
            : Image.asset(player.iconAsset!, width: 32, height: 32, errorBuilder: (_, __, ___) {
                return const AppIcon(Symbols.play_circle_rounded, fill: 1, size: 32);
              }),
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
              onPressed: () => _deleteCustomPlayer(player),
            ),
          AppIcon(
            isSelected ? Symbols.radio_button_checked_rounded : Symbols.radio_button_unchecked_rounded,
            fill: 1,
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
        ],
      ),
      onTap: () async {
        setState(() => _selectedPlayer = player);
        await _settingsService.setSelectedExternalPlayer(player);
      },
    );
  }

  Future<void> _deleteCustomPlayer(ExternalPlayer player) async {
    await _settingsService.removeCustomExternalPlayer(player.id);
    setState(() {
      _customPlayers.removeWhere((p) => p.id == player.id);
      _selectedPlayer = _settingsService.getSelectedExternalPlayer();
    });
  }

  Future<void> _showAddCustomPlayerDialog() async {
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    var selectedType = CustomPlayerType.command;

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
          } else if (AppPlatform.isAndroid) {
            fieldLabel = t.externalPlayer.playerPackage;
            fieldHint = 'com.example.player';
          } else {
            fieldLabel = t.externalPlayer.playerCommand;
            fieldHint = AppPlatform.isMacOS ? 'mpv' : '/usr/bin/player';
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
                  decoration: InputDecoration(
                    labelText: t.externalPlayer.playerName,
                    hintText: 'My Player',
                  ),
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<CustomPlayerType>(
                  segments: [
                    ButtonSegment(
                      value: CustomPlayerType.command,
                      label: Text(AppPlatform.isAndroid
                          ? t.externalPlayer.playerPackage
                          : t.externalPlayer.playerCommand),
                    ),
                    ButtonSegment(
                      value: CustomPlayerType.urlScheme,
                      label: Text(t.externalPlayer.playerUrlScheme),
                    ),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (value) {
                    setDialogState(() => selectedType = value.first);
                  },
                ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: valueController,
                  decoration: InputDecoration(
                    labelText: fieldLabel,
                    hintText: fieldHint,
                  ),
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel)),
              FilledButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty && valueController.text.isNotEmpty) {
                    Navigator.pop(context, true);
                  }
                },
                child: Text(t.common.save),
              ),
            ],
          );
        },
      ),
    );

    if (result != true) return;

    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final newPlayer = ExternalPlayer.custom(
      id: id,
      name: nameController.text,
      value: valueController.text,
      type: selectedType,
    );

    await _settingsService.addCustomExternalPlayer(newPlayer);
    setState(() {
      _customPlayers.add(newPlayer);
    });
  }
}
