import 'package:flutter/material.dart';
import '../../widgets/catalog_source_logo.dart';
import '../../models/catalog/catalog_item.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/mounted_set_state_mixin.dart';
import '../../services/settings_service.dart';
import '../../services/the_intro_db_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/settings_section.dart';

class TheIntroDbSettingsScreen extends StatefulWidget {
  const TheIntroDbSettingsScreen({super.key});

  @override
  State<TheIntroDbSettingsScreen> createState() => _TheIntroDbSettingsScreenState();
}

class _TheIntroDbSettingsScreenState extends State<TheIntroDbSettingsScreen> with MountedSetStateMixin {
  late final TextEditingController _keyController;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    final savedKey = SettingsService.instance.read(SettingsService.theIntroDbApiKey) ?? '';
    _keyController = TextEditingController(text: savedKey);
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _saveKey(String val) async {
    final trimmed = val.trim();
    if (trimmed.isEmpty) {
      await SettingsService.instance.write(SettingsService.theIntroDbApiKey, null);
    } else {
      await SettingsService.instance.write(SettingsService.theIntroDbApiKey, trimmed);
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);
    final keyToTest = _keyController.text.trim();
    await _saveKey(keyToTest);

    final success = await TheIntroDbService.instance.testConnection(keyToTest.isNotEmpty ? keyToTest : null);
    if (!mounted) return;

    setState(() => _isTesting = false);

    if (success) {
      showSuccessSnackBar(context, t.services.theIntroDb.connectionSuccess);
    } else {
      showErrorSnackBar(context, t.services.theIntroDb.connectionFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedKey = SettingsService.instance.read(SettingsService.theIntroDbApiKey);
    final hasKey = savedKey != null && savedKey.trim().isNotEmpty;

    return FocusedScrollScaffold(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CatalogSourceLogo(CatalogSourceId.theIntroDb, size: 24),
          const SizedBox(width: 12),
          Text(t.services.theIntroDb.title),
        ],
      ),
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                t.services.theIntroDb.subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            SettingsGroup(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.services.theIntroDb.apiKey,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      FocusableTextField(
                        controller: _keyController,
                        decoration: InputDecoration(
                          hintText: t.services.theIntroDb.apiKeyHint,
                          border: const OutlineInputBorder(),
                          prefixIcon: const AppIcon(Symbols.key_rounded),
                          suffixIcon: _keyController.text.isNotEmpty
                              ? IconButton(
                                  icon: const AppIcon(Symbols.clear_rounded),
                                  onPressed: () {
                                    _keyController.clear();
                                    _saveKey('');
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        onChanged: (val) {
                          _saveKey(val);
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hasKey ? t.services.theIntroDb.apiKey : t.services.theIntroDb.publicAccess,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: hasKey
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                FocusableListTile(
                  leading: const AppIcon(Symbols.network_check_rounded),
                  title: Text(t.services.theIntroDb.testConnection),
                  trailing: _isTesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const AppIcon(Symbols.chevron_right_rounded),
                  onTap: _isTesting ? null : _testConnection,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SettingsGroup(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    t.services.theIntroDb.infoText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                FocusableListTile(
                  leading: const AppIcon(Symbols.open_in_new_rounded),
                  title: Text(t.services.theIntroDb.getKeyInfo),
                  onTap: () async {
                    final uri = Uri.parse('https://theintrodb.org');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ],
    );
  }
}
