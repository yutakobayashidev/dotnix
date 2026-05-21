const fs = require('node:fs');

async function main() {
	const md = fs.readFileSync('./README.md', 'utf8');
	const content = (md.match(/```jsonc([\s\S]*?)```/) || [])[1] || '';

	const json = `{${content
		.trim()
		.split(/\n/g)
		.filter((line) => !line.trim().startsWith('//'))
		.join('\n')
		.slice(0, -1)}}`;

	console.log(json);
}

module.exports = { main };
