import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../focus/focusable_button.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/controller_disposer_mixin.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_registry.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
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

class _AddLocalProfileScreenState extends State<AddLocalProfileScreen> with ControllerDisposerMixin {
  late final TextEditingController _nameController = createTextEditingController();
  final _nameFocus = FocusNode(debugLabel: 'AddLocalProfile:Name');
  final _setPinFocus = FocusNode(debugLabel: 'AddLocalProfile:SetPin');
  final _continueFocus = FocusNode(debugLabel: 'AddLocalProfile:Continue');
  final _cancelFocus = FocusNode(debugLabel: 'AddLocalProfile:Cancel');
  String? _pinHash;
  bool _saving = false;

  @override
  void dispose() {
    _nameFocus.dispose();
    _setPinFocus.dispose();
    _continueFocus.dispose();
    _cancelFocus.dispose();
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
    final profile = Profile.local(
      id: 'local-${const Uuid().v4()}',
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
    return FocusedScrollScaffold(
      title: Text(t.profiles.newProfile),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(t.profiles.profileNameLabel, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              ProfileNameField(
                controller: _nameController,
                focusNode: _nameFocus,
                hintText: t.profiles.profileNameHint,
                onChanged: () => setState(() {}),
                onNavigateDown: () => (_pinHash == null ? _setPinFocus : _continueFocus).requestFocus(),
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
                FocusableButton(
                  focusNode: _setPinFocus,
                  useBackgroundFocus: true,
                  onPressed: _setPin,
                  child: OutlinedButton.icon(
                    onPressed: _setPin,
                    icon: const AppIcon(Symbols.lock_outline_rounded, fill: 1),
                    label: Text(t.profiles.setPin),
                  ),
                )
              else
                PinStatusRow(onChange: _setPin, onRemove: _clearPin),
              const SizedBox(height: 32),
              FocusableButton(
                focusNode: _continueFocus,
                useBackgroundFocus: true,
                onPressed: _saving || _nameController.text.trim().isEmpty ? null : _saveAndContinue,
                onNavigateUp: () => (_pinHash == null ? _setPinFocus : _nameFocus).requestFocus(),
                child: FilledButton(
                  onPressed: _saving || _nameController.text.trim().isEmpty ? null : _saveAndContinue,
                  child: Text(t.profiles.continueButton),
                ),
              ),
              const SizedBox(height: 8),
              FocusableButton(
                focusNode: _cancelFocus,
                useBackgroundFocus: true,
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: Text(t.common.cancel),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
