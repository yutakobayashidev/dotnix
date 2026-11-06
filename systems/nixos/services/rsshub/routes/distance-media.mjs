import { readFile } from 'node:fs/promises';

export const namespace = {
	name: 'DISTANCE MEDIA',
	url: 'distance.media',
};

export const routes = [
	{
		path: '/articles',
		name: 'Articles',
		maintainers: ['yutakobayashidev'],
		handler: async () => {
			const { data } = JSON.parse(await readFile(process.env.DISTANCE_MEDIA_DATA_PATH, 'utf8'));
			return {
				title: 'DISTANCE MEDIA',
				link: 'https://distance.media/',
				language: 'ja',
				item: data
					.filter((row) => row.type === 0 && row.article_id && row.title)
					.map((row) => ({
						title: row.subtitle ? `${row.title}｜${row.subtitle}` : row.title,
						link: `https://distance.media/article/${row.article_id}/`,
						description: [row.article_theme, row.article_category].filter(Boolean).join(' / '),
						// The source uses Japanese local time without a timezone suffix.
						pubDate:
							row.update_date || row.article_date
								? `${row.update_date || row.article_date}+09:00`
								: undefined,
					})),
			};
		},
	},
];
