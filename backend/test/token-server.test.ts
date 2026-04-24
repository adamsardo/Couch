import test from 'node:test';
import assert from 'node:assert/strict';

process.env.LIVEKIT_URL = 'wss://example.livekit.cloud';
process.env.LIVEKIT_API_KEY = 'devkey';
process.env.LIVEKIT_API_SECRET = 'devsecret';
process.env.COUCH_API_SHARED_SECRET = 'this-is-a-long-enough-shared-secret';
process.env.OPENAI_API_KEY = 'sk-test';
process.env.COUCH_AVATARS_ENABLED = 'true';
process.env.COUCH_AVATAR_PROVIDER = 'lemonslice';
delete process.env.LEMONSLICE_API_KEY;
delete process.env.MARCUS_LEMONSLICE_AGENT_ID;
delete process.env.MARCUS_LEMONSLICE_IMAGE_URL;

const { buildApp } = await import('../src/token-server.js');

const authHeaders = {
  'x-couch-auth': 'this-is-a-long-enough-shared-secret',
};

test('healthz returns ok', async () => {
  const app = await buildApp();
  const res = await app.inject({ method: 'GET', url: '/healthz' });
  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.json(), { ok: true });
});

test('token endpoint rejects missing auth', async () => {
  const app = await buildApp();
  const res = await app.inject({
    method: 'POST',
    url: '/v1/sessions/token',
    payload: { scenarioId: 'marcus-intake' },
  });
  assert.equal(res.statusCode, 401);
});

test('token endpoint validates payload', async () => {
  const app = await buildApp();
  const res = await app.inject({
    method: 'POST',
    url: '/v1/sessions/token',
    headers: authHeaders,
    payload: { scenarioId: '' },
  });
  assert.equal(res.statusCode, 400);
});

test('token endpoint returns 404 for unknown scenarios', async () => {
  const app = await buildApp();
  const res = await app.inject({
    method: 'POST',
    url: '/v1/sessions/token',
    headers: authHeaders,
    payload: { scenarioId: 'unknown' },
  });
  assert.equal(res.statusCode, 404);
});

test('token endpoint returns audio-only avatar shape when credentials are absent', async () => {
  const app = await buildApp();
  const res = await app.inject({
    method: 'POST',
    url: '/v1/sessions/token',
    headers: authHeaders,
    payload: { scenarioId: 'marcus-intake', mode: 'voice' },
  });
  assert.equal(res.statusCode, 200);
  const body = res.json();
  assert.equal(body.session.scenarioId, 'marcus-intake');
  assert.equal(body.session.avatar.enabled, false);
  assert.equal(body.session.avatar.provider, 'none');
});

test('debrief endpoint proxies structured payloads', async () => {
  const fakePayload = {
    strengths: [
      'You reflected the work pressure clearly.',
      'You left space before changing topic.',
      'You normalised his hesitation without rushing.',
    ],
    next_moves: [
      'Ask one short open question after the next sigh.',
      'Name the feeling before asking for detail.',
      'Avoid advice until he has described the problem.',
    ],
    micro_drill: {
      title: 'Name the feeling',
      body: 'When Marcus says he is tired, reflect the feeling before asking for more detail.',
    },
    notes: 'Marcus softened when the student stayed with work stress.',
    risk_flags: [],
  };
  const app = await buildApp({
    openaiFetch: async () => ({
      ok: true,
      status: 200,
      async text() {
        return JSON.stringify({ output_text: JSON.stringify(fakePayload) });
      },
    }),
  });

  const res = await app.inject({
    method: 'POST',
    url: '/v1/debriefs',
    headers: authHeaders,
    payload: {
      scenario: {
        id: 'marcus-intake',
        title: 'First-session intake',
        patientName: 'Marcus',
        patientAge: 28,
        summary: 'His partner referred him.',
      },
      turns: [
        { role: 'user', text: 'Sounds like work has been heavy.' },
        { role: 'agent', text: 'Yeah, I guess it has.' },
      ],
    },
  });

  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.json(), fakePayload);
});

test('debrief endpoint maps upstream failures to 502 without transcript echo', async () => {
  const app = await buildApp({
    openaiFetch: async () => ({
      ok: false,
      status: 429,
      async text() {
        return 'rate limited';
      },
    }),
  });

  const res = await app.inject({
    method: 'POST',
    url: '/v1/debriefs',
    headers: authHeaders,
    payload: {
      scenario: {
        id: 'marcus-intake',
        title: 'First-session intake',
        patientName: 'Marcus',
        patientAge: 28,
        summary: 'His partner referred him.',
      },
      turns: [{ role: 'user', text: 'Please help.' }],
    },
  });

  assert.equal(res.statusCode, 502);
  assert.equal(res.json().error, 'debrief_generation_failed');
  assert.equal(JSON.stringify(res.json()).includes('Please help'), false);
});
