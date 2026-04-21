local ui = _G.ui or {}
_G.ui = ui

local function CreateKeyLabel(owner, key)
  if not ui.debugLabels then ui.debugLabels = {} end
  local container = (owner and owner.CreateFontString and owner) or (owner and owner.GetParent and owner:GetParent()) or UIParent
  local tag = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  tag:SetPoint("TOPLEFT", owner, "TOPLEFT", 2, -2)
  tag:SetTextColor(1, 1, 1, 1)
  tag:SetText(key)
  tag:Hide()
  table.insert(ui.debugLabels, tag)
  return tag
end

local function UpdateDebugLabels()
  local show = DboxDB and DboxDB.config and DboxDB.config.debug
  if ui.debugLabels then
    for _, tag in ipairs(ui.debugLabels) do
      if show then tag:Show() else tag:Hide() end
    end
  end
end

local function CreatePanelBG(frame, alpha)
  local bg = frame:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(true)
  bg:SetColorTexture(0, 0, 0, alpha or 0.5)
  frame._dbox_bg = bg
  return bg
end

local function ApplyThemeAlpha()
  if not DboxDB or not DboxDB.config then return end
  local aMain = DboxDB.config.alphaMain or 0.3
  local aPanel = DboxDB.config.alphaPanel or 0.2

  if ui.MainFrame and ui.MainFrame._dbox_bg then
    ui.MainFrame._dbox_bg:SetColorTexture(0, 0, 0, aMain)
  end

  local function setPanelAlpha(frame)
    if frame and frame._dbox_bg then frame._dbox_bg:SetColorTexture(0, 0, 0, aPanel) end
  end

  local function setMainAlpha(frame)
    if frame and frame._dbox_bg then frame._dbox_bg:SetColorTexture(0, 0, 0, aMain) end
  end

  setPanelAlpha(ui.TitleBar)
  setPanelAlpha(ui.LeftMenu)
  setPanelAlpha(ui.ContainerArea)
  setPanelAlpha(ui.List1Frame)
  setPanelAlpha(ui.List2Frame)
  setPanelAlpha(ui.List3Frame)
  setPanelAlpha(ui.List4Frame)
  setPanelAlpha(ui.ListBar1)
  setPanelAlpha(ui.ListBar2)
  setPanelAlpha(ui.ListBar3)
  setPanelAlpha(ui.ListBar4)
  setPanelAlpha(ui.DboxInfo)
  setMainAlpha(ui.SetupFrame)
  setMainAlpha(ui.HelpFrame)
end

local function GetEnchantSkillPoint()
  for i = 1, GetNumSkillLines() do
    local skillName, _, _, skillRank, _, _, _, _, _, _, _, _, _, skillID = GetSkillLineInfo(i)
    if skillName == "附魔" or skillName == ENCHANTING or skillID == 333 then
      return skillRank
    end
  end
  return nil
end

local function UpdateEnchantSkillText()
  if not ui.EnchantSkillFS then return end
  local point = GetEnchantSkillPoint()
  local icon = "|T136244:16:16:0:0:64:64:4:60:4:60|t"
  local white = "|cffffffff"
  local reset = "|r"
  if point then
    ui.EnchantSkillFS:SetText(icon .. white .. point .. reset)
  else
    ui.EnchantSkillFS:SetText(icon .. white .. "0" .. reset)
  end
  ui.EnchantSkillFS:Show()
end

local function SetFSSize(fs, size)
  if not fs or not size then return end
  local font, _, flags = fs:GetFont()
  if font then fs:SetFont(font, size, flags) end
end

local function SetBtnFont(btn, size)
  if not btn or not size then return end
  local fs = btn.GetFontString and btn:GetFontString()
  if fs then SetFSSize(fs, size) end
end

local function ApplyFontSizes()
  if not DboxDB or not DboxDB.config then return end

  local sTitle = DboxDB.config.fontTitleSize or 14
  local sCTitle = DboxDB.config.fontContainerTitleSize or 12
  local sBtn = DboxDB.config.fontButtonSize or 12
  local sText = DboxDB.config.fontContentSize or 12

  SetFSSize(ui.DboxTitle, sTitle)
  SetFSSize(ui.DboxVer, sText)

  for i = 1, 4 do
    local title = ui["ListTitle" .. i]
    if title then SetFSSize(title, sCTitle) end
    local rows = ui["ListRows" .. i]
    if rows then
      for _, row in ipairs(rows) do
        if row and row.text then SetFSSize(row.text, sText) end
      end
    end
  end

  if ui.InfoText then SetFSSize(ui.InfoText, sText) end

  local btns = {"BtnHelp", "BtnClose", "BtnScan", "BtnDebug", "BtnSetting", "BtnReset", "BtnMiniMode", "BtnAdd2List", "BtnClearList1", "BtnClearList2", "BtnDe", "BtnAdd2DB", "BtnClearList3", "BtnReadDBList", "BtnClearDBList"}
  for _, key in ipairs(btns) do
    local button = ui[key]
    if button then SetBtnFont(button, sBtn) end
  end

  if ui.SetupFrame then
    if ui.SetupTitle then SetFSSize(ui.SetupTitle, sTitle) end
    local count = ui.SetupFrame:GetNumChildren() or 0
    for i = 1, count do
      local child = select(i, ui.SetupFrame:GetChildren())
      if child and child:GetObjectType() == "Button" then SetBtnFont(child, sBtn) end
    end
  end

  if ui.HelpTitle then SetFSSize(ui.HelpTitle, sTitle) end
  if ui.HelpText then SetFSSize(ui.HelpText, sText) end
  if ui.HelpHTML and ui.HelpHeaderFont and ui.HelpPFont then
    local fontH, _, flagsH = ui.HelpHeaderFont:GetFont()
    if fontH then ui.HelpHeaderFont:SetFont(fontH, sTitle, flagsH) end
    local fontP, _, flagsP = ui.HelpPFont:GetFont()
    if fontP then ui.HelpPFont:SetFont(fontP, sText, flagsP) end
  end
end

_G.CreateKeyLabel = CreateKeyLabel
_G.UpdateDebugLabels = UpdateDebugLabels
_G.CreatePanelBG = CreatePanelBG
_G.ApplyThemeAlpha = ApplyThemeAlpha
_G.GetEnchantSkillPoint = GetEnchantSkillPoint
_G.UpdateEnchantSkillText = UpdateEnchantSkillText
_G.SetFSSize = SetFSSize
_G.ApplyFontSizes = ApplyFontSizes