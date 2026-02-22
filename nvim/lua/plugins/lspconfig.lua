-- pretty-ts-errors formatter (installed via Nix)
local cache = {}
local cache_order = {}
local bin_path = vim.env.PRETTY_TS_ERRORS_BIN or "pretty-ts-errors-markdown"

local function format_ts_diagnostic(diagnostic)
	if diagnostic.source ~= "ts" and diagnostic.source ~= "typescript" then
		return diagnostic.message
	end

	local cache_key = diagnostic.message .. (diagnostic.code or "")
	if cache[cache_key] then
		return cache[cache_key]
	end

	local diagnostic_json = vim.json.encode(diagnostic)
	local handle = io.popen(bin_path .. " -i '" .. diagnostic_json:gsub("'", "'\\''") .. "' 2>/dev/null")
	if handle then
		local prettified = handle:read("*a")
		handle:close()
		if prettified and prettified ~= "" then
			local result = prettified:gsub("^%s*(.-)%s*$", "%1")
			-- remove markdown links
			result = result:gsub("%[([^%]]+)%]%(([^%)]+)%)", "%1")
			-- remove codeblock markers
			result = result:gsub("```%w*\n", ""):gsub("\n```", "")

			if #cache_order >= 3 then
				local oldest = table.remove(cache_order, 1)
				cache[oldest] = nil
			end
			cache[cache_key] = result
			table.insert(cache_order, cache_key)
			return result
		end
	end
	return diagnostic.message
end

-- diagnostic display config
vim.diagnostic.config({
	float = {
		format = format_ts_diagnostic,
		border = "rounded",
		source = true,
	},
	virtual_text = {
		spacing = 4,
		prefix = "●",
		format = function(diagnostic)
			return string.format("%s", diagnostic.message:match("^[^\n]*"))
		end,
	},
	signs = true,
	underline = true,
	severity_sort = true,
})

-- カーソルホールド時に自動でフロート表示
vim.api.nvim_create_autocmd("CursorHold", {
	callback = function()
		vim.diagnostic.open_float(nil, { focusable = false })
	end,
})

-- ホールド時間を短く (デフォルト4000ms → 300ms)
vim.opt.updatetime = 300

-- LSP configs using vim.lsp.config (Neovim 0.11+)

-- vtsls (TypeScript/JavaScript)
vim.lsp.config.vtsls = {
	cmd = { "vtsls", "--stdio" },
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
	root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
	settings = {
		typescript = {
			preferences = {
				importModuleSpecifier = "non-relative",
			},
		},
	},
}

-- astro
vim.lsp.config.astro = {
	cmd = { "astro-ls", "--stdio" },
	filetypes = { "astro" },
	root_markers = { "package.json", "tsconfig.json", ".git" },
}

-- emmet
vim.lsp.config.emmet_ls = {
	cmd = { "emmet-language-server", "--stdio" },
	filetypes = { "html", "css", "scss", "javascriptreact", "typescriptreact", "vue", "svelte", "astro" },
	root_markers = { ".git" },
}

-- prisma
vim.lsp.config.prismals = {
	cmd = { "prisma-language-server", "--stdio" },
	filetypes = { "prisma" },
	root_markers = { "schema.prisma", ".git" },
}

-- stylelint
vim.lsp.config.stylelint_lsp = {
	cmd = { "stylelint-lsp", "--stdio" },
	filetypes = { "css", "scss", "less", "vue", "svelte" },
	root_markers = { ".stylelintrc", ".stylelintrc.json", "stylelint.config.js", ".git" },
}

-- svelte
vim.lsp.config.svelte = {
	cmd = { "svelteserver", "--stdio" },
	filetypes = { "svelte" },
	root_markers = { "svelte.config.js", "package.json", ".git" },
}

-- tailwindcss
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
	root_markers = { "tailwind.config.js", "tailwind.config.ts", "postcss.config.js", ".git" },
}

-- html (vscode-langservers-extracted)
vim.lsp.config.html = {
	cmd = { "vscode-html-language-server", "--stdio" },
	filetypes = { "html" },
	root_markers = { ".git" },
}

-- cssls (vscode-langservers-extracted)
vim.lsp.config.cssls = {
	cmd = { "vscode-css-language-server", "--stdio" },
	filetypes = { "css", "scss", "less" },
	root_markers = { ".git" },
}

-- jsonls (vscode-langservers-extracted)
vim.lsp.config.jsonls = {
	cmd = { "vscode-json-language-server", "--stdio" },
	filetypes = { "json", "jsonc" },
	root_markers = { ".git" },
}

-- vue (volar)
vim.lsp.config.volar = {
	cmd = { "vue-language-server", "--stdio" },
	filetypes = { "vue" },
	root_markers = { "vue.config.js", "nuxt.config.js", "nuxt.config.ts", "package.json", ".git" },
}

-- yamlls
vim.lsp.config.yamlls = {
	cmd = { "yaml-language-server", "--stdio" },
	filetypes = { "yaml", "yaml.docker-compose" },
	root_markers = { ".git" },
}

-- version-lsp
vim.lsp.config.version_lsp = {
	cmd = { "version-lsp" },
	filetypes = { "json", "toml", "yaml" },
	root_markers = { "package.json", "pnpm-workspace.yaml", "Cargo.toml", "go.mod", ".git" },
}

-- Enable all LSPs
vim.lsp.enable({
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
	"version_lsp",
})

return {}
