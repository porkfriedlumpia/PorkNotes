-- PorkNotes v0.0.3

CaramelNotes = CaramelNotes or {}

local realm = GetRealmName()

-- Debug toggle
CaramelNotes.ChatDebug = false

-- Event registration helper
local function RegisterEvent(event, func)
    local frame = CreateFrame("Frame")
    frame:RegisterEvent(event)
    frame:SetScript("OnEvent", func)
end

-- Notes data functions
CaramelNotes.GetAllNotes = function()
    if CaramelNotes_Data and CaramelNotes_Data[realm] then
        return CaramelNotes_Data[realm].notes
    end
    return nil
end

CaramelNotes.GetPlayerNote = function(playername)
    if playername and CaramelNotes_Data and CaramelNotes_Data[realm] and CaramelNotes_Data[realm].notes then
        return CaramelNotes_Data[realm].notes[playername]
    end
    return nil
end

CaramelNotes.SetPlayerNote = function(playername, text)
    if not playername or not CaramelNotes_Data or not CaramelNotes_Data[realm] or not CaramelNotes_Data[realm].notes then return end

    if text and text ~= "" then
        if not CaramelNotes_Data[realm].notes[playername] then
            CaramelNotes_Data[realm].notes[playername] = {
                created = time(),
                createdBy = UnitName("player"),
                createdAtZone = GetRealZoneText()
            }
        end
        CaramelNotes_Data[realm].notes[playername].text = text
        CaramelNotes_Data[realm].notes[playername].updated = time()
        CaramelNotes_Data[realm].notes[playername].updatedBy = UnitName("player")
        CaramelNotes_Data[realm].notes[playername].updatedAtZone = GetRealZoneText()
    else
        CaramelNotes_Data[realm].notes[playername] = nil
    end
end

-- Settings helper
CaramelNotes.GetSetting = function(setting, defaultValue)
    if not CaramelNotes_Settings then return defaultValue end
    if CaramelNotes_Settings[setting] == nil then return defaultValue end
    return CaramelNotes_Settings[setting]
end

CaramelNotes.SetSetting = function(setting, value)
    CaramelNotes_Settings[setting] = value
end

-- Addon loaded
local function OnAddonLoaded()
    if arg1 == "CaramelNotes" then
        CaramelNotes_Data = CaramelNotes_Data or {}
        CaramelNotes_Data[realm] = CaramelNotes_Data[realm] or {}
        CaramelNotes_Data[realm].notes = CaramelNotes_Data[realm].notes or {}
        CaramelNotes_Settings = CaramelNotes_Settings or {}
    end
end

-- Item ref handler
local originalSetItemRef = SetItemRef
function SetItemRef(link, text, button)
    if string.sub(link, 1, 13) == "caramelnotes:" then
        CaramelNotes.ShowEditFrame(string.sub(link, 14))
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
    if not CaramelNotes.GetSetting("ShowNotesInTooltips", true) then
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
    local note = CaramelNotes.GetPlayerNote(name)
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
    if UnitPopupButtons["CARAMELNOTES_EDIT_NOTE"] then return end
    UnitPopupButtons["CARAMELNOTES_EDIT_NOTE"] = { text = "Edit note", dist = 0 }
    local menus = { "PLAYER", "FRIEND", "PARTY", "RAID" }
    for _, menu in ipairs(menus) do
        local atIndex = 1
        for index, value in ipairs(UnitPopupMenus[menu]) do
            if value == "CANCEL" then atIndex = index break end
        end
        table.insert(UnitPopupMenus[menu], atIndex, "CARAMELNOTES_EDIT_NOTE")
    end
end

-- Hook unit popup
hooksecurefunc("UnitPopup_OnClick", function()
    local button = this
    if not button then return end
    if button.value == "CARAMELNOTES_EDIT_NOTE" then
        local menu = UIDROPDOWNMENU_INIT_MENU
        if type(menu) == "string" then menu = _G[menu] end
        local playername = menu and menu.name
        if playername then CaramelNotes.ShowEditFrame(playername) end
    end
end)

-- Slash commands
local function RegisterCommands()
    SLASH_CARAMELNOTES1 = "/caramelnotes"
    SLASH_CARAMELNOTES2 = "/cn"
    SlashCmdList["CARAMELNOTES"] = function(msg) CaramelNotes.ShowNotesFrame() end

    SLASH_NOTESDEBUG1 = "/notesdebug"
    SlashCmdList["NOTESDEBUG"] = function(msg)
        CaramelNotes.ChatDebug = not CaramelNotes.ChatDebug
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[CaramelNotes]|r Chat debug: " .. tostring(CaramelNotes.ChatDebug))
    end
end

-- Chat alert routing functions
local function SendChatFrame1(alertText)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(alertText)
    end
end

-- Chat alerts
local function RegisterChatAlerts()
    local frame = CreateFrame("Frame")

    frame:SetScript("OnEvent", function()
        local msg = arg1
        local author = arg2
        local channelID = tonumber(arg7) or 0
        local channelName = tostring(arg9 or "")

        if CaramelNotes.ChatDebug then
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
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[CaramelNotes Debug]|r Event=" .. tostring(event) .. argsText)
            end
        end

        if not msg or not author then return end
        if not CaramelNotes.GetSetting("ShowNotesInChat", true) then return end

        -- Only filter channelID==0 for actual channel messages
        -- (non-channel events like SAY/PARTY/WHISPER have arg7==nil which resolves to 0)
        if event == "CHAT_MSG_CHANNEL" and channelID == 0 then return end

        local note = CaramelNotes.GetPlayerNote(author)
        if not note then return end

        local alertText = "|cff00ccff[CaramelNotes]|r |Hcaramelnotes:" .. author .. "|h|cffffcc00[" .. author .. "]|h|r|cffaaaaaa: " .. note.text .. "|r"

        -- Route World and LookingForGroup channels to user-configured chat frame
        if event == "CHAT_MSG_CHANNEL" then
            local lname = string.lower(channelName)
            if string.find(lname, "world") or string.find(lname, "lookingforgroup") then
                local frameIndex = CaramelNotes.GetSetting("WorldChatFrame", 3)
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

-- Register events
RegisterEvent("ADDON_LOADED", OnAddonLoaded)
RegisterEvent("UPDATE_MOUSEOVER_UNIT", OnUpdateMouseoverUnit)
RegisterChatAlerts()
RegisterCommands()
RegisterUnitPopupMenus()