--[[
User patch (2026-11-21): list the custom patches in KOReader's About dialog
(Menu → ⓘ Help/Info → About), for the file browser and the reader.
Remove this file (and restart KOReader) to undo.
]]
local userpatch = require("userpatch")
local logger = require("logger")

-- What each of our patches does, by file name.
local DESCRIPTIONS = {
    ["2-cwng-offline-guard.lua"] = "CWNG sync: pauses 3–30 min after a failed connection instead of freezing the UI; shorter timeouts; file-browser gestures (e.g. corner tap → light) work on the CWNG Library.",
    ["2-habitsfirst-no-page-sync.lua"] = "Habits First: no sync after every page turn; still syncs on close, sleep and Wi-Fi connect.",
    ["2-about-active-patches.lua"] = "This list.",
}

local function patchesText()
    local lines = {}
    local names = {}
    for name in pairs(userpatch.execution_status or {}) do names[#names + 1] = name end
    table.sort(names)
    for _, name in ipairs(names) do
        local ok = userpatch.execution_status[name]
        lines[#lines + 1] = string.format("%s %s%s", ok and "✓" or "⚠ FAILED:", name,
            DESCRIPTIONS[name] and ("\n   " .. DESCRIPTIONS[name]) or "")
    end
    if #lines == 0 then return "\n\nNo user patches active." end
    return "\n\nActive user patches (koreader/patches/, set up 2026-11-21):\n" .. table.concat(lines, "\n")
        .. "\n\nManage them in Tools → More tools → Patch management."
end

local function wrapAbout(menu)
    local about = menu.menu_items and menu.menu_items.about
    if not about or about._patch_list then return end
    about._patch_list = true
    about.callback = function()
        local UIManager = require("ui/uimanager")
        local InfoMessage = require("ui/widget/infomessage")
        local Version = require("version")
        UIManager:show(InfoMessage:new{
            text = "KOReader " .. Version:getCurrentRevision()
                .. "\n\nA document viewer for E Ink devices.\n\nLicensed under Affero GPL v3. All dependencies are free software.\n\nhttp://koreader.rocks"
                .. patchesText(),
            icon = "koreader",
        })
    end
end

-- MenuSorter removes entries from menu_items while sorting them into the
-- menu, so the About entry has to be changed just before mergeAndSort runs.
local MenuSorter = require("ui/menusorter")
local orig_mergeAndSort = MenuSorter.mergeAndSort
MenuSorter.mergeAndSort = function(self, config_prefix, item_table, order, ...)
    if (config_prefix == "filemanager" or config_prefix == "reader") and type(item_table) == "table" then
        local ok, err = pcall(wrapAbout, { menu_items = item_table })
        if not ok then logger.warn("about-active-patches: failed", err) end
    end
    return orig_mergeAndSort(self, config_prefix, item_table, order, ...)
end
