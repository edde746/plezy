import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/companion_remote/remote_command_type.dart';
import '../../models/companion_remote/remote_session.dart';
import '../../i18n/strings.g.dart';
import '../../providers/companion_remote_provider.dart';
import '../../utils/platform_detector.dart';
import '../../utils/app_logger.dart';
import 'pairing_screen.dart';

class MobileRemoteScreen extends StatefulWidget {
  const MobileRemoteScreen({super.key});

  @override
  State<MobileRemoteScreen> createState() => _MobileRemoteScreenState();
}

class _MobileRemoteScreenState extends State<MobileRemoteScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.companionRemote.title),
        actions: [
          Consumer<CompanionRemoteProvider>(
            builder: (context, provider, child) {
              if (provider.isConnected) {
                return IconButton(
                  icon: const Icon(Icons.link_off),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(t.common.disconnect),
                        content: Text(t.companionRemote.remote.disconnectConfirm),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.common.cancel)),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t.common.disconnect)),
                        ],
                      ),
                    );

                    if (confirmed == true && context.mounted) {
                      await context.read<CompanionRemoteProvider>().leaveSession();
                    }
                  },
                  tooltip: t.common.disconnect,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<CompanionRemoteProvider>(
        builder: (context, provider, child) {
          if (provider.status == RemoteSessionStatus.reconnecting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(t.companionRemote.remote.reconnecting, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    t.companionRemote.remote.attemptOf(current: provider.reconnectAttempts),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(onPressed: () => provider.cancelReconnect(), child: Text(t.common.cancel)),
                      const SizedBox(width: 16),
                      FilledButton(onPressed: () => provider.retryReconnectNow(), child: Text(t.companionRemote.remote.retryNow)),
                    ],
                  ),
                ],
              ),
            );
          }

          if (!provider.isConnected) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phonelink_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    provider.status == RemoteSessionStatus.error
                        ? provider.session?.errorMessage ?? t.companionRemote.remote.connectionError
                        : t.companionRemote.remote.notConnected,
                    style: const TextStyle(fontSize: 20, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PairingScreen()));
                    },
                    icon: const Icon(Icons.link),
                    label: Text(t.companionRemote.connectToDevice),
                  ),
                ],
              ),
            );
          }

          return const _RemoteControlLayout();
        },
      ),
    );
  }
}

class _RemoteControlLayout extends StatelessWidget {
  const _RemoteControlLayout();

  @override
  Widget build(BuildContext context) {
    if (PlatformDetector.isDesktop(context)) {
      return Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: const _RemoteControlContent()),
      );
    }

    return const _RemoteControlContent();
  }
}

class _RemoteControlContent extends StatefulWidget {
  const _RemoteControlContent();

  @override
  State<_RemoteControlContent> createState() => _RemoteControlContentState();
}

class _RemoteControlContentState extends State<_RemoteControlContent> {
  int _selectedTab = 0;

  void _showSearchSheet({bool switchToSearchTab = false}) {
    if (switchToSearchTab) {
      _sendCommand(RemoteCommandType.tabSearch);
    }
    final provider = context.read<CompanionRemoteProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SearchBottomSheet(provider: provider),
    );
  }

  void _sendCommand(RemoteCommandType type) {
    HapticFeedback.lightImpact();
    appLogger.d('MobileRemoteScreen: Sending command: $type');
    final provider = context.read<CompanionRemoteProvider>();
    provider.sendCommand(type);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Consumer<CompanionRemoteProvider>(
          builder: (context, provider, child) {
            final device = provider.connectedDevice;
            if (device == null) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                children: [
                  Icon(Icons.computer, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer),
                        ),
                        Text(
                          device.platform,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  ),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 0, label: Text(t.companionRemote.remote.tabRemote), icon: const Icon(Icons.navigation)),
                    ButtonSegment(value: 1, label: Text(t.companionRemote.remote.tabPlay), icon: const Icon(Icons.play_arrow)),
                    ButtonSegment(value: 2, label: Text(t.companionRemote.remote.tabMore), icon: const Icon(Icons.flash_on)),
                  ],
                  selected: {_selectedTab},
                  onSelectionChanged: (Set<int> selection) {
                    setState(() {
                      _selectedTab = selection.first;
                    });
                  },
                ),
                const SizedBox(height: 24),
                if (_selectedTab == 0) _buildNavigationTab(),
                if (_selectedTab == 1) _buildPlaybackTab(),
                if (_selectedTab == 2) _buildQuickActionsTab(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationTab() {
    final isPlayerActive = context.watch<CompanionRemoteProvider>().isPlayerActive;

    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _RemoteButton(icon: Icons.home, label: t.common.home, onPressed: () => _sendCommand(RemoteCommandType.home)),
            _RemoteButton(icon: Icons.arrow_back, label: t.common.back, onPressed: () => _sendCommand(RemoteCommandType.back)),
            _RemoteButton(
              icon: Icons.menu,
              label: t.companionRemote.remote.menu,
              onPressed: () => _sendCommand(RemoteCommandType.contextMenu),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Center(child: _DPad(onCommand: _sendCommand)),
        if (!isPlayerActive) ...[
          const SizedBox(height: 32),
          Text(t.companionRemote.remote.tabNavigation, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _RemoteChip(
                icon: Icons.explore,
                label: t.companionRemote.remote.tabDiscover,
                onPressed: () => _sendCommand(RemoteCommandType.tabDiscover),
              ),
              _RemoteChip(
                icon: Icons.video_library,
                label: t.companionRemote.remote.tabLibraries,
                onPressed: () => _sendCommand(RemoteCommandType.tabLibraries),
              ),
              _RemoteChip(
                icon: Icons.search,
                label: t.companionRemote.remote.tabSearch,
                onPressed: () => _showSearchSheet(switchToSearchTab: true),
              ),
              _RemoteChip(
                icon: Icons.download,
                label: t.companionRemote.remote.tabDownloads,
                onPressed: () => _sendCommand(RemoteCommandType.tabDownloads),
              ),
              _RemoteChip(
                icon: Icons.settings,
                label: t.companionRemote.remote.tabSettings,
                onPressed: () => _sendCommand(RemoteCommandType.tabSettings),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPlaybackTab() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RemoteButton(
              icon: Icons.skip_previous,
              label: t.companionRemote.remote.previous,
              onPressed: () => _sendCommand(RemoteCommandType.previousTrack),
            ),
            const SizedBox(width: 16),
            _RemoteButton(
              icon: Icons.play_arrow,
              label: t.companionRemote.remote.playPause,
              size: 64,
              iconSize: 36,
              onPressed: () => _sendCommand(RemoteCommandType.playPause),
            ),
            const SizedBox(width: 16),
            _RemoteButton(
              icon: Icons.skip_next,
              label: t.companionRemote.remote.next,
              onPressed: () => _sendCommand(RemoteCommandType.nextTrack),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RemoteButton(
              icon: Icons.replay_10,
              label: t.companionRemote.remote.seekBack,
              onPressed: () => _sendCommand(RemoteCommandType.seekBackward),
            ),
            const SizedBox(width: 16),
            _RemoteButton(icon: Icons.stop, label: t.companionRemote.remote.stop, onPressed: () => _sendCommand(RemoteCommandType.stop)),
            const SizedBox(width: 16),
            _RemoteButton(
              icon: Icons.forward_10,
              label: t.companionRemote.remote.seekForward,
              onPressed: () => _sendCommand(RemoteCommandType.seekForward),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(t.companionRemote.remote.volume, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RemoteButton(
              icon: Icons.volume_off,
              label: t.common.mute,
              onPressed: () => _sendCommand(RemoteCommandType.volumeMute),
            ),
            const SizedBox(width: 16),
            _RemoteButton(
              icon: Icons.volume_down,
              label: t.companionRemote.remote.volumeDown,
              onPressed: () => _sendCommand(RemoteCommandType.volumeDown),
            ),
            const SizedBox(width: 16),
            _RemoteButton(
              icon: Icons.volume_up,
              label: t.companionRemote.remote.volumeUp,
              onPressed: () => _sendCommand(RemoteCommandType.volumeUp),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsTab() {
    final isPlayerActive = context.watch<CompanionRemoteProvider>().isPlayerActive;

    return Column(
      children: [
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            if (!isPlayerActive)
              _RemoteCard(icon: Icons.search, label: t.common.search, onPressed: _showSearchSheet),
            if (isPlayerActive) ...[
              _RemoteCard(
                icon: Icons.fullscreen,
                label: t.companionRemote.remote.fullscreen,
                onPressed: () => _sendCommand(RemoteCommandType.fullscreen),
              ),
              _RemoteCard(
                icon: Icons.subtitles,
                label: t.companionRemote.remote.subtitles,
                onPressed: () => _sendCommand(RemoteCommandType.subtitles),
              ),
              _RemoteCard(
                icon: Icons.audiotrack,
                label: t.companionRemote.remote.audio,
                onPressed: () => _sendCommand(RemoteCommandType.audioTracks),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DPad extends StatelessWidget {
  final Function(RemoteCommandType) onCommand;

  const _DPad({required this.onCommand});

  @override
  Widget build(BuildContext context) {
    const size = 72.0;
    const gap = 8.0;
    const total = size * 3 + gap * 2;

    return SizedBox(
      width: total,
      height: total,
      child: Stack(
        children: [
          Positioned(
            left: size + gap,
            top: 0,
            child: _DPadButton(
              icon: Icons.arrow_drop_up,
              onPressed: () => onCommand(RemoteCommandType.dpadUp),
              size: size,
            ),
          ),
          Positioned(
            left: size + gap,
            bottom: 0,
            child: _DPadButton(
              icon: Icons.arrow_drop_down,
              onPressed: () => onCommand(RemoteCommandType.dpadDown),
              size: size,
            ),
          ),
          Positioned(
            left: 0,
            top: size + gap,
            child: _DPadButton(
              icon: Icons.arrow_left,
              onPressed: () => onCommand(RemoteCommandType.dpadLeft),
              size: size,
            ),
          ),
          Positioned(
            right: 0,
            top: size + gap,
            child: _DPadButton(
              icon: Icons.arrow_right,
              onPressed: () => onCommand(RemoteCommandType.dpadRight),
              size: size,
            ),
          ),
          Positioned(
            left: size + gap,
            top: size + gap,
            child: _DPadButton(
              icon: Icons.check,
              label: t.common.ok,
              onPressed: () => onCommand(RemoteCommandType.select),
              size: size,
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _DPadButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;
  final double size;
  final bool isPrimary;

  const _DPadButton({
    required this.icon,
    this.label,
    required this.onPressed,
    required this.size,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          backgroundColor: isPrimary ? Theme.of(context).colorScheme.primary : null,
          foregroundColor: isPrimary ? Theme.of(context).colorScheme.onPrimary : null,
        ),
        child: label != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24),
                  const SizedBox(height: 2),
                  Text(label!, style: const TextStyle(fontSize: 10)),
                ],
              )
            : Icon(icon, size: 36),
      ),
    );
  }
}

class _RemoteButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  const _RemoteButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.size = 56,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: FilledButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onPressed();
            },
            style: FilledButton.styleFrom(padding: EdgeInsets.zero, shape: const CircleBorder()),
            child: Icon(icon, size: iconSize),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }
}

class _RemoteChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _RemoteChip({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
    );
  }
}

class _SearchBottomSheet extends StatefulWidget {
  final CompanionRemoteProvider provider;

  const _SearchBottomSheet({required this.provider});

  @override
  State<_SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<_SearchBottomSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String text) {
    final trimmed = text.trim();
    if (trimmed.isNotEmpty) {
      widget.provider.sendCommand(RemoteCommandType.search, data: {'query': trimmed});
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom, left: 16, right: 16, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: t.companionRemote.remote.searchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: () => _submit(_controller.text)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(100)),
            ),
            onSubmitted: _submit,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _RemoteCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _RemoteCard({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Card(
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
