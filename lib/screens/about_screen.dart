import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../widgets/desktop_app_bar.dart';
import 'licenses_screen.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appName = '';
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appName = 'Plezy';
      _appVersion = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appName = _appName;
    final appVersion = _appVersion;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomAppBar(title: const Text('About'), pinned: true),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // App Icon and Name
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Image.asset('assets/plezy.png', width: 80, height: 80),
                      const SizedBox(height: 16),
                      Text(
                        appName,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Version $appVersion',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'A beautiful Plex client for Flutter',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Open Source Licenses
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('Open Source Licenses'),
                    subtitle: const Text(
                      'View licenses of third-party libraries',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LicensesScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
