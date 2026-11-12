// dsh 0.2.2-rc.1 llm/stream waterfall. Export only numeric usage, never
// messages, tool arguments, session identifiers, credentials, or errors.
import { randomUUID } from 'node:crypto';
import { hostname } from 'node:os';

export const name = 'dsh-otel-metrics';
export const inject = ['llm'];
const tokenFields = {
  inputTokens: 'input', outputTokens: 'output',
  cacheReadTokens: 'cacheRead', cacheWriteTokens: 'cacheCreation',
};
const outcomes = new Set(['stop', 'tool-calls', 'max-tokens', 'error', 'aborted']);
const label = value => typeof value === 'string' && /^[\w./-]{1,128}$/.test(value) ? value : 'other';
const nanos = ms => (BigInt(ms) * 1_000_000n).toString();

export function apply(ctx, config) {
  const endpoint = new URL(config.endpoint);
  if (!['http:', 'https:'].includes(endpoint.protocol)) throw new Error('Invalid metrics endpoint');
  const instance = randomUUID();
  const started = Date.now();
  const points = new Map();
  let sending = Promise.resolve();
  let busy = false;
  let disposed = false;
  let lastTime = started;
  let baselines = [];

  function point(name, unit, attributes) {
    const key = JSON.stringify([name, attributes]);
    if (!points.has(key)) {
      points.set(key, { name, unit, attributes, value: 0 });
      // Send an initial zero before the first observation (including short
      // sessions), so increase() can count its first completed call.
      const zero = { ...points.get(key) };
      baselines.push(zero);
      if (baselines.length === 1) {
        sending = sending.then(() => {
          const batch = baselines;
          baselines = [];
          return post(batch);
        });
      }
    }
    return points.get(key);
  }

  async function post(snapshot) {
    const metrics = new Map();
    lastTime = Math.max(lastTime + 1, Date.now());
    const time = nanos(lastTime);
    for (const p of snapshot) {
      if (!metrics.has(p.name)) metrics.set(p.name, {
        name: p.name, unit: p.unit,
        sum: { aggregationTemporality: 2, isMonotonic: true, dataPoints: [] },
      });
      metrics.get(p.name).sum.dataPoints.push({
        attributes: Object.entries(p.attributes).map(([key, value]) => ({ key, value: { stringValue: value } })),
        startTimeUnixNano: nanos(started), timeUnixNano: time, asDouble: p.value,
      });
    }
    const body = { resourceMetrics: [{
      resource: { attributes: [
        { key: 'service.name', value: { stringValue: 'dsh' } },
        { key: 'host.name', value: { stringValue: hostname() } },
        { key: 'service.instance.id', value: { stringValue: instance } },
      ] },
      scopeMetrics: [{ scope: { name }, metrics: [...metrics.values()] }],
    }] };
    try {
      const response = await fetch(endpoint, {
        method: 'POST', headers: { 'content-type': 'application/json' },
        body: JSON.stringify(body), signal: AbortSignal.timeout(2_000),
      });
      await response.body?.cancel();
      // The next cumulative sample includes missed exports, while this
      // process is alive. Telemetry failures must not affect LLM calls.
    } catch { /* No request/error bodies in logs. */ }
  }

  function flush() {
    if (busy || !points.size) return sending;
    busy = true;
    const snapshot = [...points.values()].map(p => ({ ...p }));
    sending = sending.then(() => post(snapshot)).finally(() => { busy = false; });
    return sending;
  }

  ctx.on('llm/stream', async function* (options, next) {
    if (disposed) { yield* next(); return; }
    const attributes = { provider: label(options.provider), model: label(options.model) };
    const tokens = Object.entries(tokenFields).map(([field, type]) => [field,
      point('dsh.token.usage', 'tokens', { ...attributes, type })]);
    const calls = {};
    for (const outcome of [...outcomes, 'other']) {
      calls[outcome] = point('dsh.api.request', '1', { ...attributes, outcome });
    }
    const duration = point('dsh.api.duration', 's', attributes);
    const reported = point('dsh.api.usage_reported', '1', attributes);
    const start = performance.now();
    let usage;
    let outcome = 'aborted'; // Includes consumers closing the iterator early.
    try {
      for await (const chunk of next()) {
        // Providers can revise cumulative usage during a stream: keep the
        // last sample instead of summing chunks. Copy only numeric fields.
        if (chunk.type === 'usage') {
          usage = Object.fromEntries(Object.keys(tokenFields).map(field => [field, chunk.usage[field]]));
        }
        if (chunk.type === 'finish') outcome = outcomes.has(chunk.reason.kind) ? chunk.reason.kind : 'other';
        yield chunk;
      }
    } catch (error) {
      outcome = options.signal?.aborted ? 'aborted' : 'error';
      throw error;
    } finally {
      calls[outcome].value++;
      duration.value += Math.max(0, performance.now() - start) / 1000;
      if (usage) {
        reported.value++;
        for (const [field, p] of tokens) {
          if (Number.isFinite(usage[field]) && usage[field] >= 0) p.value += usage[field];
        }
      }
    }
  });
  const timer = setInterval(() => void flush(), 10_000);
  timer.unref();
  ctx.effect(() => async () => {
    disposed = true;
    clearInterval(timer);
    await sending;
    await flush();
  });
}
