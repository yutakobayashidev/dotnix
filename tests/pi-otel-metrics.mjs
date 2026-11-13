import assert from 'node:assert/strict';
import test from 'node:test';

const extension = new URL(
	'../modules/features/super-intelligence/pi/extensions/otel-metrics.ts',
	import.meta.url,
);

test('short Pi sessions seed zero before usage, count new sessions only, and exclude content', async () => {
	const sent = [];
	const originalFetch = globalThis.fetch;
	globalThis.fetch = async (_url, init) => {
		sent.push(JSON.parse(init.body));
		return { ok: true };
	};
	try {
		const handlers = {};
		const { default: register } = await import(`${extension}?test=usage`);
		register({
			on: (name, fn) => {
				handlers[name] = fn;
			},
		});
		handlers.session_start(
			{ reason: 'startup' },
			{ sessionManager: { getEntries: () => [{ type: 'message' }] } },
		);
		handlers.session_start({ reason: 'new' }, { sessionManager: { getEntries: () => [] } });
		handlers.message_end({ message: { role: 'user', content: 'private prompt' } });
		handlers.message_end({
			message: {
				role: 'assistant',
				model: 'test-model',
				provider: 'test-provider',
				content: 'private reply',
				usage: { input: 5, output: 3, cacheRead: 2, cacheWrite: 0, cost: { total: 0.01 } },
			},
		});
		handlers.tool_execution_end({
			toolName: 'read',
			isError: true,
			result: 'private file content',
		});
		await handlers.session_shutdown();
		const metrics = sent.flatMap((b) =>
			b.resourceMetrics.flatMap((r) => r.scopeMetrics.flatMap((s) => s.metrics)),
		);
		const sessions = metrics
			.filter((m) => m.name === 'pi.session.count')
			.flatMap((m) => m.sum.dataPoints);
		assert.deepEqual(
			sessions.map((p) => p.asDouble),
			[0, 1],
		);
		const input = metrics
			.filter((m) => m.name === 'pi.token.usage')
			.flatMap((m) => m.sum.dataPoints)
			.filter((p) => p.attributes.some((a) => a.key === 'type' && a.value.stringValue === 'input'));
		assert.deepEqual(
			input.map((p) => p.asDouble),
			[0, 5],
		);
		assert.ok(BigInt(input[0].timeUnixNano) <= BigInt(input[1].startTimeUnixNano));
		assert.ok(metrics.every((m) => m.sum.aggregationTemporality === 1));
		const serialized = JSON.stringify(sent);
		assert.ok(!serialized.includes('private'));
		assert.ok(serialized.includes('service.instance.id'));
		assert.ok(serialized.includes('false'));
	} finally {
		globalThis.fetch = originalFetch;
	}
});

test('an unavailable collector does not reject session shutdown', async () => {
	const originalFetch = globalThis.fetch;
	globalThis.fetch = async () => {
		throw new Error('offline');
	};
	try {
		const handlers = {};
		const { default: register } = await import(`${extension}?test=offline`);
		register({
			on: (name, fn) => {
				handlers[name] = fn;
			},
		});
		handlers.session_start({ reason: 'new' }, { sessionManager: { getEntries: () => [] } });
		await assert.doesNotReject(handlers.session_shutdown());
	} finally {
		globalThis.fetch = originalFetch;
	}
});
