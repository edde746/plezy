import 'package:video_player_example/view/butterflyassetvideo.dart';
import 'package:flutter/material.dart';

class ButterFlyAssetVideoInList extends StatelessWidget {
  const ButterFlyAssetVideoInList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        const ExampleCard(title: 'Item a'),
        const ExampleCard(title: 'Item b'),
        const ExampleCard(title: 'Item c'),
        const ExampleCard(title: 'Item d'),
        const ExampleCard(title: 'Item e'),
        const ExampleCard(title: 'Item f'),
        const ExampleCard(title: 'Item g'),
        Card(
          child: Column(
            children: <Widget>[
              Column(
                children: <Widget>[
                  const ListTile(
                    leading: Icon(Icons.cake),
                    title: Text('Video video'),
                  ),
                  Stack(
                    alignment:
                        FractionalOffset.bottomRight +
                        const FractionalOffset(-0.1, -0.1),
                    children: <Widget>[
                      const ButterFlyAssetVideo(),
                      Image.asset('assets/flutter-mark-square-64.png'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const ExampleCard(title: 'Item h'),
        const ExampleCard(title: 'Item i'),
        const ExampleCard(title: 'Item j'),
        const ExampleCard(title: 'Item k'),
        const ExampleCard(title: 'Item l'),
      ],
    );
  }
}

/// A filler card to show the video in a list of scrolling contents.
class ExampleCard extends StatelessWidget {
  const ExampleCard({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.airline_seat_flat_angled),
            title: Text(title),
          ),
          OverflowBar(
            children: <Widget>[
              TextButton(
                child: const Text('BUY TICKETS'),
                onPressed: () {
                  /* ... */
                },
              ),
              TextButton(
                child: const Text('SELL TICKETS'),
                onPressed: () {
                  /* ... */
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
