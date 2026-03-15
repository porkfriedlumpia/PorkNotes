local frame = CreateFrame("Frame", "PorkNotes_NotesFrame", UIParent)
frame:SetWidth(600)
frame:SetHeight(450)
frame:SetPoint("CENTER", UIParent)
frame:SetFrameStrata("HIGH")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetResizable(true)
frame:SetMinResize(500, 300)
frame:SetMaxResize(900, 700)
frame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
})
frame:SetBackdropColor(0, 0, 0, 0.8)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function() this:StartMoving() end)
frame:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    local point, _, relativePoint, x, y = frame:GetPoint()
    PorkNotes.SetSetting("NotesFramePos", point .. "," .. relativePoint .. "," .. math.floor(x) .. "," .. math.floor(y))
end)
frame:Hide()

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", 0, -15)
title:SetText("|cFFD893EDPork|r|cFFFFBB00Notes|r")

local resizer = CreateFrame("Button", nil, frame)
resizer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 6)
resizer:SetWidth(16)
resizer:SetHeight(16)
resizer:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
resizer:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)

tinsert(UISpecialFrames, frame:GetName())

local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

local createNoteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
createNoteButton:SetWidth(100)
createNoteButton:SetHeight(24)
createNoteButton:SetPoint("BOTTOMLEFT", 30, 20)
createNoteButton:SetText("New note")
createNoteButton:SetScript("OnClick", function()
    PorkNotes.ShowCreateFrame()
end)

local settingsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
settingsButton:SetWidth(100)
settingsButton:SetHeight(24)
settingsButton:SetPoint("BOTTOMRIGHT", -30, 20)
settingsButton:SetText("Settings")
settingsButton:SetScript("OnClick", function()
    frame:Hide()
    PorkNotes.ShowSettingsFrame()
end)

-- Search and sort toolbar
local toolbarContainer = CreateFrame("Frame", nil, frame)
toolbarContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 30, -32)
toolbarContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -32)
toolbarContainer:SetHeight(26)

-- Search label
local searchLabel = toolbarContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
searchLabel:SetPoint("LEFT", 0, 0)
searchLabel:SetText("Search:")
searchLabel:SetTextColor(1, 1, 1)

-- Search editbox
local searchBox = CreateFrame("EditBox", nil, toolbarContainer)
searchBox:SetWidth(160)
searchBox:SetHeight(22)
searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 6, 0)
searchBox:SetFontObject(GameFontNormalSmall)
searchBox:SetTextInsets(4, 4, 2, 2)
searchBox:SetTextColor(1, 1, 1)
searchBox:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 10,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
searchBox:SetBackdropColor(0, 0, 0, 0.5)
searchBox:SetAutoFocus(false)

-- Clear search button
local clearButton = CreateFrame("Button", nil, toolbarContainer, "UIPanelButtonTemplate")
clearButton:SetWidth(40)
clearButton:SetHeight(20)
clearButton:SetPoint("LEFT", searchBox, "RIGHT", 4, 0)
clearButton:SetText("Clear")

-- Sort label
local sortLabel = toolbarContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
sortLabel:SetPoint("RIGHT", -130, 0)
sortLabel:SetText("Sort:")
sortLabel:SetTextColor(1, 1, 1)

-- Sort dropdown
local sortDropdown = CreateFrame("Frame", "PorkNotes_SortDropdown", toolbarContainer, "UIDropDownMenuTemplate")
sortDropdown:SetPoint("RIGHT", 20, 0)
UIDropDownMenu_SetWidth(100, sortDropdown)

-- Scroll container — pushed down to make room for toolbar
local scrollContainer = CreateFrame("Frame", nil, frame)
scrollContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 30, -62)
scrollContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 48)
scrollContainer:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
scrollContainer:SetBackdropColor(0, 0, 0, 0.4)

-- Column headers
local headerContainer = CreateFrame("Frame", nil, scrollContainer)
headerContainer:SetPoint("TOPLEFT", scrollContainer, "TOPLEFT", 10, -8)
headerContainer:SetPoint("TOPRIGHT", scrollContainer, "TOPRIGHT", -30, -8)
headerContainer:SetHeight(16)

local headerName = headerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
headerName:SetPoint("TOPLEFT", 0, 0)
headerName:SetTextColor(0.7, 0.7, 1)
headerName:SetText("Player")

local headerNote = headerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
headerNote:SetTextColor(0.7, 0.7, 1)
headerNote:SetText("Note")

local headerAuthor = headerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
headerAuthor:SetTextColor(0.7, 0.7, 1)
headerAuthor:SetText("Author")

local headerDate = headerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
headerDate:SetTextColor(0.7, 0.7, 1)
headerDate:SetText("Updated")

-- Header divider
local headerDivider = scrollContainer:CreateTexture(nil, "BACKGROUND")
headerDivider:SetHeight(1)
headerDivider:SetPoint("TOPLEFT", scrollContainer, "TOPLEFT", 6, -22)
headerDivider:SetPoint("TOPRIGHT", scrollContainer, "TOPRIGHT", -6, -22)
headerDivider:SetTexture(0.3, 0.3, 0.3, 0.8)

local scrollFrame = CreateFrame("ScrollFrame", "PorkNotes_ShowNotes_ScrollFrame", scrollContainer, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", scrollContainer, 10, -26)
scrollFrame:SetPoint("BOTTOMRIGHT", scrollContainer, -30, 10)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetWidth(1)
scrollFrame:SetScrollChild(content)

-- Empty state label
local emptyLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
emptyLabel:SetPoint("TOP", 0, -20)
emptyLabel:SetTextColor(0.5, 0.5, 0.5)
emptyLabel:SetText("No notes yet. Right-click a player to get started.")
emptyLabel:Hide()

local lines = {}
local LINE_HEIGHT = 20

-- Column width constants (proportional)
local NAME_RATIO  = 0.20
local NOTE_RATIO  = 0.45
local AUTH_RATIO  = 0.18
local DATE_RATIO  = 0.17

local function GetColumnWidths()
    local totalWidth = frame:GetWidth() - 100
    local nameW  = math.floor(totalWidth * NAME_RATIO)
    local noteW  = math.floor(totalWidth * NOTE_RATIO)
    local authW  = math.floor(totalWidth * AUTH_RATIO)
    local dateW  = totalWidth - nameW - noteW - authW
    return totalWidth, nameW, noteW, authW, dateW
end

local function ResizeEverything()
    local totalWidth, nameW, noteW, authW, dateW = GetColumnWidths()

    -- Reposition header labels
    headerName:SetWidth(nameW)
    headerNote:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", nameW + 8, 0)
    headerNote:SetWidth(noteW)
    headerAuthor:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", nameW + noteW + 16, 0)
    headerAuthor:SetWidth(authW)
    headerDate:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", nameW + noteW + authW + 24, 0)
    headerDate:SetWidth(dateW)

    for _, line in ipairs(lines) do
        line:SetWidth(totalWidth)
        line.nameLabel:SetWidth(nameW)
        line.noteLabel:SetWidth(noteW)
        line.noteLabel:SetPoint("TOPLEFT", nameW + 8, 0)
        line.authLabel:SetWidth(authW)
        line.authLabel:SetPoint("TOPLEFT", nameW + noteW + 16, 0)
        line.dateLabel:SetWidth(dateW)
        line.dateLabel:SetPoint("TOPLEFT", nameW + noteW + authW + 24, 0)
    end
end

frame:SetScript("OnSizeChanged", ResizeEverything)

local function FormatDate(timestamp)
    if not timestamp then return "" end
    return date("%Y-%m-%d", timestamp)
end

-- Right-click menu
local rightClickMenu = CreateFrame("Frame", "PorkNotes_ShowNotes_RightClickMenu", UIParent)
local currentPlayerName = nil
local deleteConfirmPending = false

rightClickMenu:SetFrameStrata("DIALOG")
rightClickMenu:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
rightClickMenu:SetBackdropColor(0, 0, 0, 0.9)
rightClickMenu:SetWidth(150)
rightClickMenu:SetHeight(80)
rightClickMenu:EnableMouse(true)
rightClickMenu:Hide()

rightClickMenu:SetScript("OnShow", function()
    PlaySound("igMainMenuOpen")
end)

rightClickMenu:SetScript("OnLeave", function()
    local frameUnderMouse = GetMouseFocus()
    if frameUnderMouse then
        local parent = frameUnderMouse:GetParent()
        if parent == rightClickMenu then return end
    end
    rightClickMenu:Hide()
    deleteConfirmPending = false
end)

rightClickMenu:SetScript("OnHide", function()
    deleteConfirmPending = false
end)

local menuTitle = rightClickMenu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
menuTitle:SetPoint("TOP", 0, -10)

local menuEditNoteButton = CreateFrame("Button", nil, rightClickMenu)
menuEditNoteButton:SetWidth(130)
menuEditNoteButton:SetHeight(20)
menuEditNoteButton:SetPoint("TOPLEFT", rightClickMenu, "TOPLEFT", 10, -30)
menuEditNoteButton:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
menuEditNoteButton:SetScript("OnClick", function()
    PorkNotes.ShowNoteDetailFrame(currentPlayerName)
    rightClickMenu:Hide()
end)
menuEditNoteButton.text = menuEditNoteButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
menuEditNoteButton.text:SetAllPoints()
menuEditNoteButton.text:SetText("Edit note")
menuEditNoteButton.text:SetJustifyH("LEFT")
menuEditNoteButton.text:SetTextColor(1, 1, 1)

-- Delete button — two-step confirmation
local menuDeleteNoteButton = CreateFrame("Button", nil, rightClickMenu)
menuDeleteNoteButton:SetWidth(130)
menuDeleteNoteButton:SetHeight(20)
menuDeleteNoteButton:SetPoint("TOPLEFT", rightClickMenu, "TOPLEFT", 10, -52)
menuDeleteNoteButton:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
menuDeleteNoteButton:SetScript("OnClick", function()
    if deleteConfirmPending then
        PorkNotes.SetPlayerNote(currentPlayerName, "")
        PorkNotes.UpdateNotesFrame()
        rightClickMenu:Hide()
        PlaySound("igMainMenuClose")
    else
        deleteConfirmPending = true
        menuDeleteNoteButton.text:SetText("Confirm delete?")
        menuDeleteNoteButton.text:SetTextColor(1, 0.3, 0.3)
    end
end)
menuDeleteNoteButton.text = menuDeleteNoteButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
menuDeleteNoteButton.text:SetAllPoints()
menuDeleteNoteButton.text:SetText("Delete note")
menuDeleteNoteButton.text:SetJustifyH("LEFT")
menuDeleteNoteButton.text:SetTextColor(1, 0.5, 0.5)

local function OpenRightClickMenu(playername)
    currentPlayerName = playername
    deleteConfirmPending = false
    menuDeleteNoteButton.text:SetText("Delete note")
    menuDeleteNoteButton.text:SetTextColor(1, 0.5, 0.5)
    menuTitle:SetText(playername)
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    rightClickMenu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", (x - 10) / scale, (y + 10) / scale)
    rightClickMenu:Show()
end

frame:SetScript("OnShow", function()
    PlaySound("igQuestListOpen")
end)

frame:SetScript("OnHide", function()
    PlaySound("igQuestListClose")
    rightClickMenu:Hide()
end)

local function OnLineClick()
    if arg1 == "LeftButton" then
        PorkNotes.ShowNoteDetailFrame(this.nameLabel:GetText())
    else
        OpenRightClickMenu(this.nameLabel:GetText())
    end
end

local function OnLineEnter()
    this.bg:SetVertexColor(0.5, 0.5, 0.5, 0.5)
    local note = PorkNotes.GetPlayerNote(this.nameLabel:GetText())
    if not note then return end
    if not note.createdAtZone and not note.created then return end
    GameTooltip:SetOwner(this, "ANCHOR_CURSOR")
    GameTooltip:ClearLines()
    if note.createdAtZone then
        GameTooltip:AddLine("Created in: " .. note.createdAtZone, 0.6, 0.6, 0.6)
    end
    if note.created then
        GameTooltip:AddLine("Created on: " .. date("%Y-%m-%d", note.created), 0.6, 0.6, 0.6)
    end
    GameTooltip:Show()
end

local function OnLineLeave()
    this.bg:SetVertexColor(1, 1, 1, this.bgAlpha)
    GameTooltip:Hide()
end

local math_mod = math.mod or math.fmod

local function CreateLine(nameText, noteText, authText, dateText, index)
    local totalWidth, nameW, noteW, authW, dateW = GetColumnWidths()

    local position = 0
    if index > 0 then
        local _, _, _, _, offsetY = lines[index]:GetPoint()
        position = -offsetY + lines[index]:GetHeight()
    end

    if lines[index + 1] then
        local line = lines[index + 1]
        line:SetPoint("TOPLEFT", 0, -position)
        line.nameLabel:SetText(nameText)
        line.noteLabel:SetText(noteText)
        line.authLabel:SetText(authText)
        line.dateLabel:SetText(dateText)
        line:Show()
        return
    end

    local button = CreateFrame("Button", nil, content)
    button:SetHeight(LINE_HEIGHT)
    button:SetWidth(totalWidth)
    button:SetPoint("TOPLEFT", 0, -position)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(1, 1, 1, 1)
    button.bg = bg
    if math_mod(index, 2) == 0 then
        button.bgAlpha = 0
    else
        button.bgAlpha = 0.04
    end
    bg:SetVertexColor(1, 1, 1, button.bgAlpha)

    local nameLabel = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", 0, 0)
    nameLabel:SetHeight(LINE_HEIGHT)
    nameLabel:SetWidth(nameW)
    nameLabel:SetText(nameText)
    nameLabel:SetJustifyH("LEFT")
    nameLabel:SetTextColor(0.847, 0.576, 0.929)
    button.nameLabel = nameLabel

    local noteLabel = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noteLabel:SetPoint("TOPLEFT", nameW + 8, 0)
    noteLabel:SetHeight(LINE_HEIGHT)
    noteLabel:SetWidth(noteW)
    noteLabel:SetText(noteText)
    noteLabel:SetJustifyH("LEFT")
    noteLabel:SetTextColor(1, 1, 1)
    button.noteLabel = noteLabel

    local authLabel = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    authLabel:SetPoint("TOPLEFT", nameW + noteW + 16, 0)
    authLabel:SetHeight(LINE_HEIGHT)
    authLabel:SetWidth(authW)
    authLabel:SetText(authText)
    authLabel:SetJustifyH("LEFT")
    authLabel:SetTextColor(0.7, 0.9, 0.7)
    button.authLabel = authLabel

    local dateLabel = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dateLabel:SetPoint("TOPLEFT", nameW + noteW + authW + 24, 0)
    dateLabel:SetHeight(LINE_HEIGHT)
    dateLabel:SetWidth(dateW)
    dateLabel:SetText(dateText)
    dateLabel:SetJustifyH("LEFT")
    dateLabel:SetTextColor(0.6, 0.6, 0.6)
    button.dateLabel = dateLabel

    button:SetScript("OnClick", OnLineClick)
    button:SetScript("OnEnter", OnLineEnter)
    button:SetScript("OnLeave", OnLineLeave)

    lines[index + 1] = button
end

-- Sort modes
local SORT_NAME    = "name"
local SORT_UPDATED = "updated"
local SORT_AUTHOR  = "author"
local currentSort  = SORT_NAME
local currentFilter = ""

local function InitSortDropdown()
    UIDropDownMenu_Initialize(sortDropdown, function()
        local options = {
            { text = "Name (A-Z)",    value = SORT_NAME },
            { text = "Last Updated",  value = SORT_UPDATED },
            { text = "Author",        value = SORT_AUTHOR },
        }
        for _, opt in ipairs(options) do
            local info = {}
            info.text = opt.text
            info.value = opt.value
            info.checked = (opt.value == currentSort)
            local optValue = opt.value
            local optText = opt.text
            info.func = function()
                currentSort = optValue
                UIDropDownMenu_SetText(optText, sortDropdown)
                CloseDropDownMenus()
                PorkNotes.UpdateNotesFrame()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetText("Name (A-Z)", sortDropdown)
end

local function RefreshNotes()
    local notes = PorkNotes.GetAllNotes()
    for _, line in ipairs(lines) do
        line:Hide()
    end

    if not notes then
        emptyLabel:Show()
        content:SetHeight(60)
        scrollFrame:UpdateScrollChildRect()
        return
    end

    -- Build filtered list
    local filtered = {}
    local filter = string.lower(currentFilter)
    for playername, note in pairs(notes) do
        local match = true
        if filter ~= "" then
            local nameMatch = string.find(string.lower(playername), filter, 1, true)
            local noteMatch = note.text and string.find(string.lower(note.text), filter, 1, true)
            local authMatch = note.updatedBy and string.find(string.lower(note.updatedBy), filter, 1, true)
            match = nameMatch or noteMatch or authMatch
        end
        if match then
            table.insert(filtered, playername)
        end
    end

    -- Sort
    if currentSort == SORT_NAME then
        table.sort(filtered)
    elseif currentSort == SORT_UPDATED then
        table.sort(filtered, function(a, b)
            local aTime = notes[a].updated or notes[a].created or 0
            local bTime = notes[b].updated or notes[b].created or 0
            return aTime > bTime
        end)
    elseif currentSort == SORT_AUTHOR then
        table.sort(filtered, function(a, b)
            local aAuth = string.lower(notes[a].updatedBy or notes[a].createdBy or "")
            local bAuth = string.lower(notes[b].updatedBy or notes[b].createdBy or "")
            return aAuth < bAuth
        end)
    end

    if table.getn(filtered) == 0 then
        emptyLabel:SetText(currentFilter ~= "" and "No notes match your search." or "No notes yet. Right-click a player to get started.")
        emptyLabel:Show()
        content:SetHeight(60)
        scrollFrame:UpdateScrollChildRect()
        return
    end

    emptyLabel:Hide()
    local count = 0
    for _, playername in ipairs(filtered) do
        local note = notes[playername]
        local authText = note.updatedBy or note.createdBy or ""
        local dateText = FormatDate(note.updated or note.created)
        CreateLine(playername, note.text or "", authText, dateText, count)
        count = count + 1
    end

    content:SetHeight(count * LINE_HEIGHT + 4)
    ResizeEverything()
    scrollFrame:UpdateScrollChildRect()
end

-- Wire up search
searchBox:SetScript("OnTextChanged", function()
    currentFilter = searchBox:GetText()
    RefreshNotes()
end)
searchBox:SetScript("OnEscapePressed", function()
    searchBox:SetText("")
    currentFilter = ""
    RefreshNotes()
end)
clearButton:SetScript("OnClick", function()
    searchBox:SetText("")
    currentFilter = ""
    RefreshNotes()
end)

PorkNotes.ShowNotesFrame = function()
    InitSortDropdown()
    RefreshNotes()
    frame:ClearAllPoints()
    local saved = PorkNotes.GetSetting("NotesFramePos", nil)
    if saved then
        local _, _, point, relativePoint, x, y = string.find(saved, "([^,]+),([^,]+),(-?%d+),(-?%d+)")
        if point then
            frame:SetPoint(point, UIParent, relativePoint, tonumber(x), tonumber(y))
        else
            frame:SetPoint("CENTER", UIParent)
        end
    else
        frame:SetPoint("CENTER", UIParent)
    end
    frame:Show()
end

PorkNotes.UpdateNotesFrame = function()
    if frame:IsShown() then
        RefreshNotes()
    end
end
