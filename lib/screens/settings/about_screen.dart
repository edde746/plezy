import 'package:plezy/widgets/app_brand.dart';
import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/settings_section.dart';
import '../../i18n/strings.g.dart';
import '../../theme/mono_tokens.dart';
import 'licenses_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static final Future<PackageInfo> _packageInfoFuture = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _packageInfoFuture,
      builder: (context, snapshot) {
        final appVersion = snapshot.data?.version ?? '';
        return FocusedScrollScaffold(
          title: Text(t.about.title),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        const AppBrandMark(decorative: true),
                        const SizedBox(height: 16),
                        const AppBrandWordmark(),
                        const SizedBox(height: 8),
                        Text(
                          t.about.versionLabel(version: appVersion),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: tokens(context).textMuted),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          t.about.appDescription,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  SettingsGroup(
                    margin: EdgeInsets.zero,
                    children: [
                      FocusableListTile(
                        leading: const AppIcon(Symbols.description_rounded, fill: 1),
                        title: Text(t.about.openSourceLicenses),
                        subtitle: Text(t.about.viewLicensesDescription),
                        trailing: AppIcon(
                          Directionality.of(context) == TextDirection.rtl
                              ? Symbols.chevron_left_rounded
                              : Symbols.chevron_right_rounded,
                          fill: 1,
                        ),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const LicensesScreen()));
                        },
                      ),
                      FocusableListTile(
                        leading: const AppIcon(Symbols.lock_rounded, fill: 1),
                        title: Text(t.about.privacyPolicy),
                        trailing: const AppIcon(Symbols.open_in_new_rounded, fill: 1),
                        onTap: () => launchUrl(
                          Uri.parse('https://github.com/snapetech-org/PlezyNG/blob/main/PRIVACY.md'),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}
