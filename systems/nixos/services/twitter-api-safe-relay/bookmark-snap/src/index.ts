import { existsSync } from 'node:fs';
import { fetchAllBookmarks } from './bookmarks.js';
import { renderTweet } from './render.js';
import type { BookmarkTweet } from './bookmarks.js';

function parseArgs(): { limit?: number; outputDir: string } {
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
	return {
		limit: parsed.limit ? Number.parseInt(parsed.limit, 10) : undefined,
		outputDir: parsed['output-dir'] ?? 'output',
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
	const { limit, outputDir } = parseArgs();

	console.log('Fetching bookmarks via proxy...');
	const tweets = await fetchAllBookmarks(limit);
	console.log(`Fetched ${tweets.length} bookmarks`);

	const rendered: Array<{ tweetId: string; filePath: string }> = [];
	for (const tweet of tweets) {
		if (!tweet.id) {
			console.log(`Skipping invalid tweet: ${tweet.url}`);
			continue;
		}
		const filePath = `${outputDir}/${tweet.id}.png`;
		const skip = existsSync(filePath);
		console.log(`${skip ? 'Skipping' : 'Rendering'}: ${tweet.id} (${tweet.name})`);
		try {
			const result = await renderTweet(tweet.id, outputDir);
			rendered.push(result);
		} catch (err) {
			console.log(`Failed to render ${tweet.id}: ${(err as Error).message}`);
		}
	}

	printSummary(tweets, rendered);
	process.exit(0);
}

main().catch((err) => {
	console.error(err);
	process.exit(1);
});
