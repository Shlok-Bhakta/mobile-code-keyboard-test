# AGENTS.md

## Gala delivery rule (always on)

After an app code change the user asks for, build and publish the current working tree through Gala Engine:

```sh
~/.local/bin/gala doctor --host local
~/.local/bin/gala build --host local
~/.local/bin/gala publish --host local
```

The executable `ios-build.sh` at the project root builds the unsigned iPhoneOS IPA. Gala signs it on the Mac and serves the current build privately over the tailnet. Report Gala's install page, signed IPA URL, and SHA-256. Confirm that signing and the private HTTPS checks succeed before replying.

The target iPhone needs Tailscale and a provisioning profile that includes it. The user opens the install page in Safari and taps Install. Gala's signed delivery expires after 48 hours; publish again if needed. Keep `.gala/` and `*.ipa` out of Git.
