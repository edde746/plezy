import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile_avatar.dart';
import '../../services/storage_service.dart';
import '../../services/tvos_user_profile_service.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/loading_indicator_box.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_section.dart';

/// Maps the current Apple TV *system* user to a Plezy profile so the app can
/// auto-activate it after a tvOS user switch (see [TvosUserProfileService]).
///
/// `TVUserManager` only exposes the *current* user, so the map is built one
/// member at a time: each person opens this screen while their own Apple TV
/// user is active and picks their profile.
class TvosProfileMappingScreen extends StatefulWidget {
  const TvosProfileMappingScreen({super.key});

  @override
  State<TvosProfileMappingScreen> createState() => _TvosProfileMappingScreenState();
}

class _TvosProfileMappingScreenState extends State<TvosProfileMappingScreen> {
  StorageService? _storage;
  String? _tvosUserId;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = await StorageService.getInstance();
    final tvosUserId = await TvosUserProfileService().getCurrentUser();
    if (!mounted) return;
    setState(() {
      _storage = storage;
      _tvosUserId = tvosUserId;
      _loaded = true;
    });
  }

  Future<void> _select(String? profileId) async {
    final storage = _storage;
    final tvosUserId = _tvosUserId;
    if (storage == null || tvosUserId == null) return;
    if (profileId == null) {
      await storage.clearProfileIdForTvosUser(tvosUserId);
      // An explicit "don't switch automatically" also silences the
      // post-switch mapping prompt for this tvOS user.
      await storage.markTvosUserPromptedForMapping(tvosUserId);
    } else {
      await storage.setProfileIdForTvosUser(tvosUserId, profileId);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: Text(t.profiles.appleTvSync),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(t.profiles.appleTvSyncExplain, style: Theme.of(context).textTheme.bodySmall),
        ),
        if (!_loaded)
          const LoadingIndicatorBox(size: 24)
        else if (_tvosUserId == null)
          SettingsGroup(
            children: [
              FocusableListTile(
                leading: const AppIcon(Symbols.person_off_rounded, fill: 1),
                title: Text(t.profiles.appleTvSyncUnavailable),
                subtitle: Text(t.profiles.appleTvSyncUnavailableMessage),
              ),
            ],
          )
        else
          _buildProfilePicker(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProfilePicker() {
    final profiles = context.watch<ActiveProfileProvider>().profiles;
    final mappedId = _storage?.getProfileIdForTvosUser(_tvosUserId!);
    return SettingsGroup(
      title: t.profiles.appleTvSyncChooseProfile,
      children: [
        _OptionTile(
          selected: mappedId == null,
          leading: const AppIcon(Symbols.do_not_disturb_on_rounded, fill: 1),
          title: t.profiles.appleTvSyncNoAutoSwitch,
          onTap: () => _select(null),
        ),
        for (final profile in profiles)
          _OptionTile(
            selected: mappedId == profile.id,
            leading: ProfileAvatar(profile: profile, size: 32),
            title: profile.displayName,
            // PIN-protected profiles are mappable — the auto-switch asks
            // for their PIN, exactly like a manual switch would.
            subtitle: profile.isPinProtected ? t.profiles.appleTvSyncAsksForPin : null,
            onTap: () => _select(profile.id),
          ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final bool selected;
  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.selected,
    required this.leading,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableListTile(
      leading: leading,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: AppIcon(
        selected ? Symbols.radio_button_checked_rounded : Symbols.radio_button_unchecked_rounded,
        fill: 1,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      onTap: onTap,
    );
  }
}
