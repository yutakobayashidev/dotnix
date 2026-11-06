import assert from 'node:assert/strict';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';
import { routes } from '../systems/nixos/services/rsshub/routes/distance-media.mjs';

test('DISTANCE MEDIA converts a local snapshot without outbound requests', async () => {
	const directory = await mkdtemp(join(tmpdir(), 'distance-media-test-'));
	const originalFetch = globalThis.fetch;
	const originalPath = process.env.DISTANCE_MEDIA_DATA_PATH;
	globalThis.fetch = () => {
		throw new Error('Feed requests must not access the network');
	};
	process.env.DISTANCE_MEDIA_DATA_PATH = join(directory, 'snapshot.json');
	try {
		await writeFile(
			process.env.DISTANCE_MEDIA_DATA_PATH,
			JSON.stringify({
				data: [
					{
						type: 0,
						article_id: '123',
						title: 'Title',
						subtitle: 'Subtitle',
						article_theme: 'Theme',
						article_category: 'Feature',
						article_date: '2026-10-01T00:00:00',
						update_date: '2026-10-02T12:30:00',
					},
					{ type: 0, article_id: '456', title: 'No subtitle', article_date: '2026-09-01T00:00:00' },
					{ type: 0, article_id: '789', title: 'No date' },
					{ type: 1, article_id: 'excluded', title: 'Not an article' },
					{ type: 0, title: 'Missing ID' },
					{ type: 0, article_id: 'missing-title' },
				],
			}),
		);
		const feed = await routes[0].handler();
		assert.equal(feed.item.length, 3);
		assert.deepEqual(feed.item[0], {
			title: 'Title｜Subtitle',
			link: 'https://distance.media/article/123/',
			description: 'Theme / Feature',
			pubDate: '2026-10-02T12:30:00+09:00',
		});
		assert.equal(feed.item[1].pubDate, '2026-09-01T00:00:00+09:00');
		assert.equal(feed.item[2].pubDate, undefined);
		await writeFile(process.env.DISTANCE_MEDIA_DATA_PATH, 'invalid JSON');
		await assert.rejects(routes[0].handler(), SyntaxError);
		await rm(process.env.DISTANCE_MEDIA_DATA_PATH);
		await assert.rejects(routes[0].handler(), { code: 'ENOENT' });
	} finally {
		globalThis.fetch = originalFetch;
		if (originalPath === undefined) delete process.env.DISTANCE_MEDIA_DATA_PATH;
		else process.env.DISTANCE_MEDIA_DATA_PATH = originalPath;
		await rm(directory, { recursive: true, force: true });
	}
});
