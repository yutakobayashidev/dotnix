import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { copyFile, mkdir, mkdtemp, readdir, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import {
	findDamagedTweets,
	hasRenderedTweet,
	isValidMedia,
	renderAtomically,
} from '../dist/storage.js';

const root = await mkdtemp(join(tmpdir(), 'bookmark-snap-test-'));
try {
	const png = join(root, '1.png');
	const mp4 = join(root, '5.mp4');
	const ffmpeg = process.env.FFMPEG_PATH ?? 'ffmpeg';
	execFileSync(ffmpeg, [
		'-v',
		'error',
		'-f',
		'lavfi',
		'-i',
		'color=c=red:s=32x32',
		'-frames:v',
		'1',
		png,
	]);
	execFileSync(ffmpeg, [
		'-v',
		'error',
		'-f',
		'lavfi',
		'-i',
		'color=c=red:s=32x32',
		'-t',
		'0.1',
		'-c:v',
		'mpeg4',
		mp4,
	]);
	const validPng = await readFile(png);
	await writeFile(join(root, '2.png'), '');
	await writeFile(join(root, '3.mp4'), 'not a video');
	await writeFile(join(root, '4.png'), validPng.subarray(0, 40));
	await writeFile(join(root, 'temp-0-6.png'), '');
	assert.equal(await isValidMedia(png), true);
	assert.equal(await isValidMedia(mp4), true);
	assert.equal(await hasRenderedTweet(root, '2'), false);
	assert.equal(await hasRenderedTweet(root, '3'), false);
	assert.equal(await hasRenderedTweet(root, '4'), false);
	assert.deepEqual(await findDamagedTweets(root), ['2', '3', '4']);
	assert.deepEqual(await findDamagedTweets(root, 1), ['2']);
	assert.equal(await hasRenderedTweet(root, '999'), false);

	const output = join(root, 'output');
	await mkdir(output);
	await writeFile(join(output, '1.png'), validPng);
	await assert.rejects(
		renderAtomically('1', output, async (dir) => {
			await writeFile(join(dir, '1.png'), 'partial');
			throw new Error('simulated render failure');
		}),
		/simulated render failure/,
	);
	assert.deepEqual(await readFile(join(output, '1.png')), validPng);
	await assert.rejects(
		renderAtomically('1', output, async (dir) => {
			const path = join(dir, '1.png');
			await writeFile(path, '');
			return path;
		}),
		/Invalid rendered media/,
	);
	assert.deepEqual(await readFile(join(output, '1.png')), validPng);
	await writeFile(join(output, '2.png'), '');
	await renderAtomically('2', output, async (dir) => {
		const path = join(dir, '2.png');
		await copyFile(png, path);
		return path;
	});
	assert.equal(await hasRenderedTweet(output, '2'), true);
	assert.deepEqual((await readdir(output)).sort(), ['1.png', '2.png']);
	console.log(
		'PASS: damaged media detection, repair discovery, atomic replacement and failure cleanup',
	);
} finally {
	await rm(root, { recursive: true, force: true });
}
