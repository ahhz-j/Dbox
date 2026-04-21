local ui = _G.ui or {}
_G.ui = ui

local function AnchorToMainTopRight(f, offsetX, offsetY)
  offsetX = offsetX or 20
  offsetY = offsetY or 0
  f:ClearAllPoints()
  if not ui.MainFrame and _G.EnsureMainUI then
    _G.EnsureMainUI()
  end
  if ui.MainFrame then
    if ui.MainFrame.Show and (not ui.MainFrame:IsShown()) then ui.MainFrame:Show() end
    f:SetPoint("TOPLEFT", ui.MainFrame, "TOPRIGHT", offsetX, offsetY)
  end
end

local function Panels_EnsureHelpFrame()
  if ui and ui.HelpFrame then
    if ui.HelpFrame:IsShown() then
      ui.HelpFrame:Hide()
      return ui.HelpFrame
    else
      AnchorToMainTopRight(ui.HelpFrame, 20, 0)
      if ui.SetupFrame and ui.SetupFrame:IsShown() then ui.SetupFrame:Hide() end
      ui.HelpFrame:Show()
      if ui.HelpFrame.Raise then ui.HelpFrame:Raise() end
      if ApplyFontSizes then ApplyFontSizes() end
      return ui.HelpFrame
    end
  end
  local f = CreateFrame("Frame", "DboxHelpFrame", UIParent, "BackdropTemplate")
  f:SetSize(520, 380)
  AnchorToMainTopRight(f, 20, 0)
  f:SetFrameStrata("DIALOG")
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:SetScript("OnShow", function()
    if ui.SetupFrame and ui.SetupFrame:IsShown() then ui.SetupFrame:Hide() end
    AnchorToMainTopRight(f, 20, 0)
  end)
  CreatePanelBG(f, (DboxDB and DboxDB.config and DboxDB.config.alphaMain) or 0.3)
  local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  title:SetPoint("TOP", 0, -10)
  title:SetText((DboxText and DboxText.helpTitle) or "Dbox 帮助")
  do
    local sTitle = (DboxDB and DboxDB.config and DboxDB.config.fontTitleSize) or 14
    if SetFSSize then SetFSSize(title, sTitle) end
  end
  ui.HelpTitle = title
  local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
  closeBtn:SetSize(28, 28)
  local sf = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", 14, -40)
  sf:SetPoint("BOTTOMRIGHT", -30, 14)
  local content = CreateFrame("Frame", nil, sf)
  content:SetSize(1, 1)
  sf:SetScrollChild(content)
  local help = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  help:SetPoint("TOPLEFT", 0, 0)
  help:SetJustifyH("LEFT")
  help:SetWidth(460)
  help:SetText((DboxHelpText) or "Dbox 帮助")
  content:SetHeight(help:GetStringHeight() + 10)
  ui.HelpText = help
  ui.HelpFrame = f
  if ApplyFontSizes then ApplyFontSizes() end
  f:Show()
  return f
end

Panels_EnsureSetupFrame = function()
  if ui.HelpFrame and ui.HelpFrame:IsShown() then ui.HelpFrame:Hide() end
  if ui.SetupFrame then
    if ui.SetupFrame:IsShown() then
      ui.SetupFrame:Hide()
      return ui.SetupFrame
    else
      AnchorToMainTopRight(ui.SetupFrame, 20, 0)
      ui.SetupFrame:Show()
      if ui.SetupFrame.Raise then ui.SetupFrame:Raise() end
      if ApplyFontSizes then ApplyFontSizes() end
      return ui.SetupFrame
    end
  end
  if not ui.SetupFrame then
    local aMain = (DboxDB and DboxDB.config and DboxDB.config.alphaMain) or 0.3
    ui.SetupFrame = CreateFrame("Frame", "SetupFrame", UIParent, "BackdropTemplate")
    ui.SetupFrame:SetSize(380, 360)
    ui.SetupFrame:SetFrameStrata("DIALOG")
    ui.SetupFrame:EnableMouse(true)
    ui.SetupFrame:SetMovable(true)
    ui.SetupFrame:RegisterForDrag("LeftButton")
    ui.SetupFrame:SetScript("OnDragStart", ui.SetupFrame.StartMoving)
    ui.SetupFrame:SetScript("OnDragStop", function(f) f:StopMovingOrSizing() end)
    ui.SetupFrame:SetScript("OnShow", function(f)
      if ui.HelpFrame and ui.HelpFrame:IsShown() then ui.HelpFrame:Hide() end
      AnchorToMainTopRight(f, 20, 0)
      if f.Raise then f:Raise() end
    end)
    AnchorToMainTopRight(ui.SetupFrame, 20, 0)
    CreatePanelBG(ui.SetupFrame, aMain)
    CreateKeyLabel(ui.SetupFrame, "SetupFrame")
    local title = ui.SetupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -8)
    title:SetText((DboxText and DboxText.settingsTitle) or "Dbox设置选项")
    do
      local sTitle = (DboxDB and DboxDB.config and DboxDB.config.fontTitleSize) or 14
      if SetFSSize then SetFSSize(title, sTitle) end
    end
    ui.SetupTitle = title
    local xbtn = CreateFrame("Button", nil, ui.SetupFrame, "UIPanelCloseButton")
    xbtn:SetPoint("TOPRIGHT", -1, -1)
    xbtn:SetSize(28, 28)
    xbtn:SetScript("OnClick", function() ui.SetupFrame:Hide() end)
    local sf = CreateFrame("ScrollFrame", nil, ui.SetupFrame, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 12, -34)
    sf:SetPoint("BOTTOMRIGHT", -28, 12)
    local content = CreateFrame("Frame", nil, sf)
    content:SetSize(10,10); sf:SetScrollChild(content)
    local function UpdateContentWidth()
      local w = sf:GetWidth() or 0
      if w > 0 then content:SetWidth(w - 14) end
    end
    UpdateContentWidth()
    sf:SetScript("OnSizeChanged", function(self) UpdateContentWidth() end)
    local controls = {}
    local function controlsAdd(entry)
      if entry then table.insert(controls, entry) end
    end
    local function setControlsEnabled(enabled)
      local function setFSColor(fs, en)
        if not fs then return end
        if en then
          if fs._origColor then fs:SetTextColor(fs._origColor.r, fs._origColor.g, fs._origColor.b) end
        else
          if not fs._origColor then
            local r,g,b = fs:GetTextColor()
            fs._origColor = {r=r,g=g,b=b}
          end
          fs:SetTextColor(0.5,0.5,0.5)
        end
      end
      for _, c in ipairs(controls) do
        local w = c.widget or c
        if w and not w._isLockControl and not w._alwaysDisabled then
          if enabled then
            if w.Enable then w:Enable() end
          else
            if w.Disable then w:Disable() end
          end
          setFSColor(c.label, enabled)
          setFSColor(c.val, enabled)
        end
      end
    end
    local function makeSlider(y, label, minV, maxV, step, getV, setV)
      local s = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
      s:ClearAllPoints()
      s:SetPoint("TOPRIGHT", content, "TOPRIGHT", -12, y)
      s:SetWidth(240)
      s:SetMinMaxValues(minV, maxV)
      s:SetValueStep(step)
      s:SetObeyStepOnDrag(true)
      s:SetValue(getV())
      _G[s:GetName() and s:GetName().."Text" or ""] = nil
      local txt = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      txt:SetPoint("TOPLEFT", content, "TOPLEFT", 8, y + 14)
      local val = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      val:SetPoint("RIGHT", s, "RIGHT", 0, 14)
      local function updateLabel(v)
        txt:SetText(label)
        val:SetText(string.format("%.0f", v))
      end
      updateLabel(s:GetValue())
      s:SetScript("OnValueChanged", function(_, v)
        setV(v)
        updateLabel(v)
      end)
      s._label = txt
      s._val = val
      controlsAdd({widget=s, label=txt, val=val})
      return s
    end
    local function makeCheck(y, label, getV, setV)
      local b = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
      b:SetPoint("TOPLEFT", 8, y)
      b:SetSize(20, 20)
      b:SetChecked(getV())
      local fs = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      fs:SetPoint("LEFT", b, "RIGHT", 6, 0)
      fs:SetText(label)
      b:SetScript("OnClick", function(self) setV(self:GetChecked() and true or false) end)
      controlsAdd({widget=b, label=fs})
      return b, fs
    end
    local y = -6
    local lockBtn = nil
    do
      local b = makeCheck(y - 2, "锁定所有设置",
        function() return not not (DboxDB and DboxDB.config and DboxDB.config.lockAllSettings) end,
        function(val)
          if not DboxDB then DboxDB = {} end
          if not DboxDB.config then DboxDB.config = {} end
          DboxDB.config.lockAllSettings = not not val
          setControlsEnabled(not DboxDB.config.lockAllSettings)
        end)
      lockBtn = b
      if lockBtn then lockBtn._isLockControl = true end
    end
    makeSlider(y - 34, "按钮承载栏Y偏移", 0, 20, 1,
      function() return (DboxDB.config.buttonBarYOffset or 2) end,
      function(v)
        DboxDB.config.buttonBarYOffset = math.floor(v + 0.5)
        for i=1,4 do
          local bar = ui["ListBar"..i]
          if bar then
            bar:ClearAllPoints()
            bar:SetPoint("BOTTOMLEFT", 0, DboxDB.config.buttonBarYOffset)
            bar:SetPoint("BOTTOMRIGHT", 0, DboxDB.config.buttonBarYOffset)
          end
        end
      end)
    local sCW = makeSlider(y - 84, "容器宽度", 150, 320, 5,
      function() return (DboxDB.config.containerWidth or 180) end,
      function(v)
        DboxDB.config.containerWidth = math.floor(v + 0.5)
        if isMiniMode then ApplyMiniLayout() else LayoutContainersRow() end
      end)
    if sCW then
      sCW._alwaysDisabled = true
      sCW:Disable()
      if sCW._label then sCW._label:SetTextColor(0.5,0.5,0.5) end
      if sCW._val then sCW._val:SetTextColor(0.5,0.5,0.5) end
    end
    makeSlider(y - 134, "容器高度", 150, 500, 10,
      function() return (DboxDB.config.containerHeight or 200) end,
      function(v)
        DboxDB.config.containerHeight = math.floor(v + 0.5)
        if isMiniMode then ApplyMiniLayout() else LayoutContainersRow() end
      end)
    local mwMin, mwMax, mwStep = 720, 1200, 10
    if isMiniMode then mwMin, mwMax, mwStep = 280, 400, 5 end
    local sMW = makeSlider(y - 184, "主界面宽度", mwMin, mwMax, mwStep,
      function() return (DboxDB.config.mainWidth or 820) end,
      function(v)
        DboxDB.config.mainWidth = math.floor(v + 0.5)
        ui.MainFrame:SetWidth(DboxDB.config.mainWidth)
        if not DboxDB.modes then DboxDB.modes = {} end
        local key = isMiniMode and "mini" or "normal"
        if not DboxDB.modes[key] then DboxDB.modes[key] = {} end
        DboxDB.modes[key].mainWidth = DboxDB.config.mainWidth
        if isMiniMode then ApplyMiniLayout() else LayoutContainersRow() end
      end)
    ui.SliderMainWidth = sMW
    if sMW then
      sMW._alwaysDisabled = true
      sMW:Disable()
      if sMW._label then sMW._label:SetTextColor(0.5,0.5,0.5) end
      if sMW._val then sMW._val:SetTextColor(0.5,0.5,0.5) end
    end
    makeSlider(y - 234, "主界面高度", 300, 700, 10,
      function() return (DboxDB.config.mainHeight or 370) end,
      function(v)
        DboxDB.config.mainHeight = math.floor(v + 0.5)
        ui.MainFrame:SetHeight(DboxDB.config.mainHeight)
        if isMiniMode then ApplyMiniLayout() else LayoutContainersRow() end
      end)
    makeSlider(y - 284, "标题栏高度", 10, 60, 2,
      function() return (DboxDB.config.titleBarHeight or 20) end,
      function(v)
        DboxDB.config.titleBarHeight = math.floor(v/2 + 0.5)*2
        ui.TitleBar:SetHeight(DboxDB.config.titleBarHeight)
        if isMiniMode then ApplyMiniLayout() else LayoutContainersRow() end
      end)
    makeSlider(y - 334, "主界面透明度", 10, 100, 5,
      function() return ((DboxDB.config.alphaMain or 0.3) * 100) end,
      function(v)
        DboxDB.config.alphaMain = (math.floor(v + 0.5))/100
        ApplyThemeAlpha()
      end)
    makeSlider(y - 384, "承载栏透明度", 10, 100, 5,
      function() return ((DboxDB.config.alphaPanel or 0.2) * 100) end,
      function(v)
        DboxDB.config.alphaPanel = (math.floor(v + 0.5))/100
        ApplyThemeAlpha()
      end)
    local function setQualityColor(fs, q)
      if not fs then return end
      local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
      if c then
        fs:SetTextColor(c.r, c.g, c.b)
      else
        local r,g,b = 1,1,1
        if q == 2 then r,g,b = 0.12, 1.00, 0.00
        elseif q == 3 then r,g,b = 0.00, 0.44, 0.87
        elseif q == 4 then r,g,b = 0.64, 0.21, 0.93 end
        fs:SetTextColor(r,g,b)
      end
    end
    local _, fs2 = makeCheck(y - 424, "筛选：精良(2)",
      function() return (DboxDB.config.qualityFilter and DboxDB.config.qualityFilter[2]) end,
      function(val) DboxDB.config.qualityFilter[2] = not not val end)
    setQualityColor(fs2, 2)
    local _, fs3 = makeCheck(y - 454, "筛选：稀有(3)",
      function() return (DboxDB.config.qualityFilter and DboxDB.config.qualityFilter[3]) end,
      function(val) DboxDB.config.qualityFilter[3] = not not val end)
    setQualityColor(fs3, 3)
    local _, fs4 = makeCheck(y - 484, "筛选：史诗(4)",
      function() return (DboxDB.config.qualityFilter and DboxDB.config.qualityFilter[4]) end,
      function(val) DboxDB.config.qualityFilter[4] = not not val end)
    setQualityColor(fs4, 4)
    makeCheck(y - 514, "连续分解模式（预留）", function() return DboxDB.config.autoDeLoop end,
      function(val) DboxDB.config.autoDeLoop = not not val end)
    makeSlider(y - 564, "标题栏字号", 8, 18, 1,
      function() return (DboxDB.config.fontTitleSize or 14) end,
      function(v)
        DboxDB.config.fontTitleSize = math.floor(v + 0.5)
        ApplyFontSizes()
      end)
    makeSlider(y - 614, "容器标题字号", 8, 18, 1,
      function() return (DboxDB.config.fontContainerTitleSize or 12) end,
      function(v)
        DboxDB.config.fontContainerTitleSize = math.floor(v + 0.5)
        ApplyFontSizes()
      end)
    makeSlider(y - 664, "按钮文字字号", 8, 18, 1,
      function() return (DboxDB.config.fontButtonSize or 12) end,
      function(v)
        DboxDB.config.fontButtonSize = math.floor(v + 0.5)
        ApplyFontSizes()
      end)
    makeSlider(y - 714, "内容文字字号", 8, 18, 1,
      function() return (DboxDB.config.fontContentSize or 12) end,
      function(v)
        DboxDB.config.fontContentSize = math.floor(v + 0.5)
        ApplyFontSizes()
      end)
    if DboxDB and DboxDB.config and DboxDB.config.lockAllSettings then
      setControlsEnabled(false)
    end
    content:SetHeight(760)
    ui.SetupFrame:Show()
  end
end

_G.EnsureHelpFrame = Panels_EnsureHelpFrame
_G.EnsureSetupFrame = Panels_EnsureSetupFrame
