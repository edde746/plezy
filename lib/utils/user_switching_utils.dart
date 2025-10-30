import 'package:flutter/material.dart';
import '../models/plex_home_user.dart';
import 'provider_extensions.dart';

class UserSwitchingUtils {
  static Future<bool> switchToUser(
    BuildContext context,
    PlexHomeUser user, {
    bool popOnSuccess = false,
  }) async {
    final userProvider = context.userProfile;

    final success = await userProvider.switchToUser(user, context);

    if (success && context.mounted && popOnSuccess) {
      Navigator.of(context).pop();
    } else if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to switch to ${user.displayName}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    return success;
  }
}
