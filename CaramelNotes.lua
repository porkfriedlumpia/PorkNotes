CaramelNotes = {}

local _G = getfenv(0)
local realm = GetRealmName()

-- Debug toggle
CaramelNotes.ChatDebug = false

-- Debug helper
CaramelNotes.DebugPrint = function(msg)
    if msg ~= nil then
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: " .. string.gsub(msg, "|", "||"))
    else
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: <nil>")
    end
end

-- Safe string replace
local function StrReplace(text, from, to)
    return string.gsub(text, from, to, 1)
end

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
    if playername and CaramelNotes_Data and CaramelNotes_Data[realm] and CaramelNotes_Data[realm].notes then
        if text and text ~= "" then
            if not CaramelNotes_Data[realm].notes[playername] then
                CaramelNotes_Data[realm].notes[playername] = {}
                CaramelNotes_Data[realm].notes[playername].created = time()
                CaramelNotes_Data[realm].notes[playername].createdBy = UnitName("player")
                CaramelNotes_Data[realm].notes[playername].createdAtZone = GetRealZoneText()
            end
            CaramelNotes_Data[realm].notes[playername].text = text
            CaramelNotes_Data[realm].notes[playername].updated = time()
            CaramelNotes_Data[realm].notes[playername].updatedBy = UnitName("player")
            CaramelNotes_Data[realm].notes[playername].updatedAtZone = GetRealZoneText()
        else
            CaramelNotes_Data[realm].notes[playername] = nil
        end
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

-- Item reference handler
local originalSetItemRef = SetItemRef
function SetItemRef(link, text, button)
    if string.sub(link,1,13) == "caramelnotes:" then
        CaramelNotes.ShowEditFrame(string.sub(link,14))
    else
        originalSetItemRef(link,text,button)
    end
end

-- Mouseover tooltip
local function OnUpdateMouseoverUnit()
    if not GameTooltip:IsShown() then return end
    local unit = "mouseover"
    if not UnitIsPlayer(unit) then return end
    local note = CaramelNotes.GetPlayerNote(UnitName(unit))
    if note then
        GameTooltip:AddLine(note.text, 1,1,0)
        GameTooltip:Show()
    end
end

-- UnitPopup menus
local function RegisterUnitPopupMenus()
    UnitPopupButtons["CARAMELNOTES_EDIT_NOTE"] = { text="Edit note", dist=0 }
    local menus = {"PLAYER","FRIEND","PARTY","RAID"}
    for _,menu in ipairs(menus) do
        local atIndex = 1
        for index,value in ipairs(UnitPopupMenus[menu]) do
            if value=="CANCEL" then atIndex=index break end
        end
        table.insert(UnitPopupMenus[menu], atIndex, "CARAMELNOTES_EDIT_NOTE")
    end
end

-- Hook UnitPopup_OnClick for 1.12
local function HookUnitPopup_OnClick()
    local original_UnitPopup_OnClick = UnitPopup_OnClick
    function UnitPopup_OnClick()
        original_UnitPopup_OnClick()
        local button = this
        if not button then return end
        if button.value == "CARAMELNOTES_EDIT_NOTE" then
            local menu = UIDROPDOWNMENU_INIT_MENU
            if type(menu) == "string" then menu = _G[menu] end
            local playername = menu and menu.name
            if playername then
                CaramelNotes.ShowEditFrame(playername)
            end
        end
    end
end

-- Slash commands
local function RegisterCommands()
    SLASH_CARAMELNOTES1 = "/caramelnotes"
    SlashCmdList["CARAMELNOTES"] = function(msg) CaramelNotes.ShowNotesFrame() end

    SLASH_NOTES1 = "/notes"
    SlashCmdList["NOTES"] = function(msg) CaramelNotes.ShowNotesFrame() end

    SLASH_NOTESDEBUG1 = "/notesdebug"
    SlashCmdList["NOTESDEBUG"] = function(msg)
        CaramelNotes.ChatDebug = not CaramelNotes.ChatDebug
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[CaramelNotes]|r Chat debug: "..tostring(CaramelNotes.ChatDebug))
    end
end

-- Chat alert routing functions
local function AlertChatFrame1(author)
    local targetFrame = DEFAULT_CHAT_FRAME
    local alertText = "|Hcaramelnotes:"..author.."|h|cffffcc00* "..author.." has a note.|h|r"
    targetFrame:AddMessage(alertText)
end

local function AlertChatFrame3(author)
    local f = getglobal("ChatFrame3")
    if f then
        local alertText = "|Hcaramelnotes:"..author.."|h|cffffcc00* "..author.." has a note.|h|r"
        f:AddMessage(alertText)
    end
end

-- Central chat alert handler
local function ChatEventHandler(self, event)
    local msg = arg1
    local author = arg2
    local channelID = tonumber(arg7) or 0

    if not msg or not author then return end
    if not CaramelNotes.GetSetting("ShowNotesInChat", true) then return end

    -- Block all messages from arg7 = 0
    if channelID == 0 then
        if CaramelNotes.ChatDebug then
            DEFAULT_CHAT_FRAME:AddMessage(
                "|cff00ffff[CaramelNotes Debug]|r blocked message from "..tostring(author)
            )
        end
        return
    end

    local note = CaramelNotes.GetPlayerNote(author)
    if not note then return end

    -- Route to ChatFrame3 for World (27) / LFG (24)
    if event == "CHAT_MSG_CHANNEL" and (channelID == "27" or channelID == "24") then
        AlertChatFrame3(author)
        if CaramelNotes.ChatDebug then
            DEFAULT_CHAT_FRAME:AddMessage(
                "|cff00ffff[CaramelNotes Debug]|r sent "..author.." alert to ChatFrame3 (channelID="..channelID..")"
            )
        end
    else
        AlertChatFrame1(author)
        if CaramelNotes.ChatDebug then
            DEFAULT_CHAT_FRAME:AddMessage(
                "|cff00ffff[CaramelNotes Debug]|r sent "..author.." alert to ChatFrame1 (channelID="..channelID..")"
            )
        end
    end
end

-- Register chat alert events
local function RegisterChatAlerts()
    local frame = CreateFrame("Frame")
    frame:SetScript("OnEvent", ChatEventHandler)

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

-- Register all events
RegisterEvent("ADDON_LOADED", OnAddonLoaded)
RegisterEvent("UPDATE_MOUSEOVER_UNIT", OnUpdateMouseoverUnit)
RegisterChatAlerts()
RegisterCommands()
RegisterUnitPopupMenus()
HookUnitPopup_OnClick()