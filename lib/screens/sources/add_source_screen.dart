import 'dart:convert';
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
          _nfsServerCertificateFileName = 'Saved server certificate';
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
    child: TextFormField(
      controller: field(key),
      obscureText: secret,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      autocorrect: false,
      enableSuggestions: !secret,
      decoration: InputDecoration(labelText: label, helperText: hint),
      validator: validator ?? (required ? (value) => value?.trim().isNotEmpty == true ? null : '$label is required.' : null),
    ),
  );

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
      return 'Enter an NFS URL such as nfs://nas:2049/export.';
    }
    return null;
  }

  String? _validateNfsInteger(String? value, {required int min, required int max, required String label}) {
    if (value?.trim().isEmpty != false) return null;
    final parsed = int.tryParse(value!.trim());
    if (parsed == null || parsed < min || parsed > max) {
      return 'Enter $label from $min to $max.';
    }
    return null;
  }

  Future<void> _pickNfsServerCertificate() async {
    try {
      final selection = await FilePicker.platform.pickFiles(
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
      final selection = await FilePicker.platform.pickFiles(
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
          'allowHttp': '${_kind != FileSourceKind.smb && _allowHttp}',
          if (_kind == FileSourceKind.smb) 'encryptSmb': '$_encryptSmb',
          'shelves': _shelves.map((s) => s.name).join(','),
          'onlineMetadata': '$_onlineMetadata',
          if (_kind == FileSourceKind.nfs && field('mountPort').text.trim().isNotEmpty)
            'mountPort': field('mountPort').text.trim(),
          if (_kind == FileSourceKind.nfs && field('uid').text.trim().isNotEmpty) 'uid': field('uid').text.trim(),
          if (_kind == FileSourceKind.nfs && field('gid').text.trim().isNotEmpty) 'gid': field('gid').text.trim(),
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
          FileSourceKind.sftp => const ['username', 'password', 'hostKeyFingerprint', 'privateKey', 'privateKeyPassphrase'],
          FileSourceKind.nfs => const ['nfsTlsClientIdentity', 'nfsTlsClientIdentityPassword'],
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
                          FileSourceKind.smb => 'smb://nas/Movies',
                          FileSourceKind.ftp => 'ftp://nas:21',
                          FileSourceKind.sftp => 'sftp://nas:22',
                          FileSourceKind.nfs => 'nfs://nas:2049/export',
                          FileSourceKind.dlna => 'http://192.168.1.20:8200/rootDesc.xml',
                          _ => null,
                        },
                        validator: _kind == FileSourceKind.nfs ? _validateNfsEndpoint : null,
                      ),
                    if (_kind == FileSourceKind.dlna) ...[
                      OutlinedButton.icon(
                        onPressed: _busy || _discoveringDlna ? null : _discoverDlna,
                        icon: _discoveringDlna
                            ? Semantics(
                                label: 'Searching local network for DLNA servers',
                                liveRegion: true,
                                child: const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
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
                        hint: _kind == FileSourceKind.dlna ? 'DLNA object ID; blank uses the device root.' : t.fileSources.folderHelp,
                      ),
                    if (const {FileSourceKind.webdav, FileSourceKind.opds, FileSourceKind.smb, FileSourceKind.ftp, FileSourceKind.sftp}.contains(_kind)) ...[
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
                      if (_kind == FileSourceKind.smb) input('domain', 'Domain (optional)'),
                    if (_kind == FileSourceKind.sftp) ...[
                      input('hostKeyFingerprint', 'SSH host key SHA256 fingerprint', required: widget.existing == null,
                        hint: widget.existing == null
                            ? 'Verify with the server administrator. On the server, run ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub and use its SHA256 value.'
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
                      input(
                        'mountPort',
                        'NFS mount service TCP port',
                        hint: 'Default: 20048',
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNfsInteger(
                          value,
                          min: 1,
                          max: 65535,
                          label: 'a TCP port',
                        ),
                      ),
                      input(
                        'uid',
                        'NFS user ID (AUTH_SYS)',
                        hint: 'Default: 1000. Use the ID the NAS export allows.',
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNfsInteger(
                          value,
                          min: 0,
                          max: 0xffffffff,
                          label: 'a UID',
                        ),
                      ),
                      input(
                        'gid',
                        'NFS group ID (AUTH_SYS)',
                        hint: 'Default: 1000. Use the group ID the NAS export allows.',
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNfsInteger(
                          value,
                          min: 0,
                          max: 0xffffffff,
                          label: 'a GID',
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Require encrypted NFS (RPC-with-TLS)'),
                        subtitle: const Text(
                          'Require TLS 1.3 for NFS and the mount service. Connections fail closed if the NAS does not support it.',
                        ),
                        value: _nfsRpcTls,
                        onChanged: _busy ? null : (value) => setState(() => _nfsRpcTls = value),
                      ),
                      if (_nfsRpcTls) ...[
                        input(
                          'rpcTlsServerCertificatePem',
                          'Custom NFS CA or server certificate (PEM, optional)',
                          maxLines: 6,
                          hint: 'Leave blank for certificates trusted by this device. Add a private CA or self-signed server certificate when needed; its names must match the NFS URL host.',
                          validator: (value) {
                            final pem = value?.trim() ?? '';
                            if (pem.isNotEmpty &&
                                (!pem.contains('-----BEGIN CERTIFICATE-----') || pem.contains('PRIVATE KEY'))) {
                              return 'Use a CA or server certificate in PEM format. Do not include a private key.';
                            }
                            return null;
                          },
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _pickNfsServerCertificate,
                          icon: const Icon(Icons.upload_file_rounded),
                          label: Text(
                            _nfsServerCertificateFileName != null
                                ? 'Replace ${_nfsServerCertificateFileName!}'
                                : field('rpcTlsServerCertificatePem').text.trim().isEmpty
                                    ? 'Add custom trust certificate'
                                    : 'Replace saved custom certificate',
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 12),
                          child: Text(
                            'RPC-with-TLS uses the usual NFS and mount service ports and requires NAS support for RFC 9289. TLS 1.3 is required. The host name or IP must match the certificate. AUTH_SYS UID/GID still apply inside the encrypted channel.',
                          ),
                        ),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text('Client certificate (optional)'),
                          subtitle: const Text('Lets the NAS authenticate this client; AUTH_SYS IDs still depend on NAS export policy.'),
                          children: [
                            if (_nfsClientIdentityFileName != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Selected client identity: ${_nfsClientIdentityFileName!}'),
                              )
                            else if (_nfsTlsIdentitySaved && !_clearNfsTlsIdentity)
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('A saved client identity will be used.'),
                              ),
                            OutlinedButton.icon(
                              onPressed: _busy ? null : _pickNfsClientIdentity,
                              icon: const Icon(Icons.upload_file_rounded),
                              label: Text(
                                _nfsClientIdentityFileName != null
                                    ? 'Replace ${_nfsClientIdentityFileName!}'
                                    : _nfsTlsIdentitySaved && !_clearNfsTlsIdentity
                                        ? 'Replace saved client identity'
                                        : 'Choose PKCS#12 client identity',
                              ),
                            ),
                            input(
                              'nfsTlsClientIdentityPassword',
                              'Client identity passphrase',
                              secret: true,
                              hint: 'Leave blank if the file has no passphrase.',
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
                              label: const Text('Remove any saved client identity'),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Client identities are saved in the encrypted source credential store. Leave this section unchanged to keep the saved identity.',
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 12),
                        child: Text(
                          'Read-only NFSv3 over TCP. Without RPC-with-TLS, NFS traffic is unencrypted. The NAS must allow the selected AUTH_SYS IDs and unprivileged client ports (often called the “insecure” export option). NFSv4 and UDP are not supported.',
                        ),
                      ),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('NFS setup help'),
                        subtitle: const Text('Check these settings if the connection does not open.'),
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Use an NFSv3 TCP export. The NFS service and mount service must both support RPC-with-TLS when encryption is required. Leave the custom certificate blank for a server certificate trusted by this device, or add the NAS CA/self-signed certificate. The certificate name must match the host in the endpoint. If the NAS asks for mutual TLS, add its PKCS#12 client identity. Finally, confirm the export allows the configured AUTH_SYS UID/GID and the client port policy.',
                            ),
                          ),
                        ],
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
                          title: const Text('Encrypt SMB3 connection'),
                          subtitle: const Text('Use SMB3 encryption when the NAS supports it.'),
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
                              'Get an API key from opensubtitles.com. Search sends the video title and available IMDb/TMDB IDs, never the video file. The key and optional account credentials are encrypted with this source.',
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
                    if (const {FileSourceKind.webdav, FileSourceKind.opds, FileSourceKind.s3, FileSourceKind.audiobookshelf, FileSourceKind.dlna}.contains(_kind))
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
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            sourceFailureText(_error!),
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                      ),
                    if (_error != null && _kind == FileSourceKind.nfs && _nfsRpcTls)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'For encrypted NFS, check RFC 9289 and TLS 1.3 support on both NAS services, the certificate name, and the export UID/GID. PlezyNG will not retry this connection without encryption.',
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
                                    selected ? _shelves.add(shelf) : _shelves.remove(shelf);
                                  }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : connect,
                      child: _busy
                          ? const Semantics(
                              label: 'Connecting to source',
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
