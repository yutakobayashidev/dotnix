-- [nfnl] init.fnl
local lazypath = (vim.fn.stdpath("data") .. "/lazy")
local init_source = debug.getinfo(1, "S").source
local config_root = vim.fs.dirname(init_source:sub(2))
vim.g.dotnix_nvim_config_root = config_root
vim.secure.trust({action = "allow", path = (config_root .. "/.nfnl.fnl")})
local function ensure(user, repo, branch, fallback_path)
  local install_path = string.format("%s/%s", lazypath, repo)
  local missing_3f = (vim.fn.empty(vim.fn.glob(install_path)) > 0)
  local plugin_path
  if (missing_3f and fallback_path) then
    plugin_path = fallback_path
  else
    plugin_path = install_path
  end
  if (missing_3f and not fallback_path) then
    local args = {"git", "clone", "--filter=blob:none", "--single-branch"}
    if branch then
      table.insert(args, "--branch")
      table.insert(args, branch)
    else
    end
    table.insert(args, string.format("https://github.com/%s/%s", user, repo))
    table.insert(args, install_path)
    local result = vim.fn.system(args)
    if (vim.v.shell_error ~= 0) then
      error(result)
    else
    end
  else
  end
  return vim.opt.runtimepath:prepend(plugin_path)
end
ensure("folke", "lazy.nvim", "stable", vim.env.DOTNIX_NVIM_LAZY)
ensure("Olical", "nfnl", nil, vim.env.DOTNIX_NVIM_NFNL)
return require("rc.init")
