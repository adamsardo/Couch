# Couch avatar architecture (LiveKit + LemonSlice)

This document describes the realtime session architecture after the LiveKit + LemonSlice migration. It is the implementation of [`PRD: Couch avatar integration via LiveKit + LemonSlice`](../README.md).

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
| LiveKit agent | [`backend/src/agent.ts`](../backend/src/agent.ts) | Registers as `couch-marcus-agent`. Connects to the room, attempts to start the LemonSlice avatar session, then starts the voice session. If the avatar doesn't join within `COUCH_AVATAR_START_TIMEOUT_SECONDS`, continues audio-only. |
| Scenario config | [`backend/src/config/scenarios.ts`](../backend/src/config/scenarios.ts) | Single source of truth for scenario id → persona prompt → agent name → avatar provider identity. Lets us swap LemonSlice agent / image without shipping a client build. |
| iOS driver seam | [`Couch/Services/Session/ConversationDriver.swift`](../Couch/Services/Session/ConversationDriver.swift) | Transport-agnostic interface the session coordinator drives. |
| iOS LiveKit driver | [`Couch/Services/Session/LiveKitConversationDriver.swift`](../Couch/Services/Session/LiveKitConversationDriver.swift) | Fetches the token, connects the room, publishes the mic, forwards transcriptions, and exposes the remote avatar video track. |
| iOS ElevenLabs driver | [`Couch/Services/Session/ElevenLabsConversationDriver.swift`](../Couch/Services/Session/ElevenLabsConversationDriver.swift) | Legacy direct-to-ElevenLabs path, preserved for fallback and rollout. |
| iOS avatar stage | [`Couch/Components/AvatarStageView.swift`](../Couch/Components/AvatarStageView.swift) | Renders the remote video track over the static portrait fallback. |
| Feature flag | [`Couch/Services/AppFeatureFlags.swift`](../Couch/Services/AppFeatureFlags.swift) | `COUCH_LIVEKIT_ENABLED` + `COUCH_AVATARS_ENABLED`, resolved at launch. |

## Fallback ladder (PRD §6.5)

The pipeline is structured so a session never hard-fails because of avatars:

1. Backend agent connects to LiveKit, then tries to start LemonSlice. If the API key is missing or credentials time out, the agent logs a warning and continues audio-only.
2. Token server still reports `session.avatar.enabled = false` when it knows the provider isn't configured; the iOS client uses that signal to show the subtle "Audio-only session" hint instead of waiting for a video that isn't coming.
3. iOS `LiveKitConversationDriver` never requires a video track to mark the session `.live` — it only flips `shouldShowVideoUnavailableHint` and keeps the static `ScenarioPortraitView` on screen.
4. If `COUCH_LIVEKIT_ENABLED` is off (or the backend URL isn't configured), the `SessionCoordinator` falls back to the legacy `ElevenLabsConversationDriver`. No shipped-build change is required.

## Security (PRD §6.9)

- No LiveKit signing key is ever on the device. The iOS client only holds the `COUCH_BACKEND_SHARED_SECRET`, which gates the token endpoint and is rotatable.
- LemonSlice API key lives on the backend only.
- The OpenAI key for the LLM/TTS is also server-side under this architecture, which is a meaningful step toward the App Store blocker called out in the README (on-device OpenAI key not production-safe). The existing on-device OpenAI usage for the debrief flow is unchanged; moving that off-device is tracked separately.

## Deploy targets

- **Token server**: any HTTP host. Default Dockerfile command is `node dist/token-server.js`.
- **Agent**: LiveKit Cloud managed hosting (preferred) or your own container host. Override the Docker command to `node dist/agent.js start`.

## Local dev

```sh
cd backend
cp .env.example .env
# fill in at least LIVEKIT_*, COUCH_API_SHARED_SECRET, OPENAI_API_KEY
npm install
npm run token-server   # terminal 1
npm run agent          # terminal 2 — registers couch-marcus-agent with dev dispatch
```

Then in Xcode set these keys in `Couch/Secrets.plist`:

```
COUCH_LIVEKIT_ENABLED = YES
COUCH_AVATARS_ENABLED = YES
COUCH_BACKEND_URL     = http://localhost:8787
COUCH_BACKEND_SHARED_SECRET = <same value as backend/.env>
```

Run Couch on an iPhone simulator. Start a session — the call screen should show the static Marcus stage during connection, then crossfade to the live LemonSlice avatar once the video track arrives.
