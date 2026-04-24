#!/usr/bin/env bash
set -euo pipefail

PROJECT="Couch.xcodeproj"
SCHEME="Couch"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5}"
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}"
export DEVELOPER_DIR

if [[ "$(xcode-select -p 2>/dev/null || true)" == "/Library/Developer/CommandLineTools" ]]; then
  echo "Using DEVELOPER_DIR=$DEVELOPER_DIR because xcode-select points at Command Line Tools."
fi

settings="$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings)"

grep -q "PRODUCT_BUNDLE_IDENTIFIER = com.adamsardo.Couch" <<<"$settings"
grep -q "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait" <<<"$settings"
grep -q "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad" <<<"$settings"
grep -q "INFOPLIST_KEY_PRIVACY_POLICY_URL = https://adamsardo.com/couch/privacy" <<<"$settings"
grep -q "INFOPLIST_KEY_TERMS_OF_USE_URL = https://adamsardo.com/couch/terms" <<<"$settings"
if grep -E "INFOPLIST_KEY_(PRIVACY_POLICY_URL|TERMS_OF_USE_URL).*example\\.com" <<<"$settings"; then
  echo "Legal links still contain example.com." >&2
  exit 1
fi

xcrun simctl list devices available >/dev/null
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination 'generic/platform=iOS Simulator' build
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "$DESTINATION" -only-testing:CouchTests test
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "$DESTINATION" -only-testing:CouchUITests test
