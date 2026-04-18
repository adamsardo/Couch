# Couch avatar architecture (LiveKit + LemonSlice)

This document is the canonical setup + operator runbook for the LiveKit transport. It covers the Node backend in `backend/`, the iOS transport seam in `Couch/Services/Session/`, and the fallback behavior that keeps sessions usable when avatar infrastructure is unavailable.

## High-level shape

```
Student on Couch iOS
        │
        │  POST /v1/sessions/token     (shared-secret auth)
        ▼
  Couch backend (Node.js)        ── mints LiveKit participant token
        │                        ── dispatches couch-marcus-agent
        ▼
 LiveKit Cloud room
    │       ▲
    │       │ publishes audio + (optional) avatar video
    │       │
    │       ├─ Node.js LiveKit Agent  (OpenAI LLM + ElevenLabs TTS)
    │       │
    │       └─ LemonSlice avatar worker (joins as avatar participant)
    │
    └── iOS app subscribes audio + remote video track
```

## Runtime components

| Component | Code | Responsibility |
|---|---|---|
| Token server | [`backend/src/token-server.ts`](../backend/src/token-server.ts) | Authenticates the client, mints a LiveKit token, writes dispatch metadata for the agent, and tells the client whether to expect avatar video. |
| LiveKit agent | [`backend/src/agent.ts`](../backend/src/agent.ts) | Registers as `couch-marcus-agent`. Starts the LemonSlice avatar session first, then starts the voice session. If the avatar doesn't join within `COUCH_AVATAR_START_TIMEOUT_SECONDS`, continues audio-only. |
| Scenario config | [`backend/src/config/scenarios.ts`](../backend/src/config/scenarios.ts) | Single source of truth for scenario id → persona prompt → agent name → avatar provider identity. Lets us swap LemonSlice agent / image without shipping a client build. |
| iOS driver seam | [`Couch/Services/Session/ConversationDriver.swift`](../Couch/Services/Session/ConversationDriver.swift) | Transport-agnostic interface the session coordinator drives. |
| iOS LiveKit driver | [`Couch/Services/Session/LiveKitConversationDriver.swift`](../Couch/Services/Session/LiveKitConversationDriver.swift) | Fetches the token, connects the room, publishes the mic, forwards transcriptions, and exposes the remote avatar video track. |
| iOS ElevenLabs driver | [`Couch/Services/Session/ElevenLabsConversationDriver.swift`](../Couch/Services/Session/ElevenLabsConversationDriver.swift) | Legacy direct-to-ElevenLabs path, preserved for fallback and rollout. |
| iOS avatar stage | [`Couch/Components/AvatarStageView.swift`](../Couch/Components/AvatarStageView.swift) | Renders the remote video track over the static portrait fallback. |
| Feature flag | [`Couch/Services/AppFeatureFlags.swift`](../Couch/Services/AppFeatureFlags.swift) | `COUCH_LIVEKIT_ENABLED` + `COUCH_AVATARS_ENABLED`, resolved at launch. |

## Session contract between app and backend

### Token request

The app posts JSON to `POST /v1/sessions/token`:

```json
{
  "scenarioId": "marcus-intake",
  "participantName": "Student",
  "participantIdentity": "student-abc123def456",
  "mode": "voice"
}
```

Headers:

- `Content-Type: application/json`
- `X-Couch-Auth: <COUCH_BACKEND_SHARED_SECRET>`

Notes:

- `scenarioId` must match `Scenario.id` on the client and `scenarioConfig(id)` on the backend.
- `participantIdentity` is optional in the HTTP schema, but the iOS app currently sends a stable per-install value so backend analytics can correlate reps without accounts.
- `mode` is `voice` or `text`. In text mode the iOS client still joins the LiveKit room, but does not publish the microphone.

### Token response

The token server returns:

```json
{
  "serverUrl": "wss://your-project.livekit.cloud",
  "participantToken": "<jwt>",
  "room": "couch-marcus-0123abcd",
  "participantIdentity": "student-abc123def456",
  "session": {
    "scenarioId": "marcus-intake",
    "mode": "voice",
    "avatar": {
      "enabled": true,
      "provider": "lemonslice",
      "startTimeoutSeconds": 8
    }
  }
}
```

The app uses `session.avatar.enabled` as an operator hint:

- `true`: wait for a remote video track and crossfade onto it when it arrives.
- `false`: stay on the static portrait and surface the subtle audio-only hint immediately.

## Transport selection and rollout

The app does not hardcode LiveKit for every run. `SessionCoordinator` resolves the effective transport once at session start:

1. `AppFeatureFlags.current.liveKitTransportEnabled` gates whether the app is even allowed to use `scenario.transport`.
2. `ScenarioCatalog.marcusScenarioModel()` prefers `.liveKit` for Marcus when that flag is on, otherwise `.elevenLabsDirect`.
3. `SeedData.seedScenarios(in:)` re-syncs the persisted Marcus scenario to the latest flag state on launch, so changing `COUCH_LIVEKIT_ENABLED` affects the next session without a schema migration.
4. Even when the stored scenario says `.liveKit`, `SessionCoordinator` falls back to `.elevenLabsDirect` if `COUCH_BACKEND_URL` or `COUCH_BACKEND_SHARED_SECRET` is missing at launch.

Operationally, this means:

- rollout is a launch-time flag flip, not a code change;
- rollback is also a launch-time flag flip;
- changing flags while the app is already running does not change the in-flight session, because `AppFeatureFlags.current` is cached for the process lifetime.

## Fallback ladder (PRD §6.5)

The pipeline is structured so a session never hard-fails because of avatars:

1. Backend agent tries to start LemonSlice. If the API key is missing or credentials time out, the agent logs a warning and continues audio-only.
2. Token server still reports `session.avatar.enabled = false` when it knows the provider isn't configured; the iOS client uses that signal to show the subtle "Audio-only session" hint instead of waiting for a video that isn't coming.
3. iOS `LiveKitConversationDriver` never requires a video track to mark the session `.live` — it only flips `shouldShowVideoUnavailableHint` and keeps the static `ScenarioPortraitView` on screen.
4. If `COUCH_LIVEKIT_ENABLED` is off (or the backend URL isn't configured), the `SessionCoordinator` falls back to the legacy `ElevenLabsConversationDriver`. No shipped-build change is required.

There are two distinct "audio-only" outcomes to keep in mind:

- **Expected audio-only session**: the room is healthy, but avatars are disabled or unavailable. The session is still live, and the UI keeps the static portrait on stage.
- **Transport failure**: the token request or room connection fails. In that case the app shows the error banner and the session does not become live.

## Security (PRD §6.9)

- No LiveKit signing key is ever on the device. The iOS client only holds the `COUCH_BACKEND_SHARED_SECRET`, which gates the token endpoint and is rotatable.
- LemonSlice API key lives on the backend only.
- The OpenAI key for the LLM/TTS is also server-side under this architecture, which is a meaningful step toward the App Store blocker called out in the README (on-device OpenAI key not production-safe). The existing on-device OpenAI usage for the debrief flow is unchanged; moving that off-device is tracked separately.

## Deploy targets

- **Token server**: any HTTP host. Default Dockerfile command is `node dist/token-server.js`.
- **Agent**: LiveKit Cloud managed hosting (preferred) or your own container host. Override the Docker command to `node dist/agent.js start`.

## Required environment

Start from [`backend/.env.example`](../backend/.env.example).

### Required to boot the backend

| Key | Used by | Why it matters |
|---|---|---|
| `LIVEKIT_URL` | token server + agent | LiveKit Cloud websocket URL returned to the app and used by the worker runtime |
| `LIVEKIT_API_KEY` | token server | Signs participant tokens |
| `LIVEKIT_API_SECRET` | token server | Signs participant tokens |
| `COUCH_API_SHARED_SECRET` | token server | Shared-secret gate for `X-Couch-Auth` |
| `OPENAI_API_KEY` | agent | Powers STT, LLM, and fallback TTS |

### Optional but recommended

| Key | Used by | Behavior when missing |
|---|---|---|
| `ELEVENLABS_API_KEY` | agent | Agent falls back to OpenAI TTS |
| `ELEVENLABS_MARCUS_VOICE_ID` | agent | Default ElevenLabs voice is used if present |
| `COUCH_AVATARS_ENABLED` | agent/backend config | Avatars disabled globally when false |
| `COUCH_AVATAR_PROVIDER` | backend config | `none` disables avatars regardless of other settings |
| `LEMONSLICE_API_KEY` | agent | Avatar startup is skipped and the session runs audio-only |
| `MARCUS_LEMONSLICE_AGENT_ID` or `MARCUS_LEMONSLICE_IMAGE_URL` | agent | If both are missing, Marcus runs audio-only |
| `COUCH_AVATAR_START_TIMEOUT_SECONDS` | agent | Controls how long to wait before falling back to audio-only |
| `TOKEN_SERVER_PORT` | token server | Defaults to `8787` |
| `LOG_LEVEL` | token server + agent | Defaults to `info` |

Important constraints:

- For Marcus, set **either** `MARCUS_LEMONSLICE_AGENT_ID` **or** `MARCUS_LEMONSLICE_IMAGE_URL`. If both are set, the agent ID wins.
- `COUCH_AVATARS_ENABLED=true` on the backend does not force the iOS app to render video by itself; the app still requires `COUCH_AVATARS_ENABLED=YES` in `Couch/Secrets.plist`.
- The app-side `COUCH_BACKEND_SHARED_SECRET` is not a LiveKit credential. Rotating it only affects access to the token endpoint.

## Local dev

```sh
cd backend
cp .env.example .env
# fill in at least LIVEKIT_*, COUCH_API_SHARED_SECRET, OPENAI_API_KEY
npm install
npm run token-server   # terminal 1
npm run agent          # terminal 2 — registers couch-marcus-agent with dev dispatch
```

Useful backend commands:

```sh
npm run build
npm run lint
npm test
```

Then in Xcode set these keys in `Couch/Secrets.plist`:

```
COUCH_LIVEKIT_ENABLED = YES
COUCH_AVATARS_ENABLED = YES
COUCH_BACKEND_URL     = http://localhost:8787
COUCH_BACKEND_SHARED_SECRET = <same value as backend/.env>
```

If you want to exercise the rollback path instead:

```text
COUCH_LIVEKIT_ENABLED = NO
```

Run Couch on an iPhone simulator. Start a session:

1. the call screen should show the static Marcus stage during connection;
2. if avatars are healthy, the stage crossfades to the live LemonSlice video track;
3. if avatars are disabled or time out, the stage stays static and the audio-only hint appears;
4. if the backend is unreachable or unauthorized, the session shows an error instead of becoming live.

## Troubleshooting

### Token request returns 401

- Verify `COUCH_BACKEND_SHARED_SECRET` in `Couch/Secrets.plist` matches `COUCH_API_SHARED_SECRET` in `backend/.env`.
- Confirm `COUCH_BACKEND_URL` points to the token server, not the LiveKit websocket URL.

### Token request returns 404 `unknown_scenario`

- The app sent a `scenarioId` the backend does not know about.
- Check that `Scenario.id` on the client matches the entry in `backend/src/config/scenarios.ts`.

### Agent connects but no avatar ever appears

- Check `COUCH_AVATARS_ENABLED`, `COUCH_AVATAR_PROVIDER`, `LEMONSLICE_API_KEY`, and Marcus's LemonSlice identity in `backend/.env`.
- Confirm the app also has `COUCH_AVATARS_ENABLED = YES`.
- If the session is otherwise live, this is an avatar fallback case, not a transport failure.

### LiveKit is configured but the app still uses ElevenLabs direct transport

- Confirm `COUCH_LIVEKIT_ENABLED = YES` in `Couch/Secrets.plist`.
- Fully relaunch the app after changing flags.
- Make sure both `COUCH_BACKEND_URL` and `COUCH_BACKEND_SHARED_SECRET` are present; otherwise `SessionCoordinator` intentionally falls back before starting the session.
