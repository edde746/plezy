import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../profiles/active_profile_provider.dart';
import '../providers/multi_server_provider.dart';
import '../services/agent_control_service.dart';

/// Mounted only in opted-in builds. The supplied context lives below the
/// appropriate navigator and existing providers; it is never retained after
/// this scope leaves the tree.
class AgentControlScope extends StatefulWidget {
  const AgentControlScope({super.key, required this.child, required this.commandContext, this.profile = false});

  final Widget child;
  final BuildContext? Function() commandContext;
  final bool profile;

  @override
  State<AgentControlScope> createState() => _AgentControlScopeState();
}

class _AgentControlScopeState extends State<AgentControlScope> {
  bool _attached = false;
  bool? _wasUncovered;
  ModalRoute<dynamic>? _rootRoute;

  BuildContext? _commandContext() => mounted ? widget.commandContext() : null;
  bool _uncovered() => mounted && (_rootRoute?.isCurrent ?? true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rootRoute = ModalRoute.of(context);
    final uncovered = _uncovered();
    if (widget.profile && _attached && _wasUncovered != uncovered) {
      AgentControlService.instance.profileVisibilityChanged(this);
    }
    _wasUncovered = uncovered;
    if (widget.profile) {
      // A keyed navigator can preserve this profile beneath a replaced root.
      // Reattach idempotently when the retained subtree is reparented.
      _attached = true;
      AgentControlService.instance.attachProfile(owner: this, commandContext: _commandContext, uncovered: _uncovered);
    } else {
      if (_attached) return;
      _attached = true;
      AgentControlService.instance.attachRoot(
        owner: this,
        commandContext: _commandContext,
        activeProfile: context.read<ActiveProfileProvider>(),
        multiServer: context.read<MultiServerProvider>(),
      );
    }
  }

  @override
  void dispose() {
    if (_attached) {
      if (widget.profile) {
        AgentControlService.instance.detachProfile(this);
      } else {
        AgentControlService.instance.detachRoot(this);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
