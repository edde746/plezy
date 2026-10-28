# PlezyNG ribbon identity

The approved identity is the coral folded-ribbon play symbol and italic
**PlezyNG** wordmark. The full emblem retains **NG** in its lower-right opening;
the compact symbol omits fine lettering and the hairline return fold.

`assets/branding/brand.json` records the immutable master checksums and every
export's role, size and appearance. `plezyng-approved.png` is the dark-surface
emblem. `source/` contains the light emblem, compact symbol, two wordmarks and
two artwork masters. The generated PNGs have real alpha, including the ribbon's
openings. These are raster assets; the lettering is artwork, not an installable
font. Compatibility SVGs embed or reference the PNGs and are not vector masters.

## Use the right asset

- `AppBrandMark` and `AppBrandWordmark` select light/dark artwork from the actual
  Flutter surface, including custom themes. Use them for startup, sign-in and
  About. Marks at 64 logical pixels or below use the compact silhouette.
- `plezyng-mark-light.png` and `plezyng-wordmark-light.png` have navy lettering
  for pale backgrounds. The `-dark` variants have ivory lettering.
- `plezyng-artwork-light.webp` and `plezyng-artwork-dark.webp` are matching 16:9
  brand artwork. README uses a theme-aware picture. Existing device and content
  illustrations remain product demonstrations rather than brand masters.
- `plezyng-compact.png` and `plezyng-monochrome.png` cover tiny and system-tinted
  uses. Windows ICO selects the compact mark separately for its small frames.
- `assets/branding/web/` contains theme-specific favicon sizes, multi-size ICO,
  opaque Apple/web app icons, and 1200 × 630 social artwork.

Keep aspect ratios and clear space. Do not add a second NG badge, stretch the
wordmark, or use pale lettering on a pale surface. Larger OS launcher icons use
the detailed mark; small target-size exports and monochrome masks omit NG.

## Regenerate and verify

```sh
python3 -m pip install -r scripts/codegen/requirements-branding.txt
python3 scripts/codegen/generate_brand_assets.py
python3 scripts/codegen/generate_brand_assets.py --check
python3 scripts/checks/check_brand_assets.py
python3 -m unittest discover -s scripts/codegen/tests -p 'test_brand_assets.py'
flutter test test/widgets/app_brand_test.dart
```

All masters stay unchanged. The exporter suppresses only alpha at 4/255 or
below, then resizes and composes outputs. Colours and lettering come from the
approved masters. `asset-manifest.json` verifies every exported file and all
sources. Pillow is pinned for repeatable encoders. Compatibility generator
entrypoints delegate to this same exporter.

## Platform coverage

The exporter covers Android legacy/adaptive/monochrome/notification/TV assets,
iOS and macOS Icon Composer, iOS alternates, tvOS stacks and both shelf formats,
Windows ICO and MSIX tiles, webOS, Linux packaging's shared PNG, and store
listing artwork. Tizen packaging copies the shared `assets/plezy.png`.

All 23 alternate launcher identifiers remain stable. Their backplates retain
the existing palette, with navy or ivory NG lettering chosen for its contrast.
Android foregrounds fit the full mark within the safe circle. Apple composed
icons use the light emblem on their existing light fill. The app's appearance
setting changes in-app branding; platform launcher selection remains governed
by the existing platform icon settings.

To hand off exactly the same outputs to the website:

```sh
cd ../plezyng.app
python3 scripts/sync_branding.py --source ../PlezyNG
npm run build
npm run check
```

The website import verifies hashes and copies bytes unchanged. Native builds
and device inspection remain the final packaging checks for their platforms.
