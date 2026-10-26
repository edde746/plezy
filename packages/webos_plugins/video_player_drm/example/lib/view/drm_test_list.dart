import 'package:flutter/material.dart';
import 'package:video_player_example/view/customvideoplayer.dart';
import 'package:video_player_drm/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:convert';

class DRMTestList extends StatefulWidget {
  const DRMTestList({super.key});

  @override
  State<DRMTestList> createState() => _DRMTestListState();
}

class _DRMTestListState extends State<DRMTestList>
    with SingleTickerProviderStateMixin {
  int? selectedIndex;
  late TabController _tabController;

  final List<_TestItem> playreadyTestItems = [
    const _TestItem(
      title:
          'Playback Test with DASH MPD and Platform License (PlayReady Encrypted Contents)',
      player: CustomVideoPlayer(
        contentsInfo:
            'https://test.playready.microsoft.com/media/profficialsite/tearsofsteel_4k.ism/manifest.mpd',
        formatHint: VideoFormat.dash,
        drmConfigs: DrmConfigs(
          type: DrmType.playready,
          licenseServerUrl:
              'https://test.playready.microsoft.com/service/rightsmanager.asmx',
        ),
      ),
    ),
    const _TestItem(
      title:
          'Playback Test with Smooth Streaming and Platform License (PlayReady Encrypted Contents)',
      player: CustomVideoPlayer(
        contentsInfo:
            'https://test.playready.microsoft.com/media/profficialsite/tearsofsteel_4k.ism.smoothstreaming/manifest',
        formatHint: VideoFormat.ss,
        drmConfigs: DrmConfigs(
          type: DrmType.playready,
          licenseServerUrl:
              'https://test.playready.microsoft.com/service/rightsmanager.asmx',
        ),
      ),
    ),
    const _TestItem(
      title:
          'Playback Test with DASH MPD and App License (PlayReady Encrypted Contents)',
      player: CustomVideoPlayer(
        contentsInfo:
            'https://test.playready.microsoft.com/media/profficialsite/tearsofsteel_4k.ism/manifest.mpd',
        formatHint: VideoFormat.dash,
        drmConfigs: DrmConfigs(
          type: DrmType.playready,
          licenseCallback: _handlePlayreadyLicenseCallback,
        ),
      ),
    ),
    const _TestItem(
      title:
          'Playback Test with Smooth Streaming and App License (PlayReady Encrypted Contents)',
      player: CustomVideoPlayer(
        contentsInfo:
            'https://test.playready.microsoft.com/media/profficialsite/tearsofsteel_4k.ism.smoothstreaming/manifest',
        formatHint: VideoFormat.ss,
        drmConfigs: DrmConfigs(
          type: DrmType.playready,
          licenseCallback: _handlePlayreadyLicenseCallback,
        ),
      ),
    ),
  ];

  final List<_TestItem> widevineTestItems = [
    const _TestItem(
      title:
          'Playback Test with DASH MPD and Platform License (Widevine Encrypted Contents)',
      player: CustomVideoPlayer(
        contentsInfo:
            'https://storage.googleapis.com/wvmedia/cenc/h264/tears/tears.mpd',
        formatHint: VideoFormat.dash,
        drmConfigs: DrmConfigs(
          type: DrmType.widevine,
          licenseServerUrl: 'https://proxy.staging.widevine.com/proxy',
        ),
      ),
    ),
    const _TestItem(
      title:
          'Playback Test with DASH MPD and App License (Widevine Encrypted Contents)',
      player: CustomVideoPlayer(
        contentsInfo:
            'https://storage.googleapis.com/wvmedia/cenc/h264/tears/tears.mpd',
        formatHint: VideoFormat.dash,
        drmConfigs: DrmConfigs(
          type: DrmType.widevine,
          licenseCallback: _handleWidevineLicenseCallback,
        ),
      ),
    ),
  ];

  static Future<Uint8List> _handlePlayreadyLicenseCallback(
    Uint8List challenge,
  ) async {
    final response = await http.post(
      Uri.parse(
        'https://test.playready.microsoft.com/service/rightsmanager.asmx',
      ),
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction':
            '"http://schemas.microsoft.com/DRM/2007/03/protocols/AcquireLicense"',
      },
      body: challenge,
    );
    return response.bodyBytes;
  }

  static Future<Uint8List> _handleWidevineLicenseCallback(
    Uint8List challenge,
  ) async {
    Uint8List actualChallenge;

    try {
      final challengeString = String.fromCharCodes(challenge);
      actualChallenge = base64Decode(challengeString);
    } catch (e) {
      actualChallenge = challenge;
    }

    final response = await http.post(
      Uri.parse('https://proxy.staging.widevine.com/proxy'),
      headers: {'Content-Type': 'application/octet-stream'},
      body: actualChallenge,
    );

    return response.bodyBytes;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTestList(List<_TestItem> testItems, int startIndex) {
    return ListView.builder(
      itemCount: testItems.length,
      itemBuilder: (context, idx) {
        return ListTile(
          title: Text(testItems[idx].title),
          trailing: const Icon(Icons.play_arrow),
          onTap: () => setState(() => selectedIndex = startIndex + idx),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (selectedIndex != null) {
      final allTestItems = [...playreadyTestItems, ...widevineTestItems];

      return Column(
        children: [
          ListTile(
            leading: const Icon(Icons.arrow_back),
            title: const Text('Back to list'),
            onTap: () => setState(() => selectedIndex = null),
          ),
          Expanded(
            child: SizedBox.expand(child: allTestItems[selectedIndex!].player),
          ),
        ],
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'PlayReady'),
            Tab(text: 'Widevine'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTestList(playreadyTestItems, 0),
              _buildTestList(widevineTestItems, playreadyTestItems.length),
            ],
          ),
        ),
      ],
    );
  }
}

class _TestItem {
  final String title;
  final Widget player;
  const _TestItem({required this.title, required this.player});
}
