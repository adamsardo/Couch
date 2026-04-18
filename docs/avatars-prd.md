# Avatars for Couch — provider research and proposal

**Status:** Research + PRD draft
**Target release:** Couch V2 (avatar-enabled Marcus)
**Author:** Cursor cloud agent research
**Scope:** Evaluate every LiveKit-supported virtual avatar provider for use inside the existing Couch iOS stack and recommend a path that preserves the ElevenLabs voice, ships without a Python/Node agent worker where possible, and keeps Marcus's persona clinically credible.

---

## 1. Why avatars for Couch

Couch is voice-first by design, but psychology students practising therapy lose a major signal when the patient is literally a photo: facial micro-expressions, eye contact, and affect changes (the "Wall," the forced `[laughs]`, the `[slow]` admissions in Marcus's system prompt) are core clinical cues. Adding a talking head turns Marcus from *a voice* into *a patient you're sitting across from* — which is the product's whole pitch ("practice therapy before it counts").

An avatar must therefore:

1. Lip-sync to ElevenLabs' existing voice, not replace it. Marcus's Eleven v3 Expressive voice is the persona.
2. Be emotionally expressive enough to render the affect cues encoded in the system prompt (guarded → defensive → quieter → shutting down).
3. Look like a specific 28-year-old man, not a stock persona. Ideally cloned from a single reference image so we can match the scenario portrait already shipped in the app.
4. Run with our current "no backend" posture for V1/V2, or the smallest possible backend we can justify.
5. Target sub-second lip-sync latency; anything noticeably lagging breaks the illusion.

---

## 2. Current Couch architecture (the constraint)

```
iOS SwiftUI app  ─────▶  ElevenLabs.startConversation(agentId: MARCUS_AGENT_ID)
                         │  (ElevenLabs Swift SDK — LiveKit under the hood)
                         ▼
                 ElevenLabs-managed LiveKit room
                   • user participant (mic)
                   • `agent` participant (Marcus TTS audio)
```

Key facts that shape every integration choice below:

- **ElevenLabs owns the LiveKit room.** Our app calls `ElevenLabs.startConversation(agentId:)` against a public agent. The SDK mints the LiveKit URL + token internally; there is no public API to pass in a BYO room or to admit a third participant.
- **We do not run a LiveKit Agents worker.** No Python, no Node, no container. `SessionCoordinator` listens to the SDK's Combine streams and persists turns locally via SwiftData.
- **LiveKit transitively ships inside the ElevenLabs SDK.** We already import `LiveKit` in `SessionCoordinator.swift`, so `client-sdk-swift` is available to us at no extra dependency cost.
- **Secrets live on device** (`Couch/Secrets.plist` + Keychain fallback). No auth server, no session minting. The PRD below preserves that posture except where a vendor truly requires a token server, in which case we call it out explicitly.

Consequence: LiveKit's canonical avatar integration model — a Python `AgentSession` hands TTS audio to an avatar worker in the *same* room via `DataStreamAudioOutput` and `lk.publish_on_behalf` — does **not** map to Couch as shipped. Every provider has to be re-evaluated through "how does this work when ElevenLabs already owns the room?"

---

## 3. Provider-by-provider assessment

13 providers reviewed (every vendor on [https://docs.livekit.io/agents/models/avatar.md](https://docs.livekit.io/agents/models/avatar.md)). Each row asks: can we integrate this without a Python/Node worker, without abandoning ElevenLabs Conversational AI, and with a Marcus-specific custom avatar?

### 3.1 Anam — `docs.anam.ai`
- **Integration surface:** Python + Node LiveKit plugin; JS SDK; `POST /v1/auth/session-token` REST for web; Flutter community SDK. No Swift SDK.
- **Audio source:** BYO audio (audio-to-video).
- **Custom avatar:** 1 photo, ready in <2 minutes; up to 10 custom avatars on Professional tier. Best-in-class turnaround.
- **Latency:** Sub-second (marketing), no hard number published.
- **Quality:** Photoreal 2D, emotive face.
- **Pricing:** Free 30 min; $12/$49/$299/$599 tiers; $0.11–$0.16/min; watermark on free/Starter.
- **Clinical posture:** HIPAA + SOC-II, Zero Data Retention on Enterprise, explicit Acceptable Use policy. Strongest of the set for therapy.
- **Fit for Couch:** Good match on persona and policy, but integration still assumes an agent in the room routing audio to the plugin. Without a Node worker we can't drive it from iOS alone. Real option if we accept a thin backend.

### 3.2 Avatario — `avatario.ai`
- **Integration surface:** Python-only LiveKit plugin. No Swift SDK, no Node plugin, REST is video-generation-oriented.
- **Audio source:** Audio-to-video via Python `DataStreamAudioOutput`.
- **Custom avatar:** 1 photo, **12–15 hour** backend processing, strict guidelines (no glasses, tucked hair). Worst turnaround in the set.
- **Latency:** "Ultra-low" (unpublished).
- **Pricing:** Free dev tier; `$0.05/min` PAYG (cheapest bundle price in the set).
- **Clinical posture:** No published HIPAA stance.
- **Fit for Couch:** Eliminated. Requires Python worker and slowest custom-avatar flow.

### 3.3 AvatarTalk — `avatartalk.ai`
- **Integration surface:** Python-only plugin; REST API oriented around per-call video generation.
- **Audio source:** Audio-to-video, but first-frame latency is **~2 s**, the slowest here.
- **Custom avatar:** "On request" only, no self-serve. Japanese male is the plugin default.
- **Pricing:** `$0.05–$0.10/min` bundle. On-prem / air-gapped appliance is a unique option.
- **Fit for Couch:** Eliminated. Too slow for natural turn-taking, and custom-persona flow isn't self-serve.

### 3.4 Beyond Presence (`bey.dev`)
- **Integration surface:** Python + Node plugins. First-class REST (`api.bey.dev/v1`) where the `session` endpoint accepts `livekit_url` + `livekit_token` you supply, so *in principle* you can inject bey into an existing LiveKit room. Vendor explicitly recommends the LiveKit plugin path over the raw endpoint for speech-to-video.
- **Audio source:** Speech-to-Video (S2V) endpoint designed to attach to any voice agent's audio (they cite ElevenLabs, Vapi, Retell as supported upstreams).
- **Custom avatar:** **4–5 min training video + email + consent verification**. No single-photo path. Consent gate is actually a net-positive for a clinical tool.
- **Latency:** **250 ms speech-to-video, ~1 s end-to-end** — fastest *published* figure.
- **Quality:** Top-of-class photoreal realism per third-party comparisons.
- **Pricing:** Credit model; S2V = 50 cr/min, Managed = 100 cr/min. Free 2,000 cr/mo, Starter $49, Growth $149, Scale $349 (drops to ~$0.0875/min S2V at Scale).
- **Fit for Couch:** Strongest "almost iOS-only" candidate. If we mint a LiveKit token for a room the iOS app owns (see §5), bey will join it. But we still need a LiveKit room that *isn't* ElevenLabs-owned, which means replacing the ElevenLabs-managed room or running a Node side-car. Actor/video requirement for custom avatar is a real cost.

### 3.5 bitHuman — `bithuman.ai`
- **Integration surface:** Python-only plugin *and* a CPU-native SDK (Arm/x86, no GPU) aimed at on-device use. No Swift binding today.
- **Audio source:** Audio-to-video. Single-image runtime avatar (`Image.open("marcus.jpg")`).
- **Latency:** **<100 ms** on-device.
- **Pricing:** Not publicly listed (contact sales).
- **Fit for Couch:** Architecturally exciting (the only provider where the avatar could run on the iPhone itself with zero cloud round-trip), but shipping it means porting a Python/C++ SDK to Swift. That's a research project, not a V2 integration. Park as a future option for HIPAA-grade fully-local operation.

### 3.6 D-ID
- **Integration surface:** Python-only LiveKit plugin. D-ID's own Real-Time Streaming API exists but is effectively enterprise-gated.
- **Audio source:** Audio-to-video via plugin; Realtime Agent product bundles its own LLM/TTS which would conflict with ElevenLabs.
- **Custom avatar:** Express (1-min video) on any plan; Premium+ (3-min video, 24 h turnaround) on Pro+. No single-photo → real-time path.
- **Latency:** Not published for the plugin; historically 300–500 ms.
- **Pricing:** Lite/Pro/Advanced bundles with watermark on Lite; real-time streaming ~`$0.012/sec` ≈ `$0.72/min` on enterprise.
- **Fit for Couch:** Eliminated. Needs Python worker + enterprise contract to hit real-time.

### 3.7 Keyframe — `keyframelabs.com`
- **Integration surface:** Python-only plugin.
- **Audio source:** Audio-to-video.
- **Unique win:** Exposes a live **`set_emotion()`** primitive (neutral / happy / sad / angry), registerable as an LLM function tool, on `persona-1.5-live` avatars. This is the single most therapy-relevant primitive across the 13 providers — it maps directly onto Marcus's guarded → defensive → quieter → shutting-down arc.
- **Custom avatar:** Gated behind signup; undocumented publicly.
- **Latency:** Not published.
- **Pricing:** ~`$0.06/min`, limited free tier.
- **Fit for Couch:** Architecturally still Python-plugin-only, so same backend cost as Anam/Avatario. Worth revisiting *after* we have a Python agent in place, specifically because of `set_emotion()`.

### 3.8 LemonSlice — `lemonslice.com`
- **Integration surface:** Python + Node plugin, **plus** a documented REST `POST /api/liveai/sessions` with `transport_type: "livekit"` and a BYO `livekit_url` + `livekit_token` that dispatches the avatar worker into your existing room. The LiveKit-plugin path explicitly *ignores* LemonSlice's own voice/personality config, confirming it lip-syncs to whatever audio is in the room.
- **Audio source:** Any audio on the LiveKit agent track.
- **Custom avatar:** Single-photo clone, ready in seconds. Also supports stylised/cartoon.
- **Latency:** "Real-time," no published number.
- **Pricing:** Credit-based; ~`$0.03–0.10/min` equivalent depending on tier.
- **Fit for Couch:** Same architectural caveat as bey — requires a LiveKit room we control, not ElevenLabs'. But the photo→avatar flow is the fastest self-serve path in the set, which matches the scenario portrait asset we already have.

### 3.9 LiveAvatar (HeyGen) — `heygen.com`
- **Integration surface:** Python LiveKit plugin, **and — critically — ElevenLabs' only officially supported "Conversational AI + live avatar" integration.** ElevenLabs docs describe a "LITE mode" where you:
  1. `POST /v1/secrets` with your ElevenLabs API key → get a `secret_id` (one-time).
  2. `POST /v1/sessions` with `{ mode: "LITE", elevenlabs_agent_config: { secret_id, agent_id }, avatar_id }` → get back a LiveKit URL + token.
  3. Join that room with the **LiveKit Swift SDK**. LiveAvatar dispatches its own worker that talks to your ElevenLabs agent; the avatar's video + ElevenLabs audio show up as tracks in the room. Events (agent state, interruptions) come back through the same LiveKit room.
- **Audio source:** The ElevenLabs agent audio itself, routed by LiveAvatar server-side. We keep every bit of the Marcus Eleven v3 Expressive persona intact.
- **Custom avatar:** HeyGen's studio — "Photo Avatar" from a single image, or "Instant Avatar" from ~2 min of selfie video. Built in HeyGen's dashboard, not via the API.
- **Latency:** Not published; HeyGen marketing claims "real-time two-way." In practice comparable to bey/Simli.
- **Quality:** HeyGen's library is the largest photoreal 2D stock catalogue, and Photo Avatars generally look cleaner than single-shot competitors.
- **Pricing:** LA Credits separate from HeyGen sub — Starter `$19 / 150 LA Credits`, Essential `$100 / 1,000 LA Credits`. LITE mode = 1 credit/min (so `$0.10–$0.13/min` once amortised). ElevenLabs Conv AI minutes billed separately (unchanged from today).
- **Prerequisite:** Marcus agent must be configured with PCM 24 kHz input/output in ElevenLabs voice settings — a five-second dashboard change.
- **Clinical posture:** HeyGen enforces consent/likeness policy for custom avatars; stock avatars are pre-cleared. No HIPAA BAA marketed for LiveAvatar.
- **Fit for Couch:** **Best match by a wide margin for the current architecture.** Only provider where the LiveKit room can be owned by the avatar service *and* still drive the existing ElevenLabs Conversational AI agent end-to-end. Turns the iOS integration into "swap `ElevenLabs.startConversation` for `Room.connect`" plus a single HTTPS call.

### 3.10 Simli — `simli.com`
- **Integration surface:** Python-only LiveKit plugin. **Also** a direct WebRTC API (`/compose/ice`, session endpoint) with a PCM Int16 / 16 kHz / mono data channel.
- **Audio source:** Raw PCM frames, ~6 KB chunks, max 64 KB. You own the audio routing.
- **Custom avatar:** Single photo via dashboard; custom-avatar build "a couple of hours."
- **Latency:** <300 ms speech-to-video (Trinity-1).
- **Pricing:** **<$0.01/min on Trinity-1** (cheapest cloud option across all 13 vendors); free tier 50 min/mo + $10 signup credit.
- **Fit for Couch:** Most interesting "Path C" option — we could leave ElevenLabs Conversational AI exactly as it is on iOS and attach a *parallel* WebRTC peer to Simli, feeding it PCM captured off the ElevenLabs audio track. This is significant custom WebRTC work on iOS (no Swift SDK) and is brittle to ElevenLabs SDK updates, but preserves the "no backend" posture absolutely. Strong fallback if we don't want HeyGen lock-in.

### 3.11 Tavus — `tavus.io`
- **Integration surface:** Python-only LiveKit plugin. Native transport is Daily; LiveKit requires `layers.transport.transport_type: "livekit"` + `pipeline_mode: "echo"` (Tavus renders audio you feed, does not run its own LLM/TTS).
- **Audio source:** Audio-to-video in `echo` mode only; otherwise Tavus insists on its own TTS stack (Cartesia or their ElevenLabs passthrough, which would re-synthesise our Marcus voice).
- **Custom avatar:** `Phoenix-3` — highest-realism model in the industry, but requires **~2 min of consented source video of a real actor**, built in 3–5 h via Tavus's studio. Replica fees `$40–65`.
- **Latency:** ~600 ms utterance-to-utterance, SLA <1 s.
- **Pricing:** Most expensive per minute — Starter `$59 / 100 min` (≈ `$0.32–0.37/min` at overages).
- **Fit for Couch:** Highest visual quality ceiling, but wrong for V2. Custom "Marcus" requires hiring an actor and video production, and the LiveKit path still needs a Python plugin. Park as a premium-tier upgrade path post-V2.

### 3.12 TruGen — `trugen.ai`
- **Integration surface:** Python + Node plugin only. No public REST for direct client join.
- **Audio source:** Audio-to-video via plugin.
- **Latency:** Claims **≤80 ms speech-to-avatar, ≤1 s end-to-end** — fastest on paper (ahead of bey).
- **Pricing:** **`$0.04/min`** base, 30-day free trial.
- **Custom avatar:** "Limited," plan-gated, details not public.
- **Fit for Couch:** Attractive price/latency combo, but the plugin-only integration means we still need a Node worker. No architectural edge over bey/Anam.

### 3.13 Hedra — **deprecated**
- Hedra sunset its Realtime Avatar product on **April 15, 2026**. The LiveKit plugin no longer functions. ElevenLabs' partnership with Hedra is voice-over-for-video, not live agents. Excluded.

### Summary table

| Provider | iOS-client-only viable? | Reuses ElevenLabs voice? | Custom-avatar flow | Price/min | Latency | Clinical-fit signal |
| --- | --- | --- | --- | --- | --- | --- |
| Anam | With Node worker | Yes (BYO audio) | 1 photo, <2 min | `$0.11–$0.16` | sub-1 s (claim) | **HIPAA + SOC-II + ZDR** |
| Avatario | No (Python only) | Via plugin | 1 photo, 12–15 h | `$0.05` | unpublished | Not marketed |
| AvatarTalk | No (Python only) | Via plugin | On request | `$0.05–$0.10` | ~2 s | On-prem option |
| Beyond Presence | Partial (Node + REST w/ BYO token) | Yes (S2V) | 4–5 min video + consent | `$0.09–$0.35` | **250 ms** | Consent gate built-in |
| bitHuman | On-device in theory | Yes | 1 photo at runtime | RFQ | **<100 ms** | Edge / self-host |
| D-ID | No (enterprise real-time) | Via plugin | 1 or 3-min video | `~$0.72` enterprise | 300–500 ms | Generic |
| Keyframe | No (Python only) | Via plugin | Gated | `~$0.06` | unpublished | **`set_emotion()` primitive** |
| LemonSlice | Partial (Node + REST w/ BYO token) | Yes | 1 photo, seconds | `~$0.03–0.10` | "real-time" | Generic |
| **LiveAvatar (HeyGen)** | **Yes — ElevenLabs LITE mode** | **Yes natively** | HeyGen studio (photo or 2-min video) | `~$0.10–$0.13` | "real-time" | Generic |
| Simli | Yes via direct WebRTC (no SDK) | Yes (PCM in) | 1 photo, ~hours | **`<$0.01`** | **<300 ms** | Generic |
| Tavus | No (Python plugin for LiveKit) | Yes in `echo` mode | 2-min consented actor video | `$0.32–0.37` | ~600 ms | Highest realism |
| TruGen | No (Node/Python plugin) | Via plugin | Plan-limited | `$0.04` | ≤80 ms / ≤1 s | Generic |
| Hedra | **Deprecated 2026-04-15** | — | — | — | — | — |

---

## 4. Integration paths for Couch

Three architectural patterns fall out of §3:

### Path A — "HeyGen LiveAvatar LITE" (recommended for V2)

```
iOS SwiftUI app ──► POST /v1/sessions (HeyGen LiveAvatar, LITE mode)
                    └─▶ LiveKit URL + token
iOS SwiftUI app ──► Room.connect(url, token) via LiveKit Swift SDK
                    ├─ publishes user mic
                    ├─ subscribes to `agent` audio track (ElevenLabs Marcus voice)
                    └─ subscribes to avatar worker video track
HeyGen worker ◀───▶ ElevenLabs Conv AI (Marcus public agent)  [server-to-server]
```

- **ElevenLabs stays the brain.** Marcus's prompt, voice, turn-taking, interruption logic, knowledge base — unchanged. We only change *how the room is reached*.
- **Only iOS and one HTTPS call.** The `POST /v1/sessions` call is ~10 lines of `URLSession`; the rest is LiveKit Swift SDK (already transitively present via ElevenLabs).
- **Secret handling.** The one-time `POST /v1/secrets` exchange registers the ElevenLabs API key with HeyGen and returns a `secret_id`. We store that `secret_id` (not the API key) in `Secrets.plist` alongside `MARCUS_AGENT_ID` and a new `HEYGEN_API_KEY`. This keeps the "keys in plist for dev, Keychain for TestFlight" posture we already have.
- **Prerequisite config:** set the Marcus agent's I/O to PCM 24 kHz in the ElevenLabs dashboard — no app changes needed.
- **New costs.** HeyGen LA Credits (`~$0.10–$0.13/min` LITE); ElevenLabs Conv AI minutes unchanged.
- **Known limitations:**
  - LiveAvatar is still in **beta**. Treat it as V2 opt-in, not a forced upgrade.
  - HeyGen does not publish a HIPAA BAA for LiveAvatar. V1 already stated "not for App Store distribution," so this is compatible with our existing posture but should be re-checked before any clinical partner pilot.
  - HeyGen owns Marcus's avatar asset; swapping vendors later means re-creating the avatar in the new vendor's studio.

### Path B — "Own the room, then pick any avatar" (future-proofing)

```
iOS SwiftUI app ──► LiveKit Swift SDK ──► our LiveKit room
Python LiveKit Agents worker ──► joins room as `agent`
  ├─ elevenlabs.STT  (or OpenAI Realtime STT)
  ├─ our LLM loop (or passthrough to ElevenLabs Agents via API)
  ├─ elevenlabs.TTS  (Marcus voice)
  └─ <avatar>.AvatarSession (bey | anam | keyframe | lemonslice | simli | tavus | …)
```

- **Maximum flexibility.** Any of the 13 providers slots in cleanly.
- **Maximum cost.** We take ownership of STT, LLM orchestration, TTS, interruption handling, and tool-call plumbing. We lose ElevenLabs Agents' managed "brain" features (turn-taking heuristics, knowledge-base grounding, tool registry) and have to re-implement them in the worker.
- **Tempting for Keyframe.** `set_emotion()` is the right primitive for Marcus's affect arc. But we'd only justify it once we've already built the worker for other reasons.
- **Deployment.** LiveKit Cloud (or self-hosted SFU) + a Python process. Smallest reasonable footprint is a single container on LiveKit Cloud.

### Path C — "Parallel Simli / Beyond Presence S2V peer, ElevenLabs unchanged"

```
iOS SwiftUI app
  ├─ ElevenLabs.startConversation(agentId:)  [unchanged]
  │    └─ reads conversation.agentAudioTrack (LiveKit AudioTrack)
  │    └─ taps PCM frames, resamples to 16 kHz Int16 mono (Simli) or
  │       forwards raw to bey S2V WebRTC peer
  └─ opens second WebRTC peer to Simli / Beyond Presence, renders returned video
```

- **Preserves the "no backend" posture absolutely.** No cloud functions, no Python.
- **We own a lot of plumbing.** Custom audio tap off a private-ish LiveKit track, PCM conversion, a second WebRTC stack on iOS (neither Simli nor bey ships a Swift SDK), interruption signalling, jitter / drift correction so lip-sync stays tight against what the *user* actually hears from ElevenLabs.
- **Brittle to ElevenLabs SDK changes.** We're reaching inside an SDK abstraction that isn't part of its public API.
- **Cheapest per minute** (<`$0.01/min` on Simli Trinity-1).

---

## 5. Recommendation

### Primary: ship Path A (HeyGen LiveAvatar LITE) as the V2 avatar experience.

Rationale, ordered:

1. **It is the only officially supported "ElevenLabs Conversational AI + live avatar" integration** ([ElevenLabs docs, LiveAvatar integration](https://elevenlabs.io/docs/eleven-agents/guides/integrations/live-avatar)). Every other path requires us to either abandon ElevenLabs Agents or hand-roll WebRTC.
2. **Matches the current architectural posture.** No Python worker, no LiveKit token server we run, no container to deploy. One HTTPS call per session + `Room.connect` on the client. That's the smallest possible delta from the Couch V1 shipping topology.
3. **Keeps the Marcus persona completely intact.** Eleven v3 Expressive voice, the Marcus system prompt, turn-taking, interruption — none of that moves. Only the room changes.
4. **Fastest path to a credible Marcus face.** HeyGen's Photo Avatar pipeline lets us clone the scenario portrait we already have; ready in minutes. bey wants a consented actor video; Tavus wants an actor + hours of training. LemonSlice/Simli's single-photo flow is comparable in quality but pays in WebRTC integration cost.
5. **Reasonable cost curve.** `~$0.10–$0.13/min` LITE + existing ElevenLabs Conv AI minutes. Higher than Simli or Avatario bundle pricing but offset by zero backend spend.
6. **Graceful fallback exists.** If Marcus ships text-only or the user blocks camera/video, we fall back to the existing `ConversationView` path — no reason the LiveAvatar path can't be behind a feature flag that defaults to today's behaviour.

### Secondary: keep Path B (own the room + LiveKit Agents worker) on the roadmap.

Two things push us toward Path B over time:

- **Richer affect control.** Keyframe's `set_emotion()` primitive is the most therapy-relevant tool in the ecosystem and is only reachable via the Python plugin path.
- **Vendor leverage.** Path B decouples Couch from HeyGen. The iOS app stays a LiveKit client; the avatar vendor becomes a config flag.

Trigger to build Path B: the first of
(a) LiveAvatar leaves beta without a viable commercial plan,
(b) we need HIPAA BAA coverage no avatar vendor offers today,
(c) we ship a second scenario and want per-scenario emotion tooling.

### Do not pursue (for V2):

- **Path C (Simli / bey parallel WebRTC peer on iOS).** Cheapest per minute but highest engineering cost and most fragile. It's the right answer if we were building a web app where `MediaStream` plumbing is cheap. It isn't the right answer for a small iOS SwiftUI codebase that already depends on LiveKit via ElevenLabs.
- **Tavus for V2.** Best visual quality ceiling, but custom-replica cost (actor + consented video + training) and `~$0.32/min` price put it in a later tier. Revisit as a premium scenario for advanced users.
- **Avatario / AvatarTalk / D-ID (real-time) / TruGen / Hedra.** Eliminated on latency, architecture, or deprecation grounds as detailed in §3.

---

## 6. PRD — Couch V2: "Face of Marcus" (Path A)

### 6.1 Goal

A therapist-in-training connecting to Marcus sees his face, animated in real time to his voice, with the same turn-taking and interruption dynamics as today. Mic permission denied → current text fallback, no avatar. Avatar cost / beta status surfaced explicitly in the session intro.

### 6.2 Non-goals (V2)

- Multi-scenario avatar catalogue (Marcus only, mirrors V1 scope).
- Custom user-facing avatar creation (Marcus is authored by us, once).
- HIPAA BAA coverage / App Store distribution (V1 was already dev-tier).
- Server-side agent worker (defer to Path B if/when triggered).

### 6.3 User flow deltas vs V1

1. Onboarding, home, scenario pick: unchanged.
2. `SessionIntroView` gains a "Meet Marcus (beta)" toggle, default **on** if `HEYGEN_API_KEY` + `HEYGEN_SECRET_ID` are present in `Secrets.plist`, otherwise hidden.
3. `ConversationView` replaces the full-bleed portrait with a LiveKit `VideoView` bound to the avatar worker's track. Fallback to the existing `ScenarioPortraitView` when (a) avatar disabled, (b) video track not yet attached, (c) error.
4. Header, live pill, timer, transcript bubbles, control bar: unchanged. Freeze-help, mute, text panel, end call: unchanged.
5. Debrief gate, post-session flow, persistence: completely unchanged. Turns are still sourced from the ElevenLabs message stream — the avatar is strictly a rendering layer.

### 6.4 Implementation plan

- **New files**
  - `Couch/Services/LiveAvatarClient.swift` — async `startSession(elevenLabsAgentId:) -> LiveAvatarSession` wrapping `POST https://api.heygen.com/v1/sessions` (LITE mode) and the one-time `POST /v1/secrets` bootstrap. Returns `{ livekitUrl, livekitToken, sessionId }`.
  - `Couch/Services/LiveKitRoomClient.swift` — small actor wrapping `LiveKit.Room`. Exposes Combine / AsyncStream for `agentAudioTrack`, `avatarVideoTrack`, remote participant state. Mirrors the surface `SessionCoordinator` uses today.
  - `Couch/Features/Session/AvatarSessionCoordinator.swift` — a sibling of `SessionCoordinator` that drives the LiveKit room path. Emits the same `Phase` / `AgentMode` / `visibleTurns` / `rapportScore` / `elapsed` surface so `ConversationView` is agnostic.
- **Edited files**
  - `Couch/Features/Session/ConversationView.swift` — swap `ScenarioPortraitView` for a `GeometryReader` + LiveKit `VideoView` when the coordinator exposes a `videoTrack`; keep the portrait as the pre-connect and error fallback.
  - `Couch/Scenarios/ScenarioCatalog.swift` — extend `ScenarioBlueprint` with `liveAvatarId: String?` (HeyGen avatar id for Marcus).
  - `Couch/Services/SecretsProvider.swift` — add `heyGenAPIKey`, `heyGenSecretId`, `marcusLiveAvatarId` accessors.
  - `Couch/Secrets.plist.example` + `README.md` — document the three new keys and the PCM 24 kHz agent config change in ElevenLabs.
- **Wiring**
  - `SessionCoordinator` today owns a `Conversation` from ElevenLabs. In Path A, for avatar-enabled sessions it instead owns a `LiveKit.Room` joined via a LiveAvatar-issued token, and maps `room.remoteParticipants` onto the same `agent` / avatar-worker taxonomy documented by LiveKit (`p.kind == .agent`, `p.attributes["lk.publish_on_behalf"]`). Turn text still comes from the ElevenLabs data-channel messages relayed through the same LiveKit room.
  - `assembler` / `estimator` / `TranscriptStore`: unchanged — they already operate on `DisplayTurn`s, which we synthesise from the LiveKit data-channel message stream.

### 6.5 Risks / open questions

- **LiveAvatar beta stability.** Mitigation: feature-flag the avatar path, default to V1 behaviour if `HEYGEN_API_KEY` is absent, and wire an error path that collapses back to the portrait on any mid-session failure.
- **PCM 24 kHz agent config.** One-time dashboard change on the Marcus agent; document in the README. If a user clones the agent later and forgets to re-apply, LITE mode fails. Catch the error and surface the exact remediation step.
- **LiveKit Swift SDK pin.** The ElevenLabs SDK pulls in LiveKit transitively. We may need to pin `client-sdk-swift` explicitly if we want to call `Room.connect(url:token:)` outside the ElevenLabs context. Verify SPM resolution before ripping the wiring in.
- **Custom Marcus avatar in HeyGen.** Creation happens in HeyGen's dashboard, not via API. We need to produce a single Marcus reference image (we already have the scenario portrait) and own the HeyGen account that holds the asset. That's an ops item, not an engineering one.
- **Privacy copy.** The session intro copy currently doesn't mention a third-party video provider. With avatars on, we are sending the ElevenLabs agent audio through HeyGen and receiving video from them. Update the onboarding safety framing and the `SessionIntroView` to disclose this before the user joins.
- **Reduce Motion / accessibility.** Respect `accessibilityReduceMotion` in `ConversationView` today — extend it so avatar can be disabled from Settings even when creds are present. A still portrait is a legitimate preference.

### 6.6 Success criteria

- From cold start, "Start session" → Marcus's face visible and lip-syncing in **≤ 3 s p95**.
- No regression in debrief quality (same structured output from `DebriefService`).
- Existing `CouchTests` and `CouchUITests` suites pass unchanged.
- Fallback to portrait when HeyGen creds absent, with no runtime crash.
- One new Swift Testing unit test covering `LiveAvatarClient.startSession` error paths (missing key, invalid agent id, PCM config mismatch) via a protocol-based URL session stub.

---

## 7. References

- LiveKit Virtual Avatar Overview — <https://docs.livekit.io/agents/models/avatar/>
- ElevenLabs × LiveAvatar (LITE mode) — <https://elevenlabs.io/docs/eleven-agents/guides/integrations/live-avatar>
- LiveKit avatar plugin pages — <https://docs.livekit.io/agents/models/avatar/plugins/>
- ElevenLabs Swift SDK — <https://elevenlabs.io/docs/eleven-agents/libraries/swift>, <https://github.com/elevenlabs/elevenlabs-swift-sdk>
- LiveKit Swift client SDK — <https://github.com/livekit/client-sdk-swift>
- LiveKit blog, "Bringing AI avatars to voice agents" — <https://livekit.com/blog/bringing-ai-avatars-to-voice-agents>
- Anam pricing + LiveKit integration — <https://anam.ai/pricing>, <https://docs.anam.ai/third-party-integrations/livekit>
- Beyond Presence docs — <https://docs.bey.dev/get-started>, <https://docs.bey.dev/get-started/api>, <https://docs.bey.dev/get-started/avatars/custom>
- LemonSlice Create Session API — <https://lemonslice.com/docs/api-reference/create-session>
- Simli WebRTC API — <https://docs.simli.com/api-reference/simli-webrtc>
- Tavus CVI — <https://docs.tavus.io/sections/conversational-video-interface/overview-cvi>
- Trulience × ElevenLabs (web reference, instructive only) — <https://docs.trulience.com/docs/external-platforms/elevenlabs-conversational-ai>
