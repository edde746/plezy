import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/companion_remote/remote_command.dart';
import '../../models/companion_remote/remote_session.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/controller_disposer_mixin.dart';
import '../../providers/companion_remote_provider.dart';
import '../../utils/platform_detector.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/app_logger.dart';
import '../../utils/dialogs.dart';
import '../../widgets/companion_remote/discovery_view.dart';
import '../../widgets/overlay_sheet.dart';
import '../../widgets/pill_input_decoration.dart';

class MobileRemoteScreen extends StatefulWidget {
  const MobileRemoteScreen({super.key});

  @override
  State<MobileRemoteScreen> createState() => _MobileRemoteScreenState();
}

class _MobileRemoteScreenState extends State<MobileRemoteScreen> {
  @override
  Widget build(BuildContext context) {
    return OverlaySheetHost(
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.companionRemote.title),
          actions: [
            Consumer<CompanionRemoteProvider>(
              builder: (context, provider, child) {
                if (provider.isConnected) {
                  return IconButton(
                    icon: const Icon(Icons.link_off),
                    onPressed: () async {
                      final confirmed = await showConfirmDialog(
                        context,
                        title: t.common.disconnect,
                        message: t.companionRemote.remote.disconnectConfirm,
                        confirmText: t.common.disconnect,
                        isDestructive: true,
                      );

                      if (confirmed && context.mounted) {
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
                        FilledButton(
                          onPressed: () => provider.retryReconnectNow(),
                          child: Text(t.companionRemote.remote.retryNow),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            if (!provider.isConnected) {
              return const DiscoveryView();
            }

            return const _RemoteControlLayout();
          },
        ),
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
    OverlaySheetController.of(context).show(builder: (_) => _SearchBottomSheet(provider: provider));
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
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  ),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: 0,
                    label: Text(t.companionRemote.remote.tabRemote),
                    icon: const Icon(Icons.navigation),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text(t.companionRemote.remote.tabPlay),
                    icon: const Icon(Icons.play_arrow),
                  ),
                  ButtonSegment(
                    value: 2,
                    label: Text(t.companionRemote.remote.tabMore),
                    icon: const Icon(Icons.flash_on),
                  ),
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
            _RemoteButton(
              icon: Icons.home,
              label: t.common.home,
              onPressed: () => _sendCommand(RemoteCommandType.home),
            ),
            _RemoteButton(
              icon: Icons.arrow_back,
              label: t.common.back,
              onPressed: () => _sendCommand(RemoteCommandType.back),
            ),
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
            _RemoteButton(
              icon: Icons.stop,
              label: t.companionRemote.remote.stop,
              onPressed: () => _sendCommand(RemoteCommandType.stop),
            ),
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
            if (!isPlayerActive) _RemoteCard(icon: Icons.search, label: t.common.search, onPressed: _showSearchSheet),
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

  static const _diameter = 220.0;
  static const _centerSize = 80.0;
  static const _gapWidth = 3.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: _diameter,
      height: _diameter,
      child: ClipOval(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surface),
            ),
            _DPadZone(
              startAngle: -135,
              icon: Icons.keyboard_arrow_up,
              onTap: () => onCommand(RemoteCommandType.dpadUp),
            ),
            _DPadZone(
              startAngle: -45,
              icon: Icons.keyboard_arrow_right,
              onTap: () => onCommand(RemoteCommandType.dpadRight),
            ),
            _DPadZone(
              startAngle: 45,
              icon: Icons.keyboard_arrow_down,
              onTap: () => onCommand(RemoteCommandType.dpadDown),
            ),
            _DPadZone(
              startAngle: 135,
              icon: Icons.keyboard_arrow_left,
              onTap: () => onCommand(RemoteCommandType.dpadLeft),
            ),
            Center(child: _DPadCenter(onTap: () => onCommand(RemoteCommandType.select))),
          ],
        ),
      ),
    );
  }
}

class _DPadZone extends StatefulWidget {
  final double startAngle;
  final IconData icon;
  final VoidCallback onTap;

  const _DPadZone({required this.startAngle, required this.icon, required this.onTap});

  Alignment get iconAlignment {
    final midRad = (startAngle + 45) * pi / 180;
    const r = 0.78;
    return Alignment(r * cos(midRad), r * sin(midRad));
  }

  @override
  State<_DPadZone> createState() => _DPadZoneState();
}

class _DPadZoneState extends State<_DPadZone> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: ClipPath(
        clipper: _SectorClipper(
          startAngle: widget.startAngle,
          innerRadius: _DPad._centerSize / 2 + _DPad._gapWidth,
          gapWidth: _DPad._gapWidth,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap();
          },
          child: AnimatedContainer(
            duration: tokens(context).fast,
            color: _pressed ? colors.primary.withValues(alpha: 0.8) : colors.primary,
            alignment: widget.iconAlignment,
            child: Icon(widget.icon, size: 28, color: colors.onPrimary),
          ),
        ),
      ),
    );
  }
}

class _DPadCenter extends StatefulWidget {
  final VoidCallback onTap;

  const _DPadCenter({required this.onTap});

  @override
  State<_DPadCenter> createState() => _DPadCenterState();
}

class _DPadCenterState extends State<_DPadCenter> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: tokens(context).fast,
        width: _DPad._centerSize,
        height: _DPad._centerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _pressed ? colors.primary.withValues(alpha: 0.8) : colors.primary,
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}

class _SectorClipper extends CustomClipper<Path> {
  final double startAngle;
  final double innerRadius;
  final double gapWidth;

  const _SectorClipper({required this.startAngle, required this.innerRadius, required this.gapWidth});

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final halfGap = gapWidth / 2;
    final startRad = startAngle * pi / 180;
    final endRad = startRad + pi / 2;

    // Use arcsin to compute angular offset at each radius for constant-width gap
    final innerOffset = asin(halfGap / innerRadius);
    final outerOffset = asin(halfGap / outerRadius);

    final innerStart = startRad + innerOffset;
    final outerStart = startRad + outerOffset;
    final outerEnd = endRad - outerOffset;
    final innerEnd = endRad - innerOffset;

    return Path()
      ..moveTo(center.dx + innerRadius * cos(innerStart), center.dy + innerRadius * sin(innerStart))
      ..lineTo(center.dx + outerRadius * cos(outerStart), center.dy + outerRadius * sin(outerStart))
      ..arcTo(Rect.fromCircle(center: center, radius: outerRadius), outerStart, outerEnd - outerStart, false)
      ..lineTo(center.dx + innerRadius * cos(innerEnd), center.dy + innerRadius * sin(innerEnd))
      ..arcTo(Rect.fromCircle(center: center, radius: innerRadius), innerEnd, innerStart - innerEnd, false)
      ..close();
  }

  @override
  bool shouldReclip(covariant _SectorClipper oldClipper) =>
      startAngle != oldClipper.startAngle || innerRadius != oldClipper.innerRadius || gapWidth != oldClipper.gapWidth;
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
    return FilledButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _SearchBottomSheet extends StatefulWidget {
  final CompanionRemoteProvider provider;

  const _SearchBottomSheet({required this.provider});

  @override
  State<_SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<_SearchBottomSheet> with ControllerDisposerMixin {
  late final _controller = createTextEditingController();

  void _submit(String text) {
    final trimmed = text.trim();
    if (trimmed.isNotEmpty) {
      widget.provider.sendCommand(RemoteCommandType.search, data: {'query': trimmed});
    }
    OverlaySheetController.of(context).close();
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
            decoration: pillInputDecoration(
              context,
              hintText: t.companionRemote.remote.searchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: () => _submit(_controller.text)),
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
          borderRadius: const BorderRadius.all(Radius.circular(12)),
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
