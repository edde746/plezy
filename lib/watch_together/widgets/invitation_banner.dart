import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../i18n/strings.g.dart';
import '../models/watch_invitation.dart';

/// Banner widget to display an incoming Watch Together invitation
class InvitationBanner extends StatelessWidget {
  final WatchInvitation invitation;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback? onDismiss;

  const InvitationBanner({
    super.key,
    required this.invitation,
    required this.onAccept,
    required this.onDecline,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 8,
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Symbols.group,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.watchTogether.invitationReceived,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        t.watchTogether.invitesYouToWatch(name: invitation.hostDisplayName),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(Symbols.close),
                    iconSize: 20,
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Media title
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Symbols.play_circle,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      invitation.mediaTitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      side: BorderSide(color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.5)),
                    ),
                    child: Text(t.watchTogether.decline),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Symbols.group_add),
                    label: Text(t.watchTogether.joinNow),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated wrapper for the invitation banner with slide-in animation
class AnimatedInvitationBanner extends StatefulWidget {
  final WatchInvitation invitation;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final Duration displayDuration;

  const AnimatedInvitationBanner({
    super.key,
    required this.invitation,
    required this.onAccept,
    required this.onDecline,
    this.displayDuration = const Duration(seconds: 30),
  });

  @override
  State<AnimatedInvitationBanner> createState() => _AnimatedInvitationBannerState();
}

class _AnimatedInvitationBannerState extends State<AnimatedInvitationBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_dismissed) return;
    _dismissed = true;

    await _controller.reverse();
  }

  void _onAccept() async {
    await _dismiss();
    widget.onAccept();
  }

  void _onDecline() async {
    await _dismiss();
    widget.onDecline();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: InvitationBanner(
            invitation: widget.invitation,
            onAccept: _onAccept,
            onDecline: _onDecline,
            onDismiss: _onDecline,
          ),
        ),
      ),
    );
  }
}
