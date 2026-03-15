local frame = CreateFrame("Frame", "PorkNotes_SettingsFrame", UIParent)
frame:SetWidth(380)
frame:SetHeight(280)
frame:SetPoint("CENTER", UIParent)
frame:SetFrameStrata("DIALOG")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetResizable(false)
frame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
})
frame:SetBackdropColor(0, 0, 0, 0.8)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function() this:StartMoving() end)
frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
frame:Hide()

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", 0, -15)
title:SetText("PorkNotes - Settings")

-- Makes the window closable by pressing Escape.
tinsert(UISpecialFrames, frame:GetName())

local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

local submitButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
submitButton:SetWidth(100)
submitButton:SetHeight(24)
submitButton:SetPoint("BOTTOM", 0, 15)
submitButton:SetText("OK")
submitButton:SetScript("OnClick", function() frame:Hide() end)

frame:SetScript("OnShow", function()
    PlaySound("igQuestListOpen")
end)

frame:SetScript("OnHide", function()
    PorkNotes.ShowNotesFrame()
    PlaySound("igQuestListClose")
end)

local checkboxes = {}

local function EnableCheckbox(checkbox)
    checkbox:Enable()
    checkbox.textElement:SetTextColor(1, 0.82, 0)
end

local function DisableCheckbox(checkbox)
    checkbox:Disable()
    checkbox.textElement:SetTextColor(0.5, 0.5, 0.5)
end

local function ChangeCheckboxState(checkboxName, isEnabled)
    if isEnabled then
        EnableCheckbox(checkboxes[checkboxName])
    else
        DisableCheckbox(checkboxes[checkboxName])
    end
end

local function OnCheckboxToggle(name, isChecked)
    PorkNotes.SetSetting(name, isChecked)
end

local function CreateCheckbox(name, text, x, y)
    local checkboxName = frame:GetName() .. "_" .. name
    local checkboxTextName = frame:GetName() .. "_" .. name .. "Text"
    local checkbox = CreateFrame("CheckButton", checkboxName, frame, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -y)
    checkbox:SetWidth(20)
    checkbox:SetHeight(20)

    checkbox.textElement = _G[checkboxTextName]
    checkbox.textElement:SetText(" " .. text)
    checkbox.textElement:SetFontObject(GameFontNormal)
    checkbox:SetHitRectInsets(0, -checkbox.textElement:GetStringWidth(), 0, 0)

    checkbox:SetScript("OnClick", function()
        -- GetChecked() returns 1 or nil, not a boolean
        OnCheckboxToggle(name, checkbox:GetChecked() ~= nil)
    end)

    EnableCheckbox(checkbox)
    checkboxes[name] = checkbox
end

local y = 40
CreateCheckbox("NotesShowCreatedBy", "Show who created the note in the main window", 20, y); y = y + 25
CreateCheckbox("NotesShowCreatedAtZone", "Show where the note was created in the main window", 20, y); y = y + 35

CreateCheckbox("ShowNotesInChat", "Display player notes in chat", 20, y); y = y + 35

CreateCheckbox("ShowNotesInTooltips", "Display player notes in tooltips", 20, y); y = y + 35

-- World/LFG chat frame dropdown
local dropdownLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
dropdownLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -y)
dropdownLabel:SetText("Route World/LFG alerts to:")

local dropdown = CreateFrame("Frame", frame:GetName() .. "_WorldChatDropdown", frame, "UIDropDownMenuTemplate")
dropdown:SetPoint("TOPLEFT", frame, "TOPLEFT", 150, -(y - 14))
UIDropDownMenu_SetWidth(100, dropdown)

local function UpdateDropdown()
    local currentValue = PorkNotes.GetSetting("WorldChatFrame", 3)
    UIDropDownMenu_Initialize(dropdown, function()
        for i = 1, 10 do
            local info = {}
            info.text = "Chat Frame " .. i
            info.value = i
            info.checked = (i == currentValue)
            info.func = function()
                local selected = this.value
                PorkNotes.SetSetting("WorldChatFrame", selected)
                UIDropDownMenu_SetText("Chat Frame " .. selected, dropdown)
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetText("Chat Frame " .. currentValue, dropdown)
end

PorkNotes.ShowSettingsFrame = function()
    checkboxes.NotesShowCreatedBy:SetChecked(PorkNotes.GetSetting("NotesShowCreatedBy", false))
    checkboxes.NotesShowCreatedAtZone:SetChecked(PorkNotes.GetSetting("NotesShowCreatedAtZone", false))
    checkboxes.ShowNotesInChat:SetChecked(PorkNotes.GetSetting("ShowNotesInChat", true))
    checkboxes.ShowNotesInTooltips:SetChecked(PorkNotes.GetSetting("ShowNotesInTooltips", true))

    UpdateDropdown()

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent)
    frame:Show()
end
