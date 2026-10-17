import { fetchAllBookmarks } from './bookmarks.js';
import { renderTweet } from './render.js';
import type { BookmarkTweet } from './bookmarks.js';
import { findDamagedTweets } from './storage.js';
import { setTimeout } from 'node:timers/promises';

function parseArgs(): { limit?: number; outputDir: string; repair: boolean } {
	const args = process.argv.slice(2);
	const parsed: Record<string, string> = {};
	for (let i = 0; i < args.length; i++) {
		if (args[i].startsWith('--')) {
			const key = args[i].slice(2);
			const val = args[i + 1];
			if (val && !val.startsWith('--')) {
				parsed[key] = val;
				i++;
			} else {
				parsed[key] = 'true';
			}
		}
	}
	const limit = parsed.limit === undefined ? undefined : Number(parsed.limit);
	if (limit !== undefined && (!Number.isSafeInteger(limit) || limit < 1)) {
		throw new Error('--limit must be a positive integer');
	}
	return {
		limit,
		outputDir: parsed['output-dir'] ?? 'output',
		repair: parsed.repair === 'true',
	};
}

function printSummary(
	tweets: BookmarkTweet[],
	rendered: Array<{ tweetId: string; filePath: string }>,
): void {
	console.log('\n=== Summary ===');
	console.log(`Total tweets fetched: ${tweets.length}`);
	console.log(`Total rendered: ${rendered.length}`);
	if (rendered.length > 0) {
		console.log('Rendered files:');
		for (const r of rendered) {
			console.log(`  ${r.filePath}`);
		}
	}
}

async function main(): Promise<void> {
	const { limit, outputDir, repair } = parseArgs();

	console.log(repair ? 'Finding damaged media...' : 'Fetching bookmarks via proxy...');
	const tweets = repair
		? (await findDamagedTweets(outputDir, limit)).map((id): BookmarkTweet => ({
				id,
				url: `https://x.com/i/status/${id}`,
				name: 'repair',
				screenName: '',
				text: '',
			}))
		: await fetchAllBookmarks(outputDir, limit);
	console.log(`Selected ${tweets.length} tweets`);

	const rendered: Array<{ tweetId: string; filePath: string }> = [];
	let failures = 0;
	for (const tweet of tweets) {
		if (!tweet.id) {
			console.log(`Skipping invalid tweet: ${tweet.url}`);
			continue;
		}
		console.log(`Rendering: ${tweet.id} (${tweet.name})`);
		if (repair) await setTimeout(2000);
		try {
			const result = await renderTweet(tweet.id, outputDir);
			rendered.push(result);
			console.log(`Rendered: ${result.filePath}`);
		} catch (err) {
			if ((err as NodeJS.ErrnoException).code === 'ENOSPC') throw err;
			failures++;
			console.log(`Failed to render ${tweet.id}: ${(err as Error).message}`);
		}
	}

	printSummary(tweets, rendered);
	console.log(`Total failed: ${failures}`);
	process.exitCode = failures > 0 ? 1 : 0;
}

main().catch((err) => {
	console.error(err);
	process.exit(1);
});
