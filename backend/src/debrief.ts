import { z } from 'zod';

export const DebriefRequestSchema = z.object({
  scenario: z.object({
    id: z.string().min(1),
    title: z.string().min(1),
    patientName: z.string().min(1),
    patientAge: z.number().int().positive(),
    summary: z.string().min(1),
  }),
  turns: z
    .array(
      z.object({
        role: z.enum(['user', 'agent', 'system']),
        text: z.string().min(1).max(4000),
      }),
    )
    .max(120),
});

export type DebriefRequest = z.infer<typeof DebriefRequestSchema>;

export interface FetchResponseLike {
  ok: boolean;
  status: number;
  text(): Promise<string>;
}

export type FetchLike = (
  input: string,
  init: {
    method: 'POST';
    headers: Record<string, string>;
    body: string;
  },
) => Promise<FetchResponseLike>;

const debriefSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['strengths', 'next_moves', 'micro_drill', 'notes', 'risk_flags'],
  properties: {
    strengths: {
      type: 'array',
      minItems: 3,
      maxItems: 3,
      items: { type: 'string', minLength: 8 },
    },
    next_moves: {
      type: 'array',
      minItems: 3,
      maxItems: 3,
      items: { type: 'string', minLength: 8 },
    },
    micro_drill: {
      type: 'object',
      additionalProperties: false,
      required: ['title', 'body'],
      properties: {
        title: { type: 'string', minLength: 4, maxLength: 80 },
        body: { type: 'string', minLength: 20, maxLength: 320 },
      },
    },
    notes: { type: 'string', maxLength: 600 },
    risk_flags: {
      type: 'array',
      items: { type: 'string' },
    },
  },
} as const;

const systemPrompt = `You are a clinical-skills coach for psychology students practising therapy reps in a simulator. The user just finished a SIMULATED session with a virtual patient. Your only job is to write a debrief that helps them get better next time.

Output rules:
- This is TRAINING practice. Never imply the user is providing care or therapy.
- Do NOT diagnose the patient, even tentatively.
- Be specific, not vague. Reference observable moments from the transcript.
- Strengths: exactly 3, warm and credible, each one observable in the transcript.
- Next moves: exactly 3, each a concrete behaviour to try in the next rep.
- Micro-drill: one focused practice prompt with a short title and 1-2 sentence body.
- Risk flags: only include supervising-clinician concerns. Otherwise return an empty array.

Tone: specific, competent, non-judgmental, practical. No clinical jargon. No emoji.`;

export async function generateDebrief(params: {
  request: DebriefRequest;
  apiKey: string;
  fetchImpl: FetchLike;
  model?: string;
}): Promise<unknown> {
  const response = await params.fetchImpl('https://api.openai.com/v1/responses', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${params.apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: params.model ?? 'gpt-4.1-mini',
      instructions: systemPrompt,
      input: renderInput(params.request),
      text: {
        format: {
          type: 'json_schema',
          name: 'couch_debrief',
          schema: debriefSchema,
          strict: true,
        },
      },
    }),
  });

  const body = await response.text();
  if (!response.ok) {
    throw new DebriefGenerationError(response.status, body);
  }
  return decodeStructuredOutput(body);
}

export class DebriefGenerationError extends Error {
  constructor(
    readonly status: number,
    readonly body: string,
  ) {
    super(`OpenAI debrief generation failed with HTTP ${status}`);
  }
}

function renderInput(request: DebriefRequest): string {
  const lines = [
    `Scenario: ${request.scenario.title} (patient: ${request.scenario.patientName}, age ${request.scenario.patientAge})`,
    `Summary: ${request.scenario.summary}`,
    '',
    'Transcript (S = student, P = patient):',
  ];
  for (const turn of request.turns) {
    const prefix = turn.role === 'user' ? 'S' : turn.role === 'agent' ? 'P' : '·';
    lines.push(`${prefix}: ${turn.text}`);
  }
  return lines.join('\n');
}

function decodeStructuredOutput(body: string): unknown {
  const parsed = JSON.parse(body) as {
    output_text?: string;
    output?: Array<{ content?: Array<{ type?: string; text?: string }> }>;
  };
  const raw =
    parsed.output_text ??
    parsed.output?.flatMap((item) => item.content ?? [])
      .find((content) => content.type?.includes('text') && content.text)?.text;
  if (!raw) {
    throw new Error('missing output_text');
  }
  return JSON.parse(raw);
}
