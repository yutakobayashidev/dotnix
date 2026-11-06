# RSSHub

RSSHub runs on B450M-Pro4 with Redis. Its configuration and private route modules
live in `systems/nixos/services/rsshub/`.

## DISTANCE MEDIA

Feed: `https://rsshub.home.yutakobayashi.com/distance-media/articles`

The `rsshub-distance-media` systemd timer fetches the fixed upstream URL
`https://distance.media/dist/js/distanceposts.json` at boot and every 30 minutes.
It validates the JSON and atomically replaces `/var/lib/rsshub/distanceposts.json`.
A failed refresh preserves the previous snapshot. RSSHub reads this file without
making network requests in the route handler. RSSHub's standard query parameters
remain available, including options such as `mode=fulltext` that perform extra
network requests in its shared middleware. No ingress restrictions are added.
The feed is unavailable until the first successful refresh; after that a failed
refresh leaves the feed serving the last successful snapshot. Check the timer's
service journal for refresh failures. RSSHub's normal response cache also applies.

The route ports `parseDistanceMediaItems` from
[Radar's workflow](https://github.com/yutakobayashidev/radar/blob/ae4d3e06d864bb0631a9f5d770fc59efacf5eb9b/workers/workflow.ts#L15):
only `type: 0` entries with an ID and title are included; subtitles are joined
with `｜`, theme/category form the description, and update dates take precedence
over publication dates. Timezone-less source dates are interpreted as Japan time.
Radar's workflow and subscriptions are not changed by this configuration.

Scheduled snapshot fetching applies only to this custom route. Existing built-in RSSHub
routes retain their normal request-driven fetching behavior.

Verify after deployment:

```sh
systemctl status rsshub rsshub-distance-media.timer
journalctl -u rsshub-distance-media -n 20
curl --fail http://127.0.0.1:1200/distance-media/articles
```

Run the route tests with Node.js:

```sh
node --test tests/rsshub-distance-media.mjs
```
