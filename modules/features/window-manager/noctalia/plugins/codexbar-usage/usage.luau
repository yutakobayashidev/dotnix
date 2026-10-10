local codexbar = "@codexbarPath@"
local usagePage = "https://chatgpt.com/codex/settings/usage"
local refreshIntervalMs = 60000

local refreshing = false
local lastSuccessfulUsage = nil

local function showUsage(usage, refreshError)
    barWidget.setGlyph("ai")
    barWidget.setText(usage.text or "Codex")

    local tooltip = usage.tooltip or "Codex usage"
    if refreshError ~= nil then
        tooltip = tooltip .. "\n\nRefresh failed: " .. refreshError
    end
    barWidget.setTooltip(tooltip)
end

local function showError(message)
    if lastSuccessfulUsage ~= nil then
        showUsage(lastSuccessfulUsage, message)
        return
    end

    barWidget.setGlyph("alert-circle")
    barWidget.setText("Codex: unavailable")
    barWidget.setTooltip("codexbar: " .. message)
end

local function refresh()
    if refreshing then
        return
    end

    refreshing = true
    noctalia.runAsync(codexbar, function(result)
        refreshing = false

        if result.exitCode ~= 0 then
            showError(result.stderr ~= "" and result.stderr or "exit " .. tostring(result.exitCode))
            return
        end

        local usage, err = noctalia.json.decode(result.stdout)
        if usage == nil then
            showError("invalid JSON: " .. (err or "unknown error"))
            return
        end

        lastSuccessfulUsage = usage
        showUsage(usage, nil)
    end, 30000)
end

function update()
    noctalia.setUpdateInterval(refreshIntervalMs)
    refresh()
end

function onClick()
    noctalia.runAsync("xdg-open " .. usagePage)
end

function onRightClick()
    refresh()
end
