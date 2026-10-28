import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../i18n/strings.g.dart';
import '../../providers/multi_server_provider.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_section.dart';
import 'logs_screen.dart';

class IssueReportScreen extends StatefulWidget {
  const IssueReportScreen({super.key, this.startupPhase, this.startupErrorType});

  /// Stable, non-user-controlled diagnostic identifiers from the startup
  /// failure record. Raw messages and stack traces are intentionally excluded
  /// from the QR payload.
  final String? startupPhase;
  final String? startupErrorType;

  @override
  State<IssueReportScreen> createState() => _IssueReportScreenState();
}

class _IssueReportScreenState extends State<IssueReportScreen> {
  static final Future<PackageInfo?> _packageInfo = _loadPackageInfo();
  String? _logId;

  static Future<PackageInfo?> _loadPackageInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (_) {
      return null;
    }
  }

  Uri _issueUri({required PackageInfo? package, required int online, required int expected}) {
    final version = package == null ? 'unknown' : '${package.version} (${package.buildNumber})';
    final body = [
      '### App and device',
      '- PlezyNG: $version',
      '- Platform: ${defaultTargetPlatform.name}',
      '- Media servers online: $online of $expected',
      if (_logId != null) '- Uploaded log ID: $_logId',
      '',
      '### What happened?',
      if (widget.startupPhase != null || widget.startupErrorType != null) ...[
        'Startup diagnostic context (phase and error type only):',
        '- Phase: ${_safeDiagnosticId(widget.startupPhase)}',
        '- Error type: ${_safeDiagnosticId(widget.startupErrorType)}',
        '',
      ],
      '[Describe what happened and what you expected.]',
      '',
      '### Steps to reproduce',
      '1. ',
    ].join('\n');
    return Uri.https('github.com', '/snapetech-org/PlezyNG/issues/new', {
      'title': '[PlezyNG] Bug report',
      'body': body,
    });
  }

  String _safeDiagnosticId(String? value) {
    final safe = (value ?? 'unknown').replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '');
    return safe.isEmpty ? 'unknown' : String.fromCharCodes(safe.runes.take(64));
  }

  Future<void> _openIssue(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // The QR and copy actions remain available when this platform cannot
      // hand the draft to an external browser.
    }
    if (mounted) showErrorSnackBar(context, t.common.error);
  }

  Future<void> _copyIssue(Uri uri) async {
    try {
      await Clipboard.setData(ClipboardData(text: uri.toString()));
      if (mounted) showSuccessSnackBar(context, t.deepLinks.copied);
    } catch (_) {
      if (mounted) showErrorSnackBar(context, t.common.error);
    }
  }

  Future<void> _attachLogs() async {
    final id = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const LogsScreen(returnUploadedLogId: true)));
    if (!mounted || id == null) return;
    setState(() => _logId = id);
  }

  @override
  Widget build(BuildContext context) {
    final servers = context.watch<MultiServerProvider?>();
    final online = servers?.onlineServerCount ?? 0;
    final expected = servers?.expectedServerIds.length ?? 0;

    return FutureBuilder<PackageInfo?>(
      future: _packageInfo,
      builder: (context, snapshot) {
        final packageInfoReady = snapshot.connectionState != ConnectionState.waiting;
        final uri = _issueUri(package: snapshot.data, online: online, expected: expected);
        return FocusedScrollScaffold(
          title: Text(t.issueReport.title),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.issueReport.instructions, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.white,
                        child: packageInfoReady
                            ? Semantics(
                                label: t.issueReport.instructions,
                                image: true,
                                child: QrImageView(
                                  data: uri.toString(),
                                  size: 240,
                                  version: QrVersions.auto,
                                  backgroundColor: Colors.white,
                                ),
                              )
                            : const SizedBox.square(dimension: 240, child: Center(child: CircularProgressIndicator())),
                      ),
                    ),
                    if (_logId != null) ...[const SizedBox(height: 12), SelectableText('${t.messages.logId}: $_logId')],
                    const SizedBox(height: 16),
                    SettingsGroup(
                      children: [
                        SettingNavigationTile(
                          icon: Symbols.open_in_new_rounded,
                          title: t.issueReport.openDraft,
                          subtitle: t.issueReport.instructions,
                          onTap: packageInfoReady ? () => _openIssue(uri) : null,
                        ),
                        SettingNavigationTile(
                          icon: Symbols.content_copy_rounded,
                          title: t.common.copy,
                          subtitle: t.issueReport.openDraft,
                          onTap: packageInfoReady ? () => _copyIssue(uri) : null,
                        ),
                        SettingNavigationTile(
                          icon: Symbols.upload_rounded,
                          title: t.logs.uploadLogs,
                          subtitle: t.issueReport.logPrivacy,
                          onTap: _attachLogs,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _PrivacyNote(text: t.issueReport.privacy),
                    const SizedBox(height: 8),
                    _PrivacyNote(text: t.issueReport.logPrivacy),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon(Symbols.info_rounded, size: 18, color: colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
        ),
      ],
    );
  }
}
