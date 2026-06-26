import { getSnapAppRenderWithCache } from 'twitter-snap';

export interface RenderResult {
	tweetId: string;
	filePath: string;
}

const snap = getSnapAppRenderWithCache({});

export async function renderTweet(tweetId: string, outputDir: string): Promise<RenderResult> {
	const filePath = `${outputDir}/${tweetId}.png`;
	const result = await snap({
		url: `https://x.com/i/status/${tweetId}`,
		callback: async (run) => {
			const res = await run({
				width: 1440,
				scale: 2,
				theme: 'RenderOceanBlueColor',
				output: filePath,
			});
			await res.file.tempCleanup();
			return res;
		},
	});
	return { tweetId, filePath };
}
