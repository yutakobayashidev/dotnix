import assert from 'node:assert/strict';
import app from '../node_modules/twitter-snap/dist/service/twitter/app.js';
import { TwitterOpenApi } from 'twitter-openapi-typescript';

const originalClient = TwitterOpenApi.prototype.getClient;
const originalGuest = TwitterOpenApi.prototype.getGuestClient;
const originalFetch = globalThis.fetch;
const originalUrl = process.env.TWITTER_SNAP_RELAY_URL;
const originalProfile = process.env.TWITTER_SNAP_RELAY_PROFILE;
try {
	delete process.env.TWITTER_SNAP_RELAY_URL;
	delete process.env.TWITTER_SNAP_RELAY_PROFILE;
	const guest = {};
	TwitterOpenApi.prototype.getGuestClient = async () => guest;
	assert.equal((await app.callback({ sessionType: 'guest' })).api, guest);

	process.env.TWITTER_SNAP_RELAY_URL = 'https://relay.example';
	let config;
	TwitterOpenApi.prototype.getClient = async (value) => {
		config = value;
		return {};
	};
	await app.callback({ sessionType: 'guest' });
	globalThis.fetch = async (url, init) => {
		assert.deepEqual(init.headers, {});
		return new Response('{}');
	};
	await config.fetchApi(`${config.basePath}/graphql/example`, {
		headers: { authorization: 'must-not-forward' },
	});
	process.env.TWITTER_SNAP_RELAY_PROFILE = 'test-profile';
	await app.callback({ sessionType: 'guest' });
	assert.equal(config.basePath, 'https://relay.example/i/api');
	assert.equal(config.apiKey('x-csrf-token'), undefined);
	const signal = new AbortController().signal;
	globalThis.fetch = async (url, init) => {
		assert.equal(url, 'https://relay.example/i/api/graphql/example');
		assert.deepEqual(init.headers, { 'x-profile-name': 'test-profile' });
		assert.equal(init.method, 'GET');
		assert.equal(init.signal, signal);
		return new Response('{}');
	};
	await config.fetchApi(`${config.basePath}/graphql/example`, {
		method: 'GET',
		signal,
		headers: { authorization: 'must-not-forward', 'x-csrf-token': 'must-not-forward' },
	});
	process.env.TWITTER_SNAP_RELAY_URL = 'file:///tmp/relay';
	await assert.rejects(app.callback({ sessionType: 'guest' }), /HTTP\(S\)/);
	console.log('Safe Relay configuration checks passed');
} finally {
	TwitterOpenApi.prototype.getClient = originalClient;
	TwitterOpenApi.prototype.getGuestClient = originalGuest;
	globalThis.fetch = originalFetch;
	if (originalUrl === undefined) delete process.env.TWITTER_SNAP_RELAY_URL;
	else process.env.TWITTER_SNAP_RELAY_URL = originalUrl;
	if (originalProfile === undefined) delete process.env.TWITTER_SNAP_RELAY_PROFILE;
	else process.env.TWITTER_SNAP_RELAY_PROFILE = originalProfile;
}
