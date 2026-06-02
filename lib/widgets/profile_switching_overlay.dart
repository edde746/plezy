import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';

/// Modal Stack child shown while a profile activation is rebinding servers.
class ProfileSwitchingOverlay extends StatelessWidget {
  const ProfileSwitchingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          const ModalBarrier(color: Colors.black54, dismissible: false),
          Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    const SizedBox(width: 56, height: 56, child: CircularProgressIndicator()),
                    const SizedBox(height: 16),
                    Text(t.profiles.switchingProfile),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
