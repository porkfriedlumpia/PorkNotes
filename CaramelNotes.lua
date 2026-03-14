CaramelNotes = {}

local _G = getfenv(0)
local chatHooks = {}
local realm = GetRealmName()

-- Debug toggle
CaramelNotes.ChatDebug = false

-- Debug helper
CaramelNotes.DebugPrint = function(msg)
    if msg ~= nil then
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: " .. gsub(msg, "|", "||"))
    else
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: <nil>")
    end
end

-- Safe string replace
local function StrReplace(text, from, to)
    return string.gsub(text, from, to, 1)
end

local function RegisterEvent(event, func)
    local frame = CreateFrame("Frame")
    frame:RegisterEvent(event)
    frame:SetScript("OnEvent", func)
end

-- Notes data functions
CaramelNotes.GetAllNotes = function ()
    if CaramelNotes_Data and CaramelNotes_Data[realm] then
        return CaramelNotes_Data[realm].notes
    end
    return nil
end

CaramelNotes.GetPlayerNote = function (playername)
    if playername and CaramelNotes_Data and CaramelNotes_Data[realm] and CaramelNotes_Data[realm].notes then
        return CaramelNotes_Data[realm].notes[playername]
    end
    return nil
end

CaramelNotes.SetPlayerNote = function (playername, text)
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
    if arg1 == "CaramelNotes" or arg1 == "CaramelNotes-WotLK" then
        CaramelNotes_Data = CaramelNotes_Data or {}
        CaramelNotes_Data[realm] = CaramelNotes_Data[realm] or {}
        CaramelNotes_Data[realm].notes = CaramelNotes_Data[realm].notes or {}
        CaramelNotes_Settings = CaramelNotes_Settings or {}
    end
end

-- Item ref handler
local originalSetItemRef = SetItemRef
function SetItemRef(link, text, button)
    if string.sub(link,1,13) == "caramelnotes:" then
        CaramelNotes.ShowEditFrame(string.sub(link,14))
    else
        originalSetItemRef(link,text,button)
    end
end

-- Tooltip handlers
local function OnHyperlinkEnter()
    local link = arg1
    if string.sub(link,1,13) ~= "caramelnotes:" then return end
    local playername = string.sub(link,14)
    local note = CaramelNotes.GetPlayerNote(playername)
    if not note then return end
    GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(playername, 1,1,1)
    GameTooltip:AddLine(note.text, 0.9,0.9,0.9)
    GameTooltip:Show()
end
local function OnHyperlinkLeave()
    local link = arg1
    if string.sub(link,1,13) == "caramelnotes:" then
        GameTooltip:Hide()
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

-- Hook unit popup
if hooksecurefunc then
    hooksecurefunc("UnitPopup_OnClick", function(self)
        local button = self or this
        if not button then return end
        if button.value=="CARAMELNOTES_EDIT_NOTE" then
            local menu = UIDROPDOWNMENU_INIT_MENU
            if type(menu)=="string" then menu = _G[menu] end
            local playername = menu and menu.name
            if playername then CaramelNotes.ShowEditFrame(playername) end
        end
    end)
else
    local original_UnitPopup_OnClick = UnitPopup_OnClick
    function UnitPopup_OnClick()
        original_UnitPopup_OnClick()
        local button = this
        if not button then return end
        if button.value=="CARAMELNOTES_EDIT_NOTE" then
            local menu = UIDROPDOWNMENU_INIT_MENU
            if type(menu)=="string" then menu=_G[menu] end
            local playername = menu and menu.name
            if playername then CaramelNotes.ShowEditFrame(playername) end
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

-- Chat alert function
local function RegisterChatAlerts()
    local frame = CreateFrame("Frame")

    frame:SetScript("OnEvent", function(self, event)
        local msg = arg1
        local author = arg2
        local channelID = tonumber(arg7) or 0
        local channelName = tostring(arg9 or "")
        local arg4Text = tostring(arg4 or "")

        if not msg or not author then return end
        if not CaramelNotes.GetSetting("ShowNotesInChat", true) then return end

        -- Normalize strings for comparison
        channelName = string.upper(string.gsub(channelName, "^%s*(.-)%s*$", "%1"))
        arg4Text = string.lower(arg4Text)

        -- Debug output
        if CaramelNotes.ChatDebug then
            DEFAULT_CHAT_FRAME:AddMessage(
                "|cff00ffff[CaramelNotes Debug]|r event="..tostring(event)..
                " author="..tostring(author)..
                " arg4="..tostring(arg4)..
                " arg7="..tostring(arg7)..
                " arg9="..tostring(arg9)
            )
        end

        -- Filter hidden/internal channels (TTRP and LFT)
        if event == "CHAT_MSG_CHANNEL" and channelID == 0 and (string.find(arg4Text, "ttrp") or string.find(arg4Text, "lft")) then
            if CaramelNotes.ChatDebug then
                DEFAULT_CHAT_FRAME:AddMessage(
                    "|cff00ffff[CaramelNotes Debug]|r blocked "..tostring(author).." on "..tostring(arg4).." / "..tostring(channelName)
                )
            end
            return
        end

        local note = CaramelNotes.GetPlayerNote(author)
        if not note then return end

        local targetFrame = DEFAULT_CHAT_FRAME
        local routeName = "ChatFrame1"

        -- Route World (27) and LookingForGroup (24) to ChatFrame3
        if event == "CHAT_MSG_CHANNEL" and (channelID == 27 or channelID == 24) then
            local f = getglobal("ChatFrame3")
            if f and f.AddMessage then
                targetFrame = f
                routeName = "ChatFrame3"
            end
        end

        local alertText = "|Hcaramelnotes:"..author.."|h|cffffcc00* "..author.." has a note.|h|r"
        targetFrame:AddMessage(alertText)

        -- Debug routing
        if CaramelNotes.ChatDebug then
            DEFAULT_CHAT_FRAME:AddMessage(
                "|cff00ffff[CaramelNotes Debug]|r sent "..tostring(author).." alert to "..routeName..
                " (channelID="..tostring(channelID)..", channelName="..tostring(channelName)..")"
            )
        end
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