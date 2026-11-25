# Contributing

## Getting Started

1. Fork and clone the repository.
2. Install JDK 27 (Gradle and the shared modules) and JDK 25 (the desktop app's toolchain). Gradle finds both through
   its toolchain resolver.
3. For Android, install the Android SDK. Without it, set `PLEZY_ANDROID=false` (or `-Pplezy.android=false`): the
   Android modules and targets are left out.
4. For the Apple apps, install Xcode 27.2 on a Mac, then generate the Xcode project (it is not committed):
   ```bash
   cd apple && "$(../tools/install_xcodegen.sh /tmp/xcodegen)" generate
   ```
   `apple/project.yml` is the only description of the Apple build. Xcode builds the shared Kotlin framework through
   Gradle as one of its build phases.

## Building and running

- **Android:** `./gradlew :app-android:installDebug`. Debug builds install as `com.edde746.plezy.dev`, beside a
  release install.
- **Desktop (Windows, Linux):** `./gradlew :app-desktop:run`.
- **iOS, iPadOS, tvOS, macOS:** open `apple/Plezy.xcodeproj` and run the `Plezy-iOS`, `Plezy-tvOS` or `Plezy-macOS`
  scheme. Simulators need no signing; a real iPhone, iPad or Apple TV needs your own team (`DEVELOPMENT_TEAM`).
- **Unsigned Mac builds don't work.** The Mac app keeps its secrets in the data protection keychain, which only a
  team-signed app may use. An ad-hoc-signed or unsigned Mac build (the project's default, CI's
  `CODE_SIGNING_ALLOWED=NO` build) gets -34018 (`errSecMissingEntitlement`) for every secret, so it can't sign in or
  keep a connection. Such builds only show that the app compiles. Run the Mac app team-signed:
  `DEVELOPMENT_TEAM=<your team ID> CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY="Apple Development"`.
- **Development session:** debug builds take `--dev` options (`--dev-server`, `--dev-open`, `--dev-setting`, …) that
  start the app on in-memory data, on a given screen, with given settings or signed in to given servers: as
  arguments on the desktop and Apple, as one string-array launch extra (`dev`) on Android. The options are in `dev/`.

## Development

- Follow Kotlin and Swift conventions and the style of the surrounding code.
- Shared behaviour (models, stores, server clients, settings) lives in `shared/`; the two UIs are `ui-compose/`
  (Android, Android TV, desktop) and `apple/` (SwiftUI). Change shared code once rather than both UIs.
- Test your changes on every platform they touch.

### AI-assisted contributions

AI-assisted pull requests must state in the PR description which model(s) were used (e.g. Claude Sonnet 4.5, GPT-5, Gemini 3 Pro).

### Checks

CI runs these on every pull request; all must pass before a change is merged.

1. **Shared, Android and desktop:**
   ```bash
   ./gradlew :build-logic:test :shared:jvmTest :shared:licenseTest :dev:jvmTest \
     :shared:verifyCommonMainPlezyDatabaseMigration :ui-compose:jvmTest :app-android:assembleDebug \
     :app-android:lintDebug :app-android:testDebugUnitTest :mpv-android:testDebugUnitTest :mpv-jvm:test :app-desktop:test
   ```
2. **Apple:** the shared tests on the simulator (`./gradlew :shared:iosSimulatorArm64Test`), and a Debug build of
   the three schemes. The UI tests in `apple/PlezyUITests` run from Xcode or `xcodebuild test`.
3. **Server:** `scripts/ci_server_checks.sh` (the Go relay in `server/`).
4. **Generated code:** `python3 scripts/codegen/generate_relay_protocol.py` and
   `python3 scripts/codegen/generate_ducet_order.py` must leave no diff.
5. **Repository:** the Python tests under `tools/`, `scripts/` and `desktop/app/packaging/`, and
   `scripts/checks/check_workflow_action_pins.py` and `scripts/checks/check_workflow_security.py`.

### Production container image updates

Production images in `server/Dockerfile` and `server/docker-compose.yml` use a readable version or source-revision tag
plus an authoritative multi-platform index digest. The adjacent `Platforms` declaration records the supported
`linux/amd64` and `linux/arm64` variants. Never replace these references with a mutable tag or a single-platform child
manifest.

Update a production image only through a reviewed change:

1. For the Bugs service, first record the running container's image ID, repository digest, platform, and OCI source
   revision without printing its environment. Prefer that reviewed running identity; selecting anything else is a
   service upgrade, not a routine pin refresh.
2. Review the upstream source revision and changelog, provenance, vulnerability results, and manifest contents. Resolve
   the readable tag and digest-qualified reference independently and confirm they identify the same OCI index in two
   clean caches. The index must contain both declared platforms; provenance/attestation descriptors do not count as
   runnable platforms.
3. Change the readable tag, full `sha256` index digest, and adjacent platform declaration together. Include the old and
   new identities, manifest/platform evidence, review findings, smoke results, and rollback notes in the change.
4. Before changing the Bugs digest, exercise it with non-production configuration and a disposable volume. Review
   migrations, take a restorable `bugs_data` backup, then validate a cloned volume. A forward-only migration rolls back
   with the prior digest and pre-change backup, not by changing the image reference alone.
5. Run `scripts/ci_server_checks.sh`. Inspect the rendered Compose configuration and rebuilt images locally without
   exposing configuration values. Do not publish or deploy from a review checkout, and never fall back to `latest` when
   a digest is unavailable.

## Internationalization (i18n)

Strings live in `shared/i18n/<locale>.i18n.json`, in slang's JSON layout; `en.i18n.json` is the base and defines every
key. build-logic's `plezy.strings` plugin generates the Kotlin accessors (`T`) from them on every build of `shared`,
and fails the build on a malformed file, naming the file, line and key.

### Adding New Strings

1. Add your string to `shared/i18n/en.i18n.json`:
   ```json
   {
     "section": {
       "myNewString": "My new text",
       "greeting": "Hello, ${name}",
       "itemCount": { "one": "${n} item", "other": "${n} items" }
     }
   }
   ```
2. Use it from Kotlin as `T.section.myNewString`, `T.section.greeting(name)` or `T.section.itemCount(n)`, and from
   Swift as `T.shared.section.myNewString`.

- Nested objects are groups. Keys are camelCase Kotlin names (`[a-z][A-Za-z0-9_]*`, not a Kotlin keyword).
- `${name}` and `$name` are `String` parameters; `\$` is a literal `$`, as is a `$` no name follows. No other
  backslash escapes, typed parameters (`${n: int}`), linked translations (`@:key`) or key modifiers (`key(rich)`).
- An object whose keys are plural categories (`zero`, `one`, `two`, `few`, `many`, `other`) is a plural: its accessor
  takes the count `n: Int` first and picks the form by the CLDR rules of the language the text is in. `other` is
  required.
- A key that is a Swift keyword or an `NSObject` member name (`description`, `copy`, `repeat`) keeps its name in
  Kotlin and is `<key>Text` in Swift (`descriptionText`).

### Adding New Languages

1. Create `shared/i18n/<BCP 47 tag>.i18n.json` (`de`, `pt`, `zh-Hant`).
2. Translate any subset of the English keys, with the same shape and parameters. A key left out or left empty shows in
   English.
3. Add the language's plural rule to `PluralRule.forTag` (`shared/src/commonMain/kotlin/com/edde746/plezy/strings/`)
   if it isn't English's.

### Guidelines

- Organize strings logically in nested objects
- Keep strings concise and clear
