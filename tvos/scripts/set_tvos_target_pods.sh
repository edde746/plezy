#!/bin/bash

set -e


# Note: sed tool only works when going in to the actual folder of the package, specifying the direct full path to the project.pbxproj does not work!

cd Pods/Pods.xcodeproj
echo "pathching $PWD/project.pbxproj ..."
find . -name 'project.pbxproj' -print0 | xargs -0 sed -i '' -e 's/TARGETED_DEVICE_FAMILY[[:space:]]=[[:space:]]\"1,2\"/TARGETED_DEVICE_FAMILY = \"3\"/g'
find . -name 'project.pbxproj' -print0 | xargs -0 sed -i '' -e 's/SDKROOT[[:space:]]=[[:space:]]iphoneos/SDKROOT = appletvos/g'
find . -name 'project.pbxproj' -print0 | xargs -0 sed -i '' -e 's/SUPPORTED_PLATFORMS[[:space:]]=[[:space:]]iphoneos/SUPPORTED_PLATFORMS = appletvos/g'
find . -name 'project.pbxproj' -print0 | xargs -0 sed -i '' -e 's/IPHONEOS_DEPLOYMENT_TARGET[[:space:]]=[[:space:]]9.0/TVOS_DEPLOYMENT_TARGET = 13.0/g'
# TODO:  8.0   --> should work with any version!

cd ../..


