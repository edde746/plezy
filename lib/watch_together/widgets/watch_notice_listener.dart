import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/profile_navigation_scope.dart';
import '../../utils/snackbar_helper.dart';
import '../models/watch_notice.dart';
import '../providers/watch_together_provider.dart';
import 'watch_labels.dart';

/// Shows a snackbar for each [WatchTogetherProvider.notices] notice that has
/// text: on the main screen while it is on top, above pushed screens (the
/// player, Watch Together) otherwise. Nothing for the user's own leave, and
/// nothing once disposed.
///
/// Mount it above the profile navigator, below the root [ScaffoldMessenger].
class WatchNoticeListener extends StatefulWidget {
  const WatchNoticeListener({super.key, required this.child});

  final Widget child;

  @override
  State<WatchNoticeListener> createState() => _WatchNoticeListenerState();
}

class _WatchNoticeListenerState extends State<WatchNoticeListener> {
  WatchTogetherProvider? _provider;
  StreamSubscription<WatchNotice>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<WatchTogetherProvider>(context, listen: false);
    if (identical(provider, _provider)) return;
    unawaited(_subscription?.cancel());
    _provider = provider;
    _subscription = provider.notices.listen(_show);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }

  void _show(WatchNotice notice) {
    final provider = _provider;
    if (!mounted || provider == null) return;
    final text = watchNoticeText(notice, media: provider.media, host: provider.host, myPeerId: provider.myPeerId);
    if (text == null) return;
    // The main screen's messenger floats above its navigation bar, but only
    // shows while the main screen is the top route.
    final navigator = profileNavigationRegistry.navigator;
    if (profileNavigationRegistry.mainScaffoldMessenger != null && navigator != null && !navigator.canPop()) {
      showMainSnackBar(text);
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.removeCurrentSnackBar();
    showAppSnackBar(context, text);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
