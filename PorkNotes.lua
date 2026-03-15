-- PorkNotes v0.2.0
-- by MrToffee and porkfriedlumpia

PorkNotes = PorkNotes or {}

local PORKNOTES_VERSION = "0.2.0"
local realm = GetRealmName()

-- Debug toggle
PorkNotes.ChatDebug = false

-- Event registration helper
local function RegisterEvent(event, func)
    local frame = CreateFrame("Frame")
    frame:RegisterEvent(event)
    frame:SetScript("OnEvent", func)
end

-- Notes data functions
PorkNotes.GetAllNotes = function()
    if PorkNotes_Data and PorkNotes_Data[realm] then
        return PorkNotes_Data[realm].notes
    end
    return nil
end

PorkNotes.GetPlayerNote = function(playername)
    if playername and PorkNotes_Data and PorkNotes_Data[realm] and PorkNotes_Data[realm].notes then
        return PorkNotes_Data[realm].notes[playername]
    end
    return nil
end

PorkNotes.SetPlayerNote = function(playername, text)
    if not playername or not PorkNotes_Data or not PorkNotes_Data[realm] or not PorkNotes_Data[realm].notes then return end

    if text and text ~= "" then
        if not PorkNotes_Data[realm].notes[playername] then
            -- New note — no history to record
            PorkNotes_Data[realm].notes[playername] = {
                created = time(),
                createdBy = UnitName("player"),
                createdAtZone = GetRealZoneText(),
                history = {}
            }
        else
            -- Existing note — archive current text to history before overwriting
            local existing = PorkNotes_Data[realm].notes[playername]
            if existing.text and existing.text ~= "" then
                existing.history = existing.history or {}
                table.insert(existing.history, {
                    text = existing.text,
                    editedBy = existing.updatedBy or existing.createdBy,
                    editedAt = existing.updated or existing.created
                })
            end
        end
        PorkNotes_Data[realm].notes[playername].text = text
        PorkNotes_Data[realm].notes[playername].updated = time()
        PorkNotes_Data[realm].notes[playername].updatedBy = UnitName("player")
        PorkNotes_Data[realm].notes[playername].updatedAtZone = GetRealZoneText()
    else
        PorkNotes_Data[realm].notes[playername] = nil
    end
end

-- Settings helper
PorkNotes.GetSetting = function(setting, defaultValue)
    if not PorkNotes_Settings then return defaultValue end
    if PorkNotes_Settings[setting] == nil then return defaultValue end
    return PorkNotes_Settings[setting]
end

PorkNotes.SetSetting = function(setting, value)
    PorkNotes_Settings[setting] = value
end

-- CaramelNotes import
PorkNotes.ImportFromCaramelNotes = function()
    if not CaramelNotes_Data then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[PorkNotes]|r No CaramelNotes data found.")
        return
    end
    local imported = 0
    local skipped = 0
    for realmName, realmData in pairs(CaramelNotes_Data) do
        if realmData.notes then
            PorkNotes_Data[realmName] = PorkNotes_Data[realmName] or {}
            PorkNotes_Data[realmName].notes = PorkNotes_Data[realmName].notes or {}
            for playername, note in pairs(realmData.notes) do
                if not PorkNotes_Data[realmName].notes[playername] then
                    PorkNotes_Data[realmName].notes[playername] = note
                    imported = imported + 1
                else
                    skipped = skipped + 1
                end
            end
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[PorkNotes]|r Import complete: " .. imported .. " notes imported, " .. skipped .. " skipped (already exist).")
    PorkNotes.UpdateNotesFrame()
end

-- Check if PorkNotes has any notes across all realms
local function HasAnyNotes()
    if not PorkNotes_Data then return false end
    for _, realmData in pairs(PorkNotes_Data) do
        if realmData.notes then
            for _ in pairs(realmData.notes) do
                return true
            end
        end
    end
    return false
end

-- Addon loaded
local function OnAddonLoaded()
    if arg1 == "PorkNotes" then
        PorkNotes_Data = PorkNotes_Data or {}
        PorkNotes_Data[realm] = PorkNotes_Data[realm] or {}
        PorkNotes_Data[realm].notes = PorkNotes_Data[realm].notes or {}
        PorkNotes_Settings = PorkNotes_Settings or {}

        -- Prompt for CaramelNotes import if data exists and PorkNotes has no notes yet
        if CaramelNotes_Data and not HasAnyNotes() then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[PorkNotes]|r CaramelNotes data detected. Type |cffffcc00/pn import|r to import your notes.")
        end

        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[PorkNotes]|r v" .. PORKNOTES_VERSION .. " loaded. Type |cffffcc00/pn|r to open.")
    end
end

-- Item ref handler
local originalSetItemRef = SetItemRef
function SetItemRef(link, text, button)
    if string.sub(link, 1, 10) == "porknotes:" then
        PorkNotes.ShowNoteDetailFrame(string.sub(link, 11))
    else
        originalSetItemRef(link, text, button)
    end
end

-- Mouseover tooltip
local lastMouseoverTooltipNote = nil

-- Reset tracker when tooltip is hidden so re-hovering the same player works
GameTooltip:HookScript("OnHide", function()
    lastMouseoverTooltipNote = nil
end)

local function OnUpdateMouseoverUnit()
    if not PorkNotes.GetSetting("ShowNotesInTooltips", true) then
        lastMouseoverTooltipNote = nil
        return
    end
    local unit = "mouseover"
    if not UnitIsPlayer(unit) then
        lastMouseoverTooltipNote = nil
        return
    end
    if not GameTooltip:IsShown() then
        lastMouseoverTooltipNote = nil
        return
    end
    local name = UnitName(unit)
    local note = PorkNotes.GetPlayerNote(name)
    if not note then
        lastMouseoverTooltipNote = nil
        return
    end
    if lastMouseoverTooltipNote == name then return end
    lastMouseoverTooltipNote = name
    GameTooltip:AddLine(note.text, 1, 1, 0)
    GameTooltip:Show()
end

-- UnitPopup menus
local function RegisterUnitPopupMenus()
    if UnitPopupButtons["PORKNOTES_EDIT_NOTE"] then return end
    UnitPopupButtons["PORKNOTES_EDIT_NOTE"] = { text = "Edit note", dist = 0 }
    local menus = { "PLAYER", "FRIEND", "PARTY", "RAID" }
    for _, menu in ipairs(menus) do
        local atIndex = 1
        for index, value in ipairs(UnitPopupMenus[menu]) do
            if value == "CANCEL" then atIndex = index break end
        end
        table.insert(UnitPopupMenus[menu], atIndex, "PORKNOTES_EDIT_NOTE")
    end
end

-- Hook unit popup
hooksecurefunc("UnitPopup_OnClick", function()
    local button = this
    if not button then return end
    if button.value == "PORKNOTES_EDIT_NOTE" then
        local menu = UIDROPDOWNMENU_INIT_MENU
        if type(menu) == "string" then menu = _G[menu] end
        local playername = menu and menu.name
        if playername then PorkNotes.ShowNoteDetailFrame(playername) end
    end
end)

-- Slash commands
local function RegisterCommands()
    SLASH_PORKNOTES1 = "/porknotes"
    SLASH_PORKNOTES2 = "/pn"
    SlashCmdList["PORKNOTES"] = function(msg)
        if string.lower(msg) == "import" then
            PorkNotes.ImportFromCaramelNotes()
        else
            PorkNotes.ShowNotesFrame()
        end
    end

    SLASH_PORKNOTESDEBUG1 = "/pndebug"
    SlashCmdList["PORKNOTESDEBUG"] = function(msg)
        PorkNotes.ChatDebug = not PorkNotes.ChatDebug
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[PorkNotes]|r Chat debug: " .. tostring(PorkNotes.ChatDebug))
    end
end

-- Chat alert routing
local function SendChatFrame1(alertText)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(alertText)
    end
end

-- Build chat alert metadata suffix based on settings
local function BuildAlertMetadata(note)
    local showCreatedBy = PorkNotes.GetSetting("ChatShowCreatedBy", false)
    local showTimestamp = PorkNotes.GetSetting("ChatShowTimestamp", false)

    local meta = {}
    if showCreatedBy and note.createdBy then
        table.insert(meta, "by " .. note.createdBy)
    end
    if showTimestamp and note.created then
        table.insert(meta, date("%Y-%m-%d", note.created))
    end

    if table.getn(meta) > 0 then
        return " |cff888888(" .. table.concat(meta, ", ") .. ")|r"
    end
    return ""
end

-- Chat alerts
local function RegisterChatAlerts()
    local frame = CreateFrame("Frame")

    frame:SetScript("OnEvent", function()
        local msg = arg1
        local author = arg2
        local channelID = tonumber(arg7) or 0
        local channelName = tostring(arg9 or "")

        if PorkNotes.ChatDebug then
            local skipDebug = false
            if event == "CHAT_MSG_CHANNEL" and channelID == 0 then
                local lname = string.lower(channelName)
                if lname == "ttrp" or lname == "lft" then
                    skipDebug = true
                end
            end
            if not skipDebug then
                local argsText = ""
                for i = 1, 9 do
                    local val = _G["arg" .. i]
                    if val == nil then val = "<nil>" end
                    argsText = argsText .. " arg" .. i .. "=" .. tostring(val)
                end
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[PorkNotes Debug]|r Event=" .. tostring(event) .. argsText)
            end
        end

        if not msg or not author then return end
        if not PorkNotes.GetSetting("ShowNotesInChat", true) then return end

        -- Only filter channelID==0 for actual channel messages
        -- (non-channel events like SAY/PARTY/WHISPER have arg7==nil which resolves to 0)
        if event == "CHAT_MSG_CHANNEL" and channelID == 0 then return end

        local note = PorkNotes.GetPlayerNote(author)
        if not note then return end

        local alertText = "|cff00ccff[PorkNotes]|r |Hporknotes:" .. author .. "|h|cffffcc00[" .. author .. "]|h|r|cffaaaaaa: " .. note.text .. "|r" .. BuildAlertMetadata(note)

        -- Route World and LookingForGroup channels to user-configured chat frame
        if event == "CHAT_MSG_CHANNEL" then
            local lname = string.lower(channelName)
            if string.find(lname, "world") or string.find(lname, "lookingforgroup") then
                local frameIndex = PorkNotes.GetSetting("WorldChatFrame", 3)
                local targetFrame = _G["ChatFrame" .. frameIndex]
                if targetFrame then
                    targetFrame:AddMessage(alertText)
                else
                    SendChatFrame1(alertText)
                end
                return
            end
        end
        SendChatFrame1(alertText)
    end)

    local events = {
        "CHAT_MSG_SAY",
        "CHAT_MSG_YELL",
        "CHAT_MSG_PARTY",
        "CHAT_MSG_GUILD",
        "CHAT_MSG_WHISPER",
        "CHAT_MSG_CHANNEL"
    }

    for _, e in ipairs(events) do
        frame:RegisterEvent(e)
    end
end

-- Minimap button
local function RegisterMinimapButton()
    local minimapButton = CreateFrame("Button", "PorkNotes_MinimapButton", Minimap)
    minimapButton:SetWidth(30)
    minimapButton:SetHeight(30)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 20, -20)
    minimapButton:SetNormalTexture("Interface\\AddOns\\PorkNotes\\Textures\\porknotes")
    minimapButton:SetPushedTexture("Interface\\AddOns\\PorkNotes\\Textures\\porknotes")
    minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local border = minimapButton:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetWidth(50)
    border:SetHeight(50)
    border:SetPoint("CENTER", minimapButton, "CENTER", 10, -10)

    if PorkNotes.GetSetting("ShowMinimapButton", true) then
        minimapButton:Show()
    else
        minimapButton:Hide()
    end

    minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    minimapButton:SetScript("OnClick", function()
        if arg1 == "LeftButton" then
            PorkNotes.ShowNotesFrame()
        else
            PorkNotes.ShowSettingsFrame()
        end
    end)

    minimapButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(minimapButton, "ANCHOR_LEFT")
        GameTooltip:SetText("PorkNotes")
        GameTooltip:AddLine("Left click: Open notes", 1, 1, 1)
        GameTooltip:AddLine("Right click: Settings", 1, 1, 1)
        GameTooltip:Show()
    end)

    minimapButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    PorkNotes.SetMinimapButtonVisible = function(visible)
        if visible then
            minimapButton:Show()
        else
            minimapButton:Hide()
        end
    end
end

-- Register events
RegisterEvent("ADDON_LOADED", OnAddonLoaded)
RegisterEvent("UPDATE_MOUSEOVER_UNIT", OnUpdateMouseoverUnit)
RegisterChatAlerts()
RegisterCommands()
RegisterUnitPopupMenus()
RegisterMinimapButton()
