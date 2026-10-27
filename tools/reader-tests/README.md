# Reader browser checks

The comic renderer uses browser APIs and the existing Flutter archive, XML and
HTTP packages. Playwright is a pinned **development-only** dependency. It is not
shipped in PlezyNG. Both the dependency and its lockfile are committed here. CI installs Chromium and runs the existing Flutter browser integration suite on the repository's private Linux JIT runner.

With the repository's Flutter SDK and Node 20 or newer on PATH:

```sh
flutter pub get --enforce-lockfile
cd tools/reader-tests
npm ci --ignore-scripts
npm exec -- playwright install --with-deps chromium
npm test
```

On Linux the PDFium native hook also requires a C/C++ compiler (`clang` and
`build-essential` on Ubuntu). Install these before running Flutter tests. The
Playwright `--with-deps` option installs Chromium's system dependencies; on a
machine without administrative access use an already provisioned browser.

`PLEZY_CHROME_PATH` and `PLEZY_PLAYWRIGHT_PATH` can point to that browser and
Playwright module. The runner fails if its browser is missing. Ordinary Flutter
tests skip the browser fixture unless `PLEZY_CHROME_PATH` is set; CI explicitly
runs this runner so those checks cannot silently disappear.

Tests use generated local EPUB/CBZ fixtures, including mixed image dimensions,
metadata, thumbnails, resume, RTL, zoom, retry and responsive layouts. They do
not require a server account or copyrighted books. `PLEZY_READER_SCREENSHOT`
optionally saves a desktop screenshot (plus a `-comic` variant) for inspection.

Installation guidance: https://playwright.dev/docs/ci and
https://playwright.dev/docs/browsers.
