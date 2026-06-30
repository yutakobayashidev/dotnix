-- [nfnl] fnl/rc/lsp.fnl
local cache = {}
local cache_order = {}
local bin_path = (vim.env.PRETTY_TS_ERRORS_BIN or "pretty-ts-errors-markdown")
local function format_ts_diagnostic(diagnostic)
	if (diagnostic.source ~= "ts") and (diagnostic.source ~= "typescript") then
		return diagnostic.message
	else
		local cache_key = (diagnostic.message .. (diagnostic.code or ""))
		local cached = cache[cache_key]
		if cached then
			return cached
		else
			local diagnostic_json = vim.json.encode(diagnostic)
			local escaped = diagnostic_json:gsub("'", "'\\''")
			local command = (bin_path .. " -i '" .. escaped .. "' 2>/dev/null")
			local handle = io.popen(command)
			if handle then
				local prettified = handle:read("*a")
				handle:close()
				if prettified and (prettified ~= "") then
					local trimmed = prettified:gsub("^%s*(.-)%s*$", "%1")
					local without_links = trimmed:gsub("%[([^%]]+)%]%(([^%)]+)%)", "%1")
					local without_open_marker = without_links:gsub("```%w*\n", "")
					local result = without_open_marker:gsub("\n```", "")
					if #cache_order >= 3 then
						local oldest = table.remove(cache_order, 1)
						cache[oldest] = nil
					else
					end
					cache[cache_key] = result
					table.insert(cache_order, cache_key)
					return result
				else
					return diagnostic.message
				end
			else
				return diagnostic.message
			end
		end
	end
end
local function _6_(diagnostic)
	return string.format("%s", diagnostic.message:match("^[^\n]*"))
end
vim.diagnostic.config({
	float = { format = format_ts_diagnostic, border = "rounded", source = true },
	virtual_text = { spacing = 4, prefix = "\226\151\143", format = _6_ },
	signs = true,
	underline = true,
	severity_sort = true,
})
local function _7_()
	return vim.diagnostic.open_float(nil, { focusable = false })
end
vim.api.nvim_create_autocmd("CursorHold", { callback = _7_ })
vim.opt.updatetime = 300
vim.lsp.config.vtsls = {
	cmd = { "vtsls", "--stdio" },
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
	root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
	settings = { typescript = { preferences = { importModuleSpecifier = "non-relative" } } },
}
vim.lsp.config.astro = {
	cmd = { "astro-ls", "--stdio" },
	filetypes = { "astro" },
	root_markers = { "package.json", "tsconfig.json", ".git" },
}
vim.lsp.config.emmet_ls = {
	cmd = { "emmet-language-server", "--stdio" },
	filetypes = { "html", "css", "scss", "javascriptreact", "typescriptreact", "vue", "svelte", "astro" },
	root_markers = { ".git" },
}
vim.lsp.config.prismals = {
	cmd = { "prisma-language-server", "--stdio" },
	filetypes = { "prisma" },
	root_markers = { "schema.prisma", ".git" },
}
vim.lsp.config.stylelint_lsp = {
	cmd = { "stylelint-lsp", "--stdio" },
	filetypes = { "css", "scss", "less", "vue", "svelte" },
	root_markers = { ".stylelintrc", ".stylelintrc.json", "stylelint.config.js", ".git" },
}
vim.lsp.config.svelte = {
	cmd = { "svelteserver", "--stdio" },
	filetypes = { "svelte" },
	root_markers = { "svelte.config.js", "package.json", ".git" },
}
vim.lsp.config.tailwindcss = {
	cmd = { "tailwindcss-language-server", "--stdio" },
	filetypes = {
		"html",
		"css",
		"scss",
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"vue",
		"svelte",
		"astro",
	},
	root_markers = { "tailwind.config.js", "tailwind.config.ts", "postcss.config.js", "vite.config.ts", ".git" },
}
vim.lsp.config.html =
	{ cmd = { "vscode-html-language-server", "--stdio" }, filetypes = { "html" }, root_markers = { ".git" } }
vim.lsp.config.cssls = {
	cmd = { "vscode-css-language-server", "--stdio" },
	filetypes = { "css", "scss", "less" },
	root_markers = { ".git" },
}
vim.lsp.config.jsonls =
	{ cmd = { "vscode-json-language-server", "--stdio" }, filetypes = { "json", "jsonc" }, root_markers = { ".git" } }
vim.lsp.config.volar = {
	cmd = { "vue-language-server", "--stdio" },
	filetypes = { "vue" },
	root_markers = { "vue.config.js", "nuxt.config.js", "nuxt.config.ts", "package.json", ".git" },
}
vim.lsp.config.yamlls = {
	cmd = { "yaml-language-server", "--stdio" },
	filetypes = { "yaml", "yaml.docker-compose" },
	root_markers = {
		".git",
	},
}
vim.lsp.config.cucumber_language_server = {
	cmd = { "cucumber-language-server", "--stdio" },
	filetypes = { "cucumber" },
	root_markers = { "cucumber.json", "cucumber.js", "cucumber.ts", "package.json", ".git" },
}
vim.lsp.config.gh_actions_ls =
	{ cmd = { "gh-actions-language-server", "--stdio" }, filetypes = { "yaml.github" }, root_markers = { ".github" } }
vim.lsp.config.version_lsp = {
	cmd = { "version-lsp" },
	filetypes = { "json", "toml", "yaml" },
	root_markers = { "package.json", "pnpm-workspace.yaml", "Cargo.toml", "go.mod", ".git" },
}
vim.lsp.config.moonbit =
	{ cmd = { "moonbit-lsp" }, filetypes = { "moonbit" }, root_markers = { "moon.mod.json", ".git" } }
vim.lsp.config.fennel_ls =
	{ cmd = { "fennel-ls" }, filetypes = { "fennel" }, root_markers = { ".nfnl.fnl", "flsproject.fnl", ".git" } }
vim.filetype.add({
	extension = { mbt = "moonbit" },
	pattern = { [".*%.github/workflows/.*%.yaml"] = "yaml.github", [".*%.github/workflows/.*%.yml"] = "yaml.github" },
})
return vim.lsp.enable({
	"vtsls",
	"astro",
	"emmet_ls",
	"prismals",
	"stylelint_lsp",
	"svelte",
	"tailwindcss",
	"html",
	"cssls",
	"jsonls",
	"eslint",
	"volar",
	"yamlls",
	"cucumber_language_server",
	"gh_actions_ls",
	"version_lsp",
	"moonbit",
	"fennel_ls",
})
