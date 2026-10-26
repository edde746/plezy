import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../i18n/strings.g.dart';
import '../../sources/dlna_discovery.dart';
import '../../sources/source_controller.dart';
import '../../sources/source_models.dart';
import '../../sources/publication_shelf.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/provider_mark.dart';
import 'source_widgets.dart';

class AddSourceScreen extends StatefulWidget {
  const AddSourceScreen({super.key, this.existing});
  final FileSource? existing;
  @override
  State<AddSourceScreen> createState() => _AddSourceScreenState();
}

class _AddSourceScreenState extends State<AddSourceScreen> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  FileSourceKind _kind = FileSourceKind.webdav;
  bool _busy = false, _allowHttp = false, _encryptSmb = false, _onlineMetadata = true;
  bool _discoveringDlna = false;
  Set<PublicationShelf> _shelves = defaultPublicationShelves(FileSourceKind.webdav);
  bool _shelvesCustomized = false;
  Object? _error;
  SourceController? _connecting;
  TextEditingController field(String key) => _fields.putIfAbsent(key, TextEditingController.new);
  bool get oauth => const {FileSourceKind.googleDrive, FileSourceKind.oneDrive, FileSourceKind.dropbox}.contains(_kind);

  @override
  void initState() {
    super.initState();
    final old = widget.existing;
    if (old != null) {
      _kind = old.kind;
      field('name').text = old.name;
      field('endpoint').text = old.endpoint;
      field('root').text = old.root;
      field('clientId').text = old.options['clientId'] ?? '';
      _allowHttp = old.options['allowHttp'] == 'true';
      _encryptSmb = old.options['encryptSmb'] == 'true';
      _onlineMetadata = old.options['onlineMetadata'] != 'false';
      final defaultShelves = defaultPublicationShelves(old.kind).map((s) => s.name).join(',');
      _shelves = PublicationShelf.values
          .where((s) => (old.options['shelves'] ?? defaultShelves).split(',').contains(s.name))
          .toSet();
      field('syncRoot').text = old.options['syncRoot'] ?? '';
      field('region').text = old.options['region'] ?? '';
    }
  }

  @override
  void dispose() {
    if (_busy) _connecting?.oauth.cancel();
    for (final f in _fields.values) {
      f.dispose();
    }
    super.dispose();
  }

  Widget input(
    String key,
    String label, {
    bool secret = false,
    bool required = false,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: field(key),
      obscureText: secret,
      maxLines: maxLines,
      autocorrect: false,
      enableSuggestions: !secret,
      decoration: InputDecoration(labelText: label, helperText: hint),
      validator: validator ?? (required ? (value) => value?.trim().isNotEmpty == true ? null : label : null),
    ),
  );
  Future<void> _discoverDlna() async {
    setState(() => _discoveringDlna = true);
    try {
      final devices = await DlnaDiscovery().discover();
      if (!mounted) return;
      if (devices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No DLNA servers found. Enter the device description URL manually.')),
        );
        return;
      }
      final selected = await showModalBottomSheet<DlnaDiscoveredDevice>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text('DLNA media servers', style: Theme.of(sheetContext).textTheme.titleLarge),
              ),
              for (final device in devices)
                ListTile(
                  title: Text(device.name),
                  subtitle: Text(device.location.toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () => Navigator.pop(sheetContext, device),
                ),
            ],
          ),
        ),
      );
      if (selected == null || !mounted) return;
      field('endpoint').text = selected.location.toString();
      setState(() => _allowHttp = selected.location.scheme == 'http');
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DLNA discovery is unavailable on this network. Enter the device description URL manually.')),
        );
      }
    } finally {
      if (mounted) setState(() => _discoveringDlna = false);
    }
  }

  Future<void> connect() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final controller = context.read<SourceController>();
    _connecting = controller;
    final epoch = controller.generation;
    try {
      await controller.ready;
      controller.requireSession(epoch);
      final source = FileSource(
        id: widget.existing?.id ?? const Uuid().v4(),
        profileId: controller.profileId!,
        kind: _kind,
        name: field('name').text.trim().isEmpty ? sourceKindName(_kind) : field('name').text.trim(),
        endpoint: field('endpoint').text.trim(),
        root: field('root').text.trim(),
        options: {
          ...?widget.existing?.options,
          'allowHttp': '${_kind != FileSourceKind.smb && _allowHttp}',
          if (_kind == FileSourceKind.smb) 'encryptSmb': '$_encryptSmb',
          'shelves': _shelves.map((s) => s.name).join(','),
          'onlineMetadata': '$_onlineMetadata',
          if (_kind == FileSourceKind.nfs && field('mountPort').text.trim().isNotEmpty)
            'mountPort': field('mountPort').text.trim(),
          if (_kind == FileSourceKind.nfs && field('uid').text.trim().isNotEmpty) 'uid': field('uid').text.trim(),
          if (_kind == FileSourceKind.nfs && field('gid').text.trim().isNotEmpty) 'gid': field('gid').text.trim(),
          if (field('clientId').text.trim().isNotEmpty) 'clientId': field('clientId').text.trim(),
          if (_kind == FileSourceKind.s3)
            'region': field('region').text.trim().isEmpty ? 'us-east-1' : field('region').text.trim(),
          if (_kind == FileSourceKind.webdav && field('syncRoot').text.trim().isNotEmpty)
            'syncRoot': field('syncRoot').text.trim(),
        },
      );
      final credentialKeys = [
        ...switch (_kind) {
          FileSourceKind.webdav || FileSourceKind.opds => const ['username', 'password'],
          FileSourceKind.smb || FileSourceKind.ftp => const ['username', 'password'],
          FileSourceKind.sftp => const ['username', 'password', 'hostKeyFingerprint', 'privateKey', 'privateKeyPassphrase'],
          FileSourceKind.s3 => const ['accessKey', 'secretKey', 'sessionToken'],
          FileSourceKind.audiobookshelf => const ['token'],
          _ => const <String>[],
        },
        'openSubtitlesApiKey',
        'openSubtitlesUsername',
        'openSubtitlesPassword',
      ];
      Map<String, String> credentials;
      if (oauth) {
        final previous = widget.existing == null
            ? const <String, String>{}
            : await controller.repository.credentials(widget.existing!);
        credentials = {
          ...previous,
          ...await controller.oauth.authorize(source, clientSecret: field('clientSecret').text),
          for (final key in ['openSubtitlesApiKey', 'openSubtitlesUsername', 'openSubtitlesPassword'])
            if (field(key).text.isNotEmpty) key: field(key).text,
        };
      } else {
        credentials = {
          if (widget.existing != null) ...await controller.repository.credentials(widget.existing!),
          for (final key in credentialKeys)
            if (field(key).text.isNotEmpty) key: field(key).text,
        };
      }
      controller.requireSession(epoch);
      if (!mounted) return;
      await controller.add(source, credentials);
      // A reconnect must discard any cached adapter and authorization lease.
      await controller.reconnect(source.id);
      await controller.browse(source.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FocusedScrollScaffold(
    title: Text(widget.existing == null ? t.fileSources.add : t.fileSources.reconnect),
    focusableAppBarActions: true,
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(24),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<FileSourceKind>(
                      isExpanded: true,
                      initialValue: _kind,
                      decoration: InputDecoration(labelText: t.fileSources.source),
                      items: [
                        for (final kind in FileSourceKind.values)
                          if ((kind != FileSourceKind.local || PlatformDetector.isDesktopOS()))
                            DropdownMenuItem(
                              value: kind,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FileSourceMark(kind, size: 24),
                                  const SizedBox(width: 12),
                                  Flexible(child: Text(sourceKindName(kind), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ),
                      ],
                      onChanged: _busy || widget.existing != null
                          ? null
                          : (kind) => setState(() {
                              _kind = kind!;
                              if (kind == FileSourceKind.dlna) _allowHttp = true;
                              if (!_shelvesCustomized) _shelves = defaultPublicationShelves(_kind);
                            }),
                    ),
                    const SizedBox(height: 24),
                    input('name', t.fileSources.name),
                    if (!oauth && _kind != FileSourceKind.local)
                      input(
                        'endpoint',
                        t.fileSources.endpoint,
                        required: true,
                        hint: switch (_kind) {
                          FileSourceKind.smb => t.fileSources.smbEndpointHint,
                          FileSourceKind.ftp => 'ftp://nas:21',
                          FileSourceKind.sftp => 'sftp://nas:22',
                          FileSourceKind.nfs => 'nfs://nas:2049/export',
                          FileSourceKind.dlna => 'http://192.168.1.20:8200/rootDesc.xml',
                          _ => null,
                        },
                        validator: _kind == FileSourceKind.smb
                            ? (value) {
                                if (value?.trim().isNotEmpty != true) return t.fileSources.endpoint;
                                try {
                                  validateSmbSourceEndpoint(value!.trim());
                                  return null;
                                } on SourceException {
                                  return t.fileSources.smbEndpointInvalid;
                                }
                              }
                            : null,
                      ),
                    if (_kind == FileSourceKind.dlna) ...[
                      OutlinedButton.icon(
                        onPressed: _busy || _discoveringDlna ? null : _discoverDlna,
                        icon: _discoveringDlna
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.search_rounded),
                        label: Text(_discoveringDlna ? 'Searching local network…' : 'Discover DLNA servers'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Discovery depends on local-network multicast. If no server appears, enter its device description URL above.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (_kind == FileSourceKind.local) ...[
                      input('root', t.fileSources.root, required: true),
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () async {
                                final path = await FilePicker.getDirectoryPath();
                                if (path != null && mounted) setState(() => field('root').text = path);
                              },
                        child: Text(t.fileSources.localFolder),
                      ),
                    ] else if (_kind != FileSourceKind.audiobookshelf && _kind != FileSourceKind.opds)
                      input(
                        'root',
                        t.fileSources.root,
                        hint: switch (_kind) {
                          FileSourceKind.dlna => 'DLNA object ID; blank uses the device root.',
                          FileSourceKind.smb => t.fileSources.smbFolderHelp,
                          _ => t.fileSources.folderHelp,
                        },
                      ),
                    if (const {
                      FileSourceKind.webdav,
                      FileSourceKind.opds,
                      FileSourceKind.smb,
                      FileSourceKind.ftp,
                      FileSourceKind.sftp,
                    }.contains(_kind)) ...[
                      input('username', t.fileSources.username, required: _kind == FileSourceKind.sftp && widget.existing == null),
                      input(
                        'password',
                        t.fileSources.password,
                        secret: true,
                        validator: _kind == FileSourceKind.sftp && widget.existing == null
                            ? (value) => value?.isNotEmpty == true || field('privateKey').text.trim().isNotEmpty
                                  ? null
                                  : 'Enter a password or add a private key below.'
                            : null,
                      ),
                      if (_kind == FileSourceKind.smb) input('domain', t.fileSources.smbDomain),
                    if (_kind == FileSourceKind.sftp) ...[
                      input('hostKeyFingerprint', 'SSH host key SHA256 fingerprint', required: widget.existing == null,
                        hint: widget.existing == null
                            ? 'Pin the server key before connecting; retrieve it from the server administrator.'
                            : 'Leave blank to keep the current pin, or enter a new server fingerprint.'),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('SSH public key authentication'),
                        subtitle: const Text('Optional; password authentication is also supported.'),
                        children: [
                          input('privateKey', 'Private key (PEM or OpenSSH format)', maxLines: 5),
                          input('privateKeyPassphrase', 'Private key passphrase', secret: true),
                        ],
                      ),
                    ],
                    if (_kind == FileSourceKind.nfs) ...[
                      input('mountPort', 'NFS mount service TCP port', hint: '20048'),
                      input('uid', 'NFS user ID (AUTH_SYS)', hint: '1000'),
                      input('gid', 'NFS group ID (AUTH_SYS)', hint: '1000'),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text('Read-only NFSv3 over TCP. The NAS must allow the selected AUTH_SYS IDs and unprivileged client ports (often the “insecure” export option). NFSv3 traffic is not encrypted.',
                          style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ],
                    if (_kind == FileSourceKind.ftp)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text('FTP uses passive mode. Use ftp:// for plain FTP, ftpes:// for explicit TLS, or ftps:// for TLS (implicit on port 990; explicit on other ports).',
                          style: Theme.of(context).textTheme.bodySmall),
                      ),
                      if (_kind == FileSourceKind.smb)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(t.fileSources.smbEncryption),
                          subtitle: Text(t.fileSources.smbEncryptionHint),
                          value: _encryptSmb,
                          onChanged: _busy ? null : (value) => setState(() => _encryptSmb = value),
                        ),
                    ],
                    if (_kind == FileSourceKind.audiobookshelf)
                      input('token', t.fileSources.token, secret: true, required: widget.existing == null),
                    if (_kind == FileSourceKind.s3) ...[
                      input('region', t.fileSources.region),
                      input('accessKey', t.fileSources.accessKey, required: widget.existing == null),
                      input('secretKey', t.fileSources.secretKey, secret: true, required: widget.existing == null),
                      input('sessionToken', t.fileSources.sessionToken, secret: true),
                    ],
                    if (_kind != FileSourceKind.opds && _kind != FileSourceKind.audiobookshelf)
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('OpenSubtitles'),
                        subtitle: const Text('Optional subtitle search for standalone videos.'),
                        children: [
                          input('openSubtitlesApiKey', 'API key', secret: true),
                          input('openSubtitlesUsername', 'Account username (optional)'),
                          input('openSubtitlesPassword', 'Account password (optional)', secret: true),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Get an API key from opensubtitles.com. The key and optional account credentials are encrypted with this source.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    if (oauth)
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(t.fileSources.advancedSetup),
                        children: [
                          input('clientId', t.fileSources.clientId),
                          if (_kind == FileSourceKind.googleDrive && !Platform.isAndroid && !Platform.isIOS)
                            input('clientSecret', t.fileSources.clientSecret, secret: true),
                        ],
                      ),
                    if (_kind != FileSourceKind.opds && _kind != FileSourceKind.audiobookshelf)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Automatic online video metadata'),
                        subtitle: const Text('Sends only filename title/year and episode numbers or an NFO ID, never media or credentials. NFO fields stay authoritative.'),
                        value: _onlineMetadata,
                        onChanged: _busy ? null : (v) => setState(() => _onlineMetadata = v),
                      ),
                    if (const {
                      FileSourceKind.webdav,
                      FileSourceKind.opds,
                      FileSourceKind.s3,
                      FileSourceKind.audiobookshelf,
                      FileSourceKind.dlna,
                    }.contains(_kind))
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.fileSources.allowHttp),
                        value: _allowHttp,
                        onChanged: _busy ? null : (v) => setState(() => _allowHttp = v),
                      ),
                    if (_kind == FileSourceKind.webdav)
                      input('syncRoot', t.fileSources.syncLocation, hint: t.fileSources.syncLocationHint),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          sourceFailureText(_error!),
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final shelf in PublicationShelf.values)
                          FilterChip(
                            label: Text(switch (shelf) {
                              PublicationShelf.ebooks => t.fileSources.ebooks,
                              PublicationShelf.audiobooks => t.fileSources.audiobooks,
                              PublicationShelf.comics => t.fileSources.comics,
                              PublicationShelf.videos => t.fileSources.video,
                            }),
                            selected: _shelves.contains(shelf),
                            onSelected: _busy
                                ? null
                                : (selected) => setState(() {
                                    _shelvesCustomized = true;
                                    selected ? _shelves.add(shelf) : _shelves.remove(shelf);
                                  }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : connect,
                      child: _busy
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : _kind == FileSourceKind.oneDrive
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const ProviderMark('microsoft.svg', size: 23),
                                const SizedBox(width: 8),
                                Flexible(child: Text(t.fileSources.microsoftSignIn, textAlign: TextAlign.center)),
                              ],
                            )
                          : Text(oauth ? t.fileSources.signIn : t.fileSources.connect),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
