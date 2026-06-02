#!/bin/sh
set -eu

xcodebuild \
  -project Demo/Demo.xcodeproj \
  -scheme Demo \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/QuickLayoutKitDemoDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
