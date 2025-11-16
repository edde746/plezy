import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/desktop_app_bar.dart';
import '../i18n/strings.g.dart';

class MergedLicenseEntry {
  final String packageName;
  final List<LicenseEntry> licenseEntries;
  final Set<String> allPackageNames;

  MergedLicenseEntry({
    required this.packageName,
    required this.licenseEntries,
    required this.allPackageNames,
  });
}

class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key});

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  List<MergedLicenseEntry> _mergedLicenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  Future<void> _loadLicenses() async {
    final licenseMap = <String, List<LicenseEntry>>{};
    final allPackageNames = <String, Set<String>>{};

    await for (final license in LicenseRegistry.licenses) {
      for (final packageName in license.packages) {
        if (!licenseMap.containsKey(packageName)) {
          licenseMap[packageName] = [];
          allPackageNames[packageName] = <String>{};
        }
        licenseMap[packageName]!.add(license);
        allPackageNames[packageName]!.addAll(license.packages);
      }
    }

    final mergedLicenses = licenseMap.entries.map((entry) {
      return MergedLicenseEntry(
        packageName: entry.key,
        licenseEntries: entry.value,
        allPackageNames: allPackageNames[entry.key]!,
      );
    }).toList();

    mergedLicenses.sort((a, b) => a.packageName.compareTo(b.packageName));

    if (mounted) {
      setState(() {
        _mergedLicenses = mergedLicenses;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomAppBar(title: Text(t.screens.licenses), pinned: true),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final mergedLicense = _mergedLicenses[index];
                final packageName = mergedLicense.packageName;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      packageName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: mergedLicense.licenseEntries.length > 1
                        ? Text(
                            t.licenses.licensesCount(
                              count: mergedLicense.licenseEntries.length,
                            ),
                          )
                        : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLicenseDetail(mergedLicense),
                  ),
                );
              }, childCount: _mergedLicenses.length),
            ),
          ),
        ],
      ),
    );
  }

  void _showLicenseDetail(MergedLicenseEntry mergedLicense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _LicenseDetailScreen(mergedLicense: mergedLicense),
      ),
    );
  }
}

class _LicenseDetailScreen extends StatelessWidget {
  final MergedLicenseEntry mergedLicense;

  const _LicenseDetailScreen({required this.mergedLicense});

  @override
  Widget build(BuildContext context) {
    final packageName = mergedLicense.packageName;
    final licenseEntries = mergedLicense.licenseEntries;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomAppBar(title: Text(packageName), pinned: true),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Package info card
                if (mergedLicense.allPackageNames.length > 1)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.licenses.relatedPackages,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mergedLicense.allPackageNames.join(', '),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (mergedLicense.allPackageNames.length > 1)
                  const SizedBox(height: 16),

                // License cards
                ...licenseEntries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final license = entry.value;
                  final isMultipleLicenses = licenseEntries.length > 1;

                  return Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMultipleLicenses
                                    ? t.licenses.licenseNumber(
                                        number: index + 1,
                                      )
                                    : t.licenses.license,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              ...license.paragraphs.map((paragraph) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: SelectableText(
                                    paragraph.text,
                                    style: TextStyle(
                                      fontFamily: paragraph.indent > 0
                                          ? 'monospace'
                                          : null,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      if (index < licenseEntries.length - 1)
                        const SizedBox(height: 16),
                    ],
                  );
                }),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
