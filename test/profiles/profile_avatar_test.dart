import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_avatar.dart';
import 'package:plezy/utils/initials_palette.dart';

void main() {
  Future<void> pumpAvatar(
    WidgetTester tester, {
    required Profile profile,
    String? avatarUrl,
    double size = 40,
    double devicePixelRatio = 1,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: MediaQuery(
          data: MediaQueryData(devicePixelRatio: devicePixelRatio),
          child: Center(
            child: ProfileAvatar(profile: profile, avatarUrl: avatarUrl, size: size),
          ),
        ),
      ),
    );
  }

  Profile localProfile({String? avatarThumbUrl, String? pinHash}) {
    return Profile.local(
      id: 'local-owner',
      displayName: 'Owner',
      avatarThumbUrl: avatarThumbUrl,
      pinHash: pinHash,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  // Avatars now go through MediaImageHelper.serverArtworkProvider, so they
  // share the `plex_optimized_<sha1>` disk-key namespace with every other
  // artwork surface instead of being cached a second time under the raw URL.
  // That means the assertions are on the resolved provider, not on a
  // CachedNetworkImage widget.
  ResizeImage avatarResizeImage(WidgetTester tester) {
    final image = tester.widget<Image>(find.byType(Image));
    return image.image as ResizeImage;
  }

  String avatarUrlOf(WidgetTester tester) {
    final inner = avatarResizeImage(tester).imageProvider;
    return (inner as CachedNetworkImageProvider).url;
  }

  testWidgets('avatarUrl renders the derived network image', (tester) async {
    const avatarUrl = 'https://jellyfin.example/Users/user-1/Images/Primary?tag=derived';

    await pumpAvatar(tester, profile: localProfile(), avatarUrl: avatarUrl);

    expect(avatarUrlOf(tester), avatarUrl);
  });

  testWidgets('avatarUrl takes precedence over the profile thumbnail', (tester) async {
    const derivedUrl = 'https://jellyfin.example/Users/user-1/Images/Primary?tag=derived';
    const profileThumbUrl = 'https://plex.example/profile-thumb.jpg';

    await pumpAvatar(
      tester,
      profile: localProfile(avatarThumbUrl: profileThumbUrl),
      avatarUrl: derivedUrl,
    );

    expect(avatarUrlOf(tester), derivedUrl);
  });

  testWidgets('a null avatarUrl preserves the profile thumbnail fallback', (tester) async {
    const profileThumbUrl = 'https://plex.example/profile-thumb.jpg';

    await pumpAvatar(tester, profile: localProfile(avatarThumbUrl: profileThumbUrl));

    expect(avatarUrlOf(tester), profileThumbUrl);
  });

  testWidgets('a profile without a picture renders its display-name initial', (tester) async {
    final profile = localProfile();

    await pumpAvatar(tester, profile: profile);

    expect(find.byType(Image), findsNothing);
    expect(find.text(initialOf(profile.displayName)), findsOneWidget);
  });

  testWidgets('an empty avatarUrl falls through to the profile picture rather than suppressing it', (tester) async {
    const plexThumb = 'https://plex.tv/users/abc/avatar';

    // An empty override means "nothing derived". Treating it as a value would
    // blank out a Plex Home profile that owns a perfectly good thumb.
    await pumpAvatar(
      tester,
      profile: localProfile(avatarThumbUrl: plexThumb),
      avatarUrl: '',
    );

    expect(avatarUrlOf(tester), plexThumb);
  });

  testWidgets('an empty avatarUrl renders initials instead of requesting an empty URL', (tester) async {
    final profile = localProfile();

    await pumpAvatar(tester, profile: profile, avatarUrl: '');

    expect(find.byType(Image), findsNothing);
    expect(find.text(initialOf(profile.displayName)), findsOneWidget);
  });

  testWidgets('network image decoding is bounded by the physical avatar size', (tester) async {
    const size = 44.0;
    const devicePixelRatio = 2.5;

    await pumpAvatar(
      tester,
      profile: localProfile(),
      avatarUrl: 'https://jellyfin.example/Users/user-1/Images/Primary?tag=large-original',
      size: size,
      devicePixelRatio: devicePixelRatio,
    );
    final resize = avatarResizeImage(tester);
    final expectedDecodeSize = (size * devicePixelRatio).round();
    expect(resize.width, expectedDecodeSize);
    expect(resize.height, expectedDecodeSize);
  });

  testWidgets('a derived avatar keeps the PIN lock badge visible', (tester) async {
    await pumpAvatar(
      tester,
      profile: localProfile(pinHash: 'stored-pin-hash'),
      avatarUrl: 'https://jellyfin.example/Users/user-1/Images/Primary?tag=derived',
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Symbols.lock_rounded), findsOneWidget);
  });
}
