# Plezy name and logo

Plezy's code is licensed under [GPL-3.0](LICENSE). The license covers the code, not the Plezy name or logo.

## What this covers

- The name "Plezy", and names built on it or confusingly similar to it, such as "PlezyNG" or "Plezy Pro".
- The Plezy logo and app icons, including the alternate icons in `assets/app_icons/`, and icons that look like them.

## Personal use

You don't need permission to build, modify, or run Plezy for your own use, under any name.

## Packaging Plezy

Distributions and package managers can ship Plezy under its name when the package is built from this repository's
source. Patches needed to build, package, or integrate with the platform are fine. A package that adds, removes, or
changes features is a fork.

## Distributing a fork

A modified version distributed beyond personal use, whether through app stores, package managers, public release builds,
or a website, must be clearly a different app:

- **Name.** Use a name that doesn't include or resemble "Plezy" for the app's display name, store listings, package and
  bundle identifiers, website and domain, and release artifacts.
- **Logo and icons.** Replace the Plezy logo and app icons with your own.
- **URL scheme.** Register your own scheme instead of `plezy://`. With both apps installed, a shared scheme sends links
  to the wrong app.
- **Services.** Don't use services the Plezy project runs or registered: `ice.plezy.app` (tracker OAuth proxy, log
  uploads, Discord posters), `bugs.plezy.app` (crash reports), the Discord application, and the Trakt, MyAnimeList,
  AniList, Simkl, and MDBList app registrations. Register your own, and run your own instance of [`server/`](server/)
  for the OAuth proxy.

Internal identifiers users never see, such as the Dart package name and the `com.edde746.plezy` Kotlin package, can
stay. Keeping them makes upstream changes easier to merge.

You can say your app is a fork of, or based on, Plezy in your README, store listing, and About screen, as long as it
doesn't suggest the Plezy project makes or endorses it.

## Permission

Exceptions need written permission from the maintainer ([@edde746](https://github.com/edde746)); open an issue on this
repository to ask. Without it, no other app is approved to use the Plezy name, logo, or icons, including under store
policies that require the original developer's approval, such as
[App Store Review Guideline 4.1(c)](https://developer.apple.com/app-store/review/guidelines/#copycats).
