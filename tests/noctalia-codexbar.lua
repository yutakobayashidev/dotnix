-- Run from the repository root with Lua 5.2+.
local displayed = {}
local callback
local decodedUsage

barWidget = {
	setGlyph = function(value)
		displayed.glyph = value
	end,
	setText = function(value)
		displayed.text = value
	end,
	setTooltip = function(value)
		displayed.tooltip = value
	end,
}
noctalia = {
	setUpdateInterval = function() end,
	runAsync = function(_, fn)
		callback = fn
	end,
	json = {
		decode = function()
			return decodedUsage
		end,
	},
}

dofile("modules/features/window-manager/noctalia/plugins/codexbar-usage/usage.luau")

decodedUsage = {
	text = "<span foreground='#cba6f7'><b>42%</b></span> &amp; 7%",
	tooltip = "<span font_family='Mono'>Usage\n&lt;limit&gt; &amp;lt; &quot;Pro&quot; &apos;plan&apos;</span>",
}
update()
callback({ exitCode = 0, stdout = "fixture", stderr = "" })
assert(displayed.text == "42% & 7%")
assert(displayed.tooltip == "Usage\n<limit> &lt; \"Pro\" 'plan'")

-- A failed refresh retains the clean last successful value.
onRightClick()
callback({ exitCode = 1, stdout = "", stderr = "offline" })
assert(displayed.text == "42% & 7%")
assert(displayed.tooltip == "Usage\n<limit> &lt; \"Pro\" 'plan'\n\nRefresh failed: offline")

decodedUsage = { text = "Codex 12%", tooltip = "Plain text\nSecond line" }
onRightClick()
callback({ exitCode = 0, stdout = "fixture", stderr = "" })
assert(displayed.text == "Codex 12%")
assert(displayed.tooltip == "Plain text\nSecond line")

decodedUsage = {}
onRightClick()
callback({ exitCode = 0, stdout = "fixture", stderr = "" })
assert(displayed.text == "Codex")
assert(displayed.tooltip == "Codex usage")
print("Codexbar markup, entities, plain text, defaults and cached refresh: passed")
