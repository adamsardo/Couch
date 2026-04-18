import {
  type JobContext,
  type JobProcess,
  ServerOptions,
  cli,
  defineAgent,
  voice,
} from '@livekit/agents';
import * as openai from '@livekit/agents-plugin-openai';
import * as elevenlabs from '@livekit/agents-plugin-elevenlabs';
import * as lemonslice from '@livekit/agents-plugin-lemonslice';
import * as silero from '@livekit/agents-plugin-silero';
import { fileURLToPath } from 'node:url';

import { env } from './config/env.js';
import {
  resolveAvatarConfig,
  scenarioConfig,
  ScenarioLookupError,
  type ScenarioConfig,
} from './config/scenarios.js';

/**
 * Parse per-room dispatch metadata written by the token server.
 * See token-server.ts → `token.roomConfig.agents[0].metadata`.
 */
interface DispatchMetadata {
  scenarioId: string;
  mode?: 'voice' | 'text';
}

function parseDispatchMetadata(raw: string | undefined | null): DispatchMetadata {
  if (!raw) {
    throw new Error('agent dispatched without metadata; cannot resolve scenario');
  }
  try {
    const parsed = JSON.parse(raw);
    if (typeof parsed?.scenarioId !== 'string') {
      throw new Error('metadata.scenarioId missing');
    }
    return { scenarioId: parsed.scenarioId, mode: parsed.mode };
  } catch (err) {
    throw new Error(`invalid dispatch metadata: ${(err as Error).message}`);
  }
}

/**
 * Build the TTS plugin for a scenario. Prefers ElevenLabs (§6.3 of the PRD)
 * so Marcus keeps the voice identity students already know; falls back to
 * OpenAI TTS if no ElevenLabs key is configured.
 */
function buildTTS(scenario: ScenarioConfig): voice.TTS {
  const e = env();
  if (e.ELEVENLABS_API_KEY) {
    const voiceId = scenario.elevenLabsVoiceID ?? e.ELEVENLABS_MARCUS_VOICE_ID;
    return new elevenlabs.TTS({
      apiKey: e.ELEVENLABS_API_KEY,
      ...(voiceId ? { voiceId } : {}),
    });
  }
  return new openai.TTS({ apiKey: e.OPENAI_API_KEY });
}

/**
 * Start the LemonSlice avatar worker with a timeout. Returns true if the
 * avatar joined, false (and keeps the session running audio-only) otherwise.
 * This is the required fallback ladder from §6.5 of the PRD.
 */
async function maybeStartAvatar(
  session: voice.AgentSession,
  ctx: JobContext,
  scenario: ScenarioConfig,
): Promise<boolean> {
  const avatar = resolveAvatarConfig(scenario);
  if (!avatar.enabled || avatar.provider !== 'lemonslice' || !avatar.lemonslice) {
    ctx.log.info({ scenarioId: scenario.id }, 'avatar disabled, running audio-only');
    return false;
  }

  const options: lemonslice.AvatarSessionOptions = {
    apiKey: avatar.lemonslice.apiKey,
    ...(avatar.lemonslice.agentId
      ? { agentId: avatar.lemonslice.agentId }
      : avatar.lemonslice.agentImageUrl
        ? { agentImageUrl: avatar.lemonslice.agentImageUrl }
        : {}),
    ...(avatar.lemonslice.agentPrompt
      ? { agentPrompt: avatar.lemonslice.agentPrompt }
      : {}),
  };

  const avatarSession = new lemonslice.AvatarSession(options);

  const startPromise = avatarSession.start(session, ctx.room);
  const timeoutMs = avatar.startTimeoutSeconds * 1000;

  try {
    await Promise.race([
      startPromise,
      new Promise((_, reject) =>
        setTimeout(
          () => reject(new Error(`avatar start timed out after ${timeoutMs}ms`)),
          timeoutMs,
        ),
      ),
    ]);
    ctx.log.info({ scenarioId: scenario.id }, 'avatar started');
    return true;
  } catch (err) {
    ctx.log.warn(
      { err: (err as Error).message, scenarioId: scenario.id },
      'avatar start failed — falling back to audio-only',
    );
    // best effort — the worker might still finish joining; if it does, great;
    // if it does not, the session continues audio-only.
    return false;
  }
}

export default defineAgent({
  prewarm: async (proc: JobProcess) => {
    proc.userData.vad = await silero.VAD.load();
  },
  entry: async (ctx: JobContext) => {
    const e = env();

    const meta = parseDispatchMetadata(ctx.job.metadata);
    let scenario: ScenarioConfig;
    try {
      scenario = scenarioConfig(meta.scenarioId);
    } catch (err) {
      if (err instanceof ScenarioLookupError) {
        ctx.log.error({ scenarioId: meta.scenarioId }, 'unknown scenario — aborting');
      }
      throw err;
    }

    const vad = ctx.proc.userData.vad as silero.VAD;

    const session = new voice.AgentSession({
      vad,
      stt: new openai.STT({ apiKey: e.OPENAI_API_KEY, model: 'whisper-1' }),
      llm: new openai.LLM({ apiKey: e.OPENAI_API_KEY, model: 'gpt-4o-mini' }),
      tts: buildTTS(scenario),
    });

    // Try to start the avatar first (LemonSlice docs: start the avatar, then
    // start the user-facing agent session). If it fails, we continue audio-
    // only, which is the PRD-required fallback.
    await maybeStartAvatar(session, ctx, scenario);

    await session.start({
      agent: new voice.Agent({ instructions: scenario.persona.systemPrompt }),
      room: ctx.room,
    });

    await ctx.connect();

    if (meta.mode !== 'text') {
      // Let the student open. Marcus is reluctant — we deliberately do NOT
      // have the agent speak first (see persona prompt).
      ctx.log.info({ scenarioId: scenario.id, mode: meta.mode }, 'session ready');
    }
  },
});

const isDirectEntry = import.meta.url === `file://${process.argv[1]}`;
if (isDirectEntry) {
  // The agent name must match what the token server requests via roomConfig.
  // For the PRD's single-scenario launch we register once as the Marcus
  // agent; when more scenarios ship the dispatcher can fan out by agentName.
  cli.runApp(
    new ServerOptions({
      agent: fileURLToPath(import.meta.url),
      agentName: 'couch-marcus-agent',
    }),
  );
}
