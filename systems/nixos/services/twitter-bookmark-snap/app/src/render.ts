import { getSnapAppRenderWithCache } from 'twitter-snap';

export interface RenderResult {
	tweetId: string;
	filePath: string;
}

const snap = getSnapAppRenderWithCache({});

export async function renderTweet(tweetId: string, outputDir: string): Promise<RenderResult> {
	const [result] = await snap({
		url: `https://x.com/i/status/${tweetId}`,
		callback: async (run) => {
			const res = await run({
				width: 1440,
				scale: 2,
				theme: 'RenderOceanBlueColor',
				output: `${outputDir}/{id}.{if-type:png:mp4:json:}`,
				ffmpegPath: process.env.FFMPEG_PATH,
				ffprobePath: process.env.FFPROBE_PATH,
			});
			const filePath = res.file.path.toString();
			await res.file.tempCleanup();
			return { filePath };
		},
	});
	if (!result) {
		throw new Error(`No render result for ${tweetId}`);
	}
	return { tweetId, filePath: result.filePath };
}
