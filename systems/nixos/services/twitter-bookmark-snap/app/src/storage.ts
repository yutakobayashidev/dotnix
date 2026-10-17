import { execFile } from 'node:child_process';
import { mkdir, mkdtemp, readdir, rename, rm, stat } from 'node:fs/promises';
import { basename, dirname, join, resolve } from 'node:path';
import { promisify } from 'node:util';

const execFileAsync = promisify(execFile);

export async function isValidMedia(path: string): Promise<boolean> {
	try {
		const file = await stat(path);
		if (!file.isFile() || file.size === 0) return false;
	} catch (error) {
		if ((error as NodeJS.ErrnoException).code === 'ENOENT') return false;
		throw error;
	}
	try {
		await execFileAsync(
			process.env.FFMPEG_PATH ?? 'ffmpeg',
			[
				'-v',
				'error',
				'-xerror',
				'-nostdin',
				'-threads',
				'2',
				'-i',
				path,
				'-map',
				'0:v:0',
				'-f',
				'null',
				'-',
			],
			{ timeout: 120_000, maxBuffer: 64 * 1024 },
		);
		return true;
	} catch (error) {
		const failure = error as { code?: string | number; killed?: boolean };
		if (typeof failure.code !== 'number' || failure.killed) throw error;
		return false;
	}
}

export async function hasRenderedTweet(outputDir: string, tweetId: string): Promise<boolean> {
	return (
		(await isValidMedia(join(outputDir, `${tweetId}.png`))) ||
		(await isValidMedia(join(outputDir, `${tweetId}.mp4`)))
	);
}

export async function findDamagedTweets(outputDir: string, limit?: number): Promise<string[]> {
	const ids = new Set<string>();
	for (const name of (await readdir(outputDir)).sort()) {
		const match = /^(\d+)\.(png|mp4)$/.exec(name);
		if (match && !(await isValidMedia(join(outputDir, name)))) {
			ids.add(match[1]);
			if (limit && ids.size >= limit) break;
		}
	}
	return [...ids];
}

export async function renderAtomically(
	tweetId: string,
	outputDir: string,
	render: (stagingDir: string) => Promise<string>,
): Promise<string> {
	await mkdir(outputDir, { recursive: true });
	// Same filesystem for atomic rename; excluded by the library's **/temp-* pattern.
	const stagingDir = await mkdtemp(join(resolve(outputDir), 'temp-render-'));
	try {
		const renderedPath = resolve(await render(stagingDir));
		const name = basename(renderedPath);
		if (
			dirname(renderedPath) !== stagingDir ||
			![`${tweetId}.png`, `${tweetId}.mp4`].includes(name) ||
			!(await isValidMedia(renderedPath))
		) {
			throw new Error(`Invalid rendered media for ${tweetId}`);
		}
		const destination = join(resolve(outputDir), name);
		await rename(renderedPath, destination);
		return destination;
	} finally {
		await rm(stagingDir, { recursive: true, force: true });
	}
}
