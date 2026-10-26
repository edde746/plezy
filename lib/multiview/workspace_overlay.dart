import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../i18n/strings.g.dart';
import '../theme/mono_motion.dart';
import '../theme/mono_tokens.dart';
import 'workspace_controller.dart';
import 'workspace_models.dart';

/// Mounts a persistent entry in the profile Overlay.
///
/// The owner remains the original media route or service. This host only moves
/// that owner's widget into a window and keeps profile-scoped state alive while
/// the Navigator changes routes.
class MultiviewOverlayHost extends StatefulWidget {
  const MultiviewOverlayHost({super.key, required this.controller, required this.overlayKey});

  final MultiviewWorkspaceController controller;
  final GlobalKey<OverlayState> overlayKey;

  @override
  State<MultiviewOverlayHost> createState() => _MultiviewOverlayHostState();
}

class _MultiviewOverlayHostState extends State<MultiviewOverlayHost> {
  OverlayEntry? _entry;
  bool _installScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncEntry);
    _syncEntry();
  }

  @override
  void didUpdateWidget(covariant MultiviewOverlayHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncEntry);
      _removeEntry();
      widget.controller.addListener(_syncEntry);
      _syncEntry();
    }
    if (oldWidget.overlayKey != widget.overlayKey) {
      _removeEntry();
      _syncEntry();
    }
  }

  void _syncEntry() {
    if (!mounted) return;
    if (!widget.controller.hasVisibleSessions) {
      _removeEntry();
      return;
    }
    final entry = _entry;
    if (entry != null) {
      entry.markNeedsBuild();
      return;
    }
    if (_installScheduled) return;
    _installScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _installScheduled = false;
      if (!mounted || !widget.controller.hasVisibleSessions || _entry != null) return;
      final overlay = widget.overlayKey.currentState;
      if (overlay == null) return;
      final entry = OverlayEntry(builder: (context) => _MultiviewOverlay(controller: widget.controller));
      _entry = entry;
      overlay.insert(entry);
    });
  }

  void _removeEntry() {
    final entry = _entry;
    _entry = null;
    if (entry == null) return;
    entry.remove();
    entry.dispose();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncEntry);
    _removeEntry();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _MultiviewOverlay extends StatelessWidget {
  const _MultiviewOverlay({required this.controller});

  final MultiviewWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final visible = controller.visibleSessions;
        final fullscreenId = controller.fullscreenSessionId;
        final fullscreen = fullscreenId == null ? null : controller.session(fullscreenId);
        final content = fullscreen != null
            ? _WorkspaceWindow(
                controller: controller,
                registration: fullscreen,
                viewport: MediaQuery.sizeOf(context),
                floating: false,
                fullscreen: true,
              )
            : controller.layoutMode == MultiviewLayoutMode.sideBySide && visible.isNotEmpty
            ? _SplitWorkspace(controller: controller, sessions: visible)
            : SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final viewport = Size(constraints.maxWidth, constraints.maxHeight);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [for (final registration in visible) _floatingWindow(context, registration, viewport)],
                    );
                  },
                ),
              );

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: content),
            PositionedDirectional(end: 12, bottom: 12, child: _WorkspaceDock(controller: controller)),
            if (controller.sessionTrayVisible)
              PositionedDirectional(end: 12, bottom: 68, child: _WorkspaceSessionTray(controller: controller)),
          ],
        );
      },
    );
  }

  Widget _floatingWindow(BuildContext context, WorkspaceSurfaceRegistration registration, Size viewport) {
    final id = registration.descriptor.id;
    final placement = controller.placementFor(id);
    final minWidth = math.min(220.0, viewport.width);
    final width = (viewport.width * placement.width).clamp(minWidth, math.min(520.0, viewport.width)).toDouble();
    final height = (viewport.height * placement.height)
        .clamp(math.min(150.0, viewport.height), math.min(420.0, viewport.height))
        .toDouble();
    final position = placement.resolveTopLeft(viewport, windowWidth: width, windowHeight: height);
    final left = position.dx;
    final top = position.dy;

    return AnimatedPositioned(
      duration: MonoMotion.shape(context),
      curve: MonoMotion.standard,
      left: left,
      top: top,
      width: width,
      height: height,
      child: _WorkspaceWindow(
        key: ValueKey<String>('workspace:${registration.descriptor.id}'),
        controller: controller,
        registration: registration,
        viewport: viewport,
        floating: true,
        paneSize: Size(width, height),
      ),
    );
  }
}

class _SplitWorkspace extends StatelessWidget {
  const _SplitWorkspace({required this.controller, required this.sessions});

  final MultiviewWorkspaceController controller;
  final List<WorkspaceSurfaceRegistration> sessions;

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    final columns = math.sqrt(sessions.length).ceil().clamp(1, sessions.length).toInt();
    return ColoredBox(
      color: tk.bg,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 760;
            final crossAxisCount = horizontal ? columns : 1;
            return GridView.builder(
              padding: EdgeInsets.all(tk.space),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: tk.groupGap,
                mainAxisSpacing: tk.groupGap,
                childAspectRatio: horizontal ? 1.45 : 1.65,
              ),
              itemCount: sessions.length,
              itemBuilder: (context, index) => _WorkspaceWindow(
                key: ValueKey<String>('workspace:${sessions[index].descriptor.id}'),
                controller: controller,
                registration: sessions[index],
                viewport: Size(constraints.maxWidth, constraints.maxHeight),
                floating: false,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WorkspaceWindow extends StatefulWidget {
  const _WorkspaceWindow({
    super.key,
    required this.controller,
    required this.registration,
    required this.viewport,
    required this.floating,
    this.paneSize,
    this.fullscreen = false,
  });

  final MultiviewWorkspaceController controller;
  final WorkspaceSurfaceRegistration registration;
  final Size viewport;
  final bool floating;
  final Size? paneSize;
  final bool fullscreen;

  @override
  State<_WorkspaceWindow> createState() => _WorkspaceWindowState();
}

class _WorkspaceWindowState extends State<_WorkspaceWindow> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'multiview_window');
  Offset _lastLongPressOffset = Offset.zero;
  bool _wasSelected = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _WorkspaceWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.registration.descriptor.id;
    final nextId = widget.registration.descriptor.id;
    if (oldWidget.controller != widget.controller || oldId != nextId) {
      oldWidget.controller.setSurfaceInputFocus(oldId, false);
      _wasSelected = false;
      _onFocusChanged();
    }
  }

  void _onFocusChanged() {
    widget.controller.setSurfaceInputFocus(widget.registration.descriptor.id, _focusNode.hasFocus);
  }

  bool get _supportsDirectLongPressMove => switch (widget.registration.descriptor.kind) {
    MultiviewMediaKind.video ||
    MultiviewMediaKind.liveTv ||
    MultiviewMediaKind.music ||
    MultiviewMediaKind.audiobook => true,
    MultiviewMediaKind.publication || MultiviewMediaKind.comic || MultiviewMediaKind.game => false,
  };

  @override
  void dispose() {
    widget.controller.setSurfaceInputFocus(widget.registration.descriptor.id, false);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildSurfaceWithMoveGestures(BuildContext context, String id, WorkspaceSurfaceRegistration registration) {
    final surface = registration.buildSurface(context);
    if (!widget.floating) return surface;

    if (controller.positioningSessionId == id) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (details) =>
            controller.movePositionedByPixels(id, details.delta, widget.viewport, paneSize: widget.paneSize),
        onPanEnd: (_) => controller.finishPositioning(),
        onPanCancel: () => controller.finishPositioning(),
        child: surface,
      );
    }
    if (!_supportsDirectLongPressMove) return surface;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: (_) {
        _lastLongPressOffset = Offset.zero;
        controller.focus(id);
        HapticFeedback.selectionClick();
      },
      onLongPressMoveUpdate: (details) {
        final nextOffset = details.offsetFromOrigin;
        final delta = nextOffset - _lastLongPressOffset;
        _lastLongPressOffset = nextOffset;
        if (delta != Offset.zero) {
          controller.moveByPixels(id, delta, widget.viewport, paneSize: widget.paneSize);
        }
      },
      child: surface,
    );
  }

  MultiviewWorkspaceController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    final registration = widget.registration;
    final controller = widget.controller;
    final id = registration.descriptor.id;
    final selected = controller.focusedSessionId == id;
    final moving = controller.positioningSessionId == id;
    final borderColor = selected ? tk.accent : tk.outline;
    final radius = widget.fullscreen ? 0.0 : tk.radiusLg;
    if (selected != _wasSelected) {
      _wasSelected = selected;
      if (selected) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.controller.focusedSessionId == id && !_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        });
      }
    }

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        // Child player and reader controls keep their own arrow-key behavior.
        // The workspace owns arrows only during its explicit Move action.
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final moving = controller.positioningSessionId == id;
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          if (moving) {
            controller.finishPositioning(cancel: true);
            return KeyEventResult.handled;
          }
          if (widget.fullscreen) {
            controller.exitFullscreen();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        }
        if (moving) {
          final delta = switch (event.logicalKey) {
            LogicalKeyboardKey.arrowLeft => const Offset(-24, 0),
            LogicalKeyboardKey.arrowRight => const Offset(24, 0),
            LogicalKeyboardKey.arrowUp => const Offset(0, -24),
            LogicalKeyboardKey.arrowDown => const Offset(0, 24),
            _ => null,
          };
          if (delta != null) {
            controller.movePositionedByPixels(id, delta, widget.viewport, paneSize: widget.paneSize);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            controller.finishPositioning();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Semantics(
        container: true,
        label: registration.descriptor.title,
        onIncrease: () =>
            controller.resizeByPixels(id, const Offset(20, 12), widget.viewport, paneSize: widget.paneSize),
        onDecrease: () =>
            controller.resizeByPixels(id, const Offset(-20, -12), widget.viewport, paneSize: widget.paneSize),
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            controller.focus(id);
            if (!_focusNode.hasFocus) _focusNode.requestFocus();
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tk.surface,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
              boxShadow: widget.floating
                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.38), blurRadius: 26, offset: const Offset(0, 12))]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius > 0 ? radius - 1 : 0),
              child: Column(
                children: [
                  _WorkspaceTitleBar(
                    controller: controller,
                    registration: registration,
                    viewport: widget.viewport,
                    floating: widget.floating,
                    paneSize: widget.paneSize,
                    fullscreen: widget.fullscreen,
                    moving: moving,
                    onMoveToggle: () {
                      if (controller.positioningSessionId == id) {
                        controller.finishPositioning();
                      } else if (controller.beginPositioning(id)) {
                        _focusNode.requestFocus();
                      }
                    },
                  ),
                  Expanded(
                    child: SizedBox.expand(
                      child: _buildSurfaceWithMoveGestures(context, id, registration),
                    ),
                  ),
                  if (widget.floating && !widget.fullscreen)
                    _ResizeHandle(
                      onResize: (delta) =>
                          controller.resizeByPixels(id, delta, widget.viewport, paneSize: widget.paneSize),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkspaceTitleBar extends StatelessWidget {
  const _WorkspaceTitleBar({
    required this.controller,
    required this.registration,
    required this.viewport,
    required this.floating,
    this.paneSize,
    required this.fullscreen,
    required this.moving,
    required this.onMoveToggle,
  });

  final MultiviewWorkspaceController controller;
  final WorkspaceSurfaceRegistration registration;
  final Size viewport;
  final bool floating;
  final Size? paneSize;
  final bool fullscreen;
  final bool moving;
  final VoidCallback onMoveToggle;

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    final id = registration.descriptor.id;
    return Material(
      color: tk.surface,
      child: SizedBox(
        height: 42,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: floating
                    ? (details) => controller.moveByPixels(id, details.delta, viewport, paneSize: paneSize)
                    : null,
                onTap: () => controller.focus(id),
                onDoubleTap: () {
                  if (fullscreen) {
                    controller.exitFullscreen();
                  } else {
                    controller.promoteToFullscreen(id);
                  }
                },
                child: Padding(
                  padding: EdgeInsetsDirectional.only(start: tk.space * 1.4),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      registration.descriptor.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: tk.text, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
            if (floating && !fullscreen)
              IconButton(
                tooltip: moving ? t.common.save : t.common.edit,
                visualDensity: VisualDensity.compact,
                iconSize: 19,
                onPressed: onMoveToggle,
                icon: Icon(moving ? Symbols.check_rounded : Symbols.drag_handle_rounded),
              ),
            if (registration.descriptor.hasAudio)
              IconButton(
                tooltip: controller.audibleSessionId == id ? t.videoControls.muteButton : t.videoControls.unmuteButton,
                visualDensity: VisualDensity.compact,
                iconSize: 19,
                onPressed: () => controller.setAudibleSession(controller.audibleSessionId == id ? null : id),
                icon: Icon(controller.audibleSessionId == id ? Symbols.volume_up_rounded : Symbols.volume_off_rounded),
              ),
            IconButton(
              tooltip: fullscreen ? t.common.exitFullscreen : t.common.fullscreen,
              visualDensity: VisualDensity.compact,
              iconSize: 19,
              icon: Icon(fullscreen ? Symbols.fullscreen_exit_rounded : Symbols.open_in_full_rounded),
              onPressed: () {
                if (fullscreen) {
                  controller.exitFullscreen();
                } else {
                  controller.promoteToFullscreen(id);
                }
              },
            ),
            IconButton(
              tooltip: t.common.close,
              visualDensity: VisualDensity.compact,
              iconSize: 19,
              onPressed: () => controller.close(id),
              icon: const Icon(Symbols.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceDock extends StatelessWidget {
  const _WorkspaceDock({required this.controller});

  final MultiviewWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    final fullscreen = controller.fullscreenSessionId != null;
    final mode = controller.layoutMode;
    return Material(
      color: tk.surface.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(tk.radiusLg),
      elevation: 10,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!fullscreen && controller.visibleSessions.length > 1)
            IconButton(
              tooltip: t.common.viewAll,
              onPressed: controller.swapFocusedWithNext,
              icon: const Icon(Symbols.swap_horiz_rounded),
            ),
          if (fullscreen)
            IconButton(
              tooltip: t.common.exitFullscreen,
              onPressed: controller.exitFullscreen,
              icon: const Icon(Symbols.fullscreen_exit_rounded),
            )
          else
            IconButton(
              tooltip: mode == MultiviewLayoutMode.floating ? t.common.viewAll : t.videoControls.pipButton,
              onPressed: () => controller.setLayoutMode(
                mode == MultiviewLayoutMode.floating ? MultiviewLayoutMode.sideBySide : MultiviewLayoutMode.floating,
              ),
              icon: Icon(
                mode == MultiviewLayoutMode.floating
                    ? Symbols.grid_view_rounded
                    : Symbols.picture_in_picture_alt_rounded,
              ),
            ),
          IconButton(
            tooltip: t.common.options,
            onPressed: controller.toggleSessionTray,
            icon: const Icon(Symbols.dashboard_customize_rounded),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceSessionTray extends StatelessWidget {
  const _WorkspaceSessionTray({required this.controller});

  final MultiviewWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    final sessions = controller.sessions.where((s) => !controller.isRestored(s.descriptor.id)).toList(growable: false);
    return Material(
      color: tk.surface,
      borderRadius: BorderRadius.circular(tk.radiusLg),
      elevation: 18,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320, maxHeight: 360),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.all(tk.space * 0.5),
          children: [
            for (final registration in sessions)
              ListTile(
                dense: true,
                selected: controller.focusedSessionId == registration.descriptor.id,
                leading: Icon(
                  controller.parkedSessions.any((s) => s.descriptor.id == registration.descriptor.id)
                      ? Symbols.pause_circle_outline_rounded
                      : Symbols.play_circle_rounded,
                ),
                title: Text(registration.descriptor.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  final id = registration.descriptor.id;
                  controller.unpark(id);
                  if (controller.fullscreenSessionId != null) {
                    controller.promoteToFullscreen(id);
                  } else {
                    controller.focus(id);
                  }
                  controller.setSessionTrayVisible(false);
                },
                trailing: IconButton(
                  tooltip: t.common.back,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Symbols.arrow_back_rounded),
                  onPressed: () {
                    controller.setSessionTrayVisible(false);
                    controller.restore(registration.descriptor.id);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({required this.onResize});

  final ValueChanged<Offset> onResize;

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    return Align(
      alignment: AlignmentDirectional.bottomEnd,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          final delta = switch (event.logicalKey) {
            LogicalKeyboardKey.arrowLeft => const Offset(-20, 0),
            LogicalKeyboardKey.arrowRight => const Offset(20, 0),
            LogicalKeyboardKey.arrowUp => const Offset(0, -12),
            LogicalKeyboardKey.arrowDown => const Offset(0, 12),
            _ => null,
          };
          if (delta == null) return KeyEventResult.ignored;
          onResize(delta);
          return KeyEventResult.handled;
        },
        child: Semantics(
          button: true,
          label: t.common.edit,
          onIncrease: () => onResize(const Offset(20, 12)),
          onDecrease: () => onResize(const Offset(-20, -12)),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) => onResize(details.delta),
            child: SizedBox(
              width: 44,
              height: 36,
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  end: tk.space * 0.5,
                  bottom: tk.space * 0.25,
                  start: tk.space,
                  top: tk.space * 0.25,
                ),
                child: Icon(Symbols.drag_handle_rounded, size: 20, color: tk.textMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
