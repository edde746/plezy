#!/usr/bin/env bash

# based on scripts in /engine/src/flutter/testing/scenario_app
# and xcode_backend.sh script for integration in xcode


# Exit on error
set -e

debug_sim=""


if [[ $(uname -m) == "arm64" ]]; then
  TARGET_POSTFIX='_arm64'
  CLANG_POSTFIX='_arm64'
  SIM_ARCH='arm64'
else 
  TARGET_POSTFIX=''
  CLANG_POSTFIX='_X86'
  SIM_ARCH='x86_64'
fi

ReadPubspecVersion() {
  local fallback_build_name="${FLUTTER_BUILD_NAME:-}"
  local fallback_build_number="${FLUTTER_BUILD_NUMBER:-}"

  local app_path="${FLUTTER_APPLICATION_PATH:-}"
  if [[ -z "$app_path" ]]; then
    if [[ -n "${PROJECT_DIR:-}" ]]; then
      app_path="$(cd "$(dirname "$PROJECT_DIR")" && pwd)"
    else
      app_path="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    fi
  fi

  local pubspec="$app_path/pubspec.yaml"
  local pub_version=""
  if [[ -f "$pubspec" ]]; then
    local line
    while IFS= read -r line; do
      case "$line" in
        version:*)
          pub_version="${line#version:}"
          pub_version="${pub_version%%#*}"
          pub_version="${pub_version#"${pub_version%%[![:space:]]*}"}"
          pub_version="${pub_version%"${pub_version##*[![:space:]]}"}"
          pub_version="${pub_version%\"}"
          pub_version="${pub_version#\"}"
          pub_version="${pub_version%\'}"
          pub_version="${pub_version#\'}"
          break
          ;;
      esac
    done < "$pubspec"
  fi

  if [[ -n "$pub_version" ]]; then
    FLUTTER_BUILD_NAME="${pub_version%+*}"
    if [[ "$pub_version" == *+* ]]; then
      FLUTTER_BUILD_NUMBER="${pub_version#*+}"
    else
      FLUTTER_BUILD_NUMBER="1"
    fi
  else
    FLUTTER_BUILD_NAME="${fallback_build_name:-1.0.0}"
    FLUTTER_BUILD_NUMBER="${fallback_build_number:-1}"
  fi

  export FLUTTER_BUILD_NAME
  export FLUTTER_BUILD_NUMBER
}

SetPlistString() {
  local plist="$1"
  local key="$2"
  local value="$3"

  local current=""
  if current="$(/usr/libexec/PlistBuddy -c "Print :$key" "$plist" 2>/dev/null)"; then
    if [[ "$current" != "$value" ]]; then
      /usr/libexec/PlistBuddy -c "Set :$key $value" "$plist"
    fi
  else
    /usr/libexec/PlistBuddy -c "Add :$key string $value" "$plist"
  fi
}

ValidatePlistVersion() {
  local plist="$1"
  local label="$2"
  local build_name=""
  local build_number=""

  build_name="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist" 2>/dev/null || true)"
  build_number="$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$plist" 2>/dev/null || true)"

  if [[ "$build_name" != "$FLUTTER_BUILD_NAME" || "$build_number" != "$FLUTTER_BUILD_NUMBER" ]]; then
    echo " └─ERROR: $label Info.plist version is $build_name ($build_number), expected $FLUTTER_BUILD_NAME ($FLUTTER_BUILD_NUMBER)"
    return 1
  fi
}

CopyAppFrameworkInfoPlist() {
  local plist="$1"
  local minimum_os_version="${2:-${TVOS_DEPLOYMENT_TARGET:-}}"

  if [[ -z "$minimum_os_version" ]]; then
    echo " └─ERROR: TVOS_DEPLOYMENT_TARGET is not set for App.framework Info.plist"
    return 1
  fi

  cp "$PROJECT_DIR/scripts/Info.plist" "$plist"
  SetPlistString "$plist" MinimumOSVersion "$minimum_os_version"
}

ValidateMinimumOSVersion() {
  local plist="$1"
  local label="$2"
  local expected="$3"
  local current=""

  current="$(/usr/libexec/PlistBuddy -c "Print :MinimumOSVersion" "$plist" 2>/dev/null || true)"
  if [[ "$current" != "$expected" ]]; then
    echo " └─ERROR: $label MinimumOSVersion is $current, expected $expected"
    return 1
  fi
}

VersionLessThan() {
  awk -v lhs="$1" -v rhs="$2" '
    BEGIN {
      split(lhs, left, ".")
      split(rhs, right, ".")
      for (i = 1; i <= 3; i++) {
        l = left[i] == "" ? 0 : left[i] + 0
        r = right[i] == "" ? 0 : right[i] + 0
        if (l < r) exit 0
        if (l > r) exit 1
      }
      exit 1
    }
  '
}

FrameworkExecutable() {
  local framework="$1"
  local plist="$framework/Info.plist"
  local executable_name=""

  executable_name="$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$plist" 2>/dev/null || true)"
  if [[ -z "$executable_name" ]]; then
    executable_name="$(basename "$framework" .framework)"
  fi

  printf "%s/%s\n" "$framework" "$executable_name"
}

MachOMinimumOSVersion() {
  local executable="$1"

  otool -l "$executable" 2>/dev/null | awk '
    $1 == "cmd" && ($2 == "LC_BUILD_VERSION" || $2 == "LC_VERSION_MIN_APPLETVOS" || $2 == "LC_VERSION_MIN_IPHONEOS") {
      in_version_command = 1
      next
    }
    in_version_command && ($1 == "minos" || $1 == "version") {
      print $2
      exit
    }
    $1 == "cmd" {
      in_version_command = 0
    }
  '
}

NormalizeFrameworkMinimumOSVersion() {
  local framework="$1"
  local app_minimum_os_version="$2"
  local executable=""
  local macho_minimum_os_version=""
  local plist_minimum_os_version="$app_minimum_os_version"

  executable="$(FrameworkExecutable "$framework")"
  if [[ ! -f "$executable" ]]; then
    echo " └─ERROR: framework executable missing: $executable"
    return 1
  fi

  macho_minimum_os_version="$(MachOMinimumOSVersion "$executable")"
  if [[ -n "$macho_minimum_os_version" ]] && VersionLessThan "$plist_minimum_os_version" "$macho_minimum_os_version"; then
    plist_minimum_os_version="$macho_minimum_os_version"
  fi

  SetPlistString "$framework/Info.plist" MinimumOSVersion "$plist_minimum_os_version"
  ValidateMinimumOSVersion "$framework/Info.plist" "$(basename "$framework")" "$plist_minimum_os_version"
}

CodeSignFramework() {
  local framework="$1"
  local executable=""

  executable="$(FrameworkExecutable "$framework")"
  if [[ ! -f "$executable" ]]; then
    echo " └─ERROR: framework executable missing: $executable"
    return 1
  fi

  if [[ "${PLATFORM_NAME:-}" != "appletvsimulator" && -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" && "${CODE_SIGNING_ALLOWED:-YES}" != "NO" ]]; then
    codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" -- "$framework"
  fi
}

EmbedFlutterFrameworks() {
  if [[ "${TARGET_NAME:-}" != "Runner" ]]; then
    return 0
  fi

  local minimum_os_version="${TVOS_DEPLOYMENT_TARGET:-}"
  local runner_plist="$TARGET_BUILD_DIR/$WRAPPER_NAME/Info.plist"
  if [[ -z "$minimum_os_version" && -f "$runner_plist" ]]; then
    minimum_os_version="$(/usr/libexec/PlistBuddy -c "Print :MinimumOSVersion" "$runner_plist" 2>/dev/null || true)"
  fi

  if [[ -z "$minimum_os_version" ]]; then
    echo " └─ERROR: could not resolve tvOS MinimumOSVersion for embedded Flutter frameworks"
    return 1
  fi

  local app_frameworks_dir="$TARGET_BUILD_DIR/$WRAPPER_NAME/Frameworks"
  mkdir -p "$app_frameworks_dir"

  local framework=""
  for framework in App.framework Flutter.framework; do
    local source="$BUILT_PRODUCTS_DIR/$framework"
    local destination="$app_frameworks_dir/$framework"

    if [[ ! -d "$source" ]]; then
      echo " └─ERROR: built framework missing: $source"
      return 1
    fi

    NormalizeFrameworkMinimumOSVersion "$source" "$minimum_os_version"
    rm -rf "$destination"
    cp -R "$source" "$app_frameworks_dir"
    NormalizeFrameworkMinimumOSVersion "$destination" "$minimum_os_version"
  done

  for framework in "$app_frameworks_dir"/*.framework; do
    if [[ ! -d "$framework" ]]; then
      continue
    fi

    NormalizeFrameworkMinimumOSVersion "$framework" "$minimum_os_version"
    CodeSignFramework "$framework"
  done
}

SyncRunnerVersion() {
  ReadPubspecVersion

  local plist=""
  if [[ -n "${TARGET_BUILD_DIR:-}" && -n "${INFOPLIST_PATH:-}" ]]; then
    plist="$TARGET_BUILD_DIR/$INFOPLIST_PATH"
  fi
  if [[ -z "$plist" || ! -f "$plist" ]]; then
    plist="$TARGET_BUILD_DIR/$WRAPPER_NAME/Info.plist"
  fi

  if [[ ! -f "$plist" ]]; then
    echo " └─ERROR: Runner Info.plist not found for version sync"
    return 1
  fi

  local bundle_label="${TARGET_NAME:-Runner}"
  echo " └─Syncing $bundle_label version $FLUTTER_BUILD_NAME ($FLUTTER_BUILD_NUMBER)"
  SetPlistString "$plist" CFBundleShortVersionString "$FLUTTER_BUILD_NAME"
  SetPlistString "$plist" CFBundleVersion "$FLUTTER_BUILD_NUMBER"
  ValidatePlistVersion "$plist" "$bundle_label"

  local top_shelf_plist="$TARGET_BUILD_DIR/$WRAPPER_NAME/PlugIns/TopShelfExtension.appex/Info.plist"
  if [[ -f "$top_shelf_plist" ]]; then
    echo " └─Syncing TopShelfExtension version $FLUTTER_BUILD_NAME ($FLUTTER_BUILD_NUMBER)"
    SetPlistString "$top_shelf_plist" CFBundleShortVersionString "$FLUTTER_BUILD_NAME"
    SetPlistString "$top_shelf_plist" CFBundleVersion "$FLUTTER_BUILD_NUMBER"
    ValidatePlistVersion "$top_shelf_plist" "TopShelfExtension"
  fi

  EmbedFlutterFrameworks
}

EngineOutputExists() {
  local variant="$1"
  [[ -d "$FLUTTER_LOCAL_ENGINE/out/$variant" ]]
}

ResolveEngineOutput() {
  local variant
  for variant in "$@"; do
    local candidate="$FLUTTER_LOCAL_ENGINE/out/$variant"
    if [[ -d "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  echo " └─ERROR: none of these Flutter engine outputs exist: $*" >&2
  return 1
}

BuildAppDebug() {
  # Host tools (frontend_server, patched SDK, dartaotruntime) ship in
  # host_release for both debug and release consumers — the frontend_server
  # compiles debug kernels regardless of the host build flavor.
  HOST_TOOLS=$FLUTTER_LOCAL_ENGINE/out/host_release
  if [[ "$debug_sim" == "true" ]]; then
    DEVICE_TOOLS=$(ResolveEngineOutput "tvos_debug_sim_unopt$TARGET_POSTFIX" "tvos_debug_sim_unopt_arm64" "tvos_debug_sim_unopt") || return 1
  else
    # Device build is always arm64; gn outputs `tvos_debug_unopt` without suffix.
    DEVICE_TOOLS=$(ResolveEngineOutput "tvos_debug_unopt") || return 1
  fi

  ROOTDIR=$(dirname "$PROJECT_DIR")
  OUTDIR=$ROOTDIR/build/ios/Release-iphoneos
  mkdir -p $OUTDIR
  echo " └─OUTDIR: $OUTDIR"
  echo " └─BUILT_PRODUCTS_DIR: $BUILT_PRODUCTS_DIR"
 

  echo " └─Copying Flutter.framework"
  rm -rf "$OUTDIR/Flutter.framework"
  cp -R "$DEVICE_TOOLS/Flutter.framework" "$OUTDIR"
  # The engine tarball's Flutter.framework/Info.plist declares MinimumOSVersion
  # 13.0 but the binary is linked with the resolved deployment target. Apple's
  # validator compares both against the host app, so keep the plist aligned.
  plutil -replace MinimumOSVersion -string "$TVOS_DEPLOYMENT_TARGET" "$OUTDIR/Flutter.framework/Info.plist"


  tvos_deployment_target="$TVOS_DEPLOYMENT_TARGET"

  echo " └─Generate flutter_assets via flutter build bundle"
  mkdir -p "$OUTDIR/App.framework/flutter_assets"
  # Resolve the flutter CLI: prefer FLUTTER_ROOT from Generated.xcconfig, else
  # fall back to the `flutter` on PATH.
  FLUTTER_BIN=""
  if [ -n "$FLUTTER_ROOT" ] && [ -x "$FLUTTER_ROOT/bin/flutter" ]; then
    FLUTTER_BIN="$FLUTTER_ROOT/bin/flutter"
  elif command -v flutter >/dev/null 2>&1; then
    FLUTTER_BIN="$(command -v flutter)"
  fi

  if [ -z "$FLUTTER_BIN" ]; then
    echo " └─ERROR: flutter CLI not found (set FLUTTER_ROOT or add flutter to PATH)"
    return 1
  fi

  # flutter build bundle produces: AssetManifest, FontManifest, NOTICES,
  # shaders, fonts, assets, packages, plus a kernel_blob.bin and
  # isolate_snapshot_data compiled against the stock flutter engine. We
  # overwrite kernel_blob.bin and both snapshot blobs below with versions
  # from our tvOS engine so the tvOS VM can load them.
  (
    cd "$FLUTTER_APPLICATION_PATH" && \
    "$FLUTTER_BIN" build bundle \
      --asset-dir="$OUTDIR/App.framework/flutter_assets" \
      --no-tree-shake-icons \
      --suppress-analytics
  ) || {
    echo " └─ERROR: flutter build bundle failed"
    return 1
  }

  echo " └─Compiling tvOS kernel via local engine frontend_server"
  FRONTEND_SERVER="$HOST_TOOLS/dart-sdk/bin/snapshots/frontend_server_aot.dart.snapshot"
  if [ ! -f "$FRONTEND_SERVER" ]; then
    FRONTEND_SERVER="$HOST_TOOLS/gen/frontend_server_aot.dart.snapshot"
  fi
  "$HOST_TOOLS/dart-sdk/bin/dartaotruntime" \
    "$FRONTEND_SERVER" \
    --sdk-root "$HOST_TOOLS/flutter_patched_sdk" \
    --tfa --target=flutter \
    -DTVOS_BUILD=true \
    --output-dill "$OUTDIR/App.framework/flutter_assets/kernel_blob.bin" \
    "$FLUTTER_APPLICATION_PATH/lib/main.dart"

  echo " └─Copying tvOS VM + isolate snapshots (pure JIT, no gen_snapshot)"
  cp "$DEVICE_TOOLS/gen/flutter/lib/snapshot/vm_isolate_snapshot.bin" \
     "$OUTDIR/App.framework/flutter_assets/vm_snapshot_data"
  cp "$DEVICE_TOOLS/gen/flutter/lib/snapshot/isolate_snapshot.bin" \
     "$OUTDIR/App.framework/flutter_assets/isolate_snapshot_data"


  if [[ "$debug_sim" == "true" ]]; then
    SYSROOT=$(xcrun --sdk appletvsimulator --show-sdk-path)
  else
    SYSROOT=$(xcrun --sdk appletvos --show-sdk-path)
  fi

  echo " └─Creating stub App using $SYSROOT"


  if [[ "$debug_sim" == "true" ]]; then
    echo "static const int Moo = 88;" | xcrun clang -x c \
      -arch $SIM_ARCH \
      -L"$SYSROOT/usr/lib" \
      -isysroot "$SYSROOT" \
      -mappletvsimulator-version-min=$tvos_deployment_target \
      -dynamiclib \
      -Xlinker -rpath -Xlinker '@executable_path/Frameworks' \
      -Xlinker -rpath -Xlinker '@loader_path/Frameworks' \
      -install_name '@rpath/App.framework/App' \
      -o "$OUTDIR/App.framework/App" -

  else
    echo "static const int Moo = 88;" | xcrun clang -x c \
      -arch arm64 \
      -isysroot "$SYSROOT" \
      -mtvos-version-min=$tvos_deployment_target \
      -dynamiclib \
      -Xlinker -rpath -Xlinker '@executable_path/Frameworks' \
      -Xlinker -rpath -Xlinker '@loader_path/Frameworks' \
      -install_name '@rpath/App.framework/App' \
      -o "$OUTDIR/App.framework/App" -
  fi

  strip "$OUTDIR/App.framework/App"

  echo " └─copy frameworks"
  CopyAppFrameworkInfoPlist "$OUTDIR/App.framework/Info.plist" "$tvos_deployment_target"

  # Two destinations:
  # 1. BUILT_PRODUCTS_DIR — Swift/linker search path. For plain builds this
  #    equals TARGET_BUILD_DIR; for Archive it differs.
  # 2. $TARGET_BUILD_DIR/$WRAPPER_NAME/Frameworks — embedded into Runner.app
  #    so @rpath resolves at runtime.
  #
  # DO NOT drop frameworks flat into TARGET_BUILD_DIR. During archive that's
  # Products/Applications/ — sibling to Runner.app — and extra framework
  # bundles there make Organizer classify the archive as "Other Items".
  mkdir -p "$BUILT_PRODUCTS_DIR"
  rm -rf "$BUILT_PRODUCTS_DIR/App.framework" "$BUILT_PRODUCTS_DIR/Flutter.framework"
  cp -R "${OUTDIR}/"{App.framework,Flutter.framework} "$BUILT_PRODUCTS_DIR"

  APP_FRAMEWORKS_DIR="$TARGET_BUILD_DIR/$WRAPPER_NAME/Frameworks"
  mkdir -p "$APP_FRAMEWORKS_DIR"
  rm -rf "$APP_FRAMEWORKS_DIR/App.framework" "$APP_FRAMEWORKS_DIR/Flutter.framework"
  cp -R "${OUTDIR}/"{App.framework,Flutter.framework} "$APP_FRAMEWORKS_DIR"

  # Sign the embedded frameworks. Skip when signing is disabled. Xcode's
  # later CodeSign phase re-signs the full app anyway.
  echo " └─Sign"
  if [[ "$debug_sim" != "true" && -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" && "${CODE_SIGNING_ALLOWED:-YES}" != "NO" ]]; then
    codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" -- "${BUILT_PRODUCTS_DIR}/App.framework/App"
    codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" -- "${BUILT_PRODUCTS_DIR}/Flutter.framework/Flutter"
    codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" -- "${APP_FRAMEWORKS_DIR}/App.framework/App"
    codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" -- "${APP_FRAMEWORKS_DIR}/Flutter.framework/Flutter"
  else
    echo "   (skipped — no code sign identity or signing disabled)"
  fi

  echo " └─Done"

  return 0
}


BuildAppRelease() {
  HOST_TOOLS=$FLUTTER_LOCAL_ENGINE/out/host_release
  DEVICE_TOOLS=$FLUTTER_LOCAL_ENGINE/out/tvos_release

  # Locate gen_snapshot. Use the cross-compile variant that targets iOS/tvOS
  # arm64 (emits arm64-ios assembly). The plain host gen_snapshot targets
  # macOS and its snapshots are rejected at runtime by the iOS/tvOS VM.
  GEN_SNAPSHOT=""
  for cand in \
      "$DEVICE_TOOLS/artifacts_arm64/gen_snapshot_arm64" \
      "$DEVICE_TOOLS/universal/gen_snapshot_arm64" \
      "$DEVICE_TOOLS/artifacts_x64/gen_snapshot_arm64" \
      "$DEVICE_TOOLS/gen_snapshot_arm64"; do
    if [ -x "$cand" ]; then
      GEN_SNAPSHOT="$cand"
      break
    fi
  done
  if [ -z "$GEN_SNAPSHOT" ]; then
    echo " └─ERROR: gen_snapshot not found under $DEVICE_TOOLS or $HOST_TOOLS"
    return 1
  fi

  ROOTDIR=$(dirname "$PROJECT_DIR")
  OUTDIR=$ROOTDIR/build/ios/Release-iphoneos
  mkdir -p "$OUTDIR"

  echo " └─OUTDIR: $OUTDIR"
  echo " └─gen_snapshot: $GEN_SNAPSHOT"

  echo " └─Copying Flutter.framework"
  rm -rf "$OUTDIR/Flutter.framework"
  cp -R "$DEVICE_TOOLS/Flutter.framework" "$OUTDIR"
  # The engine tarball's Flutter.framework/Info.plist declares MinimumOSVersion
  # 13.0 but the binary is linked with the resolved deployment target. Apple's
  # validator compares both against the host app, so keep the plist aligned.
  plutil -replace MinimumOSVersion -string "$TVOS_DEPLOYMENT_TARGET" "$OUTDIR/Flutter.framework/Info.plist"

  tvos_deployment_target="$TVOS_DEPLOYMENT_TARGET"

  # Resolve flutter CLI.
  FLUTTER_BIN=""
  if [ -n "$FLUTTER_ROOT" ] && [ -x "$FLUTTER_ROOT/bin/flutter" ]; then
    FLUTTER_BIN="$FLUTTER_ROOT/bin/flutter"
  elif command -v flutter >/dev/null 2>&1; then
    FLUTTER_BIN="$(command -v flutter)"
  fi
  if [ -z "$FLUTTER_BIN" ]; then
    echo " └─ERROR: flutter CLI not found (set FLUTTER_ROOT or add flutter to PATH)"
    return 1
  fi

  echo " └─Generate flutter_assets via flutter build bundle (release)"
  mkdir -p "$OUTDIR/App.framework/flutter_assets"
  (
    cd "$FLUTTER_APPLICATION_PATH" && \
    "$FLUTTER_BIN" build bundle \
      --release \
      --asset-dir="$OUTDIR/App.framework/flutter_assets" \
      --no-tree-shake-icons \
      --suppress-analytics
  ) || {
    echo " └─ERROR: flutter build bundle failed"
    return 1
  }
  # AOT builds don't need kernel_blob.bin in flutter_assets — the compiled
  # arm64 code lives in App.framework/App itself.
  rm -f "$OUTDIR/App.framework/flutter_assets/kernel_blob.bin"

  echo " └─Compiling AOT kernel via local engine frontend_server"
  # The snapshot under dart-sdk/bin/snapshots/ is the actual AOT-compiled one;
  # the one under gen/ is a stale/placeholder kernel.
  FRONTEND_SERVER="$HOST_TOOLS/dart-sdk/bin/snapshots/frontend_server_aot.dart.snapshot"
  if [ ! -f "$FRONTEND_SERVER" ]; then
    FRONTEND_SERVER="$HOST_TOOLS/gen/frontend_server_aot.dart.snapshot"
  fi
  "$HOST_TOOLS/dart-sdk/bin/dartaotruntime" \
    "$FRONTEND_SERVER" \
    --sdk-root "$HOST_TOOLS/flutter_patched_sdk" \
    --aot --tfa --target=flutter \
    -Ddart.vm.product=true \
    -Ddart.vm.profile=false \
    -DFLUTTER_BUILD_MODE=release \
    -DTARGET_PLATFORM=TVOS \
    -DTVOS_BUILD=true \
    --output-dill "$OUTDIR/app.dill" \
    "$FLUTTER_APPLICATION_PATH/lib/main.dart"

  echo " └─Compiling AOT Assembly"
  "$GEN_SNAPSHOT" \
    --deterministic \
    --snapshot_kind=app-aot-assembly \
    --assembly="$OUTDIR/snapshot_assembly.S" \
    --strip \
    "$OUTDIR/app.dill"

  echo " └─Compiling Assembly"
  SYSROOT=$(xcrun --sdk appletvos --show-sdk-path)
  cc -arch arm64 \
    -isysroot "$SYSROOT" \
    -mtvos-version-min=$tvos_deployment_target \
    -c "$OUTDIR/snapshot_assembly.S" \
    -o "$OUTDIR/snapshot_assembly.o"

  echo " └─Linking app"
  clang -arch arm64 \
    -isysroot "$SYSROOT" \
    -mtvos-version-min=$tvos_deployment_target \
    -dynamiclib \
    -Xlinker -rpath -Xlinker @executable_path/Frameworks \
    -Xlinker -rpath -Xlinker @loader_path/Frameworks \
    -install_name @rpath/App.framework/App \
    -o "$OUTDIR/App.framework/App" \
    "$OUTDIR/snapshot_assembly.o"

  strip "$OUTDIR/App.framework/App"

  CopyAppFrameworkInfoPlist "$OUTDIR/App.framework/Info.plist" "$tvos_deployment_target"

  echo " └─copy frameworks"
  # BUILT_PRODUCTS_DIR = linker search path. DO NOT use TARGET_BUILD_DIR
  # flat — during archive that's Products/Applications/ and loose framework
  # bundles next to Runner.app make Xcode classify the archive as "Other".
  mkdir -p "$BUILT_PRODUCTS_DIR"
  rm -rf "$BUILT_PRODUCTS_DIR/App.framework" "$BUILT_PRODUCTS_DIR/Flutter.framework"
  cp -R "${OUTDIR}/"{App.framework,Flutter.framework} "$BUILT_PRODUCTS_DIR"

  APP_FRAMEWORKS_DIR="$TARGET_BUILD_DIR/$WRAPPER_NAME/Frameworks"
  mkdir -p "$APP_FRAMEWORKS_DIR"
  rm -rf "$APP_FRAMEWORKS_DIR/App.framework" "$APP_FRAMEWORKS_DIR/Flutter.framework"
  cp -R "${OUTDIR}/"{App.framework,Flutter.framework} "$APP_FRAMEWORKS_DIR"

  echo " └─Sign"
  if [[ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" && "${CODE_SIGNING_ALLOWED:-YES}" != "NO" ]]; then
    codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" -- "${BUILT_PRODUCTS_DIR}/App.framework/App"
    codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" -- "${BUILT_PRODUCTS_DIR}/Flutter.framework/Flutter"
    codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" -- "${APP_FRAMEWORKS_DIR}/App.framework/App"
    codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" -- "${APP_FRAMEWORKS_DIR}/Flutter.framework/Flutter"
  else
    echo "   (skipped — no code sign identity or signing disabled)"
  fi

  echo " └─Done"

  return 0
}


BuildApp() {
  ReadPubspecVersion

  local build_mode="$(echo "${FLUTTER_BUILD_MODE:-${CONFIGURATION}}" | tr "[:upper:]" "[:lower:]")"

  echo "Compiling Flutter/App.Framework"
  echo " └─version $FLUTTER_BUILD_NAME ($FLUTTER_BUILD_NUMBER)"

  if [ -z "$FLUTTER_LOCAL_ENGINE" ]; then
    echo " └─ERROR: FLUTTER_LOCAL_ENGINE not set!" 
    return 1;
  fi

  echo " └─engine $FLUTTER_LOCAL_ENGINE"


  if [[ "$PLATFORM_NAME" == "appletvsimulator" ]]; then
    debug_sim="true"
    if [[ ! "$build_mode" =~ "debug" ]]; then
      echo " └─simulator builds use the debug simulator engine"
    fi
    BuildAppDebug
  elif [[ "$build_mode" =~ "debug" ]]; then
    if EngineOutputExists "tvos_debug_unopt"; then
      BuildAppDebug
    else
      echo " └─debug tvOS device engine not found; building release Flutter app"
      BuildAppRelease
    fi
  elif [[ "$build_mode" =~ "release" ]]; then
    # release/archive   (archive: build mode == "release" && ${ACTION} == "install")
    BuildAppRelease
  else
    echo " └─ERROR: unknown target: ${build_mode}" 
    return 1;
  fi

  return 0
}


# Main entry point.
if [[ $# == 0 ]]; then
  # Backwards-compatibility: if no args are provided, build and embed.
  BuildApp
  EmbedFlutterFrameworks
else
  case $1 in
    "build")
      BuildApp ;;
    "sync_version")
      SyncRunnerVersion ;;
#   "embed_and_thin")
#       "Not needed, used from flutter xcode_backend.sh script"
  esac
fi
