return {
	"akinsho/git-conflict.nvim",
	version = "*",
	event = "BufReadPre",
	keys = {
		{ "<leader>gx", "<cmd>GitConflictListQf<cr>", desc = "List Conflicts (QuickFix)" },
	},
	config = function()
		require("git-conflict").setup({
			default_mappings = true, -- デフォルトキーマッピングを有効化
			default_commands = true, -- コマンドを有効化
			disable_diagnostics = false, -- 診断を無効にしない
			list_opener = "copen", -- quickfixリストを開く
			highlights = {
				incoming = "DiffAdd",
				current = "DiffText",
			},
		})

		-- キーマッピング（ファイル内での操作）
		-- co (choose ours) - 現在のブランチの変更を採用
		-- ct (choose theirs) - マージ元ブランチの変更を採用
		-- cb (choose both) - 両方の変更を採用
		-- c0 (choose none) - 両方の変更を削除
		-- ]x - 次のコンフリクトへ移動
		-- [x - 前のコンフリクトへ移動

		vim.api.nvim_create_autocmd("User", {
			pattern = "GitConflictDetected",
			callback = function()
				vim.notify("コンフリクトが検出されました", vim.log.levels.WARN)
			end,
		})
	end,
}
