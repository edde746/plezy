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

BuildAppDebug() {
  # Host tools (frontend_server, patched SDK, dartaotruntime) ship in
  # host_release for both debug and release consumers — the frontend_server
  # compiles debug kernels regardless of the host build flavor.
  HOST_TOOLS=$FLUTTER_LOCAL_ENGINE/out/host_release
  if [[ "$debug_sim" == "true" ]]; then
    DEVICE_TOOLS=$FLUTTER_LOCAL_ENGINE/out/tvos_debug_sim_unopt$TARGET_POSTFIX
  else
    # Device build is always arm64; gn outputs `tvos_debug_unopt` without suffix.
    DEVICE_TOOLS=$FLUTTER_LOCAL_ENGINE/out/tvos_debug_unopt
  fi

  ROOTDIR=$(dirname "$PROJECT_DIR")
  OUTDIR=$ROOTDIR/build/ios/Release-iphoneos
  mkdir -p $OUTDIR
  echo " └─OUTDIR: $OUTDIR"
  echo " └─BUILT_PRODUCTS_DIR: $BUILT_PRODUCTS_DIR"
 

  echo " └─Copying Flutter.framework"
  rm -rf "$OUTDIR/Flutter.framework"
  cp -R "$DEVICE_TOOLS/Flutter.framework" "$OUTDIR"


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
  cp "$PROJECT_DIR/scripts/Info.plist" "$OUTDIR/App.framework/Info.plist"

  # For Archive builds BUILT_PRODUCTS_DIR differs from TARGET_BUILD_DIR:
  # Swift compile looks up frameworks under BUILT_PRODUCTS_DIR, but the
  # embedded copy needs to end up inside TARGET_BUILD_DIR/Runner.app.
  cp -R "${OUTDIR}/"{App.framework,Flutter.framework} "$TARGET_BUILD_DIR"
  if [ -n "${BUILT_PRODUCTS_DIR:-}" ] && [ "$BUILT_PRODUCTS_DIR" != "$TARGET_BUILD_DIR" ]; then
    rm -rf "$BUILT_PRODUCTS_DIR/App.framework" "$BUILT_PRODUCTS_DIR/Flutter.framework"
    cp -R "${OUTDIR}/"{App.framework,Flutter.framework} "$BUILT_PRODUCTS_DIR"
  fi

  # Also embed into Runner.app/Frameworks so the dylib @rpath resolves at launch.
  APP_FRAMEWORKS_DIR="$TARGET_BUILD_DIR/$WRAPPER_NAME/Frameworks"
  mkdir -p "$APP_FRAMEWORKS_DIR"
  rm -rf "$APP_FRAMEWORKS_DIR/App.framework" "$APP_FRAMEWORKS_DIR/Flutter.framework"
  cp -R "${OUTDIR}/"{App.framework,Flutter.framework} "$APP_FRAMEWORKS_DIR"

  # Sign the binaries we moved. Both the flat copy (used by linker/embedder)
  # and the embedded copy inside Runner.app/Frameworks need signatures.
  # Skip when signing is disabled (CODE_SIGNING_ALLOWED=NO, unit-test builds,
  # or sim builds where Xcode doesn't sign frameworks). Xcode's own CodeSign
  # phase will sign the final app + frameworks in proper archive builds.
  echo " └─Sign"
  if [[ "$debug_sim" != "true" && -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" && "${CODE_SIGNING_ALLOWED:-YES}" != "NO" ]]; then
    codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" -- "${TARGET_BUILD_DIR}/App.framework/App"
    codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" -- "${TARGET_BUILD_DIR}/Flutter.framework/Flutter"
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

  cp "$PROJECT_DIR/scripts/Info.plist" "$OUTDIR/App.framework/Info.plist"

  echo " └─copy frameworks"
  # Archive builds point BUILT_PRODUCTS_DIR at a separate products path that
  # Swift compile scans for frameworks — copy there too so downstream
  # compilation in the same target can resolve Flutter.h.
  cp -R "${OUTDIR}/"{App.framework,Flutter.framework} "$TARGET_BUILD_DIR"
  if [ -n "${BUILT_PRODUCTS_DIR:-}" ] && [ "$BUILT_PRODUCTS_DIR" != "$TARGET_BUILD_DIR" ]; then
    rm -rf "$BUILT_PRODUCTS_DIR/App.framework" "$BUILT_PRODUCTS_DIR/Flutter.framework"
    cp -R "${OUTDIR}/"{App.framework,Flutter.framework} "$BUILT_PRODUCTS_DIR"
  fi

  APP_FRAMEWORKS_DIR="$TARGET_BUILD_DIR/$WRAPPER_NAME/Frameworks"
  mkdir -p "$APP_FRAMEWORKS_DIR"
  rm -rf "$APP_FRAMEWORKS_DIR/App.framework" "$APP_FRAMEWORKS_DIR/Flutter.framework"
  cp -R "${OUTDIR}/"{App.framework,Flutter.framework} "$APP_FRAMEWORKS_DIR"

  echo " └─Sign"
  if [[ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" && "${CODE_SIGNING_ALLOWED:-YES}" != "NO" ]]; then
    codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" -- "${TARGET_BUILD_DIR}/App.framework/App"
    codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" -- "${TARGET_BUILD_DIR}/Flutter.framework/Flutter"
    codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" -- "${APP_FRAMEWORKS_DIR}/App.framework/App"
    codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" -- "${APP_FRAMEWORKS_DIR}/Flutter.framework/Flutter"
  else
    echo "   (skipped — no code sign identity or signing disabled)"
  fi

  echo " └─Done"

  return 0
}


BuildApp() {
  
  local build_mode="$(echo "${FLUTTER_BUILD_MODE:-${CONFIGURATION}}" | tr "[:upper:]" "[:lower:]")"
  
  echo "Compiling Flutter/App.Framework"
 
  if [ -z "$FLUTTER_LOCAL_ENGINE" ]; then
    echo " └─ERROR: FLUTTER_LOCAL_ENGINE not set!" 
    return 1;
  fi

  echo " └─engine $FLUTTER_LOCAL_ENGINE"


  if [[ "$PLATFORM_NAME" == "appletvsimulator" && "$build_mode" =~ "debug" ]]; then
    debug_sim="true"
    BuildAppDebug
  elif [[ "$build_mode" =~ "debug" ]]; then
    BuildAppDebug
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
#   "embed_and_thin")
#       "Not needed, used from flutter xcode_backend.sh script"
  esac
fi
