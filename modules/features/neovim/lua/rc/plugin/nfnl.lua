-- [nfnl] fnl/rc/plugin/nfnl.fnl
local function compile_all_files()
	local nfnl = require("nfnl.api")
	local config_root = vim.g.dotnix_nvim_config_root
	local results = assert(nfnl["compile-all-files"](config_root), "nfnl did not find a project configuration")
	for _, result in ipairs(results) do
		if result.status == "compilation-error" then
			error(result.error)
		else
		end
	end
	return results
end
return vim.api.nvim_create_user_command("NfnlCompileAllFiles", compile_all_files, {})
