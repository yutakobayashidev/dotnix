-- [nfnl] fnl/rc/plugin/autopairs.fnl
local autopairs = require("nvim-autopairs")
return autopairs.setup({ disable_filetype = { "TelescopePrompt", "vim" } })
