import { existsSync } from 'node:fs';
import { TwitterClient } from '@yuta/bird';
import type { TweetData } from '@yuta/bird';

const PROXY_URL = 'https://tw.home.yutakobayashi.com';
const PROFILE_NAME = 'account2';
const CONSECUTIVE_EXISTING_THRESHOLD = 5;

export interface BookmarkTweet {
	id: string;
	url: string;
	name: string;
	screenName: string;
	text: string;
}

function mapTweet(tweet: TweetData): BookmarkTweet {
	return {
		id: tweet.id,
		url: `https://x.com/i/status/${tweet.id}`,
		name: tweet.author?.name ?? 'unknown',
		screenName: tweet.author?.username ?? 'unknown',
		text: tweet.text.slice(0, 100),
	};
}

function hasRenderedTweet(outputDir: string, tweetId: string): boolean {
	return existsSync(`${outputDir}/${tweetId}.png`) || existsSync(`${outputDir}/${tweetId}.mp4`);
}

async function randomSleep(minMs: number, maxMs: number): Promise<void> {
	const delay = Math.floor(Math.random() * (maxMs - minMs) + minMs);
	await new Promise((resolve) => setTimeout(resolve, delay));
}

export async function fetchAllBookmarks(
	outputDir: string,
	limit?: number,
): Promise<BookmarkTweet[]> {
	const client = new TwitterClient({
		relayBaseUrl: PROXY_URL,
		profileName: PROFILE_NAME,
	});

	const all: BookmarkTweet[] = [];
	let cursor: string | null = null;
	let page = 0;
	let consecutiveExisting = 0;

	while (true) {
		page++;
		const result = await client.getAllBookmarks({
			cursor: cursor ?? undefined,
			maxPages: 1,
		});

		if (!result.success || !result.tweets || result.tweets.length === 0) break;

		for (const tweet of result.tweets) {
			if (hasRenderedTweet(outputDir, tweet.id)) {
				consecutiveExisting++;
				if (consecutiveExisting >= CONSECUTIVE_EXISTING_THRESHOLD) {
					console.log(
						`[page ${page}] ${consecutiveExisting} consecutive existing tweets, stopping fetch`,
					);
					return all;
				}
				continue;
			}
			consecutiveExisting = 0;
			all.push(mapTweet(tweet));
			if (limit && all.length >= limit) return all;
		}

		console.log(`[page ${page}] fetched ${result.tweets.length} tweets (new: ${all.length})`);
		if (!result.nextCursor) break;
		cursor = result.nextCursor;
		await randomSleep(2000, 5000);
	}

	return all;
}
