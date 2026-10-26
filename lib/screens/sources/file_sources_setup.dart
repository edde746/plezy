import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../i18n/strings.g.dart';
import '../../navigation/profile_session_screen.dart';
import '../../profiles/active_profile_binder.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_registry.dart';
import '../../profiles/profile_selection_policy.dart';
import '../../services/settings_service.dart';
import '../profile/profile_switch_screen.dart';

/// Standard local profile and binder; owned files need no media-server login.
/// Existing protected profiles always pass through the ordinary PIN picker.
Future<bool> openFileSourcesSession(BuildContext context, {required bool createIfEmpty}) async {
  final active = context.read<ActiveProfileProvider>(),
      registry = context.read<ProfileRegistry>(),
      binder = context.read<ActiveProfileBinder>();
  await active.reloadFromStorage();
  if (!context.mounted) return false;
  if (active.profiles.isEmpty) {
    if (!createIfEmpty) return false;
    final profile = Profile.local(id: const Uuid().v4(), displayName: t.fileSources.title, createdAt: DateTime.now());
    await registry.upsert(profile);
    await active.reloadFromStorage();
    if (!await active.activate(profile)) return false;
  }
  if (!context.mounted) return false;
  binder.start();
  final pick =
      active.active == null ||
      active.active!.isPinProtected ||
      active.requiresSelectionOnOpen(SettingsService.instance) ||
      createIfEmpty && active.profiles.length > 1;
  if (pick) {
    final selected = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const ProfileSwitchScreen(requireSelection: true)));
    if (selected != true) return false;
  }
  if (!context.mounted || active.active == null || !await active.awaitBindingSettle()) return false;
  if (!context.mounted) return false;
  unawaited(
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const ProfileSessionScreen(initialPromptHandled: true, initialSourceLibrary: true),
      ),
    ),
  );
  return true;
}
