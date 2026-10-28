import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../i18n/iptv_copy.dart';
import '../../iptv/iptv_models.dart';
import '../../iptv/iptv_source_repository.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile.dart';
import '../../theme/mono_tokens.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';

/// Adds or edits a profile-owned IPTV feed. Playlist addresses and credentials
/// are stored by [IptvSourceRepository] in the platform credential vault.
class AddIptvSourceScreen extends StatefulWidget {
  const AddIptvSourceScreen({super.key, this.targetProfile, this.profileId, this.sourceId});

  final Profile? targetProfile;
  final String? profileId;
  final String? sourceId;

  @override
  State<AddIptvSourceScreen> createState() => _AddIptvSourceScreenState();
}

class _AddIptvSourceScreenState extends State<AddIptvSourceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _endpoint = TextEditingController();
  final _guide = TextEditingController();
  final _additionalGuides = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _macAddress = TextEditingController();
  final _dispatcharrApiEndpoint = TextEditingController();
  final _dispatcharrApiKey = TextEditingController();
  IptvInputKind _kind = IptvInputKind.m3u;
  bool _allowHttp = false;
  bool _localTimeShiftEnabled = true;
  bool _busy = false;
  bool _loading = false;
  bool _loaded = false;
  bool _saved = false;
  bool _loadFailed = false;
  String? _sourceId;
  String? _boundProfileId;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _boundProfileId = widget.profileId ?? widget.targetProfile?.id ?? context.read<ActiveProfileProvider>().activeId;
    _sourceId = widget.sourceId;
    if (_sourceId != null) {
      _loading = true;
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    try {
      final profileId = _boundProfileId;
      if (profileId == null) throw const IptvImportException('source_missing');
      final config = await context.read<IptvSourceRepository>().configuration(profileId, _sourceId!);
      if (!mounted) return;
      if (config == null) throw const IptvImportException('source_missing');
      setState(() {
        _name.text = config.displayName;
        _kind = config.kind;
        _endpoint.text = config.endpoint;
        _guide.text = config.guideEndpoint;
        _additionalGuides.text = config.additionalGuideEndpoints.join('\n');
        _username.text = config.username;
        _password.text = config.password;
        _macAddress.text = config.macAddress;
        _dispatcharrApiEndpoint.text = config.dispatcharrApiEndpoint;
        _dispatcharrApiKey.text = config.dispatcharrApiKey;
        _localTimeShiftEnabled = config.localTimeShiftEnabled;
        _allowHttp = config.allowHttp;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
        _error = _messageFor(error);
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _endpoint.dispose();
    _guide.dispose();
    _additionalGuides.dispose();
    _username.dispose();
    _password.dispose();
    _macAddress.dispose();
    _dispatcharrApiEndpoint.dispose();
    _dispatcharrApiKey.dispose();
    super.dispose();
  }

  String get _typeName => switch (_kind) {
    IptvInputKind.m3u => t.iptv.m3u,
    IptvInputKind.xtream => t.iptv.xtream,
    IptvInputKind.tunerr => t.iptv.tunerr,
    IptvInputKind.dispatcharr => t.iptv.dispatcharr,
    IptvInputKind.stalker => t.iptv.stalker,
  };

  String get _typeHelp => switch (_kind) {
    IptvInputKind.m3u => t.iptv.m3uHelp,
    IptvInputKind.xtream => t.iptv.xtreamHelp,
    IptvInputKind.tunerr => t.iptv.managedFeedHelp,
    IptvInputKind.dispatcharr => t.iptv.dispatcharrHelp,
    IptvInputKind.stalker => t.iptv.stalkerHelp,
  };

  String _messageFor(Object error) {
    if (error is! IptvImportException) return t.iptv.genericError;
    return switch (error.code) {
      'source_invalid' || 'invalid_stream_address' => t.iptv.sourceInvalid,
      'http_not_allowed' => t.iptv.httpNotAllowed,
      'authentication' => t.iptv.authentication,
      'permission' => t.iptv.permission,
      'invalid_data' => t.iptv.invalidData,
      'playlist_is_stream' => t.iptv.playlistIsStream,
      'source_changed' => t.iptv.sourceChanged,
      'credential_unavailable' => t.iptv.credentialUnavailable,
      'source_missing' => t.iptv.sourceMissing,
      _ => t.iptv.providerUnavailable,
    };
  }

  Future<void> _save() async {
    if (_saved) {
      Navigator.of(context).pop(true);
      return;
    }
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    final profileId = _boundProfileId;
    if (profileId == null) {
      setState(() => _error = t.iptv.noActiveProfile);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final repository = context.read<IptvSourceRepository>();
    try {
      final sourceId = _sourceId;
      if (sourceId == null) {
        _sourceId = await repository.createSource(
          profileId: profileId,
          displayName: _name.text,
          kind: _kind,
          endpoint: _endpoint.text,
          guideEndpoint: _guide.text,
          additionalGuideEndpoints: _additionalGuides.text.split(RegExp(r'\r?\n')),
          username: _username.text,
          password: _password.text,
          macAddress: _macAddress.text,
          dispatcharrApiEndpoint: _dispatcharrApiEndpoint.text,
          dispatcharrApiKey: _dispatcharrApiKey.text,
          localTimeShiftEnabled: _localTimeShiftEnabled,
          allowHttp: _allowHttp,
        );
      } else {
        await repository.updateSource(
          IptvSourceConfiguration(
            id: sourceId,
            profileId: profileId,
            displayName: _name.text.trim(),
            kind: _kind,
            endpoint: _endpoint.text.trim(),
            guideEndpoint: _guide.text.trim(),
            additionalGuideEndpoints: _additionalGuides.text
                .split(RegExp(r'\r?\n'))
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toList(growable: false),
            username: _username.text,
            password: _password.text,
            macAddress: _macAddress.text.trim().toUpperCase(),
            dispatcharrApiEndpoint: _dispatcharrApiEndpoint.text,
            dispatcharrApiKey: _dispatcharrApiKey.text.trim(),
            localTimeShiftEnabled: _localTimeShiftEnabled,
            allowHttp: _allowHttp,
          ),
        );
      }
      try {
        final count = await repository.refresh(profileId, _sourceId!);
        if (!mounted) return;
        final messenger = ScaffoldMessenger.maybeOf(context);
        Navigator.of(context).pop(true);
        messenger?.showSnackBar(SnackBar(content: Text(t.iptv.importComplete(count: count))));
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _saved = true;
          _error = '${t.iptv.savedRefreshFailed}\n${_messageFor(error)}';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _sourceId == null ? t.iptv.addSource : t.iptv.edit;
    final profileId = _boundProfileId;
    final unusable = profileId == null || _loadFailed || _loading;
    return FocusedScrollScaffold(
      title: Text(title),
      bottomBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _busy || unusable ? null : _save,
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : AppIcon(_saved ? Symbols.check_rounded : Symbols.download_rounded, fill: 1),
            label: Text(_saved ? t.iptv.done : (_sourceId == null ? t.iptv.saveAndImport : t.iptv.retryImport)),
          ),
        ),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverToBoxAdapter(
            child: AbsorbPointer(
              absorbing: _saved || _loading,
              child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (profileId == null) _InfoCard(icon: Symbols.person_rounded, text: t.iptv.noActiveProfile),
                  if (_error case final error?) ...[
                    _InfoCard(icon: Symbols.info_rounded, text: error, isError: !_saved),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(labelText: t.iptv.sourceName),
                    textInputAction: TextInputAction.next,
                    validator: (value) => (value?.trim().isEmpty ?? true) ? t.iptv.required : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<IptvInputKind>(
                    initialValue: _kind,
                    decoration: InputDecoration(labelText: t.iptv.provider),
                    items: [
                      for (final value in IptvInputKind.values)
                        DropdownMenuItem(value: value, child: Text(_labelFor(value))),
                    ],
                    onChanged: _busy || _saved
                        ? null
                        : (value) => setState(() {
                            _kind = value ?? _kind;
                            if (_kind != IptvInputKind.dispatcharr) {
                              _dispatcharrApiEndpoint.clear();
                              _dispatcharrApiKey.clear();
                            }
                            if (_kind != IptvInputKind.xtream && _kind != IptvInputKind.dispatcharr) {
                              _username.clear();
                              _password.clear();
                            }
                            if (_kind != IptvInputKind.stalker) _macAddress.clear();
                          }),
                  ),
                  const SizedBox(height: 8),
                  Text(_typeHelp, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted)),
                  if (_kind != IptvInputKind.stalker) ...[
                    const SizedBox(height: 4),
                    Text(
                      t.iptv.playlistHeadersHelp,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted),
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _endpoint,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: _kind == IptvInputKind.xtream ? t.iptv.xtreamEndpoint : t.iptv.endpoint,
                      hintText: _kind == IptvInputKind.xtream ? 'https://provider.example' : 'https://…',
                      prefixIcon: const AppIcon(Symbols.link_rounded),
                    ),
                    validator: (value) => (value?.trim().isEmpty ?? true) ? t.iptv.required : null,
                  ),
                  if (_kind == IptvInputKind.xtream || _kind == IptvInputKind.dispatcharr) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _username,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: t.iptv.username),
                      validator: (value) => (value?.isEmpty ?? true) ? t.iptv.required : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: t.iptv.password),
                      validator: (value) => _kind == IptvInputKind.xtream && (value?.isEmpty ?? true)
                          ? t.iptv.required
                          : null,
                    ),
                  ],
                  if (_kind == IptvInputKind.stalker) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _macAddress,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: t.iptv.macAddress,
                        hintText: '00:1A:79:00:00:00',
                        prefixIcon: const AppIcon(Symbols.devices_rounded),
                      ),
                      validator: (value) => _kind == IptvInputKind.stalker &&
                              !RegExp(r'^(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$').hasMatch(value?.trim() ?? '')
                          ? t.iptv.macAddressInvalid
                          : null,
                    ),
                  ],
                  if (_kind == IptvInputKind.dispatcharr) ...[
                    const SizedBox(height: 18),
                    Text(t.iptv.dispatcharrDvr, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(t.iptv.dispatcharrDvrHelp, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dispatcharrApiEndpoint,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: t.iptv.dispatcharrApiEndpoint),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dispatcharrApiKey,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: t.iptv.dispatcharrApiKey),
                    ),
                  ],
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.iptv.localTimeShift),
                    subtitle: Text(t.iptv.localTimeShiftHelp),
                    value: _localTimeShiftEnabled,
                    onChanged: _busy || _saved ? null : (value) => setState(() => _localTimeShiftEnabled = value),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _guide,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: t.iptv.guideEndpoint,
                      prefixIcon: const AppIcon(Symbols.event_note_rounded),
                      helperText: t.iptv.guideEndpointHelp,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _additionalGuides,
                    keyboardType: TextInputType.multiline,
                    minLines: 2,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: t.iptv.additionalGuideEndpoints,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 42),
                        child: AppIcon(Symbols.library_add_check_rounded),
                      ),
                      helperText: t.iptv.additionalGuideEndpointsHelp,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.iptv.allowHttp),
                    subtitle: Text(t.iptv.allowHttpDescription),
                    value: _allowHttp,
                    onChanged: _busy || _saved ? null : (value) => setState(() => _allowHttp = value),
                  ),
                ],
              ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _labelFor(IptvInputKind kind) => switch (kind) {
    IptvInputKind.m3u => t.iptv.m3u,
    IptvInputKind.xtream => t.iptv.xtream,
    IptvInputKind.tunerr => t.iptv.tunerr,
    IptvInputKind.dispatcharr => t.iptv.dispatcharr,
    IptvInputKind.stalker => t.iptv.stalker,
  };
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text, this.isError = false});

  final IconData icon;
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? colors.errorContainer : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, color: isError ? colors.onErrorContainer : colors.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isError ? colors.onErrorContainer : colors.onSurfaceVariant,
            )),
          ),
        ],
      ),
    );
  }
}
