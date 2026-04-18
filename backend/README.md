# Couch backend

Small Node.js backend for the Couch iOS app. Two processes, one repo:

- **`token-server`** — authenticated HTTP endpoint that mints LiveKit participant tokens and tells the agent which scenario to dispatch.
- **`agent`** — LiveKit Node.js Agents worker that runs the Marcus persona, drives STT/LLM/TTS, and (when configured) starts a LemonSlice virtual avatar session.

This service is the "small backend" called out in the PRD (§6.6). It does not store sessions — the iOS app still owns local transcript persistence. It only exists to (a) keep LiveKit signing keys off the device, and (b) run the realtime agent.

## Requirements

- Node.js >= 20 (tested on 22)
- A [LiveKit Cloud](https://cloud.livekit.io/) project (or self-hosted server) for room transport
- An OpenAI API key for LLM + STT
- Optional: an ElevenLabs API key to preserve Marcus's voice identity (recommended per PRD §6.3)
- Optional: a LemonSlice API key + either a LemonSlice agent ID or a public image URL for Marcus

## Quick start

```sh
cd backend
cp .env.example .env
# edit .env and fill in at least LIVEKIT_*, COUCH_API_SHARED_SECRET, OPENAI_API_KEY
npm install
npm run token-server   # terminal 1
npm run agent          # terminal 2 (registers as couch-marcus-agent)
```

The iOS client then posts to `POST /v1/sessions/token` with the scenario id. The shared secret goes in the `X-Couch-Auth` header.

## Endpoints

### `POST /v1/sessions/token`

Request body:

```json
{
  "scenarioId": "marcus-intake",
  "mode": "voice",
  "participantName": "Student",
  "participantIdentity": "a stable id, e.g. UserProfile UUID"
}
```

Response:

```json
{
  "serverUrl": "wss://your-project.livekit.cloud",
  "participantToken": "eyJhbGciOi...",
  "room": "couch-marcus-7fa1...",
  "participantIdentity": "student-...",
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

The `session.avatar` block is advisory — it tells the client whether to expect a video track. The actual avatar may still fail to join, in which case the session falls back to audio-only.

### `GET /healthz`

Returns `{ "ok": true }`. Use for Kubernetes / LiveKit Cloud readiness probes.

## Avatar fallback behavior

The agent always tries the full path first: start the LemonSlice avatar, then start the voice session. If the avatar does not join within `COUCH_AVATAR_START_TIMEOUT_SECONDS`, the agent logs a warning and starts the voice session anyway. The iOS client already draws a static `ScenarioPortraitView` whenever no remote video track is subscribed, so this degrades gracefully to audio-only without breaking anything.

## Running tests

```sh
npm test
```

The test suite only exercises the scenario/env resolver — it does not start a real LiveKit process.

## Deployment sketch

The PRD recommends LiveKit Cloud for managed rooms + managed agent hosting. This repo is shaped for that layout:

- Token server runs anywhere that can speak HTTPS (Cloud Run, Fly, Render, Railway, Cloudflare Workers with a small wrapper).
- Agent registers itself via `cli.runApp` and is typically packaged as the container LiveKit Cloud pulls. See [`deploy/agents/quickstart`](https://docs.livekit.io/deploy/agents/quickstart/).

The included Dockerfile builds both entry points. Override the command to switch roles:

```sh
docker run --env-file .env -p 8787:8787 couch-backend node dist/token-server.js
docker run --env-file .env             couch-backend node dist/agent.js start
```
