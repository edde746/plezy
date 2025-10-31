import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import '../providers/theme_provider.dart';
import '../services/settings_service.dart' as settings;
import '../services/keyboard_shortcuts_service.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/hotkey_recorder_widget.dart';
import 'about_screen.dart';

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
  int _videoBufferSize = 64;
  int _audioBufferSize = 8;

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
      _videoBufferSize = _settingsService.getVideoBufferSize();
      _audioBufferSize = _settingsService.getAudioBufferSize();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
                _buildKeyboardShortcutsSection(),
                const SizedBox(height: 24),
                _buildAdvancedSection(),
                const SizedBox(height: 24),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
            title: const Text('Video Buffer Size'),
            subtitle: Text('${_videoBufferSize}MB'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBufferSizeDialog(true),
          ),
          ListTile(
            leading: const Icon(Icons.audiotrack),
            title: const Text('Audio Buffer Size'),
            subtitle: Text('${_audioBufferSize}MB'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBufferSizeDialog(false),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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


  void _showBufferSizeDialog(bool isVideo) {
    final currentSize = isVideo ? _videoBufferSize : _audioBufferSize;
    final title = isVideo ? 'Video Buffer Size' : 'Audio Buffer Size';
    final options = isVideo ? [16, 32, 64, 128, 256] : [2, 4, 8, 16, 32];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((size) {
              return ListTile(
                leading: Icon(
                  currentSize == size
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text('${size}MB'),
                onTap: () {
                  setState(() {
                    if (isVideo) {
                      _videoBufferSize = size;
                      _settingsService.setVideoBufferSize(size);
                    } else {
                      _audioBufferSize = size;
                      _settingsService.setAudioBufferSize(size);
                    }
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

  void _showKeyboardShortcutsDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _KeyboardShortcutsScreen(
          keyboardService: _keyboardService,
        ),
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
                    const SnackBar(content: Text('Settings reset successfully')),
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

}

class _KeyboardShortcutsScreen extends StatefulWidget {
  final KeyboardShortcutsService keyboardService;

  const _KeyboardShortcutsScreen({required this.keyboardService});

  @override
  State<_KeyboardShortcutsScreen> createState() => _KeyboardShortcutsScreenState();
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
                      const SnackBar(content: Text('Shortcuts reset to defaults')),
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
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final actions = _hotkeys.keys.toList();
                  final action = actions[index];
                  final hotkey = _hotkeys[action]!;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(widget.keyboardService.getActionDisplayName(action)),
                      subtitle: Text(action),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor),
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
                },
                childCount: _hotkeys.length,
              ),
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
            final existingAction = widget.keyboardService.getActionForHotkey(newHotkey);
            if (existingAction != null && existingAction != action) {
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Shortcut already assigned to ${widget.keyboardService.getActionDisplayName(existingAction)}'),
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
                  content: Text('Shortcut updated for ${widget.keyboardService.getActionDisplayName(action)}'),
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