# Store and package descriptions

Use this copy for release channels that accept an app summary or full description. Lead with what PlezyNG does and the servers it supports; keep product copy about the app itself.

Name the product PlezyNG. Keep descriptions focused on its Plex client features and Jellyfin and Emby support; leave project history out of release copy.

## Short descriptions

Shared short copy, 70 characters:

> Plex client with Jellyfin and Emby support, offline downloads, and HDR

Use it for Google Play's short description, Snapcraft's summary, and package metadata. Google Play allows up to 80 characters.

Apple App Store subtitle, 27 characters:

> More from your Plex library

AppStream summary, 30 characters:

> Plex, Jellyfin and Emby client

## Full store description

> PlezyNG is an enhanced Plex client that also supports Jellyfin and Emby. Browse movies, shows, and music across your servers, search connected libraries, and keep watchlists and viewing progress in sync. Download media for offline playback. Watch Live TV and DVR where your server supports them. Choose audio tracks and subtitles, adjust playback speed and audio sync, and use HDR or Dolby Vision on supported devices. Watch Together keeps playback in sync when everyone can access the same media on the same server. Use PlezyNG on phones, tablets, TVs, and desktop computers. You’ll need your own Plex, Jellyfin, or Emby server. Features vary by server, device, and media.

## Store links

- Privacy policy: `https://github.com/snapetech-org/PlezyNG/blob/main/PRIVACY.md`
- Support: `https://github.com/snapetech-org/PlezyNG/issues`

## Channel audit

- The shared short description is used in Homebrew, Snap, Debian, RPM, AUR, AppImage, Chocolatey, WinGet, desktop entries, and the Microsoft Store package template.
- Flatpak/AppStream uses its shorter summary and the full feature description.
- Google Play, App Store Connect, and Amazon Appstore listing text is managed in their consoles. `publish-app-stores.yml` uploads binaries; it does not upload descriptions or screenshots. Use the copy above when editing those listings.
- Google Play artwork is in `docs/maintainers/store-listing-assets/google-play/`: the 512×512 app icon, 1024×500 feature graphic, and four 1080×1920 phone screenshots. The phone set shows server selection, Discover, library browsing, and media details.
- GitHub Release notes are generated from `CHANGELOG.md`, and Discord announcements use those notes. Keep both specific to each release instead of repeating the permanent store description.
- The README and internal project-history text are separate from this release copy.

## TV store handoff

The Samsung and LG build workflows can prepare a manual upload bundle with the
shared description, privacy policy, package identity, hash, and build evidence.
They do not create seller accounts or submit app listings. Capture screenshots
from the actual supported TV model and add them in the vendor portal; no
placeholder TV imagery is included. Confirm locale, age-rating, region,
review-account, and certification fields in the seller portal before submission.

Google Play's short-description limit is 80 characters. Apple allows a 30-character subtitle and a 4,000-character description. See [Google Play listing guidance](https://support.google.com/googleplay/android-developer/answer/9866151) and [App Store Connect platform metadata](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information).
