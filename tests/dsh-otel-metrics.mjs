import assert from 'node:assert/strict';
import { test } from 'node:test';
import { apply } from '../modules/features/super-intelligence/dsh/otel-metrics.mjs';

async function harness(run, fail = false) {
	const bodies = [];
	const original = globalThis.fetch;
	globalThis.fetch = async (_, options) => {
		bodies.push(JSON.parse(options.body));
		if (fail) throw new Error('collector unavailable');
		return { body: { cancel: async () => {} } };
	};
	let stream, dispose;
	apply(
		{
			on(event, handler) {
				assert.equal(event, 'llm/stream');
				stream = handler;
			},
			effect(effect) {
				dispose = effect();
			},
		},
		{ endpoint: 'http://127.0.0.1:4318/v1/metrics' },
	);
	try {
		await run(stream);
	} finally {
		await dispose();
		globalThis.fetch = original;
	}
	return bodies;
}
const options = {
	provider: 'openai-codex',
	model: 'gpt-test',
	messages: [{ content: 'SECRET_PROMPT' }],
};
const metric = (b, name) =>
	b.resourceMetrics[0].scopeMetrics[0].metrics.find((m) => m.name === name)?.sum.dataPoints ?? [];
const total = (b, name) => metric(b, name).reduce((n, p) => n + p.asDouble, 0);
const drain = async (stream) => {
	const chunks = [];
	for await (const c of stream) chunks.push(c);
	return chunks;
};

test('revised usage counts once, retries count separately, and only allowed fields leave process', async () => {
	const bodies = await harness(async (stream) => {
		for (let i = 0; i < 2; i++) {
			const chunks = [
				{ type: 'text-delta', text: 'SECRET_OUTPUT' },
				{ type: 'usage', usage: { inputTokens: 10, outputTokens: 1 } },
				{
					type: 'usage',
					usage: {
						inputTokens: 10,
						outputTokens: 4,
						cacheReadTokens: 8,
						cacheWriteTokens: 2,
						reasoningTokens: 3,
						secret: 'SECRET_USAGE',
					},
				},
				{ type: 'finish', reason: { kind: i ? 'stop' : 'error', failure: 'SECRET_ERROR' } },
			];
			assert.deepEqual(
				await drain(
					stream(options, async function* () {
						yield* chunks;
					}),
				),
				chunks,
			);
		}
	});
	assert.equal(bodies.length, 2); // One batched zero, then shutdown snapshot.
	assert.equal(total(bodies[0], 'dsh.token.usage'), 0);
	assert.equal(total(bodies[1], 'dsh.token.usage'), 48);
	assert.equal(total(bodies[1], 'dsh.api.request'), 2);
	assert.equal(total(bodies[1], 'dsh.api.usage_reported'), 2);
	assert.ok(!JSON.stringify(bodies).includes('SECRET'));
	assert.ok(
		BigInt(metric(bodies[0], 'dsh.token.usage')[0].timeUnixNano) <
			BigInt(metric(bodies[1], 'dsh.token.usage')[0].timeUnixNano),
	);
});

test('thrown failures propagate unchanged even when collector is unavailable', async () => {
	const error = new Error('SECRET_FAILURE');
	const bodies = await harness(async (stream) => {
		await assert.rejects(
			drain(
				stream(options, async function* () {
					throw error;
				}),
			),
			(e) => e === error,
		);
	}, true);
	assert.equal(total(bodies.at(-1), 'dsh.api.request'), 1);
	assert.equal(total(bodies.at(-1), 'dsh.api.usage_reported'), 0);
	assert.ok(!JSON.stringify(bodies).includes('SECRET'));
});

test('consumer cancellation counts aborted and invalid token values cannot corrupt counters', async () => {
	const bodies = await harness(async (stream) => {
		const iterator = stream(options, async function* () {
			yield {
				type: 'usage',
				usage: {
					inputTokens: -2,
					outputTokens: NaN,
					cacheReadTokens: Infinity,
					cacheWriteTokens: 5,
				},
			};
			yield { type: 'text-delta', text: 'SECRET' };
		});
		await iterator.next();
		await iterator.return();
	});
	const body = bodies.at(-1);
	assert.equal(total(body, 'dsh.token.usage'), 5);
	assert.equal(
		metric(body, 'dsh.api.request').find((p) =>
			p.attributes.some((a) => a.key === 'outcome' && a.value.stringValue === 'aborted'),
		).asDouble,
		1,
	);
});

test('launcher preserves shorthand, plugin management, default dumps and spaced app arguments', async () => {
	const { mkdtemp, readFile, writeFile, rm } = await import('node:fs/promises');
	const { tmpdir } = await import('node:os');
	const { join } = await import('node:path');
	const { execFileSync } = await import('node:child_process');
	const dir = await mkdtemp(join(tmpdir(), 'dsh-launcher-test-'));
	try {
		const mock = join(dir, 'mock');
		await writeFile(mock, '#!/usr/bin/env bash\nprintf "%s\\0" "$@"\n', { mode: 0o700 });
		const template = await readFile(
			new URL('../modules/features/super-intelligence/dsh/launcher.sh', import.meta.url),
			'utf8',
		);
		const launcher = join(dir, 'launcher');
		await writeFile(
			launcher,
			template.replaceAll('@dsh@', mock).replaceAll('@patch@', '/metrics.yml'),
		);
		const run = (args) =>
			execFileSync('bash', [launcher, ...args])
				.toString()
				.split('\0')
				.slice(0, -1);
		assert.deepEqual(run(['headless', 'two words']), [
			'--patch',
			'/metrics.yml',
			'--profile',
			'headless',
			'two words',
		]);
		assert.deepEqual(run(['--profile', 'web', '--port', '3082']), [
			'--patch',
			'/metrics.yml',
			'--profile',
			'web',
			'--port',
			'3082',
		]);
		for (const args of [
			['plugin', '--profile', 'web', 'list'],
			['web', '--dump-default-config'],
			['--version'],
		]) {
			assert.deepEqual(run(args), args);
		}
	} finally {
		await rm(dir, { recursive: true, force: true });
	}
});
