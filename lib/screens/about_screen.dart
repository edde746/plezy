import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/app_bar_back_button.dart';

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
          DesktopSliverAppBar(
            title: const Text('About'),
            pinned: true,
            leading: const AppBarBackButton(style: BackButtonStyle.circular),
          ),
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
                      showLicensePage(
                        context: context,
                        applicationName: appName,
                        applicationVersion: appVersion,
                        applicationIcon: Image.asset(
                          'assets/plezy.png',
                          width: 48,
                          height: 48,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Key Dependencies
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Key Dependencies',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildDependencyItem('http', 'HTTP networking'),
                        _buildDependencyItem('dio', 'Advanced HTTP client'),
                        _buildDependencyItem(
                          'cached_network_image',
                          'Image caching',
                        ),
                        _buildDependencyItem('media_kit', 'Video playback'),
                        _buildDependencyItem(
                          'shared_preferences',
                          'Local storage',
                        ),
                        _buildDependencyItem('xml', 'XML parsing'),
                        _buildDependencyItem('url_launcher', 'External links'),
                        _buildDependencyItem(
                          'window_manager',
                          'Desktop window management',
                        ),
                        _buildDependencyItem(
                          'macos_window_utils',
                          'macOS window controls',
                        ),
                        _buildDependencyItem('logger', 'Logging'),
                      ],
                    ),
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

  Widget _buildDependencyItem(String name, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: ' - $description',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
