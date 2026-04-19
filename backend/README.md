# Couch backend

Node.js services that power the LiveKit-based Couch session flow.

## What lives here

| Surface | Codepath | Responsibility |
|---|---|---|
| Token server | `src/token-server.ts` | Authenticates the iOS app, validates the requested scenario, mints a LiveKit participant token, and returns session metadata the client uses to decide whether to expect avatar video. |
| LiveKit agent | `src/agent.ts` | Registers as `couch-marcus-agent`, starts the LemonSlice avatar when configured, then starts the voice agent session that handles STT, LLM, and TTS. |
| Scenario config | `src/config/scenarios.ts` | Backend source of truth for scenario id, agent dispatch name, persona prompt, and avatar provider wiring. |
| Env contract | `src/config/env.ts` | Validates runtime configuration with Zod and applies defaults for ports, logging, avatar flags, and startup timeouts. |

For the higher-level architecture, see [`docs/avatar-architecture.md`](../docs/avatar-architecture.md).

## Public interface

### `GET /healthz`

Simple health probe for local checks and deploy health checks.

Response:

```json
{ "ok": true }
```

### `POST /v1/sessions/token`

Mints a LiveKit participant token for one Couch session.

Headers:

- `Content-Type: application/json`
- `X-Couch-Auth: <COUCH_API_SHARED_SECRET>`

Request body:

```json
{
  "scenarioId": "marcus-intake",
  "mode": "voice",
  "participantName": "Student",
  "participantIdentity": "student-ab12cd34ef56"
}
```

Constraints:

- `scenarioId` must exist in `src/config/scenarios.ts`.
- `mode` must be `voice` or `text`.
- `participantName` is optional and capped at 64 chars.
- `participantIdentity` is optional and capped at 128 chars.
- A bad shared secret returns `401`.
- An unknown scenario returns `404`.

Successful response shape:

```json
{
  "serverUrl": "wss://your-project.livekit.cloud",
  "participantToken": "<jwt>",
  "room": "couch-marcus-0123abcd",
  "participantIdentity": "student-ab12cd34ef56",
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

The iOS client consumes this via `Couch/Services/Session/LiveKitTokenClient.swift`.

## Runtime behavior

### Session startup

1. The iOS app posts `scenarioId`, `mode`, and a stable per-install participant identity to `/v1/sessions/token`.
2. The token server authenticates the request with `X-Couch-Auth`, validates the scenario, and embeds dispatch metadata for the agent in the LiveKit room config.
3. The client joins the LiveKit room with the returned token.
4. The LiveKit agent reads the dispatch metadata, resolves the scenario prompt, and tries to start the LemonSlice avatar.
5. If the avatar joins in time, the iOS app subscribes to the remote video track and crossfades from the static portrait to live video.
6. If the avatar is unavailable, the room still becomes live and the app keeps showing the static portrait with an audio-only hint.

### Mode semantics

- `voice`: the iOS client enables the local microphone after connecting.
- `text`: the iOS client keeps the mic off and publishes typed input on the `lk.chat` data topic instead.

### Avatar fallback ladder

The backend is intentionally tolerant of avatar failures:

- `COUCH_AVATARS_ENABLED=false` disables avatars globally.
- `COUCH_AVATAR_PROVIDER=none` forces audio-only mode.
- Missing LemonSlice credentials or identity data disable avatars without failing the session.
- Avatar startup timeout is controlled by `COUCH_AVATAR_START_TIMEOUT_SECONDS`.
- Even after an avatar failure, the voice session continues.

## Local setup

### 1. Install dependencies

```sh
cd backend
npm install
```

### 2. Configure environment

```sh
cp .env.example .env
```

Required values:

| Variable | Required | Notes |
|---|---|---|
| `LIVEKIT_URL` | Yes | LiveKit Cloud websocket URL. |
| `LIVEKIT_API_KEY` | Yes | Used to mint participant tokens. |
| `LIVEKIT_API_SECRET` | Yes | Used to sign participant tokens. |
| `COUCH_API_SHARED_SECRET` | Yes | Must match the iOS `COUCH_BACKEND_SHARED_SECRET`. |
| `OPENAI_API_KEY` | Yes | Required by the agent for STT and LLM. |
| `ELEVENLABS_API_KEY` | No | If unset, TTS falls back to OpenAI. |
| `ELEVENLABS_MARCUS_VOICE_ID` | No | Optional Marcus voice override. |
| `COUCH_AVATARS_ENABLED` | No | Defaults to `true`. |
| `COUCH_AVATAR_PROVIDER` | No | `lemonslice` or `none`; defaults to `lemonslice`. |
| `LEMONSLICE_API_KEY` | No | Required only for live avatar video. |
| `MARCUS_LEMONSLICE_AGENT_ID` | No | Preferred LemonSlice identity for Marcus. |
| `MARCUS_LEMONSLICE_IMAGE_URL` | No | Used only if no LemonSlice agent id is set. |
| `COUCH_AVATAR_START_TIMEOUT_SECONDS` | No | Defaults to `8`. |
| `TOKEN_SERVER_PORT` | No | Defaults to `8787`. |
| `LOG_LEVEL` | No | Defaults to `info`. |

### 3. Run the services

Terminal 1:

```sh
cd backend
npm run token-server
```

Terminal 2:

```sh
cd backend
npm run agent
```

Useful alternates:

- `npm run build` - compile TypeScript into `dist/`
- `npm run lint` - typecheck the backend
- `npm run test` - run the backend tests
- `npm run agent:prod` - production-style agent entrypoint

### 4. Point the iOS app at the backend

Add these keys to `Couch/Secrets.plist`:

```plist
COUCH_LIVEKIT_ENABLED = YES
COUCH_AVATARS_ENABLED = YES
COUCH_BACKEND_URL = http://localhost:8787
COUCH_BACKEND_SHARED_SECRET = <same value as backend/.env>
```

Notes:

- `COUCH_LIVEKIT_ENABLED` is the transport switch. If it is off, the app falls back to the legacy direct ElevenLabs driver.
- `COUCH_AVATARS_ENABLED` controls whether the iOS stage tries to render remote video. You can keep LiveKit on and set this to `NO` for audio-only sessions.
- The app still needs `OPENAI_API_KEY` locally for the debrief flow, because post-session debrief generation remains on-device.

## Quick checks

Check the token server:

```sh
curl http://localhost:8787/healthz
```

Request a token:

```sh
curl -X POST http://localhost:8787/v1/sessions/token \
  -H 'Content-Type: application/json' \
  -H 'X-Couch-Auth: change-me-to-a-long-random-string' \
  -d '{"scenarioId":"marcus-intake","mode":"voice","participantName":"Student"}'
```

If this returns `serverUrl`, `participantToken`, and `session.avatar`, the client-side LiveKit setup is usually the next place to investigate.

## Troubleshooting

### `401 unauthorized` from `/v1/sessions/token`

- Cause: `X-Couch-Auth` does not match `COUCH_API_SHARED_SECRET`.
- Check: compare backend `.env` with iOS `COUCH_BACKEND_SHARED_SECRET`.
- Fix: update one side so they match, then relaunch the app.

### `404 unknown_scenario` from `/v1/sessions/token`

- Cause: the app requested a scenario id not present in `src/config/scenarios.ts`.
- Check: the seeded iOS scenario id and backend scenario config should both be `marcus-intake`.
- Fix: keep scenario ids in sync before adding a new case.

### Sessions connect but stay audio-only

- Cause: avatar support is disabled or underconfigured.
- Check: `COUCH_AVATARS_ENABLED`, `COUCH_AVATAR_PROVIDER`, `LEMONSLICE_API_KEY`, and either `MARCUS_LEMONSLICE_AGENT_ID` or `MARCUS_LEMONSLICE_IMAGE_URL`.
- Expected behavior: audio should still work even when video does not.

### Agent fails during startup with env validation errors

- Cause: a required variable is missing or malformed.
- Check: the aggregated error from `src/config/env.ts`.
- Fix: correct the missing value in `.env`; the process validates config on boot.

### The app falls back to the legacy direct path

- Cause: `COUCH_LIVEKIT_ENABLED` is off in the app, or the backend URL/shared secret is missing on-device.
- Check: `Couch/Services/AppFeatureFlags.swift` and `Couch/Services/Session/LiveKitTokenClient.swift` behavior.
- Fix: enable the flag and set both `COUCH_BACKEND_URL` and `COUCH_BACKEND_SHARED_SECRET` in `Couch/Secrets.plist`.

## Deployment notes

- Token server deploy command: `node dist/token-server.js`
- Agent deploy command: `node dist/agent.js start`
- The token server and agent can be deployed separately.
- LiveKit signing credentials and LemonSlice credentials stay server-side only.
