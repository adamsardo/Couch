import { config as loadDotenv } from 'dotenv';
import { z } from 'zod';

loadDotenv();

const truthy = new Set(['1', 'true', 'yes', 'on']);
const falsy = new Set(['0', 'false', 'no', 'off', '']);

const BoolFromString = z
  .union([z.boolean(), z.string()])
  .transform((raw) => {
    if (typeof raw === 'boolean') return raw;
    const normalized = raw.trim().toLowerCase();
    if (truthy.has(normalized)) return true;
    if (falsy.has(normalized)) return false;
    return false;
  });

const AvatarProvider = z.enum(['lemonslice', 'none']).default('lemonslice');

const NumberFromString = z
  .union([z.number(), z.string()])
  .transform((raw) => (typeof raw === 'number' ? raw : Number(raw)))
  .refine((v) => Number.isFinite(v) && v > 0, 'must be a positive number');

const OptionalTrimmed = z
  .union([z.string(), z.undefined()])
  .transform((v) => {
    if (v === undefined) return undefined;
    const trimmed = v.trim();
    return trimmed.length === 0 ? undefined : trimmed;
  });

export const EnvSchema = z.object({
  LIVEKIT_URL: z.string().url(),
  LIVEKIT_API_KEY: z.string().min(1),
  LIVEKIT_API_SECRET: z.string().min(1),

  COUCH_API_SHARED_SECRET: z.string().min(16, 'pick a long random string'),
  TOKEN_SERVER_PORT: NumberFromString.default('8787'),

  OPENAI_API_KEY: z.string().min(1),

  ELEVENLABS_API_KEY: OptionalTrimmed,
  ELEVENLABS_MARCUS_VOICE_ID: OptionalTrimmed,

  COUCH_AVATARS_ENABLED: BoolFromString.default('true'),
  COUCH_AVATAR_PROVIDER: AvatarProvider,

  LEMONSLICE_API_KEY: OptionalTrimmed,
  MARCUS_LEMONSLICE_AGENT_ID: OptionalTrimmed,
  MARCUS_LEMONSLICE_IMAGE_URL: OptionalTrimmed,

  COUCH_AVATAR_START_TIMEOUT_SECONDS: NumberFromString.default('8'),

  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),
});

export type Env = z.infer<typeof EnvSchema>;

let cached: Env | undefined;

/** Parse env on first use and cache. Throws with a readable aggregate error. */
export function env(): Env {
  if (cached) return cached;
  const parsed = EnvSchema.safeParse(process.env);
  if (!parsed.success) {
    const issues = parsed.error.issues
      .map((i) => ` - ${i.path.join('.') || '(root)'}: ${i.message}`)
      .join('\n');
    throw new Error(`Invalid backend environment:\n${issues}`);
  }
  cached = parsed.data;
  return cached;
}
