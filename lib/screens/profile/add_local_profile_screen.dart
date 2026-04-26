import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../i18n/strings.g.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_registry.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/desktop_app_bar.dart';
import '../settings/add_connection_screen.dart';
import 'pin_entry_dialog.dart';
import 'pin_status_row.dart';
import 'profile_name_field.dart';

/// Create a local "Plezy" profile — name + optional 4-digit PIN.
///
/// On save, routes into [AddConnectionScreen] so the user can either add
/// a brand-new Plex/Jellyfin connection to this profile or borrow one from
/// an existing profile. Profiles with zero connections are stored but
/// blocked from activation.
class AddLocalProfileScreen extends StatefulWidget {
  const AddLocalProfileScreen({super.key});

  @override
  State<AddLocalProfileScreen> createState() => _AddLocalProfileScreenState();
}

class _AddLocalProfileScreenState extends State<AddLocalProfileScreen> {
  late final TextEditingController _nameController;
  String? _pinHash;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _setPin() async {
    final pin = await captureAndConfirmPin(
      context,
      onMismatch: (ctx) => showErrorSnackBar(ctx, t.profiles.pinsDontMatch),
    );
    if (pin == null || !mounted) return;
    setState(() => _pinHash = computePinHash(pin));
  }

  void _clearPin() => setState(() => _pinHash = null);

  Future<void> _saveAndContinue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);

    final registry = context.read<ProfileRegistry>();
    final profile = Profile(
      id: 'local-${const Uuid().v4()}',
      kind: ProfileKind.local,
      displayName: name,
      pinHash: _pinHash,
      sortOrder: DateTime.now().millisecondsSinceEpoch,
      createdAt: DateTime.now(),
    );
    await registry.upsert(profile);

    if (!mounted) return;
    // Drop the user into the connection picker so they end up with at least
    // one connection. The picker offers both new sign-ins and borrowing from
    // existing profiles — empty borrow lists no longer trap the user.
    final navigator = Navigator.of(context);
    await navigator.push(MaterialPageRoute(builder: (_) => AddConnectionScreen(targetProfile: profile)));
    if (!mounted) return;
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          ExcludeFocus(child: CustomAppBar(title: Text(t.profiles.newProfile), pinned: true)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(t.profiles.profileNameLabel, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                ProfileNameField(
                  controller: _nameController,
                  hintText: t.profiles.profileNameHint,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 24),
                Text(t.profiles.pinProtectionOptional, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Text(
                  t.profiles.pinExplain,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                if (_pinHash == null)
                  OutlinedButton.icon(
                    onPressed: _setPin,
                    icon: const AppIcon(Symbols.lock_outline_rounded, fill: 1),
                    label: Text(t.profiles.setPin),
                  )
                else
                  PinStatusRow(onChange: _setPin, onRemove: _clearPin),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _saving || _nameController.text.trim().isEmpty ? null : _saveAndContinue,
                  child: Text(t.profiles.continueButton),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: Text(t.common.cancel)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
