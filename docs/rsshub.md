# RSSHub

RSSHub runs on B450M-Pro4 with Redis. Its configuration and private route modules
live in `systems/nixos/services/rsshub/`.

## DISTANCE MEDIA

Feed: `https://rsshub.home.yutakobayashi.com/distance-media/articles`

The route fetches `https://distance.media/dist/js/distanceposts.json` and converts
its articles to RSS. RSSHub's standard Redis-backed response cache handles reuse:
a request after cache expiry fetches the latest data. No separate service, timer,
or local snapshot is needed.

The route ports `parseDistanceMediaItems` from
[Radar's workflow](https://github.com/yutakobayashidev/radar/blob/ae4d3e06d864bb0631a9f5d770fc59efacf5eb9b/workers/workflow.ts#L15):
only `type: 0` entries with an ID and title are included; subtitles are joined
with `｜`, theme/category form the description, and update dates take precedence
over publication dates. Timezone-less source dates are interpreted as Japan time.
Radar's workflow and subscriptions are not changed by this configuration.

Verify after deployment:

```sh
systemctl status rsshub
journalctl -u rsshub -n 20
curl --fail http://127.0.0.1:1200/distance-media/articles
```

Run the route tests with Node.js:

```sh
node --test tests/rsshub-distance-media.mjs
```
