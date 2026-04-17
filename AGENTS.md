# AGENTS.md

Guidance for coding agents working in this repository.

## Project Overview

`Couch` is a small iOS SwiftUI app generated with Xcode 26.3.

- App source lives in `Couch/`.
- Unit tests live in `CouchTests/` and use Swift Testing.
- UI tests live in `CouchUITests/` and use XCTest.
- The Xcode project uses file-system synchronized groups for the main source and test folders, so adding Swift files under those folders should not usually require editing `Couch.xcodeproj/project.pbxproj`.
- Current project settings target iPhone and iPad with iOS deployment target 26.2.

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

Use the shared `Couch` scheme unless a task explicitly needs target-level commands.

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
