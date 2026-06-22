const PROXY_URL = 'https://tw.home.yutakobayashi.com';
const BOOKMARKS_QUERY_ID = 'R5wixmhMi4oEBUYvBM-44g';

const FEATURES = {
	rweb_video_screen_enabled: false,
	rweb_cashtags_enabled: true,
	profile_label_improvements_pcf_label_in_post_enabled: true,
	responsive_web_profile_redirect_enabled: false,
	rweb_tipjar_consumption_enabled: false,
	creator_subscriptions_tweet_preview_api_enabled: true,
	responsive_web_graphql_timeline_navigation_enabled: true,
	responsive_web_graphql_skip_user_profile_image_extensions_enabled: false,
	premium_content_api_read_enabled: false,
	communities_web_enable_tweet_community_results_fetch: true,
	c9s_tweet_anatomy_moderator_badge_enabled: true,
	responsive_web_grok_analyze_button_fetch_trends_enabled: false,
	responsive_web_grok_analyze_post_followups_enabled: true,
	rweb_cashtags_composer_attachment_enabled: true,
	responsive_web_jetfuel_frame: true,
	responsive_web_grok_share_attachment_enabled: true,
	responsive_web_grok_annotations_enabled: true,
	articles_preview_enabled: true,
	responsive_web_edit_tweet_api_enabled: true,
	rweb_conversational_replies_downvote_enabled: false,
	graphql_is_translatable_rweb_tweet_is_translatable_enabled: true,
	view_counts_everywhere_api_enabled: true,
	longform_notetweets_consumption_enabled: true,
	responsive_web_twitter_article_tweet_consumption_enabled: true,
	content_disclosure_indicator_enabled: true,
	content_disclosure_ai_generated_indicator_enabled: true,
	responsive_web_grok_show_grok_translated_post: true,
	responsive_web_grok_analysis_button_from_backend: true,
	post_ctas_fetch_enabled: false,
	freedom_of_speech_not_reach_fetch_enabled: true,
	standardized_nudges_misinfo: true,
	tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled: true,
	longform_notetweets_rich_text_read_enabled: true,
	longform_notetweets_inline_media_enabled: false,
	responsive_web_grok_image_annotation_enabled: true,
	responsive_web_grok_imagine_annotation_enabled: true,
	responsive_web_grok_community_note_auto_translation_is_enabled: true,
	responsive_web_enhance_cards_enabled: false,
};

export interface BookmarkTweet {
	id: string;
	url: string;
	name: string;
	screenName: string;
	text: string;
}

export interface BookmarksPage {
	tweets: BookmarkTweet[];
	cursor: string | null;
}

function extractTweet(result: Record<string, unknown>): BookmarkTweet {
	if (result.__typename === 'TweetWithVisibilityResults') {
		const tweet = (result as { tweet: Record<string, unknown> }).tweet;
		if (tweet) return extractTweet(tweet);
	}
	const legacy = (result as { legacy?: Record<string, unknown> }).legacy ?? {};
	const userResult = (
		result as {
			core?: {
				user_results?: {
					result?: { core?: Record<string, unknown>; legacy?: Record<string, unknown> };
				};
			};
		}
	).core?.user_results?.result;
	const userCore = userResult?.core ?? {};
	const userLegacy = userResult?.legacy ?? {};
	return {
		id: (result.rest_id ?? legacy.id_str) as string,
		url: `https://x.com/i/status/${(result.rest_id ?? legacy.id_str) as string}`,
		name: (userCore.name ?? userLegacy.name ?? 'unknown') as string,
		screenName: (userCore.screen_name ?? userLegacy.screen_name ?? 'unknown') as string,
		text: ((legacy.full_text as string) ?? '').slice(0, 100),
	};
}

export async function fetchBookmarksPage(
	cursor: string | null,
	count = 20,
): Promise<BookmarksPage> {
	const variables: Record<string, unknown> = {
		count,
		includePromotedContent: true,
	};
	if (cursor) {
		variables.cursor = cursor;
	}
	const params = new URLSearchParams({
		variables: JSON.stringify(variables),
		features: JSON.stringify(FEATURES),
	});
	const response = await fetch(
		`${PROXY_URL}/i/api/graphql/${BOOKMARKS_QUERY_ID}/Bookmarks?${params}`,
	);
	const data = (await response.json()) as {
		data: { bookmark_timeline_v2: { timeline: Record<string, unknown> } };
	};
	const timeline = data.data.bookmark_timeline_v2.timeline;
	const instructions = timeline.instructions as Array<{ entries?: Array<Record<string, unknown>> }>;
	const tweets: BookmarkTweet[] = [];
	let nextCursor: string | null = null;
	for (const instr of instructions) {
		if (!instr.entries) continue;
		for (const entry of instr.entries) {
			const content = entry.content as Record<string, unknown>;
			if (content.cursorType === 'Bottom') {
				nextCursor = content.value as string;
			} else if (content.itemContent) {
				const itemContent = content.itemContent as {
					tweet_results?: { result?: Record<string, unknown> };
				};
				if (itemContent.tweet_results?.result) {
					tweets.push(extractTweet(itemContent.tweet_results.result));
				}
			}
		}
	}
	return { tweets, cursor: nextCursor };
}

async function randomSleep(minMs: number, maxMs: number): Promise<void> {
	const delay = Math.floor(Math.random() * (maxMs - minMs) + minMs);
	await new Promise((resolve) => setTimeout(resolve, delay));
}

export async function fetchAllBookmarks(limit?: number): Promise<BookmarkTweet[]> {
	const all: BookmarkTweet[] = [];
	let cursor: string | null = null;
	let page = 0;
	while (true) {
		page++;
		const result = await fetchBookmarksPage(cursor, 20);
		for (const tweet of result.tweets) {
			all.push(tweet);
			if (limit && all.length >= limit) return all.slice(0, limit);
		}
		console.log(`[page ${page}] fetched ${result.tweets.length} tweets (total: ${all.length})`);
		if (!result.cursor || result.tweets.length === 0) break;
		cursor = result.cursor;
		await randomSleep(2000, 5000);
	}
	return limit ? all.slice(0, limit) : all;
}
