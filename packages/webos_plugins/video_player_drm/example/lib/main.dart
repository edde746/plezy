// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An example of using the plugin, controlling lifecycle and playback of the
/// video.
library;

import 'package:video_player_example/view/bumblebeeremotevideo.dart';
import 'package:video_player_example/view/butterflyassetvideo.dart';
import 'package:video_player_example/view/butterflyassetvideoinlist.dart';
import 'package:video_player_example/view/fullscreenbutterflyassetvideo.dart';
import 'package:video_player_example/view/multitrack_test.dart';
import 'package:flutter/material.dart';
import 'package:video_player_example/view/drm_test_list.dart';

void main() {
  runApp(MaterialApp(home: App()));
}

class App extends StatelessWidget {
  App({super.key});

  final _screenList = <Widget>[
    const BumbleBeeRemoteVideo(),
    const ButterFlyAssetVideo(),
    const ButterFlyAssetVideoInList(),
    const FullScreenButterFlyAssetVideo(),
    const DRMTestList(),
    const MultiTrackTest(),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _screenList.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Video player example'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: <Widget>[
              Tab(icon: Icon(Icons.cloud), text: 'Remote'),
              Tab(icon: Icon(Icons.insert_drive_file), text: 'Asset'),
              Tab(icon: Icon(Icons.list), text: 'List example'),
              Tab(icon: Icon(Icons.navigation), text: 'Full Screen'),
              Tab(icon: Icon(Icons.playlist_play), text: 'DRM Player Test'),
              Tab(icon: Icon(Icons.subtitles), text: 'MultiTrack'),
            ],
          ),
        ),
        body: TabBarView(children: _screenList),
      ),
    );
  }
}
