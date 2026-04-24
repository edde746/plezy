#!/usr/bin/env bash

# based on scripts in /engine/src/flutter/testing/scenario_app
# and xcode_backend.sh script for integration in xcode


# Exit on error
set -e

if [[ $(uname -m) == "arm64" ]]; then
	TARGET_POSTFIX='_arm64'
	CLANG_POSTFIX='_arm64'
else 
	TARGET_POSTFIX=''
	CLANG_POSTFIX='_X86'
fi


if [ -z "$FLUTTER_LOCAL_ENGINE" ]; then
	echo " └─ERROR: FLUTTER_LOCAL_ENGINE not set!"
    return 1;
fi

if [ "$1" == "release" ]; then
	echo "Coping Flutter.framework (release)..."
	DEVICE_TOOLS=$FLUTTER_LOCAL_ENGINE/out/ios_release$TARGET_POSTFIX
elif [[ "$1" == "debug_sim" ]] ; then
	echo "Coping Flutter.framework (debug-simulator)..."
	DEVICE_TOOLS=$FLUTTER_LOCAL_ENGINE/out/ios_debug_sim_unopt$TARGET_POSTFIX
else
	#debug
	echo "Coping Flutter.framework (debug)..."
	DEVICE_TOOLS=$FLUTTER_LOCAL_ENGINE/out/ios_debug_unopt$TARGET_POSTFIX
fi


OUTDIR=$PWD/Flutter

rm -rf "$OUTDIR/Flutter.framework"
cp -R "$DEVICE_TOOLS/Flutter.framework" "$OUTDIR"


