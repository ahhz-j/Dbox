local ui = _G.ui or {}
_G.ui = ui
_G.isMiniMode = _G.isMiniMode or false
_G.savedInterfaceState = _G.savedInterfaceState or {}

local function RefreshEnchantSkillText()
  local updater = _G.UpdateEnchantSkillText
  if type(updater) == "function" then
    updater()
    return
  end

  if not ui.EnchantSkillFS then return end

  local point
  local getter = _G.GetEnchantSkillPoint
  if type(getter) == "function" then
    point = getter()
  elseif GetNumSkillLines and GetSkillLineInfo then
    for i = 1, GetNumSkillLines() do
      local skillName, _, _, skillRank, _, _, _, _, _, _, _, _, _, skillID = GetSkillLineInfo(i)
      if skillName == "附魔" or (ENCHANTING and skillName == ENCHANTING) or skillID == 333 then
        point = skillRank
        break
      end
    end
  end

  local icon = "|T136244:16:16:0:0:64:64:4:60:4:60|t"
  local white = "|cffffffff"
  local reset = "|r"
  ui.EnchantSkillFS:SetText(icon .. white .. tostring(point or 0) .. reset)
  ui.EnchantSkillFS:Show()
end

local function LayoutContainersRow()
  if not (ui.ContainerArea and ui.List1Frame and ui.List2Frame and ui.List3Frame and ui.List4Frame) then return end

  local gap = 6
  local aw = ui.ContainerArea:GetWidth() or 612
  if aw <= 0 then aw = 612 end
  local cfgW = (DboxDB and DboxDB.config and DboxDB.config.containerWidth) or 180
  local aveW = math.floor((aw - gap * 3) / 4)
  local cw = math.min(cfgW, aveW)
  if cw < 150 then cw = 150 end

  local cfgH = (DboxDB and DboxDB.config and DboxDB.config.containerHeight) or 200
  local areaH = ui.ContainerArea:GetHeight() or cfgH
  local ch = math.min(cfgH, areaH - 10)
  if ch < 150 then ch = 150 end

  local frames = {ui.List1Frame, ui.List2Frame, ui.List3Frame, ui.List4Frame}
  for i, frame in ipairs(frames) do
    if frame then
      frame:ClearAllPoints()
      if i == 1 then
        frame:SetPoint("TOPLEFT")
      else
        frame:SetPoint("TOPLEFT", frames[i - 1], "TOPRIGHT", gap, 0)
      end
      frame:SetSize(cw, ch)
    end
  end
end

local function GetMainWidthBreakdown()
  local leftMenuW = 100
  local leftGap = 4
  local rightGap = 4
  local colGap = 6
  local mw = (ui.MainFrame and ui.MainFrame.GetWidth and math.floor((ui.MainFrame:GetWidth() or 0) + 0.5)) or (DboxDB and DboxDB.config and DboxDB.config.mainWidth) or 820
  local aw = mw - (leftMenuW + leftGap + rightGap)
  local cfgW = (DboxDB and DboxDB.config and DboxDB.config.containerWidth) or 180
  local aveW = math.floor(((aw >= 0 and aw or 0) - colGap * 3) / 4)
  local cw = math.min(cfgW, aveW)
  if cw < 150 then cw = 150 end
  local total = leftMenuW + leftGap + cw * 4 + colGap * 3 + rightGap
  return leftMenuW, leftGap, cw, colGap, rightGap, total
end

local function GetMainWidthBreakdownText()
  local lm, lg, cw, gg, rg, total = GetMainWidthBreakdown()
  return string.format("左侧菜单%d + 左间隙%d + 容器列宽%d*4 + 列间隙%d*3 + 右间隙%d = %d", lm, lg, cw, gg, rg, total)
end

local function saveInterfaceState()
  savedInterfaceState = {}
  _G.savedInterfaceState = savedInterfaceState
  for i = 1, 4 do
    local frame = ui["List" .. i .. "Frame"]
    savedInterfaceState["container" .. i .. "Visible"] = (frame and frame:IsShown()) and true or false
  end
  savedInterfaceState.mainWidth = ui.MainFrame and ui.MainFrame:GetWidth()
  savedInterfaceState.infoBarMode = "full"
end

local function SetContainerVisible(id, visible)
  local keys = {"List" .. id .. "Frame", "ListBar" .. id}
  for _, key in ipairs(keys) do
    local frame = ui[key]
    if frame then
      if visible then frame:Show() else frame:Hide() end
    end
  end

  if id == 1 then
    for _, name in ipairs({"BtnAdd2List", "BtnClearList1"}) do
      local button = ui[name]
      if button then if visible then button:Show() else button:Hide() end end
    end
  elseif id == 2 then
    for _, name in ipairs({"BtnClearList2", "BtnDe"}) do
      local button = ui[name]
      if button then if visible then button:Show() else button:Hide() end end
    end
  elseif id == 3 then
    for _, name in ipairs({"BtnAdd2DB", "BtnClearList3"}) do
      local button = ui[name]
      if button then if visible then button:Show() else button:Hide() end end
    end
  elseif id == 4 then
    for _, name in ipairs({"BtnReadDBList", "BtnClearDBList"}) do
      local button = ui[name]
      if button then if visible then button:Show() else button:Hide() end end
    end
  end
end

local function ApplyMiniLayout()
  if not (ui.ContainerArea and ui.List2Frame) then return end
  ui.List2Frame:ClearAllPoints()
  ui.List2Frame:SetPoint("TOPLEFT")
  local cw = (DboxDB and DboxDB.config and DboxDB.config.containerWidth) or 180
  if cw < 150 then cw = 150 end
  local cfgH = (DboxDB and DboxDB.config and DboxDB.config.containerHeight) or 200
  local areaH = (ui.ContainerArea and ui.ContainerArea.GetHeight and ui.ContainerArea:GetHeight()) or cfgH
  local ch = math.min(cfgH, (areaH or cfgH) - 10)
  if ch < 150 then ch = 150 end
  ui.List2Frame:SetSize(cw, ch)
end

local function _AnchorInfoBar(mode)
  if not ui.DboxInfo or not ui.InfoText then return end
  ui.InfoText:ClearAllPoints()
  if mode == "mini" then
    ui.InfoText:SetPoint("LEFT", ui.DboxInfo, "LEFT", 8, 0)
  else
    if not ui.BagFreeText then return end
    ui.InfoText:SetPoint("LEFT", ui.BagFreeText, "RIGHT", 10, 0)
  end
end

local function ApplyMiniInfoBarAnchors()
  _AnchorInfoBar("mini")
end

local function ApplyNormalInfoBarAnchors()
  _AnchorInfoBar("normal")
end

local function ReanchorPanels()
  if not UIParent then return end
  local frames = {ui.SetupFrame, ui.HelpFrame}
  for _, frame in ipairs(frames) do
    if frame and frame:IsShown() then
      frame:ClearAllPoints()
      if ui.MainFrame and ui.MainFrame.GetRight and ui.MainFrame.GetTop then
        local rx = ui.MainFrame:GetRight() or 0
        local ty = ui.MainFrame:GetTop() or 0
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", rx + 20, ty)
      else
        frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -20)
      end
    end
  end
end

local function ReanchorPanelsSoon()
  if C_Timer and C_Timer.After then
    C_Timer.After(0, function()
      if not ui or not ui.MainFrame then return end
      ReanchorPanels()
    end)
  else
    ReanchorPanels()
  end
end

local function GetModeKey()
  return isMiniMode and "mini" or "normal"
end

local function SaveCurrentModeSettings()
  if not DboxDB then DboxDB = {} end
  if not DboxDB.modes then DboxDB.modes = {} end
  local key = GetModeKey()
  if not DboxDB.modes[key] then DboxDB.modes[key] = {} end
  local mode = DboxDB.modes[key]
  if DboxDB.config then
    mode.mainWidth = DboxDB.config.mainWidth or mode.mainWidth
    mode.mainHeight = DboxDB.config.mainHeight or mode.mainHeight
    mode.containerWidth = DboxDB.config.containerWidth or mode.containerWidth
    mode.containerHeight = DboxDB.config.containerHeight or mode.containerHeight
    mode.titleBarHeight = DboxDB.config.titleBarHeight or mode.titleBarHeight
  end
end

local function ApplyModeSettings(key)
  if not DboxDB then return end
  local modes = DboxDB.modes or {}
  local mode = modes[key] or {}
  if not DboxDB.config then DboxDB.config = {} end
  if mode.mainWidth then
    DboxDB.config.mainWidth = mode.mainWidth
    if ui.MainFrame then ui.MainFrame:SetWidth(DboxDB.config.mainWidth) end
  end
  if mode.mainHeight then
    DboxDB.config.mainHeight = mode.mainHeight
    if ui.MainFrame then ui.MainFrame:SetHeight(DboxDB.config.mainHeight) end
  end
  if mode.containerWidth then DboxDB.config.containerWidth = mode.containerWidth end
  if mode.containerHeight then DboxDB.config.containerHeight = mode.containerHeight end
  if mode.titleBarHeight then
    DboxDB.config.titleBarHeight = mode.titleBarHeight
    if ui.TitleBar then ui.TitleBar:SetHeight(DboxDB.config.titleBarHeight) end
  end
end

local function UpdateMainWidthSliderRange()
  local slider = ui and ui.SliderMainWidth
  if not slider then return end
  local minV, maxV, step = 720, 1200, 10
  local key = isMiniMode and "mini" or "normal"
  if isMiniMode then minV, maxV, step = 280, 400, 5 end
  slider:SetMinMaxValues(minV, maxV)
  local stored = (DboxDB and DboxDB.modes and DboxDB.modes[key] and DboxDB.modes[key].mainWidth) or nil
  local def = isMiniMode and 290 or 820
  local mw = (DboxDB and DboxDB.config and DboxDB.config.mainWidth) or stored or def
  if mw < minV then mw = minV end
  if mw > maxV then mw = maxV end
  if not DboxDB then DboxDB = {} end
  if not DboxDB.config then DboxDB.config = {} end
  DboxDB.config.mainWidth = mw
  if ui.MainFrame then ui.MainFrame:SetWidth(mw) end
  slider:SetValue(mw)
end

local function toggleMiniMode()
  SaveCurrentModeSettings()
  isMiniMode = not isMiniMode

  if isMiniMode then
    saveInterfaceState()
    for _, id in ipairs({1, 3, 4}) do SetContainerVisible(id, false) end

    ApplyModeSettings("mini")
    if ui.MainFrame then
      DboxDB.config.mainWidth = 290
      ui.MainFrame:SetWidth(290)
      ApplyMiniLayout()
      if ui.SliderMainWidth then
        ui.SliderMainWidth:SetMinMaxValues(280, 400)
        ui.SliderMainWidth:SetValue(290)
      end
    end

    SetContainerVisible(2, true)
    ApplyMiniInfoBarAnchors()
    if UpdateInfoBarCounters then UpdateInfoBarCounters() end
  else
    isMiniMode = false
    if not DboxDB then DboxDB = {} end
    DboxDB.miniMode = false
    ApplyModeSettings("normal")
    for id = 1, 4 do SetContainerVisible(id, true) end
    if ui.MainFrame then
      DboxDB.config.mainWidth = 820
      ui.MainFrame:SetWidth(820)
      if ui.SliderMainWidth then
        ui.SliderMainWidth:SetMinMaxValues(720, 1200)
        ui.SliderMainWidth:SetValue(820)
      end
    end
    ApplyNormalInfoBarAnchors()
    LayoutContainersRow()
    if UpdateInfoBarCounters then UpdateInfoBarCounters() end
  end

  if ui.BtnMiniMode then
    local txtMini = (DboxText and DboxText.btnMini) or "迷你模式"
    ui.BtnMiniMode:SetText(isMiniMode and "正常模式" or txtMini)
  end

  if not DboxDB then DboxDB = {} end
  DboxDB.miniMode = isMiniMode
  ReanchorPanelsSoon()
  UpdateMainWidthSliderRange()
end

local function InitializeMiniMode()
  if ui.LeftMenu and not ui.BtnMiniMode then
    ui.BtnMiniMode = CreateFrame("Button", "BtnMiniMode", ui.LeftMenu, "UIPanelButtonTemplate")
    ui.BtnMiniMode:SetSize(75, 30)
    ui.BtnMiniMode:SetPoint("TOPLEFT", ui.BtnReset, "BOTTOMLEFT", 0, -8)
    ui.BtnMiniMode:SetText("迷你模式")
    ui.BtnMiniMode:SetScript("OnClick", toggleMiniMode)
    CreateKeyLabel(ui.BtnMiniMode, "BtnMiniMode")
    ApplyFontSizes()
  end

  if ui.BtnMiniMode and not ui.EnchantSkillFS then
    ui.EnchantSkillFS = ui.LeftMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.EnchantSkillFS:SetPoint("TOP", ui.BtnMiniMode, "BOTTOM", 0, -4)
    ui.EnchantSkillFS:SetJustifyH("CENTER")
    ui.EnchantSkillFS:SetTextColor(0.7, 0.9, 1, 1)
    ui.EnchantSkillFS:SetText("")
    RefreshEnchantSkillText()
    ui.EnchantSkillFS:EnableMouse(true)
    ui.EnchantSkillFS:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:ClearLines()
      GameTooltip:AddLine("附魔技能等级与可分解物品的关系（诺森德）", 1, 1, 1)
      GameTooltip:AddLine("- 325：诺森德精良装备，物品等级121-165；", 0.8, 0.8, 0.8)
      GameTooltip:AddLine("- 350：诺森德稀有装备，物品等级166-200；", 0.8, 0.8, 0.8)
      GameTooltip:AddLine("- 375：当前版本所有装备都可以分解，分解史诗装备的最低要求；", 0.8, 0.8, 0.8)
      GameTooltip:Show()
    end)
    ui.EnchantSkillFS:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
  end

  if not ui._EnchantSkillEvent then
    ui._EnchantSkillEvent = CreateFrame("Frame")
    ui._EnchantSkillEvent:RegisterEvent("SKILL_LINES_CHANGED")
    ui._EnchantSkillEvent:SetScript("OnEvent", function()
      RefreshEnchantSkillText()
    end)
  end

  if not ui._EnchantSkillLoginEvent then
    ui._EnchantSkillLoginEvent = CreateFrame("Frame")
    ui._EnchantSkillLoginEvent:RegisterEvent("PLAYER_ENTERING_WORLD")
    ui._EnchantSkillLoginEvent:SetScript("OnEvent", function(self)
      RefreshEnchantSkillText()
      self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end)
  end

  if DboxDB and DboxDB.miniMode then
    isMiniMode = false
    if C_Timer and C_Timer.After then
      C_Timer.After(0.1, function()
        toggleMiniMode()
      end)
    else
      toggleMiniMode()
    end
  end
end

local function SaveMiniModeState()
  if not DboxDB then DboxDB = {} end
  DboxDB.miniMode = isMiniMode
end

_G.LayoutContainersRow = LayoutContainersRow
_G.ApplyMiniLayout = ApplyMiniLayout
_G.ApplyNormalInfoBarAnchors = ApplyNormalInfoBarAnchors
_G.ApplyMiniInfoBarAnchors = ApplyMiniInfoBarAnchors
_G.toggleMiniMode = toggleMiniMode
_G.InitializeMiniMode = InitializeMiniMode
_G.SaveMiniModeState = SaveMiniModeState