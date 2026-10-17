import { getSnapAppRenderWithCache } from 'twitter-snap';
import { renderAtomically } from './storage.js';

export interface RenderResult {
	tweetId: string;
	filePath: string;
}

const snap = getSnapAppRenderWithCache({});

export async function renderTweet(tweetId: string, outputDir: string): Promise<RenderResult> {
	const filePath = await renderAtomically(tweetId, outputDir, async (stagingDir) => {
		const [result] = await snap({
			url: `https://x.com/i/status/${tweetId}`,
			callback: async (run) => {
				const res = await run({
					width: 1440,
					scale: 2,
					theme: 'RenderOceanBlueColor',
					output: `${stagingDir}/{id}.{if-type:png:mp4:json:}`,
					ffmpegPath: process.env.FFMPEG_PATH,
					ffprobePath: process.env.FFPROBE_PATH,
				});
				return { filePath: res.file.path.toString() };
			},
		});
		if (!result) {
			throw new Error(`No render result for ${tweetId}`);
		}
		return result.filePath;
	});
	return { tweetId, filePath };
}
