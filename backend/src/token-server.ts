import Fastify from 'fastify';
import { AccessToken } from 'livekit-server-sdk';
import { z } from 'zod';

import { env } from './config/env.js';
import {
  resolveAvatarConfig,
  scenarioConfig,
  ScenarioLookupError,
} from './config/scenarios.js';

const TokenRequest = z.object({
  scenarioId: z.string().min(1),
  /** Optional display name; falls back to "Student". */
  participantName: z.string().min(1).max(64).optional(),
  /** Optional stable participant identity (e.g. UserProfile UUID). */
  participantIdentity: z.string().min(1).max(128).optional(),
  /** voice | text — threaded through to the agent via room metadata. */
  mode: z.enum(['voice', 'text']).default('voice'),
});

/**
 * Mints a LiveKit token for a Couch session and, via room metadata, tells the
 * agent which scenario + mode to run. Returns the same shape the LiveKit Swift
 * client expects (`serverUrl`, `participantToken`) plus a small `session`
 * block Couch uses to configure the iOS stage (e.g. whether to expect video).
 */
export async function buildApp() {
  const e = env();
  const app = Fastify({
    logger: { level: e.LOG_LEVEL },
    trustProxy: true,
  });

  app.get('/healthz', async () => ({ ok: true }));

  app.post('/v1/sessions/token', async (req, reply) => {
    const auth = req.headers['x-couch-auth'];
    if (typeof auth !== 'string' || auth !== e.COUCH_API_SHARED_SECRET) {
      reply.code(401);
      return { error: 'unauthorized' };
    }

    const parsed = TokenRequest.safeParse(req.body);
    if (!parsed.success) {
      reply.code(400);
      return { error: 'bad_request', issues: parsed.error.issues };
    }

    let scenario;
    try {
      scenario = scenarioConfig(parsed.data.scenarioId);
    } catch (err) {
      if (err instanceof ScenarioLookupError) {
        reply.code(404);
        return { error: 'unknown_scenario' };
      }
      throw err;
    }

    const avatar = resolveAvatarConfig(scenario);

    const roomName = `${scenario.roomPrefix}-${cryptoRandomHex(8)}`;
    const identity =
      parsed.data.participantIdentity ?? `student-${cryptoRandomHex(8)}`;

    const token = new AccessToken(e.LIVEKIT_API_KEY, e.LIVEKIT_API_SECRET, {
      identity,
      name: parsed.data.participantName ?? 'Student',
      ttl: 60 * 60,
      metadata: JSON.stringify({
        role: 'student',
        scenarioId: scenario.id,
        mode: parsed.data.mode,
      }),
    });

    token.addGrant({
      room: roomName,
      roomJoin: true,
      roomCreate: true,
      canPublish: true,
      canPublishData: true,
      canSubscribe: true,
      canUpdateOwnMetadata: true,
    });

    token.roomConfig = {
      agents: [
        {
          agentName: scenario.agentName,
          metadata: JSON.stringify({
            scenarioId: scenario.id,
            mode: parsed.data.mode,
          }),
        },
      ],
    };

    const jwt = await token.toJwt();

    return {
      serverUrl: e.LIVEKIT_URL,
      participantToken: jwt,
      room: roomName,
      participantIdentity: identity,
      session: {
        scenarioId: scenario.id,
        mode: parsed.data.mode,
        avatar: {
          enabled: avatar.enabled,
          provider: avatar.provider,
          startTimeoutSeconds: avatar.startTimeoutSeconds,
        },
      },
    };
  });

  return app;
}

function cryptoRandomHex(bytes: number): string {
  const buf = new Uint8Array(bytes);
  crypto.getRandomValues(buf);
  return Array.from(buf, (b) => b.toString(16).padStart(2, '0')).join('');
}

async function main(): Promise<void> {
  const e = env();
  const app = await buildApp();
  try {
    await app.listen({ port: e.TOKEN_SERVER_PORT, host: '0.0.0.0' });
    app.log.info(
      { port: e.TOKEN_SERVER_PORT, livekitUrl: e.LIVEKIT_URL },
      'couch token server listening',
    );
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
}

// Only run the server when this file is executed directly (not when imported
// by tests).
const isDirectEntry = import.meta.url === `file://${process.argv[1]}`;
if (isDirectEntry) {
  await main();
}
