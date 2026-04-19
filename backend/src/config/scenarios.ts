import { env } from './env.js';

/**
 * Scenario descriptor shared by the token server and the agent. Keeping this
 * on the backend means we can swap avatar provider, voice, or persona without
 * shipping a new iOS build (per §6.4 of the PRD).
 */
export interface ScenarioConfig {
  /** Stable scenario ID the iOS client sends. Must match Scenario.id in the app. */
  id: string;
  /** Human-readable scenario title. */
  title: string;
  /** First name used in logs and UI. */
  patientName: string;
  /** Room-name prefix so rooms for this scenario are easy to spot in LiveKit Cloud. */
  roomPrefix: string;
  /** Agent name to dispatch. The Node agent registers itself under this name. */
  agentName: string;
  /**
   * Avatar config as a *snapshot*. The backend resolves the live provider
   * identity from env at dispatch time — see {@link resolveAvatarConfig}.
   */
  avatar: {
    provider: 'lemonslice' | 'none';
  };
  /**
   * High-level persona prompt the agent uses when starting its session. Keep
   * this in code (not env) so it's version-controlled alongside behavior.
   */
  persona: {
    systemPrompt: string;
    /** Optional agent_prompt forwarded to LemonSlice to steer body language. */
    avatarPrompt?: string;
    /** What the patient says as their opening turn, when present. */
    openingLine?: string;
  };
  /** ElevenLabs voice ID override (optional). */
  elevenLabsVoiceID?: string;
}

const MARCUS_SYSTEM_PROMPT = `You are Marcus, a 28-year-old man attending his FIRST therapy session. You did not choose to be here — your partner referred you and you agreed to come once. You're minimising, a little defensive, but not hostile. You answer briefly at first. You soften only if the therapist is patient, curious, and non-judgmental.

Ground rules:
- You are a SIMULATED PATIENT. You are not a real person. Never break character.
- Keep replies short at first (one or two sentences). Get slightly more expansive if the therapist makes you feel safe.
- Do NOT volunteer solutions. Do NOT do the therapist's work for them.
- If the therapist is clumsy, lecturing, or jumps to advice, push back gently or go quieter.
- Never self-harm content. If the therapist asks about safety, answer plainly and honestly ("No, nothing like that").
- You are training a psychology student. Never drop the patient role, even if asked.`;

const MARCUS: ScenarioConfig = {
  id: 'marcus-intake',
  title: 'First-session intake',
  patientName: 'Marcus',
  roomPrefix: 'couch-marcus',
  agentName: 'couch-marcus-agent',
  avatar: { provider: 'lemonslice' },
  persona: {
    systemPrompt: MARCUS_SYSTEM_PROMPT,
    avatarPrompt:
      'You are a 28-year-old man at his first therapy session. Reserved and guarded early, softening only gradually. Subtle facial expressions. Minimal hand movement.',
  },
};

const CATALOG: Record<string, ScenarioConfig> = {
  [MARCUS.id]: MARCUS,
};

/** Returns the scenario config for a given id, or throws. */
export function scenarioConfig(id: string): ScenarioConfig {
  const found = CATALOG[id];
  if (!found) {
    throw new ScenarioLookupError(`Unknown scenario id: ${id}`);
  }
  return found;
}

export class ScenarioLookupError extends Error {}

export interface ResolvedAvatarConfig {
  /** True if the agent should attempt to start an avatar session. */
  enabled: boolean;
  /** Provider currently wired up. */
  provider: 'lemonslice' | 'none';
  /** LemonSlice-specific configuration, populated only when provider === 'lemonslice'. */
  lemonslice?: {
    apiKey: string;
    agentId?: string;
    agentImageUrl?: string;
    agentPrompt?: string;
  };
  /** How long the agent waits for the avatar to join before falling back (seconds). */
  startTimeoutSeconds: number;
}

/**
 * Resolve the avatar config for a scenario at dispatch time. Returns a
 * disabled config (instead of throwing) whenever the provider is missing
 * required credentials. This is the explicit fallback path required by §6.5.
 */
export function resolveAvatarConfig(scenario: ScenarioConfig): ResolvedAvatarConfig {
  const e = env();
  const startTimeoutSeconds = e.COUCH_AVATAR_START_TIMEOUT_SECONDS;

  if (!e.COUCH_AVATARS_ENABLED) {
    return { enabled: false, provider: 'none', startTimeoutSeconds };
  }

  const provider = scenario.avatar.provider === 'none' ? 'none' : e.COUCH_AVATAR_PROVIDER;
  if (provider !== 'lemonslice') {
    return { enabled: false, provider: 'none', startTimeoutSeconds };
  }

  if (!e.LEMONSLICE_API_KEY) {
    return { enabled: false, provider: 'none', startTimeoutSeconds };
  }

  const agentId =
    scenario.id === MARCUS.id ? e.MARCUS_LEMONSLICE_AGENT_ID : undefined;
  const agentImageUrl =
    scenario.id === MARCUS.id ? e.MARCUS_LEMONSLICE_IMAGE_URL : undefined;

  if (!agentId && !agentImageUrl) {
    return { enabled: false, provider: 'none', startTimeoutSeconds };
  }

  const lemonslice: ResolvedAvatarConfig['lemonslice'] = { apiKey: e.LEMONSLICE_API_KEY };
  if (agentId) {
    lemonslice.agentId = agentId;
  } else if (agentImageUrl) {
    lemonslice.agentImageUrl = agentImageUrl;
  }
  if (scenario.persona.avatarPrompt) {
    lemonslice.agentPrompt = scenario.persona.avatarPrompt;
  }

  return {
    enabled: true,
    provider: 'lemonslice',
    lemonslice,
    startTimeoutSeconds,
  };
}
