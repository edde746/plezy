import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../sources/source_models.dart';
import 'app_icon.dart';

/// Official, unmodified artwork. Brand colours deliberately survive theme
/// changes; only the surrounding PlezyNG surface and spacing are themed.
class ProviderMark extends StatelessWidget {
  const ProviderMark(this.asset, {super.key, this.size = 28, this.label});
  final String asset;
  final double size;
  final String? label;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    image: true,
    child: SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: asset.endsWith('.svg')
            ? SvgPicture.asset('assets/provider_marks/$asset', fit: BoxFit.contain)
            : Image.asset('assets/provider_marks/$asset', fit: BoxFit.contain),
      ),
    ),
  );
}

class FileSourceMark extends StatelessWidget {
  const FileSourceMark(this.kind, {super.key, this.size = 28});
  final FileSourceKind kind;
  final double size;
  @override
  Widget build(BuildContext context) => switch (kind) {
    FileSourceKind.googleDrive => ProviderMark('google_drive.png', size: size, label: 'Google Drive'),
    FileSourceKind.oneDrive => ProviderMark('onedrive.svg', size: size, label: 'OneDrive'),
    FileSourceKind.dropbox => ProviderMark('dropbox.png', size: size, label: 'Dropbox'),
    FileSourceKind.local => AppIcon(Symbols.folder_open_rounded, size: size),
    FileSourceKind.opds => AppIcon(Symbols.auto_stories_rounded, size: size),
    FileSourceKind.audiobookshelf => AppIcon(Symbols.headphones_rounded, size: size),
    FileSourceKind.webdav || FileSourceKind.s3 => AppIcon(Symbols.cloud_queue_rounded, size: size),
    FileSourceKind.smb || FileSourceKind.ftp || FileSourceKind.dlna =>
      AppIcon(Symbols.storage_rounded, size: size),
    FileSourceKind.sftp => AppIcon(Symbols.lock_rounded, size: size),
    FileSourceKind.nfs => AppIcon(Symbols.folder_open_rounded, size: size),
  };
}
