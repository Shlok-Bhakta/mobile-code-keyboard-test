#!/usr/bin/env bash
set -euo pipefail

: "${GALA_BUILD_DIR:?Gala Engine sets this}"
: "${GALA_ARTIFACT_DIR:?Gala Engine sets this}"

xcodebuild \
  -project MobileEditor.xcodeproj \
  -scheme MobileEditor \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$GALA_BUILD_DIR/DerivedData" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  DEVELOPMENT_TEAM="" \
  build

mkdir -p "$GALA_ARTIFACT_DIR/Payload"
cp -R \
  "$GALA_BUILD_DIR/DerivedData/Build/Products/Release-iphoneos/MobileEditor.app" \
  "$GALA_ARTIFACT_DIR/Payload/"
ditto -c -k --keepParent \
  "$GALA_ARTIFACT_DIR/Payload" \
  "$GALA_ARTIFACT_DIR/MobileEditor-unsigned.ipa"
