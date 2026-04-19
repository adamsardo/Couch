import test from 'node:test';
import assert from 'node:assert/strict';

// Populate the minimum env needed for config loading. These values only need
// to parse; no network calls are made. Set them before importing the module
// because env() parses lazily and then caches.
process.env.LIVEKIT_URL = 'wss://example.livekit.cloud';
process.env.LIVEKIT_API_KEY = 'devkey';
process.env.LIVEKIT_API_SECRET = 'devsecret';
process.env.COUCH_API_SHARED_SECRET = 'this-is-a-long-enough-shared-secret';
process.env.OPENAI_API_KEY = 'sk-test';
process.env.COUCH_AVATARS_ENABLED = 'true';
process.env.COUCH_AVATAR_PROVIDER = 'lemonslice';
// Intentionally leave LEMONSLICE_API_KEY + MARCUS_* unset so the resolver
// returns the audio-only fallback shape.
delete process.env.LEMONSLICE_API_KEY;
delete process.env.MARCUS_LEMONSLICE_AGENT_ID;
delete process.env.MARCUS_LEMONSLICE_IMAGE_URL;

const { scenarioConfig, resolveAvatarConfig, ScenarioLookupError } =
  await import('../src/config/scenarios.js');

test('scenario catalog includes marcus-intake', () => {
  const s = scenarioConfig('marcus-intake');
  assert.equal(s.id, 'marcus-intake');
  assert.equal(s.patientName, 'Marcus');
  assert.equal(s.agentName, 'couch-marcus-agent');
  assert.equal(s.avatar.provider, 'lemonslice');
  assert.ok(s.persona.systemPrompt.includes('Marcus'));
});

test('scenario lookup throws ScenarioLookupError for unknown ids', () => {
  assert.throws(() => scenarioConfig('does-not-exist'), ScenarioLookupError);
});

test('avatar resolves to disabled without credentials (audio-only fallback)', () => {
  const s = scenarioConfig('marcus-intake');
  const a = resolveAvatarConfig(s);
  assert.equal(a.enabled, false);
  assert.equal(a.provider, 'none');
  assert.ok(a.startTimeoutSeconds > 0);
});
