import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/iptv_copy.dart';
import '../i18n/strings.g.dart';
import '../models/livetv_channel.dart';
import '../profiles/active_profile_provider.dart';
import '../profiles/profile.dart';
import '../profiles/profile_activation.dart';
import '../utils/snackbar_helper.dart';

/// In-memory parental access window for channels locked in IPTV settings.
/// A successful profile PIN check unlocks IPTV playback for ten minutes.
class IptvParentalAccessService {
  IptvParentalAccessService._();

  static const _accessWindow = Duration(minutes: 10);
  static final Map<String, DateTime> _unlockedUntil = {};

  static Future<bool> ensureAllowed(BuildContext context, LiveTvChannel channel) async {
    if (!channel.iptvParentalLocked) return true;
    final profiles = context.read<ActiveProfileProvider>();
    final active = profiles.active;
    if (active is! LocalProfile || active.pinHash == null || active.pinHash!.isEmpty) {
      if (context.mounted) showErrorSnackBar(context, t.iptv.parentalAccessDenied);
      return false;
    }
    final profileId = active.id;
    final unlockedUntil = _unlockedUntil[profileId];
    if (unlockedUntil != null && DateTime.now().isBefore(unlockedUntil)) return true;
    final allowed = await requestActiveProfileActionPin(context);
    if (!allowed || !context.mounted || profiles.activeId != profileId) return false;
    _unlockedUntil[profileId] = DateTime.now().add(_accessWindow);
    return true;
  }
}
