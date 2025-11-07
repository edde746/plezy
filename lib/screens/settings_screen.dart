import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../services/settings_service.dart' as settings;
import '../services/keyboard_shortcuts_service.dart';
import '../services/update_service.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/hotkey_recorder_widget.dart';
import 'about_screen.dart';
import 'logs_screen.dart';
import 'subtitle_styling_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late settings.SettingsService _settingsService;
  late KeyboardShortcutsService _keyboardService;
  bool _isLoading = true;

  bool _enableDebugLogging = false;
  bool _enableHardwareDecoding = true;
  int _bufferSize = 128;
  int _seekTimeSmall = 10;
  int _seekTimeLarge = 30;
  int _sleepTimerDuration = 30;

  // Update checking state
  bool _isCheckingForUpdate = false;
  Map<String, dynamic>? _updateInfo;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsService = await settings.SettingsService.getInstance();
    _keyboardService = await KeyboardShortcutsService.getInstance();

    setState(() {
      _enableDebugLogging = _settingsService.getEnableDebugLogging();
      _enableHardwareDecoding = _settingsService.getEnableHardwareDecoding();
      _bufferSize = _settingsService.getBufferSize();
      _seekTimeSmall = _settingsService.getSeekTimeSmall();
      _seekTimeLarge = _settingsService.getSeekTimeLarge();
      _sleepTimerDuration = _settingsService.getSleepTimerDuration();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const CustomAppBar(title: Text('Settings'), pinned: true),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAppearanceSection(),
                const SizedBox(height: 24),
                _buildVideoPlaybackSection(),
                const SizedBox(height: 24),
                _buildShufflePlaySection(),
                const SizedBox(height: 24),
                _buildKeyboardShortcutsSection(),
                const SizedBox(height: 24),
                _buildAdvancedSection(),
                const SizedBox(height: 24),
                if (UpdateService.isUpdateCheckEnabled) ...[
                  _buildUpdateSection(),
                  const SizedBox(height: 24),
                ],
                _buildAboutSection(),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Appearance',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ListTile(
                leading: Icon(themeProvider.themeModeIcon),
                title: const Text('Theme'),
                subtitle: Text(themeProvider.themeModeDisplayName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(themeProvider),
              );
            },
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return ListTile(
                leading: const Icon(Icons.grid_view),
                title: const Text('Library Density'),
                subtitle: Text(settingsProvider.libraryDensityDisplayName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLibraryDensityDialog(),
              );
            },
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return ListTile(
                leading: const Icon(Icons.view_list),
                title: const Text('View Mode'),
                subtitle: Text(settingsProvider.viewMode == settings.ViewMode.grid ? 'Grid' : 'List'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showViewModeDialog(),
              );
            },
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return SwitchListTile(
                secondary: const Icon(Icons.image),
                title: const Text('Use Season Posters'),
                subtitle: const Text(
                  'Show season poster instead of series poster for episodes',
                ),
                value: settingsProvider.useSeasonPoster,
                onChanged: (value) async {
                  await settingsProvider.setUseSeasonPoster(value);
                },
              );
            },
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return SwitchListTile(
                secondary: const Icon(Icons.featured_play_list),
                title: const Text('Show Hero Section'),
                subtitle: const Text(
                  'Display featured content carousel on home screen',
                ),
                value: settingsProvider.showHeroSection,
                onChanged: (value) async {
                  await settingsProvider.setShowHeroSection(value);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaybackSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Video Playback',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.hardware),
            title: const Text('Hardware Decoding'),
            subtitle: const Text('Use hardware acceleration when available'),
            value: _enableHardwareDecoding,
            onChanged: (value) async {
              setState(() {
                _enableHardwareDecoding = value;
              });
              await _settingsService.setEnableHardwareDecoding(value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.memory),
            title: const Text('Buffer Size'),
            subtitle: Text('${_bufferSize}MB'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBufferSizeDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.subtitles),
            title: const Text('Subtitle Styling'),
            subtitle: const Text('Customize subtitle appearance'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubtitleStylingScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.replay_10),
            title: const Text('Small Skip Duration'),
            subtitle: Text('$_seekTimeSmall seconds'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSeekTimeSmallDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.replay_30),
            title: const Text('Large Skip Duration'),
            subtitle: Text('$_seekTimeLarge seconds'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSeekTimeLargeDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.bedtime),
            title: const Text('Default Sleep Timer'),
            subtitle: Text('$_sleepTimerDuration minutes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSleepTimerDurationDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildShufflePlaySection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Shuffle Play',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return SwitchListTile(
                secondary: const Icon(Icons.visibility_off),
                title: const Text('Unwatched Only'),
                subtitle: const Text(
                  'Only include unwatched episodes in shuffle queue',
                ),
                value: settingsProvider.shuffleUnwatchedOnly,
                onChanged: (value) async {
                  await settingsProvider.setShuffleUnwatchedOnly(value);
                },
              );
            },
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return SwitchListTile(
                secondary: const Icon(Icons.shuffle),
                title: const Text('Shuffle Order Navigation'),
                subtitle: const Text(
                  'Next/previous buttons follow shuffled order',
                ),
                value: settingsProvider.shuffleOrderNavigation,
                onChanged: (value) async {
                  await settingsProvider.setShuffleOrderNavigation(value);
                },
              );
            },
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return SwitchListTile(
                secondary: const Icon(Icons.loop),
                title: const Text('Loop Shuffle Queue'),
                subtitle: const Text(
                  'Restart queue when reaching the end',
                ),
                value: settingsProvider.shuffleLoopQueue,
                onChanged: (value) async {
                  await settingsProvider.setShuffleLoopQueue(value);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardShortcutsSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Keyboard Shortcuts',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.keyboard),
            title: const Text('Video Player Controls'),
            subtitle: const Text('Customize keyboard shortcuts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showKeyboardShortcutsDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Advanced',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.bug_report),
            title: const Text('Debug Logging'),
            subtitle: const Text('Enable detailed logging for troubleshooting'),
            value: _enableDebugLogging,
            onChanged: (value) async {
              setState(() {
                _enableDebugLogging = value;
              });
              await _settingsService.setEnableDebugLogging(value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.article),
            title: const Text('View Logs'),
            subtitle: const Text('View application logs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LogsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('Clear Cache'),
            subtitle: const Text('Free up storage space'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showClearCacheDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Reset Settings'),
            subtitle: const Text('Reset all settings to defaults'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showResetSettingsDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateSection() {
    final hasUpdate = _updateInfo != null && _updateInfo!['hasUpdate'] == true;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Updates',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: Icon(
              hasUpdate ? Icons.system_update : Icons.check_circle,
              color: hasUpdate ? Colors.orange : null,
            ),
            title: Text(hasUpdate ? 'Update Available' : 'Check for Updates'),
            subtitle: hasUpdate
                ? Text('Version ${_updateInfo!['latestVersion']} is available')
                : const Text('Check for the latest version on GitHub'),
            trailing: _isCheckingForUpdate
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _isCheckingForUpdate
                ? null
                : () {
                    if (hasUpdate) {
                      _showUpdateDialog();
                    } else {
                      _checkForUpdates();
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info),
        title: const Text('About'),
        subtitle: const Text('App information and licenses'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AboutScreen()),
          );
        },
      ),
    );
  }

  void _showThemeDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  themeProvider.themeMode == settings.ThemeMode.system
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: const Text('System'),
                subtitle: const Text('Follow system settings'),
                onTap: () {
                  themeProvider.setThemeMode(settings.ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  themeProvider.themeMode == settings.ThemeMode.light
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: const Text('Light'),
                onTap: () {
                  themeProvider.setThemeMode(settings.ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  themeProvider.themeMode == settings.ThemeMode.dark
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: const Text('Dark'),
                onTap: () {
                  themeProvider.setThemeMode(settings.ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showBufferSizeDialog() {
    final options = [64, 128, 256, 512, 1024];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Buffer Size'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((size) {
              return ListTile(
                leading: Icon(
                  _bufferSize == size
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text('${size}MB'),
                onTap: () {
                  setState(() {
                    _bufferSize = size;
                    _settingsService.setBufferSize(size);
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showSeekTimeSmallDialog() {
    final controller = TextEditingController(text: _seekTimeSmall.toString());
    String? errorText;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Small Skip Duration'),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Seconds',
                  hintText: 'Enter duration (1-120)',
                  errorText: errorText,
                  suffixText: 's',
                ),
                autofocus: true,
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  setDialogState(() {
                    if (parsed == null) {
                      errorText = 'Please enter a valid number';
                    } else if (parsed < 1 || parsed > 120) {
                      errorText = 'Duration must be between 1 and 120 seconds';
                    } else {
                      errorText = null;
                    }
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final parsed = int.tryParse(controller.text);
                    if (parsed != null && parsed >= 1 && parsed <= 120) {
                      setState(() {
                        _seekTimeSmall = parsed;
                        _settingsService.setSeekTimeSmall(parsed);
                      });
                      // Reload keyboard shortcuts service to use new settings
                      await _keyboardService.refreshFromStorage();
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSeekTimeLargeDialog() {
    final controller = TextEditingController(text: _seekTimeLarge.toString());
    String? errorText;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Large Skip Duration'),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Seconds',
                  hintText: 'Enter duration (1-120)',
                  errorText: errorText,
                  suffixText: 's',
                ),
                autofocus: true,
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  setDialogState(() {
                    if (parsed == null) {
                      errorText = 'Please enter a valid number';
                    } else if (parsed < 1 || parsed > 120) {
                      errorText = 'Duration must be between 1 and 120 seconds';
                    } else {
                      errorText = null;
                    }
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final parsed = int.tryParse(controller.text);
                    if (parsed != null && parsed >= 1 && parsed <= 120) {
                      setState(() {
                        _seekTimeLarge = parsed;
                        _settingsService.setSeekTimeLarge(parsed);
                      });
                      // Reload keyboard shortcuts service to use new settings
                      await _keyboardService.refreshFromStorage();
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSleepTimerDurationDialog() {
    final controller = TextEditingController(
      text: _sleepTimerDuration.toString(),
    );
    String? errorText;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Default Sleep Timer'),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Minutes',
                  hintText: 'Enter duration (5-180)',
                  errorText: errorText,
                  suffixText: 'min',
                ),
                autofocus: true,
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  setDialogState(() {
                    if (parsed == null) {
                      errorText = 'Please enter a valid number';
                    } else if (parsed < 5 || parsed > 180) {
                      errorText = 'Duration must be between 5 and 180 minutes';
                    } else {
                      errorText = null;
                    }
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final parsed = int.tryParse(controller.text);
                    if (parsed != null && parsed >= 5 && parsed <= 180) {
                      setState(() {
                        _sleepTimerDuration = parsed;
                        _settingsService.setSleepTimerDuration(parsed);
                      });
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showKeyboardShortcutsDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _KeyboardShortcutsScreen(keyboardService: _keyboardService),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Cache'),
          content: const Text(
            'This will clear all cached images and data. The app may take longer to load content after clearing the cache.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                await _settingsService.clearCache();
                if (mounted) {
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Cache cleared successfully')),
                  );
                }
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  void _showResetSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Settings'),
          content: const Text(
            'This will reset all settings to their default values. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                await _settingsService.resetAllSettings();
                await _keyboardService.resetToDefaults();
                if (mounted) {
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Settings reset successfully'),
                    ),
                  );
                  // Reload settings
                  _loadSettings();
                }
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingForUpdate = true;
    });

    try {
      final updateInfo = await UpdateService.checkForUpdates();

      if (mounted) {
        setState(() {
          _updateInfo = updateInfo;
          _isCheckingForUpdate = false;
        });

        if (updateInfo == null || updateInfo['hasUpdate'] != true) {
          // Show "no updates" message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are on the latest version'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingForUpdate = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to check for updates'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showUpdateDialog() {
    if (_updateInfo == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version ${_updateInfo!['latestVersion']} is available',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Current: ${_updateInfo!['currentVersion']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () async {
                final url = Uri.parse(_updateInfo!['releaseUrl']);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('View Release'),
            ),
          ],
        );
      },
    );
  }

  void _showLibraryDensityDialog() {
    final settingsProvider = context.read<SettingsProvider>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<SettingsProvider>(
          builder: (context, provider, child) {
            return AlertDialog(
              title: const Text('Library Density'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(
                      provider.libraryDensity == settings.LibraryDensity.compact
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: const Text('Compact'),
                    subtitle: const Text('Smaller cards, more items visible'),
                    onTap: () async {
                      await settingsProvider.setLibraryDensity(
                        settings.LibraryDensity.compact,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      provider.libraryDensity == settings.LibraryDensity.normal
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: const Text('Normal'),
                    subtitle: const Text('Default size'),
                    onTap: () async {
                      await settingsProvider.setLibraryDensity(
                        settings.LibraryDensity.normal,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      provider.libraryDensity ==
                              settings.LibraryDensity.comfortable
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: const Text('Comfortable'),
                    subtitle: const Text('Larger cards, fewer items visible'),
                    onTap: () async {
                      await settingsProvider.setLibraryDensity(
                        settings.LibraryDensity.comfortable,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showViewModeDialog() {
    final settingsProvider = context.read<SettingsProvider>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<SettingsProvider>(
          builder: (context, provider, child) {
            return AlertDialog(
              title: const Text('View Mode'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(
                      provider.viewMode == settings.ViewMode.grid
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: const Text('Grid'),
                    subtitle: const Text('Display items in a grid layout'),
                    onTap: () async {
                      await settingsProvider.setViewMode(
                        settings.ViewMode.grid,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      provider.viewMode == settings.ViewMode.list
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: const Text('List'),
                    subtitle: const Text('Display items in a list layout'),
                    onTap: () async {
                      await settingsProvider.setViewMode(
                        settings.ViewMode.list,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _KeyboardShortcutsScreen extends StatefulWidget {
  final KeyboardShortcutsService keyboardService;

  const _KeyboardShortcutsScreen({required this.keyboardService});

  @override
  State<_KeyboardShortcutsScreen> createState() =>
      _KeyboardShortcutsScreenState();
}

class _KeyboardShortcutsScreenState extends State<_KeyboardShortcutsScreen> {
  Map<String, HotKey> _hotkeys = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHotkeys();
  }

  Future<void> _loadHotkeys() async {
    await widget.keyboardService.refreshFromStorage();
    setState(() {
      _hotkeys = widget.keyboardService.hotkeys;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomAppBar(
            title: const Text('Keyboard Shortcuts'),
            pinned: true,
            actions: [
              TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await widget.keyboardService.resetToDefaults();
                  await _loadHotkeys();
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Shortcuts reset to defaults'),
                      ),
                    );
                  }
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final actions = _hotkeys.keys.toList();
                final action = actions[index];
                final hotkey = _hotkeys[action]!;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      widget.keyboardService.getActionDisplayName(action),
                    ),
                    subtitle: Text(action),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.keyboardService.formatHotkey(hotkey),
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    onTap: () => _editHotkey(action, hotkey),
                  ),
                );
              }, childCount: _hotkeys.length),
            ),
          ),
        ],
      ),
    );
  }

  void _editHotkey(String action, HotKey currentHotkey) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return HotKeyRecorderWidget(
          actionName: widget.keyboardService.getActionDisplayName(action),
          currentHotKey: currentHotkey,
          onHotKeyRecorded: (newHotkey) async {
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);

            // Check for conflicts
            final existingAction = widget.keyboardService.getActionForHotkey(
              newHotkey,
            );
            if (existingAction != null && existingAction != action) {
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Shortcut already assigned to ${widget.keyboardService.getActionDisplayName(existingAction)}',
                  ),
                ),
              );
              return;
            }

            // Save the new hotkey
            await widget.keyboardService.setHotkey(action, newHotkey);

            if (mounted) {
              // Update UI directly instead of reloading from storage
              setState(() {
                _hotkeys[action] = newHotkey;
              });

              navigator.pop();

              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Shortcut updated for ${widget.keyboardService.getActionDisplayName(action)}',
                  ),
                ),
              );
            }
          },
          onCancel: () => Navigator.pop(context),
        );
      },
    );
  }
}
