local COLLAPSED_HEIGHT = 255
local EXPANDED_HEIGHT = 455

local frame = CreateFrame("Frame", "PorkNotes_NoteDetailFrame", UIParent)
frame:SetWidth(380)
frame:SetHeight(COLLAPSED_HEIGHT)
frame:SetFrameStrata("DIALOG")
frame:SetPoint("CENTER", UIParent, "CENTER")
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function() this:StartMoving() end)
frame:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    local point, _, relativePoint, x, y = frame:GetPoint()
    PorkNotes.SetSetting("NoteDetailFramePos", point .. "," .. relativePoint .. "," .. math.floor(x) .. "," .. math.floor(y))
end)
frame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
})
frame:SetBackdropColor(0, 0, 0, 0.8)
frame:Hide()

frame:SetScript("OnShow", function()
    PlaySound("igMainMenuOpen")
end)

frame:SetScript("OnHide", function()
    PlaySound("igMainMenuClose")
end)

-- Makes the window closable by pressing Escape
tinsert(UISpecialFrames, frame:GetName())

local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

-- Title
local titleLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleLabel:SetPoint("TOP", 0, -15)
titleLabel:SetTextColor(1, 1, 1)

-- Note text display (view mode)
local noteLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
noteLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -40)
noteLabel:SetWidth(340)
noteLabel:SetJustifyH("LEFT")
noteLabel:SetTextColor(1, 1, 0)

-- Note text editbox (edit mode)
local editBox = CreateFrame("EditBox", nil, frame)
editBox:SetWidth(300)
editBox:SetHeight(30)
editBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -36)
editBox:SetFontObject(GameFontNormal)
editBox:SetMaxLetters(200)
editBox:SetTextInsets(5, 5, 3, 3)
editBox:SetTextColor(1, 1, 1)
editBox:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
editBox:SetBackdropColor(0, 0, 0, 0.5)
editBox:Hide()

-- Character counter
local charCounter = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
charCounter:SetPoint("TOPRIGHT", editBox, "BOTTOMRIGHT", 0, -1)
charCounter:SetTextColor(0.6, 0.6, 0.6)
charCounter:Hide()

editBox:SetScript("OnTextChanged", function()
    local current = string.len(editBox:GetText())
    charCounter:SetText(current .. " / 200")
    if current >= 180 then
        charCounter:SetTextColor(1, 0.3, 0.3)
    else
        charCounter:SetTextColor(0.6, 0.6, 0.6)
    end
end)

-- Divider
local divider = frame:CreateTexture(nil, "BACKGROUND")
divider:SetHeight(1)
divider:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -78)
divider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -78)
divider:SetTexture(0.3, 0.3, 0.3, 0.8)

-- Metadata labels
local function CreateMetaLabel(yOffset)
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    label:SetWidth(340)
    label:SetJustifyH("LEFT")
    label:SetTextColor(1, 1, 1)
    return label
end

local createdByLabel   = CreateMetaLabel(-90)
local createdDateLabel = CreateMetaLabel(-104)
local createdZoneLabel = CreateMetaLabel(-118)
local updatedByLabel   = CreateMetaLabel(-136)
local updatedDateLabel = CreateMetaLabel(-150)

local function MetaText(label, value)
    return "|cFFD893ED" .. label .. ":|r " .. (value or "unknown")
end

-- History divider
local historyDivider = frame:CreateTexture(nil, "BACKGROUND")
historyDivider:SetHeight(1)
historyDivider:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -168)
historyDivider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -168)
historyDivider:SetTexture(0.3, 0.3, 0.3, 0.8)

-- History toggle button
local historyToggle = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
historyToggle:SetWidth(120)
historyToggle:SetHeight(20)
historyToggle:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -175)
historyToggle:SetText("Show history ▼")

-- History scroll container (shown when expanded)
local historyContainer = CreateFrame("Frame", nil, frame)
historyContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -202)
historyContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -202)
historyContainer:SetHeight(210)
historyContainer:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
historyContainer:SetBackdropColor(0, 0, 0, 0.4)
historyContainer:Hide()

local historyScroll = CreateFrame("ScrollFrame", "PorkNotes_NoteDetailHistory_ScrollFrame", historyContainer, "UIPanelScrollFrameTemplate")
historyScroll:SetPoint("TOPLEFT", historyContainer, 6, -6)
historyScroll:SetPoint("BOTTOMRIGHT", historyContainer, -26, 6)

local historyContent = CreateFrame("Frame", nil, historyScroll)
historyContent:SetWidth(1)
historyScroll:SetScrollChild(historyContent)

-- Bottom buttons
local editButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
editButton:SetWidth(80)
editButton:SetHeight(24)
editButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 15)
editButton:SetText("Edit")

local deleteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
deleteButton:SetWidth(80)
deleteButton:SetHeight(24)
deleteButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 110, 15)
deleteButton:SetText("Delete")

local saveButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
saveButton:SetWidth(80)
saveButton:SetHeight(24)
saveButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 15)
saveButton:SetText("Save")
saveButton:Hide()

local cancelEditButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
cancelEditButton:SetWidth(80)
cancelEditButton:SetHeight(24)
cancelEditButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 110, 15)
cancelEditButton:SetText("Cancel")
cancelEditButton:Hide()

local confirmDeleteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
confirmDeleteButton:SetWidth(100)
confirmDeleteButton:SetHeight(24)
confirmDeleteButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 15)
confirmDeleteButton:SetText("Yes, delete")
confirmDeleteButton:Hide()

local cancelDeleteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
cancelDeleteButton:SetWidth(80)
cancelDeleteButton:SetHeight(24)
cancelDeleteButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 130, 15)
cancelDeleteButton:SetText("Cancel")
cancelDeleteButton:Hide()

local deletePromptLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
deletePromptLabel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 22)
deletePromptLabel:SetTextColor(1, 0.3, 0.3)
deletePromptLabel:SetText("Delete this note?")
deletePromptLabel:Hide()

local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
closeBtn:SetWidth(80)
closeBtn:SetHeight(24)
closeBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 15)
closeBtn:SetText("Close")

-- State
local currentPlayerName = nil
local isEditMode = false
local isHistoryExpanded = false
local historyLines = {}

-- Format timestamp
local function FormatDate(timestamp)
    if not timestamp then return "unknown" end
    return date("%Y-%m-%d", timestamp)
end

-- Populate metadata
local function RefreshMetadata()
    local note = PorkNotes.GetPlayerNote(currentPlayerName)
    if not note then return end
    createdByLabel:SetText(MetaText("Created by", note.createdBy))
    createdDateLabel:SetText(MetaText("Created on", FormatDate(note.created)))
    createdZoneLabel:SetText(MetaText("Created in", note.createdAtZone))
    if note.updatedBy then
        updatedByLabel:SetText(MetaText("Updated by", note.updatedBy))
        updatedDateLabel:SetText(MetaText("Updated on", FormatDate(note.updated)))
    else
        updatedByLabel:SetText("")
        updatedDateLabel:SetText("")
    end
end

-- Build history scroll content
local function RefreshHistory()
    -- Hide existing lines
    for _, line in ipairs(historyLines) do
        line:Hide()
    end
    historyLines = {}

    local note = PorkNotes.GetPlayerNote(currentPlayerName)
    if not note or not note.history or table.getn(note.history) == 0 then
        local emptyLabel = historyContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        emptyLabel:SetPoint("TOPLEFT", 4, -4)
        emptyLabel:SetTextColor(0.6, 0.6, 0.6)
        emptyLabel:SetText("No history yet.")
        table.insert(historyLines, emptyLabel)
        historyContent:SetHeight(20)
        historyScroll:UpdateScrollChildRect()
        return
    end

    -- Show newest first
    local totalHeight = 0
    local count = table.getn(note.history)
    for i = count, 1, -1 do
        local entry = note.history[i]
        local yPos = -totalHeight - 4

        local dateLine = historyContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        dateLine:SetPoint("TOPLEFT", 4, yPos)
        dateLine:SetWidth(300)
        dateLine:SetJustifyH("LEFT")
        dateLine:SetTextColor(0.7, 0.7, 1)
        dateLine:SetText("Edited by " .. (entry.editedBy or "unknown") .. " — " .. FormatDate(entry.editedAt))
        table.insert(historyLines, dateLine)
        totalHeight = totalHeight + 14

        local textLine = historyContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        textLine:SetPoint("TOPLEFT", 4, -totalHeight - 4)
        textLine:SetWidth(300)
        textLine:SetJustifyH("LEFT")
        textLine:SetTextColor(0.9, 0.9, 0.9)
        textLine:SetText(entry.text or "")
        table.insert(historyLines, textLine)
        totalHeight = totalHeight + 18

        -- Separator between entries
        if i > 1 then
            local sep = historyContent:CreateTexture(nil, "BACKGROUND")
            sep:SetHeight(1)
            sep:SetPoint("TOPLEFT", 0, -totalHeight - 4)
            sep:SetPoint("TOPRIGHT", historyContent, "TOPRIGHT", 0, -totalHeight - 4)
            sep:SetTexture(0.2, 0.2, 0.2, 0.8)
            table.insert(historyLines, sep)
            totalHeight = totalHeight + 8
        end
    end

    historyContent:SetHeight(totalHeight + 8)
    historyScroll:UpdateScrollChildRect()
end

-- Collapse history
local function CollapseHistory()
    isHistoryExpanded = false
    historyContainer:Hide()
    frame:SetHeight(COLLAPSED_HEIGHT)
    historyToggle:SetText("Show history ▼")
end

-- Expand history
local function ExpandHistory()
    isHistoryExpanded = true
    RefreshHistory()
    historyContainer:Show()
    frame:SetHeight(EXPANDED_HEIGHT)
    historyToggle:SetText("Hide history ▲")
end

historyToggle:SetScript("OnClick", function()
    if isHistoryExpanded then
        CollapseHistory()
    else
        ExpandHistory()
    end
end)

-- View mode
local function SetViewMode()
    isEditMode = false
    local note = PorkNotes.GetPlayerNote(currentPlayerName)
    noteLabel:SetText(note and note.text or "")
    noteLabel:Show()
    editBox:Hide()
    charCounter:Hide()
    editButton:Show()
    deleteButton:Show()
    saveButton:Hide()
    cancelEditButton:Hide()
    confirmDeleteButton:Hide()
    cancelDeleteButton:Hide()
    deletePromptLabel:Hide()
    closeBtn:Show()
end

-- Edit mode
local function SetEditMode()
    isEditMode = true
    local note = PorkNotes.GetPlayerNote(currentPlayerName)
    editBox:SetText(note and note.text or "")
    editBox:SetFocus()
    local current = string.len(editBox:GetText())
    charCounter:SetText(current .. " / 200")
    noteLabel:Hide()
    editBox:Show()
    charCounter:Show()
    editButton:Hide()
    deleteButton:Hide()
    saveButton:Show()
    cancelEditButton:Show()
    confirmDeleteButton:Hide()
    cancelDeleteButton:Hide()
    deletePromptLabel:Hide()
    closeBtn:Hide()
end

-- Delete confirm mode
local function SetDeleteConfirmMode()
    editButton:Hide()
    deleteButton:Hide()
    saveButton:Hide()
    cancelEditButton:Hide()
    confirmDeleteButton:Show()
    cancelDeleteButton:Show()
    deletePromptLabel:Show()
    closeBtn:Hide()
end

-- Button handlers
editButton:SetScript("OnClick", SetEditMode)
cancelEditButton:SetScript("OnClick", SetViewMode)
editBox:SetScript("OnEscapePressed", SetViewMode)

saveButton:SetScript("OnClick", function()
    PorkNotes.SetPlayerNote(currentPlayerName, editBox:GetText())
    PorkNotes.UpdateNotesFrame()
    SetViewMode()
    RefreshMetadata()
    if isHistoryExpanded then RefreshHistory() end
end)

editBox:SetScript("OnEnterPressed", function()
    PorkNotes.SetPlayerNote(currentPlayerName, editBox:GetText())
    PorkNotes.UpdateNotesFrame()
    SetViewMode()
    RefreshMetadata()
    if isHistoryExpanded then RefreshHistory() end
end)

deleteButton:SetScript("OnClick", SetDeleteConfirmMode)
cancelDeleteButton:SetScript("OnClick", SetViewMode)

confirmDeleteButton:SetScript("OnClick", function()
    PorkNotes.SetPlayerNote(currentPlayerName, "")
    PorkNotes.UpdateNotesFrame()
    frame:Hide()
end)

closeBtn:SetScript("OnClick", function()
    frame:Hide()
end)

-- Public API
PorkNotes.ShowNoteDetailFrame = function(playername)
    currentPlayerName = playername
    titleLabel:SetText("|cFFD893EDPork|r|cFFFFBB00Notes|r - " .. playername)
    CollapseHistory()
    SetViewMode()
    RefreshMetadata()
    frame:ClearAllPoints()
    local saved = PorkNotes.GetSetting("NoteDetailFramePos", nil)
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
