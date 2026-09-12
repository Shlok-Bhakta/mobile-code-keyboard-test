# AGENTS.md

## Auto-build + Autoloader rule (always on)

After every code change the user asks for:

1. Build a fresh unsigned Release IPA from the current working tree:
   ```
   xcodebuild -project MobileEditor.xcodeproj -scheme MobileEditor -configuration Release -sdk iphoneos -derivedDataPath /tmp/ME-build CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" DEVELOPMENT_TEAM=""
   rm -rf /tmp/ME-payload && mkdir -p /tmp/ME-payload/Payload
   cp -R /tmp/ME-build/Build/Products/Release-iphoneos/MobileEditor.app /tmp/ME-payload/Payload/
   ditto -c -k --keepParent /tmp/ME-payload/Payload /tmp/MobileEditor-baseline.ipa
   ```
2. Publish it on the rolling `baseline` GitHub pre-release (do NOT use Planista for IPAs — save that space):
   ```
   gh release view baseline >/dev/null 2>&1 || gh release create baseline --prerelease --title baseline --notes "Rolling on-device baseline build."
   gh release upload baseline /tmp/MobileEditor-baseline.ipa --clobber
   ```
   The stable asset URL is:
   `https://github.com/Shlok-Bhakta/mobile-code-keyboard-test/releases/download/baseline/MobileEditor.ipa`
3. Reply with all three Autoloader forms (percent-encode the IPA URL with `quote(url, safe="")`):
   - `autoloader://install?url=<ENCODED_IPA_URL>`
   - `https://marginally-better-apps.github.io/Autoloader/?url=<ENCODED_IPA_URL>` (tappable shim for chat/GitHub — GitHub markdown won't link `autoloader://` directly)
   - Raw IPA URL for reference.

Do this automatically, without being asked again. Build must succeed before replying. `dist/` and `*.ipa` are gitignored — don't commit IPAs.
