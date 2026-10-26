# PlezyNG branding

The approved logo is the two nested coral play triangles with a solid navy
centre and the NG badge at the lower right. The master is
[`assets/branding/plezyng-approved.png`](../../assets/branding/plezyng-approved.png).
It is the exact user-selected upload, retained byte-for-byte at 1254 × 1254.
Its SHA-256 is recorded in `assets/branding/brand.json`.

Use `assets/plezy.png` for the app, README, Linux packages, and website handoff.
It is a transparent 1024 × 1024 export of the approved image. The NG badge is
already part of the artwork; never add a second badge or substitute the old
wave mark. The SVG compatibility files embed the approved raster and are not
editable vector reconstructions.

The webOS TV package icon at `webos/meta/icon.png` is generated from the same
approved master, so it stays in sync with the desktop and mobile app icons.

`assets/plezyng-app-icon.png` is the full-resolution 1254 × 1254 compatibility
export for store-listing workflows and uses the same approved master.

## Regenerate and verify

```sh
python3 -m pip install -r scripts/codegen/requirements-branding.txt
python3 scripts/codegen/generate_brand_assets.py
python3 scripts/codegen/generate_brand_assets.py --check
python3 scripts/checks/check_brand_assets.py
python3 -m unittest discover -s scripts/codegen/tests -p 'test_brand_assets.py'
```

The existing `generate_app_icons.py` and `generate_android_icons.sh` commands
delegate to the same exporter, so no older generator can restore the wave
logo. Export dimensions and roles are explicit in `brand.json`; content hashes
are in `asset-manifest.json`. CI checks the source, configuration, generator,
and every exported file without needing a graphics SDK.

The original PNG remains untouched. Exports remove only almost-transparent
matte residue (alpha 4/255 or less), then resize and place the image. The colour
art is never traced, repainted, recoloured, or passed through image generation.
Android monochrome and notification masks keep the rings, NG letters, and
badge border; navy interiors become transparent for system tinting.

## Platform coverage

- Flutter startup, authentication, about, README and Linux packaging use the
  shared PNG exports. The icon picker uses the padded foreground.
- Android legacy, adaptive, monochrome, notification, TV, and all 23 alternate
  slots are exported. Adaptive foregrounds fit the entire mark and NG badge
  inside a circle smaller than the Android safe area.
- iOS and macOS Icon Composer assets use the approved PNG. iOS alternate icons
  remain opaque. Glass, specular, and shadow effects are disabled on the mark.
- tvOS front/back/middle stacks, alternate stacks, both shelf formats and the
  wide shelf's 2× image are exported.
- Windows ICO includes 16, 24, 32, 48, 64, 128 and 256 px frames. Every MSIX tile,
  target-size variant, store logo and splash image is exported.
- The webOS TV package icon uses the same approved 1024 × 1024 mark.
- Google Play and Amazon icons, the Play feature graphic, and the Android and
  iPhone server-selection screenshots use the selected mark. The graphic and
  screenshots retain their previous non-logo content from clean bases in
  `assets/branding`. These are logo replacements in existing screenshots, not
  new device captures. Other screenshots do not contain the replaced mark.

The 23 alternate names and launcher identifiers are permanent compatibility
identifiers. Their old motifs have been replaced with this logo; only the
backplate colours differ. Keep every alias, catalog entry, and image stack so
an existing selection survives upgrades. Source SVG wrappers reference the
shared PNG instead of maintaining independent artwork.

Branding verification covers source identity, export integrity, native asset
references, safe-area placement, opacity and icon sizes. A Flutter build and
Apple/Android device inspection still qualify the packaged appearance.
