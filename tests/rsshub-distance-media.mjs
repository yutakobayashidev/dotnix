import assert from 'node:assert/strict';
import { test } from 'node:test';
import { routes } from '../systems/nixos/services/rsshub/routes/distance-media.mjs';

test('DISTANCE MEDIA converts articles and reports upstream errors', async (t) => {
	const fetchMock = t.mock.method(globalThis, 'fetch', async (url) => {
		assert.equal(url, 'https://distance.media/dist/js/distanceposts.json');
		return Response.json({
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
		});
	});
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
	fetchMock.mock.mockImplementation(async () => new Response('', { status: 503 }));
	await assert.rejects(routes[0].handler(), /HTTP 503/);
	fetchMock.mock.mockImplementation(async () => new Response('invalid JSON'));
	await assert.rejects(routes[0].handler(), SyntaxError);
});
