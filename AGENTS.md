# AGENTS.md

Guidance for coding agents working in this repository.

## Project Overview

`Couch` is a small iOS SwiftUI app generated with Xcode 26.3.

- App source lives in `Couch/`.
- Unit tests live in `CouchTests/` and use Swift Testing.
- UI tests live in `CouchUITests/` and use XCTest.
- The Xcode project uses file-system synchronized groups for the main source and test folders, so adding Swift files under those folders should not usually require editing `Couch.xcodeproj/project.pbxproj`.
- Current project settings target iPhone and iPad. The app target currently declares iOS deployment target 26.0; test targets use 26.2 settings.

## Build And Test

List available simulators before choosing a concrete test destination:

```sh
xcrun simctl list devices available
```

Build the app for the iOS simulator:

```sh
xcodebuild -project Couch.xcodeproj -scheme Couch -destination 'generic/platform=iOS Simulator' build
```

Run tests with an available iPhone simulator:

```sh
xcodebuild -project Couch.xcodeproj -scheme Couch -destination 'platform=iOS Simulator,name=<available iPhone simulator>' test
```

If `xcodebuild` reports that the active developer directory is Command Line Tools instead of full Xcode, prefix the same command with:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -project Couch.xcodeproj -scheme Couch -destination 'generic/platform=iOS Simulator' build
```

For focused verification, run one test target at a time:

```sh
xcodebuild -project Couch.xcodeproj -scheme Couch -destination 'platform=iOS Simulator,name=<available iPhone simulator>' -only-testing:CouchTests test
xcodebuild -project Couch.xcodeproj -scheme Couch -destination 'platform=iOS Simulator,name=<available iPhone simulator>' -only-testing:CouchUITests test
```

`-only-testing` narrows execution, but it still compiles the full app target.

Use the shared `Couch` scheme unless a task explicitly needs target-level commands.

## Backend LiveKit Workflow

The optional LiveKit + LemonSlice backend lives in `backend/`. Use `docs/avatar-architecture.md` for the runtime flow and `backend/.env.example` for local environment keys.

Set up and verify the backend:

```sh
cd backend
npm install
npm run build
npm test
```

Run local LiveKit sessions with the token server and agent in separate terminals:

```sh
cd backend
npm run token-server
```

```sh
cd backend
npm run agent
```

`backend/dist/` and `backend/node_modules/` are generated and ignored. Edit `backend/src/` and rebuild instead of editing generated output.

TODO: `README.md` references `backend/README.md`, but that file is not present in this checkout. Keep backend operating notes in `docs/avatar-architecture.md` until a dedicated backend README exists.

## Release Diagnostics

For App Store orientation issues, inspect generated build settings before archiving:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -project Couch.xcodeproj -scheme Couch -showBuildSettings | rg 'TARGETED_DEVICE_FAMILY|UISupportedInterfaceOrientations'
```

With `TARGETED_DEVICE_FAMILY = "1,2"`, keep explicit iPhone and iPad orientation settings rather than relying on a single plist key. If App Store upload warns about missing symbols for `LiveKitWebRTC.framework`, inspect the SwiftPM binary artifact first; app-target debug-information settings cannot create a dSYM for a packaged binary.

## Coding Guidelines

- Prefer SwiftUI-first implementations and keep views small enough to preview and test.
- Keep app code in `Couch/`; put unit-test-only helpers in `CouchTests/` and UI-test helpers in `CouchUITests/`.
- Use Swift Testing (`@Test`, `#expect`, `#require`) for unit tests.
- Use XCTest APIs for UI tests because the target is already XCTest-based.
- Keep `#Preview` blocks compiling when editing SwiftUI views.
- Avoid introducing new dependencies unless the task clearly needs them.
- Do not hand-edit `project.pbxproj` for routine file additions while synchronized groups are in use.

## Git Hygiene

- Treat unrelated working-tree changes as user work.
- Do not revert or overwrite changes you did not make.
- Keep generated files, derived data, and local machine artifacts out of commits unless explicitly requested.

## External UI/UX skill

The [`userinterface-wiki`](https://github.com/raphaelsalaja/userinterface-wiki) skill is installed globally at `~/.agents/skills/userinterface-wiki/` (152 rules across animation, visual design, typography, laws of UX, etc.). It is written for web, but a transferable subset applies to this SwiftUI app.

- SwiftUI-specific audit and prioritized fix list: [`Couch/docs/userinterface-wiki-audit.md`](Couch/docs/userinterface-wiki-audit.md).
- When animating, theming, or adding interactive surfaces, consult the audit first, then open the relevant `~/.agents/skills/userinterface-wiki/rules/<rule-id>.md` for the rationale before implementing.
- Rules the audit flags as `N/A (web-only)` (CSS pseudo-elements, Web Audio, predictive prefetching) should be ignored for this app.
