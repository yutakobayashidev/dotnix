// Adapted from nyanshiba/harness-bonsai (MIT), commit 6e32b7673495966de274a2fb5fb7bd7defc92e8e.
// See LICENSE.harness-bonsai.
const agents = new Set(['build', 'build-auto']);
const actions = new Set(['read', 'edit', 'external_directory']);
const maxEntries = 2048;

function remember(map, key, value) {
	map.delete(key);
	if (map.size >= maxEntries) map.delete(map.keys().next().value);
	map.set(key, value);
}

function requestKey({ sessionID, action, resources, source }) {
	return JSON.stringify([sessionID, source.messageID, source.id, action, [...resources].sort()]);
}

function approvalKey(sessionID, agent, action, resource) {
	return JSON.stringify([sessionID, agent, action, resource]);
}

export default {
	id: 'ask-once',
	async setup(ctx) {
		const candidates = new Map();
		const pending = new Map();
		const approved = new Map();
		const controller = new AbortController();

		await ctx.permission.hook('evaluate', (event) => {
			const { agent, action, effect, resources, sessionID, source } = event;
			if (effect !== 'ask' || !agents.has(agent) || !actions.has(action)) return;
			if (source?.type !== 'tool' || !resources.length) return;

			if (
				resources.every((resource) => approved.has(approvalKey(sessionID, agent, action, resource)))
			) {
				event.effect = 'allow';
				return;
			}
			remember(candidates, requestKey(event), agent);
		});

		// A successful tool result can include a handled denial from a nested call.
		// Cache only a matching permission request with an explicit "once" reply.
		const events = ctx.event.subscribe({
			types: ['permission.asked', 'permission.replied'],
			signal: controller.signal,
		});
		void (async () => {
			for await (const { type, data } of events) {
				if (type === 'permission.asked' && data.source?.type === 'tool') {
					const key = requestKey(data);
					const agent = candidates.get(key);
					if (candidates.delete(key)) remember(pending, data.id, { agent, request: data });
				} else if (type === 'permission.replied') {
					const entry = pending.get(data.requestID);
					pending.delete(data.requestID);
					if (data.reply !== 'once' || entry?.request.sessionID !== data.sessionID) continue;
					const { agent, request } = entry;
					for (const resource of request.resources) {
						remember(
							approved,
							approvalKey(request.sessionID, agent, request.action, resource),
							true,
						);
					}
				}
			}
		})().catch(() => approved.clear());

		return () => controller.abort();
	},
};
