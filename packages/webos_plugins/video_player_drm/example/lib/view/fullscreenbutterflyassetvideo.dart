import 'package:video_player_example/components/full_screen/full_screen.dart';
import 'package:flutter/material.dart';

class FullScreenButterFlyAssetVideo extends StatelessWidget {
  const FullScreenButterFlyAssetVideo({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.push<PlayerVideoAndPopPage>(
          context,
          MaterialPageRoute<PlayerVideoAndPopPage>(
            builder: (BuildContext context) => const PlayerVideoAndPopPage(),
          ),
        );
      },
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.navigation),
            Text('Full Screen'),
            Text('Click Here'),
          ],
        ),
      ),
    );
  }
}
