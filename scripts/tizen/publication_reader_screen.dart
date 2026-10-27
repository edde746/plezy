// Staged in place of the desktop reader: that reader already refuses TVs,
// but its PDFium dependency runs a desktop native-assets hook during a build.
import 'package:flutter/material.dart';
import 'package:plezy/sources/source_models.dart';

class PublicationReaderScreen extends StatelessWidget {
  const PublicationReaderScreen({super.key, required this.entry, required this.file});
  final SourceEntry entry;
  final PublicationFile file;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reader unavailable')),
    body: const Center(child: Text('Books and PDFs are not available on Samsung TV.')),
  );
}
