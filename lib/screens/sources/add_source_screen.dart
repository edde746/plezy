import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../i18n/presentation_formats.dart';
import '../../providers/trackers_provider.dart';
import '../../sources/dlna_discovery.dart';
import '../../sources/source_controller.dart';
import '../../sources/source_models.dart';
import '../../sources/publication_shelf.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/provider_mark.dart';
import '../settings/services_settings_screen.dart';
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
  bool _nfsRpcTls = false;
  bool _nfsTlsIdentitySelected = false;
  bool _clearNfsTlsIdentity = false;
  bool _nfsTlsIdentitySaved = false;
  String? _nfsServerCertificateFileName;
  String? _nfsClientIdentityFileName;
  Set<PublicationShelf> _shelves = {PublicationShelf.ebooks, PublicationShelf.audiobooks, PublicationShelf.videos};
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
      _nfsRpcTls = old.options['rpcTls'] == 'required';
      field('rpcTlsServerCertificatePem').text = old.options['rpcTlsServerCertificatePem'] ?? '';
      if (old.kind == FileSourceKind.nfs) {
        if (field('rpcTlsServerCertificatePem').text.isNotEmpty) {
          _nfsServerCertificateFileName = t.sourceSetup.savedCertificate;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedNfsTlsIdentity(old));
      }
      _shelves = PublicationShelf.values
          .where((s) => (old.options['shelves'] ?? 'ebooks,audiobooks,videos').split(',').contains(s.name))
          .toSet();
      field('syncRoot').text = old.options['syncRoot'] ?? '';
      field('region').text = old.options['region'] ?? '';
    }
  }

  Future<void> _loadSavedNfsTlsIdentity(FileSource source) async {
    try {
      final controller = context.read<SourceController>();
      await controller.ready;
      final credentials = await controller.repository.credentials(source);
      if (mounted) {
        setState(() => _nfsTlsIdentitySaved = credentials['nfsTlsClientIdentity']?.isNotEmpty == true);
      }
    } on Object {
      // Credential state is optional UI context; the saved source still works.
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
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    FormFieldValidator<String>? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: FocusableTextFormField(
      controller: field(key),
      obscureText: secret,
      textDirection: key == 'name' ? null : TextDirection.ltr,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      autocorrect: false,
      enableSuggestions: !secret,
      decoration: InputDecoration(labelText: label, helperText: hint, helperMaxLines: 6, errorMaxLines: 4),
      validator:
          validator ??
          (required
              ? (value) => value?.trim().isNotEmpty == true ? null : t.sourceSetup.fieldRequired(label: label)
              : null),
    ),
  );

  String? _validateSmbEndpoint(String? value) {
    try {
      validateSmbSourceEndpoint(value?.trim() ?? '');
      return null;
    } on SourceException {
      return t.fileSources.smbEndpointInvalid;
    }
  }

  String? _validateNfsEndpoint(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    if (uri == null ||
        uri.scheme != 'nfs' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.hasPort && (uri.port < 1 || uri.port > 65535) ||
        uri.pathSegments.any((part) => part == '.' || part == '..' || part.contains(String.fromCharCode(0)))) {
      return t.sourceSetup.nfsEndpointInvalid;
    }
    return null;
  }

  String? _validateNfsInteger(String? value, {required int min, required int max, required String label}) {
    if (value?.trim().isEmpty != false) return null;
    final parsed = parseLocalizedInteger(value!);
    if (parsed == null || parsed < min || parsed > max) {
      return t.sourceSetup.integerRange(
        label: label,
        min: formatDecimal(min, maximumDecimals: 0),
        max: formatDecimal(max, maximumDecimals: 0),
      );
    }
    return null;
  }

  Future<void> _pickNfsServerCertificate() async {
    try {
      final selection = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pem', 'crt', 'cer'],
        withData: true,
      );
      final file = selection?.files.single;
      if (file == null) return;
      final bytes = file.bytes;
      if (bytes == null || bytes.length > 256 * 1024) {
        throw const SourceException(SourceFailure.invalidData);
      }
      final pem = utf8.decode(bytes).trim();
      if (!pem.contains('-----BEGIN CERTIFICATE-----') || pem.contains('PRIVATE KEY')) {
        throw const SourceException(SourceFailure.invalidData);
      }
      if (!mounted) return;
      setState(() {
        field('rpcTlsServerCertificatePem').text = pem;
        _nfsServerCertificateFileName = file.name;
        _error = null;
      });
    } on Object {
      if (mounted) setState(() => _error = const SourceException(SourceFailure.invalidData));
    }
  }

  Future<void> _pickNfsClientIdentity() async {
    try {
      final selection = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['p12', 'pfx'],
        withData: true,
      );
      final file = selection?.files.single;
      if (file == null) return;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty || bytes.length > 1024 * 1024) {
        throw const SourceException(SourceFailure.invalidData);
      }
      if (!mounted) return;
      setState(() {
        field('nfsTlsClientIdentity').text = base64Encode(bytes);
        _nfsClientIdentityFileName = file.name;
        _nfsTlsIdentitySelected = true;
        _clearNfsTlsIdentity = false;
        _error = null;
      });
    } on Object {
      if (mounted) setState(() => _error = const SourceException(SourceFailure.invalidData));
    }
  }

  Future<void> _discoverDlna() async {
    setState(() => _discoveringDlna = true);
    try {
      final devices = await DlnaDiscovery().discover();
      if (!mounted) return;
      if (devices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.sourceSetup.dlnaNone)));
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
                child: Text(t.sourceSetup.dlnaServers, style: Theme.of(sheetContext).textTheme.titleLarge),
              ),
              for (final device in devices)
                FocusableListTile(
                  title: Text(isolateDisplayText(device.name), maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    isolateDisplayText(device.location.toString()),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                  ),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.sourceSetup.dlnaUnavailable)));
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
          'allowHttp': '${_kind != FileSourceKind.smb && _allowHttp}',
          if (_kind == FileSourceKind.smb) 'encryptSmb': '$_encryptSmb',
          'shelves': _shelves.map((s) => s.name).join(','),
          'onlineMetadata': '$_onlineMetadata',
          if (_kind == FileSourceKind.nfs && field('mountPort').text.trim().isNotEmpty)
            'mountPort': normalizeDecimalDigits(field('mountPort').text.trim()),
          if (_kind == FileSourceKind.nfs && field('uid').text.trim().isNotEmpty)
            'uid': normalizeDecimalDigits(field('uid').text.trim()),
          if (_kind == FileSourceKind.nfs && field('gid').text.trim().isNotEmpty)
            'gid': normalizeDecimalDigits(field('gid').text.trim()),
          if (_kind == FileSourceKind.nfs && _nfsRpcTls) ...{
            'rpcTls': 'required',
            'rpcTlsServerCertificatePem': field('rpcTlsServerCertificatePem').text.trim(),
          },
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
          FileSourceKind.sftp => const [
            'username',
            'password',
            'hostKeyFingerprint',
            'privateKey',
            'privateKeyPassphrase',
          ],
          FileSourceKind.nfs => const ['nfsTlsClientIdentity', 'nfsTlsClientIdentityPassword'],
          FileSourceKind.s3 => const ['accessKey', 'secretKey', 'sessionToken'],
          FileSourceKind.audiobookshelf => const ['token'],
          FileSourceKind.komga => const ['username', 'password', 'token'],
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
      if (_clearNfsTlsIdentity) {
        credentials.remove('nfsTlsClientIdentity');
        credentials.remove('nfsTlsClientIdentityPassword');
      }
      if (_nfsTlsIdentitySelected && field('nfsTlsClientIdentityPassword').text.trim().isEmpty) {
        credentials.remove('nfsTlsClientIdentityPassword');
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
                              if (kind == FileSourceKind.komga) _shelves = {PublicationShelf.comics};
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
                          FileSourceKind.komga => 'https://komga.example.com',
                          _ => null,
                        },
                        validator: _kind == FileSourceKind.nfs
                            ? _validateNfsEndpoint
                            : _kind == FileSourceKind.smb
                            ? _validateSmbEndpoint
                            : null,
                      ),
                    if (_kind == FileSourceKind.dlna) ...[
                      OutlinedButton.icon(
                        onPressed: _busy || _discoveringDlna ? null : _discoverDlna,
                        icon: _discoveringDlna
                            ? Semantics(
                                label: t.sourceSetup.dlnaSearching,
                                liveRegion: true,
                                child: const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : const Icon(Icons.search_rounded),
                        label: Text(_discoveringDlna ? t.sourceSetup.networkSearching : t.sourceSetup.dlnaDiscover),
                      ),
                      const SizedBox(height: 8),
                      Text(t.sourceSetup.dlnaHelp, style: Theme.of(context).textTheme.bodySmall),
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
                    ] else if (_kind != FileSourceKind.audiobookshelf &&
                        _kind != FileSourceKind.opds &&
                        _kind != FileSourceKind.komga)
                      input(
                        'root',
                        t.fileSources.root,
                        hint: _kind == FileSourceKind.dlna
                            ? t.sourceSetup.dlnaRoot
                            : _kind == FileSourceKind.smb
                            ? t.fileSources.smbFolderHelp
                            : t.fileSources.folderHelp,
                      ),
                    if (const {
                      FileSourceKind.webdav,
                      FileSourceKind.opds,
                      FileSourceKind.komga,
                      FileSourceKind.smb,
                      FileSourceKind.ftp,
                      FileSourceKind.sftp,
                    }.contains(_kind)) ...[
                      input(
                        'username',
                        t.fileSources.username,
                        required: _kind == FileSourceKind.sftp && widget.existing == null,
                      ),
                      input(
                        'password',
                        t.fileSources.password,
                        secret: true,
                        validator: _kind == FileSourceKind.sftp && widget.existing == null
                            ? (value) => value?.isNotEmpty == true || field('privateKey').text.trim().isNotEmpty
                                  ? null
                                  : t.sourceSetup.passwordOrKey
                            : null,
                      ),
                      if (_kind == FileSourceKind.smb) input('domain', t.fileSources.smbDomain),
                      if (_kind == FileSourceKind.sftp) ...[
                        input(
                          'hostKeyFingerprint',
                          t.sourceSetup.sshFingerprint,
                          required: widget.existing == null,
                          hint: widget.existing == null
                              ? t.sourceSetup.sshFingerprintHelp
                              : t.sourceSetup.sshFingerprintKeep,
                        ),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(t.sourceSetup.sshAuthentication),
                          subtitle: Text(t.sourceSetup.sshAuthenticationHelp),
                          children: [
                            input('privateKey', t.sourceSetup.privateKey, maxLines: 5),
                            input('privateKeyPassphrase', t.sourceSetup.privateKeyPassphrase, secret: true),
                          ],
                        ),
                      ],
                      if (_kind == FileSourceKind.nfs) ...[
                        input(
                          'mountPort',
                          t.sourceSetup.nfsMountPort,
                          hint: t.sourceSetup.nfsMountPortHelp,
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              _validateNfsInteger(value, min: 1, max: 65535, label: t.sourceSetup.nfsMountPort),
                        ),
                        input(
                          'uid',
                          t.sourceSetup.nfsUserId,
                          hint: t.sourceSetup.nfsUserIdHelp,
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              _validateNfsInteger(value, min: 0, max: 0xffffffff, label: t.sourceSetup.nfsUserId),
                        ),
                        input(
                          'gid',
                          t.sourceSetup.nfsGroupId,
                          hint: t.sourceSetup.nfsGroupIdHelp,
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              _validateNfsInteger(value, min: 0, max: 0xffffffff, label: t.sourceSetup.nfsGroupId),
                        ),
                        FocusableSwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(t.sourceSetup.nfsEncryption),
                          subtitle: Text(t.sourceSetup.nfsEncryptionHelp),
                          value: _nfsRpcTls,
                          onChanged: _busy ? null : (value) => setState(() => _nfsRpcTls = value),
                        ),
                        if (_nfsRpcTls) ...[
                          input(
                            'rpcTlsServerCertificatePem',
                            t.sourceSetup.nfsTrustCertificate,
                            maxLines: 6,
                            hint: t.sourceSetup.nfsTrustHelp,
                            validator: (value) {
                              final pem = value?.trim() ?? '';
                              if (pem.isNotEmpty &&
                                  (!pem.contains('-----BEGIN CERTIFICATE-----') || pem.contains('PRIVATE KEY'))) {
                                return t.sourceSetup.nfsTrustInvalid;
                              }
                              return null;
                            },
                          ),
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _pickNfsServerCertificate,
                            icon: const Icon(Icons.upload_file_rounded),
                            label: Text(
                              _nfsServerCertificateFileName != null
                                  ? t.sourceSetup.replaceFile(name: isolateDisplayText(_nfsServerCertificateFileName!))
                                  : field('rpcTlsServerCertificatePem').text.trim().isEmpty
                                  ? t.sourceSetup.addTrustCertificate
                                  : t.sourceSetup.replaceTrustCertificate,
                            ),
                          ),
                          Padding(padding: EdgeInsets.only(top: 8, bottom: 12), child: Text(t.sourceSetup.nfsTlsHelp)),
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(t.sourceSetup.clientCertificate),
                            subtitle: Text(t.sourceSetup.clientCertificateHelp),
                            children: [
                              if (_nfsClientIdentityFileName != null)
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    t.sourceSetup.selectedIdentity(
                                      name: isolateDisplayText(_nfsClientIdentityFileName!),
                                    ),
                                  ),
                                )
                              else if (_nfsTlsIdentitySaved && !_clearNfsTlsIdentity)
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(t.sourceSetup.savedIdentity),
                                ),
                              OutlinedButton.icon(
                                onPressed: _busy ? null : _pickNfsClientIdentity,
                                icon: const Icon(Icons.upload_file_rounded),
                                label: Text(
                                  _nfsClientIdentityFileName != null
                                      ? t.sourceSetup.replaceFile(name: isolateDisplayText(_nfsClientIdentityFileName!))
                                      : _nfsTlsIdentitySaved && !_clearNfsTlsIdentity
                                      ? t.sourceSetup.replaceIdentity
                                      : t.sourceSetup.chooseIdentity,
                                ),
                              ),
                              input(
                                'nfsTlsClientIdentityPassword',
                                t.sourceSetup.identityPassphrase,
                                secret: true,
                                hint: t.sourceSetup.identityPassphraseHelp,
                              ),
                              TextButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => setState(() {
                                        _clearNfsTlsIdentity = true;
                                        _nfsTlsIdentitySelected = false;
                                        _nfsClientIdentityFileName = null;
                                        field('nfsTlsClientIdentity').clear();
                                        field('nfsTlsClientIdentityPassword').clear();
                                      }),
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: Text(t.sourceSetup.removeIdentity),
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Text(t.sourceSetup.identityStorageHelp),
                              ),
                            ],
                          ),
                        ],
                        Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 12),
                          child: Text(t.sourceSetup.nfsLimitations),
                        ),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(t.sourceSetup.nfsSetupHelp),
                          subtitle: Text(t.sourceSetup.nfsSetupHint),
                          children: [
                            Padding(padding: EdgeInsets.only(bottom: 12), child: Text(t.sourceSetup.nfsSetupDetails)),
                          ],
                        ),
                      ],
                      if (_kind == FileSourceKind.ftp)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(t.sourceSetup.ftpHelp, style: Theme.of(context).textTheme.bodySmall),
                        ),
                      if (_kind == FileSourceKind.smb)
                        FocusableSwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(t.fileSources.smbEncryption),
                          subtitle: Text(t.fileSources.smbEncryptionHint),
                          value: _encryptSmb,
                          onChanged: _busy ? null : (value) => setState(() => _encryptSmb = value),
                        ),
                    ],
                    if (_kind == FileSourceKind.audiobookshelf)
                      input('token', t.fileSources.token, secret: true, required: widget.existing == null),
                    if (_kind == FileSourceKind.komga)
                      input('token', t.fileSources.token, secret: true, hint: t.sourceSetup.sshAuthenticationHelp),
                    if (_kind == FileSourceKind.s3) ...[
                      input('region', t.fileSources.region),
                      input('accessKey', t.fileSources.accessKey, required: widget.existing == null),
                      input('secretKey', t.fileSources.secretKey, secret: true, required: widget.existing == null),
                      input('sessionToken', t.fileSources.sessionToken, secret: true),
                    ],
                    if (_kind != FileSourceKind.opds &&
                        _kind != FileSourceKind.audiobookshelf &&
                        _kind != FileSourceKind.komga)
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(t.sourceSetup.openSubtitles),
                        subtitle: Text(t.sourceSetup.subtitleSetup),
                        children: [
                          input('openSubtitlesApiKey', t.sourceSetup.apiKey, secret: true),
                          input('openSubtitlesUsername', t.sourceSetup.optionalUsername),
                          input('openSubtitlesPassword', t.sourceSetup.optionalPassword, secret: true),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(t.sourceSetup.subtitlePrivacy, style: Theme.of(context).textTheme.bodySmall),
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
                    if (_kind != FileSourceKind.opds &&
                        _kind != FileSourceKind.audiobookshelf &&
                        _kind != FileSourceKind.komga)
                      FocusableSwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.sourceSetup.automaticMetadata),
                        subtitle: Text(t.sourceSetup.metadataPrivacy),
                        value: _onlineMetadata,
                        onChanged: _busy ? null : (v) => setState(() => _onlineMetadata = v),
                      ),
                    if (context.watch<TrackersProvider?>()?.traktCatalogClient == null)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ServicesSettingsScreen()),
                          ),
                          icon: const Icon(Icons.link_rounded),
                          label: Text('${t.common.connect} ${t.trakt.title}'),
                        ),
                      ),
                    if (const {
                      FileSourceKind.webdav,
                      FileSourceKind.opds,
                      FileSourceKind.s3,
                      FileSourceKind.audiobookshelf,
                      FileSourceKind.dlna,
                      FileSourceKind.komga,
                    }.contains(_kind))
                      FocusableSwitchListTile(
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
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            sourceFailureText(_error!),
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                      ),
                    if (_error != null && _kind == FileSourceKind.nfs && _nfsRpcTls)
                      Padding(padding: EdgeInsets.only(bottom: 12), child: Text(t.sourceSetup.nfsEncryptionFailure)),
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
                                    selected ? _shelves.add(shelf) : _shelves.remove(shelf);
                                  }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : connect,
                      child: _busy
                          ? Semantics(
                              label: t.sourceSetup.sourceConnecting,
                              liveRegion: true,
                              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
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
