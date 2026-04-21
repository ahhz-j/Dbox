-- 文件：dbox.lua（Dbox 插件主入口）
local ADDON_NAME = ...
local DBOX_VERSION = "1.2.1"
local DBOX_BUILD = 10420
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
eventFrame:RegisterEvent("SPELL_UPDATE_USABLE")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("PLAYER_STARTED_MOVING")
eventFrame:RegisterEvent("PLAYER_STOPPED_MOVING")
eventFrame:RegisterEvent("SKILL_LINES_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("LOOT_OPENED")
eventFrame:RegisterEvent("LOOT_READY")
eventFrame:RegisterEvent("LOOT_CLOSED")
eventFrame:RegisterEvent("LOOT_SLOT_CLEARED")

-- 功能：去除字符串首尾空白（创建：b0001；修改：b0009 补注释）
local function trim(s)
  if not s then return "" end
  return s:match("^%s*(.-)%s*$")
end

local function RegisterFrameForEscape(frameName)
  if type(frameName) ~= "string" or frameName == "" then return end
  if type(UISpecialFrames) ~= "table" then UISpecialFrames = {} end
  for _, name in ipairs(UISpecialFrames) do
    if name == frameName then return end
  end
  table.insert(UISpecialFrames, frameName)
end

-- 运行期 UI/状态容器（创建：b0003 ui；b0005 state 列表；修改：b0009 补注释）
local ui = _G.ui or {}
_G.ui = ui
local state = _G.DboxState or { list1 = {}, list2 = {}, list3 = {}, list4 = {}, selected = {} }
_G.DboxState = state
local pendingDE = nil
local lastDeAt = 0
local deThrottle = 0.6
local deJustSucceeded = false
local suppressLootFrame = false

-- 迷你模式相关变量
_G.isMiniMode = _G.isMiniMode or false
_G.savedInterfaceState = _G.savedInterfaceState or {}

-- 模块：分解能力识别
-- 功能：获取“分解”法术的本地化名称（用于宏与事件比对）
local function GetDEName()
  local n = GetSpellInfo and GetSpellInfo(13262)
  return n or "分解"
end

-- 功能：检测玩家是否具备“分解”能力（支持法术ID与已知法术）
local function HasDE()
  if IsPlayerSpell and IsPlayerSpell(13262) then return true end
  if IsSpellKnown and IsSpellKnown(13262) then return true end
  local n = GetDEName()
  return n ~= nil
end

-- 功能：根据当前状态刷新“执行分解”按钮可用性
local function RefreshDeButton()
  if not ui.BtnDe then return end
  local enable = true
  if not state.list2 or #state.list2 == 0 then enable = false end
  if not HasDE() then enable = false end
  if UnitAffectingCombat and UnitAffectingCombat("player") then enable = false end
  if UnitCastingInfo and UnitCastingInfo("player") then enable = false end
  if UnitChannelInfo and UnitChannelInfo("player") then enable = false end
  if enable then
    ui.BtnDe:SetAlpha(1.0)
  else
    ui.BtnDe:SetAlpha(0.5)
  end
end

-- 通用 UI 工具、样式与附魔提示已拆分到 ui.lua。

-- 列表、扫描、布局、UI 工具与配置逻辑已拆分到独立模块。

local function EnsureMainUI()
  if ui.MainFrame then return end
  local aMain = (DboxDB and DboxDB.config and DboxDB.config.alphaMain) or 0.3
  local aPanel = (DboxDB and DboxDB.config and DboxDB.config.alphaPanel) or 0.2

  -- 模块：主界面与控件创建
  -- 功能：搭建主框体、标题栏、左侧菜单与四个容器区，以及信息栏与批量按钮
  ui.MainFrame = CreateFrame("Frame", "MainFrame", UIParent)
  RegisterFrameForEscape("MainFrame")
  local mw = (DboxDB and DboxDB.config and DboxDB.config.mainWidth) or 820
  local mh = (DboxDB and DboxDB.config and DboxDB.config.mainHeight) or 370
  ui.MainFrame:SetSize(mw, mh) -- 主界面宽/高读取配置（b0014）
  ui.MainFrame:SetPoint("CENTER")
  ui.MainFrame:SetMovable(true)
  ui.MainFrame:EnableMouse(true)
  ui.MainFrame:RegisterForDrag("LeftButton")
  ui.MainFrame:SetScript("OnDragStart", function(f) f:StartMoving() end)
  ui.MainFrame:SetScript("OnDragStop", function(f) f:StopMovingOrSizing() end)
  ui.MainFrame:SetScript("OnHide", function()
    if ui.SetupFrame and ui.SetupFrame:IsShown() then ui.SetupFrame:Hide() end
    if ui.HelpFrame and ui.HelpFrame:IsShown() then ui.HelpFrame:Hide() end
  end)
  CreatePanelBG(ui.MainFrame, aMain)
  CreateKeyLabel(ui.MainFrame, "MainFrame")

  ui.TitleBar = CreateFrame("Frame", "TitleBar", ui.MainFrame)
  ui.TitleBar:SetPoint("TOPLEFT")
  ui.TitleBar:SetPoint("TOPRIGHT")
  ui.TitleBar:SetHeight((DboxDB and DboxDB.config and DboxDB.config.titleBarHeight) or 20)
  CreatePanelBG(ui.TitleBar, 0)
  CreateKeyLabel(ui.TitleBar, "TitleBar")

  local titleFS = {
    {name="DboxTitle", template="GameFontNormal", point={"LEFT", 8, 0}, text=((DboxText and DboxText.title) or "ahhz's Dbox")},
    {name="DboxVer",   template="GameFontNormalSmall", point={"LEFT", "DboxTitle", "RIGHT", 8, 0}, text=("V"..DBOX_VERSION.."B"..DBOX_BUILD)},
  }
  for _, t in ipairs(titleFS) do
    local fs = ui.TitleBar:CreateFontString(t.name, "OVERLAY", t.template)
    if type(t.point[2])=="string" then
      fs:SetPoint(t.point[1], _G[t.point[2]], t.point[3], t.point[4], t.point[5])
    else
      fs:SetPoint(t.point[1], t.point[2], t.point[3])
    end
    fs:SetText(t.text)
    ui[t.name] = fs
    CreateKeyLabel(fs, t.name)
  end

  ui.BtnHelp = CreateFrame("Button", "BtnHelp", ui.TitleBar, "UIPanelButtonTemplate")
  ui.BtnHelp:SetSize(40, 18)
  ui.BtnHelp:SetPoint("RIGHT", -72, 0)
  ui.BtnHelp:SetText((DboxText and DboxText.btnHelp) or "帮助")
  ui.BtnHelp:SetScript("OnClick", function()
    if ui.HelpFrame and ui.HelpFrame:IsShown() then
      ui.HelpFrame:Hide()
    else
      if ui.SetupFrame and ui.SetupFrame:IsShown() then ui.SetupFrame:Hide() end
      if EnsureHelpFrame then EnsureHelpFrame() end
    end
  end)
  CreateKeyLabel(ui.BtnHelp, "BtnHelp")

  ui.BtnClose = CreateFrame("Button", "BtnClose", ui.TitleBar, "UIPanelButtonTemplate")
  ui.BtnClose:SetSize(40, 18)
  ui.BtnClose:SetPoint("RIGHT", -8, 0)
  ui.BtnClose:SetText((DboxText and DboxText.btnClose) or "关闭")
  ui.BtnClose:SetScript("OnClick", function()
    if ui.SetupFrame and ui.SetupFrame:IsShown() then ui.SetupFrame:Hide() end
    if ui.HelpFrame and ui.HelpFrame:IsShown() then ui.HelpFrame:Hide() end
    ui.MainFrame:Hide()
  end)
  CreateKeyLabel(ui.BtnClose, "BtnClose")
  if ui.BtnHelp and ui.BtnClose then
    ui.BtnHelp:ClearAllPoints()
    ui.BtnHelp:SetPoint("RIGHT", ui.BtnClose, "LEFT", -6, 0)
  end

  ui.LeftMenu = CreateFrame("Frame", "LeftMenu", ui.MainFrame)
  ui.LeftMenu:SetPoint("TOPLEFT", ui.TitleBar, "BOTTOMLEFT", 0, 0)
  ui.LeftMenu:SetPoint("BOTTOMLEFT", 0, 20)
  ui.LeftMenu:SetWidth(100)
  CreatePanelBG(ui.LeftMenu, aPanel)
  CreateKeyLabel(ui.LeftMenu, "LeftMenu")

  local function CreateMenuBtn(name, relTo, dx, dy, text, onClick)
    local b = CreateFrame("Button", name, ui.LeftMenu, "UIPanelButtonTemplate")
    b:SetSize(75, 30)
    if relTo == ui.LeftMenu then
      b:SetPoint("TOPLEFT", ui.LeftMenu, "TOPLEFT", dx, dy)
    else
      b:SetPoint("TOPLEFT", relTo, "BOTTOMLEFT", dx, dy)
    end
    b:SetText(text)
    if onClick then b:SetScript("OnClick", onClick) end
    CreateKeyLabel(b, name)
    return b
  end

  ui.BtnScan = CreateMenuBtn("BtnScan", ui.LeftMenu, 12, -12, (DboxText and DboxText.btnScan) or "扫描",
    function() ScanBagsForDisenchantables() end)
  ui.BtnDebug = CreateMenuBtn("BtnDebug", ui.BtnScan, 0, -8, (DboxText and DboxText.btnDebug) or "Debug",
    function()
      if type(DboxDB) ~= "table" then DboxDB = {} end
      if type(DboxDB.config) ~= "table" then DboxDB.config = {} end
      DboxDB.config.debug = not not (not DboxDB.config.debug)
      UpdateDebugLabels()
    end)

  ui.BtnSetting = CreateMenuBtn("BtnSetting", ui.BtnDebug, 0, -8, (DboxText and DboxText.btnSetting) or "设置",
    function()
      _G.isMiniMode = isMiniMode
      if EnsureMainUI then EnsureMainUI() end
      if EnsureSetupFrame then EnsureSetupFrame() end
    end)
  

  -- Reset 按钮（清除持久化数据）
  ui.BtnReset = CreateFrame("Button", "BtnReset", ui.LeftMenu, "UIPanelButtonTemplate")
  ui.BtnReset:SetSize(75, 30)
  ui.BtnReset:SetPoint("TOPLEFT", ui.BtnSetting, "BOTTOMLEFT", 0, -8)
  ui.BtnReset:SetText((DboxText and DboxText.btnReset) or "Reset")
  ui.BtnReset:SetScript("OnClick", function()
    if StaticPopup_Show then StaticPopup_Show("DBOX_RESET_CONFIRM") end
  end)
  CreateKeyLabel(ui.BtnReset, "BtnReset")

  ui.ContainerArea = CreateFrame("Frame", nil, ui.MainFrame)
  ui.ContainerArea:SetPoint("TOPLEFT", ui.LeftMenu, "TOPRIGHT", 4, 0)
  ui.ContainerArea:SetPoint("BOTTOMRIGHT", -4, 20)
  CreatePanelBG(ui.ContainerArea, 0)

  ui.List1Frame = CreateFrame("Frame", "List1Frame", ui.ContainerArea)
  ui.List1Frame:SetPoint("TOPLEFT")
  ui.List1Frame:SetSize(150, 190)
  CreatePanelBG(ui.List1Frame, aPanel)
  CreateKeyLabel(ui.List1Frame, "List1Frame")

  ui.List2Frame = CreateFrame("Frame", "List2Frame", ui.ContainerArea)
  ui.List2Frame:SetPoint("TOPLEFT", ui.List1Frame, "TOPRIGHT", 6, 0)
  ui.List2Frame:SetSize(150, 190)
  CreatePanelBG(ui.List2Frame, aPanel)
  CreateKeyLabel(ui.List2Frame, "List2Frame")

  ui.List3Frame = CreateFrame("Frame", "List3Frame", ui.ContainerArea)
  ui.List3Frame:SetPoint("TOPLEFT", ui.List2Frame, "TOPRIGHT", 6, 0)
  ui.List3Frame:SetSize(150, 190)
  CreatePanelBG(ui.List3Frame, aPanel)
  CreateKeyLabel(ui.List3Frame, "List3Frame")

  ui.List4Frame = CreateFrame("Frame", "List4Frame", ui.ContainerArea)
  ui.List4Frame:SetPoint("TOPLEFT", ui.List3Frame, "TOPRIGHT", 6, 0)
  ui.List4Frame:SetSize(150, 190)
  CreatePanelBG(ui.List4Frame, aPanel)
  CreateKeyLabel(ui.List4Frame, "List4Frame")

  -- 容器标题：白色；“排除”更名为“待排除”（b0012）
  CreateListUI(ui.List1Frame, 1, "可分解")
  CreateListUI(ui.List2Frame, 2, "待分解")
  CreateListUI(ui.List3Frame, 3, "待排除")
  CreateListUI(ui.List4Frame, 4, "已排除")

  local function CreateFlatBtn(parent, name, text, pointSpec, onClick)
    local btn = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    btn:SetSize(75, 30)
    if pointSpec.prev then
      btn:SetPoint("BOTTOMLEFT", pointSpec.prev, "BOTTOMRIGHT", 8, 0)
    else
      btn:SetPoint("BOTTOMLEFT", 8, 4)
    end
    btn:SetText(text)
    if onClick then btn:SetScript("OnClick", onClick) end
    CreateKeyLabel(btn, name)
    return btn
  end

  do
    local b1 = CreateFlatBtn(ui.List1Frame, "BtnAdd2List",
      (DboxText and DboxText.btnAddAll) or "全部添加",
      {}, function()
        TransferAll(1, 2)
        ui.RenderList1()
        ui.RenderList2()
        UpdateInfoBarCounters()
      end)
    ui.BtnAdd2List = b1
    ui.BtnClearList1 = CreateFlatBtn(ui.List1Frame, "BtnClearList1",
      (DboxText and DboxText.btnClearAll) or "全部清除",
      {prev = b1}, function()
        ClearList(1)
        ui.RenderList1()
        UpdateInfoBarCounters()
      end)
  end

  ui.BtnClearList2 = CreateFlatBtn(ui.List2Frame, "BtnClearList2",
    (DboxText and DboxText.btnClearAll) or "全部清除",
    {}, function()
      ClearList(2)
      ui.RenderList2()
      UpdateInfoBarCounters()
    end)

  -- 模块：分解执行按钮与宏生成
  -- 功能：逐件分解“待分解”队列中的条目，事件驱动成功/失败回滚
  ui.BtnDe = CreateFrame("Button", "BtnDe", ui.List2Frame, "UIPanelButtonTemplate,SecureActionButtonTemplate")
  ui.BtnDe:SetSize(75, 30)
  ui.BtnDe:SetPoint("BOTTOMLEFT", ui.BtnClearList2, "BOTTOMRIGHT", 8, 0)
  ui.BtnDe:SetText((DboxText and DboxText.btnDe) or "执行分解")
  CreateKeyLabel(ui.BtnDe, "BtnDe")
  ui.BtnDe:RegisterForClicks("AnyUp")
  ui.BtnDe:SetAttribute("type", "macro")
  ui.BtnDe:SetAttribute("useOnKeyDown", false)
  ui.BtnDe:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local reasons = {}
    local enable = true
    if not HasDE or not HasDE() then enable = false; table.insert(reasons, "未学会“分解”") end
    if UnitAffectingCombat and UnitAffectingCombat("player") then enable = false; table.insert(reasons, "战斗中") end
    if UnitCastingInfo and UnitCastingInfo("player") then enable = false; table.insert(reasons, "正在施法") end
    if UnitChannelInfo and UnitChannelInfo("player") then enable = false; table.insert(reasons, "正在引导") end
    local freeSlots = 0
    if C_Container and C_Container.GetContainerNumFreeSlots then
      local maxBags = NUM_BAG_SLOTS or 4
      for bag = 0, maxBags do freeSlots = freeSlots + (C_Container.GetContainerNumFreeSlots(bag) or 0) end
    elseif GetContainerNumFreeSlots then
      for bag = 0, 4 do local n = GetContainerNumFreeSlots(bag); if type(n)=="number" then freeSlots = freeSlots + n end end
    end
    if freeSlots <= 1 then enable = false; table.insert(reasons, "背包空格不足 (>1)") end
    if not state.list2 or #state.list2 == 0 then enable = false; table.insert(reasons, "待分解为空") end
    if enable then
      GameTooltip:SetText("执行分解：准备就绪")
    else
      GameTooltip:SetText("执行分解不可用：\n- " .. table.concat(reasons, "\n- "))
    end
    GameTooltip:Show()
  end)
  ui.BtnDe:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  ui.BtnDe:SetScript("PreClick", function(self)
    if pendingDE then
      self:SetAttribute("macrotext", "")
      return
    end
    if not HasDE() then
      -- removed print
      self:SetAttribute("macrotext", "")
      return
    end
    if UnitAffectingCombat and UnitAffectingCombat("player") then
      -- removed print
      self:SetAttribute("macrotext", "")
      return
    end
    local freeSlots = 0
    if C_Container and C_Container.GetContainerNumFreeSlots then
      local maxBags = NUM_BAG_SLOTS or 4
      for bag = 0, maxBags do freeSlots = freeSlots + (C_Container.GetContainerNumFreeSlots(bag) or 0) end
    elseif GetContainerNumFreeSlots then
      for bag = 0, 4 do local n = GetContainerNumFreeSlots(bag); if type(n)=="number" then freeSlots = freeSlots + n end end
    end
    if freeSlots <= 1 then
      -- removed print
      self:SetAttribute("macrotext", "")
      return
    end
    if (GetTime and (GetTime() - lastDeAt) < deThrottle) then
      self:SetAttribute("macrotext", "")
      return
    end
    if UnitCastingInfo and UnitCastingInfo("player") then
      self:SetAttribute("macrotext", "")
      return
    end
    if UnitChannelInfo and UnitChannelInfo("player") then
      self:SetAttribute("macrotext", "")
      return
    end
    local it = state.list2 and state.list2[1]
    if not it then
      self:SetAttribute("macrotext", "")
      return
    end
    table.remove(state.list2, 1)
    pendingDE = it
    if ui.RenderList2 then ui.RenderList2() end
    UpdateInfoBarCounters()
    local id = it.key or (it.itemLink and tonumber(string.match(it.itemLink, "item:(%d+):")))
    local name = nil
    if id then name = select(1, GetItemInfo(id)) end
    if not name and it.itemLink then name = it.itemLink:match("%[(.-)%]") end
    local useToken = id and ("item:" .. tostring(id)) or name
    local castName = GetDEName()
    if useToken then
      self:SetAttribute("macrotext", "/cast " .. (castName or "分解") .. "\n/use " .. useToken)
      lastDeAt = GetTime and GetTime() or 0
    else
      table.insert(state.list2, 1, it)
      pendingDE = nil
      if ui.RenderList2 then ui.RenderList2() end
      UpdateInfoBarCounters()
      self:SetAttribute("macrotext", "")
    end
  end)
  ui.BtnDe:HookScript("OnShow", RefreshDeButton)

  do
    local b1 = CreateFlatBtn(ui.List3Frame, "BtnAdd2DB",
      (DboxText and DboxText.btnAdd2DB) or "全部写入",
      {}, function()
        local n = WriteFilterListToDB()
        state.list3 = {}
        ui.RenderList3()
        ReadFilterListFromDB()
        UpdateInfoBarCounters()
      end)
    ui.BtnAdd2DB = b1
    ui.BtnClearList3 = CreateFlatBtn(ui.List3Frame, "BtnClearList3",
      (DboxText and DboxText.btnClearAll) or "全部清除",
      {prev = b1}, function()
        TransferAll(3, 2)
        if ui.RenderList3 then ui.RenderList3() end
        if ui.RenderList2 then ui.RenderList2() end
        UpdateInfoBarCounters()
      end)
  end

  do
    local b1 = CreateFlatBtn(ui.List4Frame, "BtnReadDBList",
      (DboxText and DboxText.btnReadDB) or "读取表单",
      {}, function()
        ReadFilterListFromDB()
      end)
    ui.BtnReadDBList = b1
    ui.BtnClearDBList = CreateFlatBtn(ui.List4Frame, "BtnClearDBList",
      (DboxText and DboxText.btnClearDB) or "清除表单",
      {prev = b1}, function()
        ClearDBFilterList()
      end)
  end

  ui.DboxInfo = CreateFrame("Frame", "DboxInfo", ui.MainFrame)
  ui.DboxInfo:SetPoint("BOTTOMLEFT")
  ui.DboxInfo:SetPoint("BOTTOMRIGHT")
  ui.DboxInfo:SetHeight(20)
  CreatePanelBG(ui.DboxInfo, 0)
  CreateKeyLabel(ui.DboxInfo, "DboxInfo")

  ui.BagFreeText = ui.DboxInfo:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ui.BagFreeText:SetPoint("LEFT", 8, 0)
  ui.BagFreeText:SetText(" 背包空格:0")
  ui.InfoText = ui.DboxInfo:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ui.InfoText:SetPoint("LEFT", ui.BagFreeText, "RIGHT", 10, 0)
  ui.InfoText:SetText(" 可分解:0 待分解:0 待排除:0 已排除:0")
  UpdateInfoBarCounters()

  -- 根据容器区宽度动态布局：普通模式横排四列，迷你模式仅布局待分解容器
  ui.ContainerArea:SetScript("OnSizeChanged", function()
    if not (ui.MainFrame and ui.MainFrame:IsShown()) then return end
    if isMiniMode then
      ApplyMiniLayout()
    else
      LayoutContainersRow()
    end
  end)
  if isMiniMode then
    ApplyMiniLayout()
  else
    LayoutContainersRow()
  end

  UpdateDebugLabels()
  ApplyFontSizes()
  ui.MainFrame:Hide()

  -- 初始化迷你模式
  InitializeMiniMode()
end

_G.EnsureMainUI = EnsureMainUI

SLASH_DBOX1 = "/dbox"
-- Slash 命令分发（创建：b0001；扩展：b0002 /dbox ver；b0003 调用 EnsureMainUI；b0009 补注释）
SlashCmdList["DBOX"] = function(msg)
  local m = trim(string.lower(tostring(msg or "")))
  if m == "debug" then
    if type(DboxDB) ~= "table" then DboxDB = {} end
    if type(DboxDB.config) ~= "table" then DboxDB.config = {} end
    DboxDB.config.debug = not not (not DboxDB.config.debug)
    -- removed print
    return
  elseif m == "width" or m == "w" then
    EnsureMainUI()
    -- removed print
    return
  elseif m == "mini" or m == "minimode" then
    EnsureMainUI()
    if toggleMiniMode then toggleMiniMode() end
    return
  elseif m == "ver" or m == "version" or m == "about" then
    -- removed print
    return
  end
  EnsureMainUI()
  if ui.MainFrame:IsShown() then
    ui.MainFrame:Hide()
    if ui.SetupFrame and ui.SetupFrame:IsShown() then ui.SetupFrame:Hide() end
    if ui.HelpFrame and ui.HelpFrame:IsShown() then ui.HelpFrame:Hide() end
  else
    ui.MainFrame:Show()
  end
end

-- 事件：ADDON_LOADED 初始化 SavedVariables 与 UI（创建：b0001；扩展：b0002 SavedVariables；b0007 透明度；b0009 补注释）
eventFrame:SetScript("OnEvent", function(_, event, a, b, c, d)
  if event == "ADDON_LOADED" and a == ADDON_NAME then
    EnsureDBDefaults(DBOX_BUILD)
    EnsureMainUI()
    ApplyThemeAlpha()
    UpdateDebugLabels()
    RefreshDeButton()
    return
  end
  if event == "PLAYER_LOGOUT" then
    SaveMiniModeState()
    return
  end
  if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
    RefreshDeButton()
    return
  end
  if event == "SKILL_LINES_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
    UpdateInfoBarCounters()
    return
  end
  if event == "CURRENT_SPELL_CAST_CHANGED" or event == "SPELL_UPDATE_USABLE" or event == "SPELLS_CHANGED" or event == "PLAYER_STARTED_MOVING" or event == "PLAYER_STOPPED_MOVING" then
    -- 在移动/可用性变化/法术表变化时刷新按钮；若存在悬挂 pending，交给安全定时回退处理
    RefreshDeButton()
    return
  end
  -- 处理分解施法结果
  if event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
    local unit, castGUID, spellID = a, b, c
    if unit ~= "player" then return end
    local id = tonumber(spellID) or 0
    local isDE = (id == 13262)
    if not isDE and GetSpellInfo then
      local name = GetSpellInfo(id) or ""
      local deName = (GetSpellInfo(13262)) or "分解"
      if name == deName or name == "分解" then isDE = true end
    end
    if not isDE then return end
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
      pendingDE = nil
      deJustSucceeded = true
      suppressLootFrame = true
      if ui.RenderList2 then ui.RenderList2() end
      UpdateInfoBarCounters()
      RefreshDeButton()
    else
      if pendingDE then
        table.insert(state.list2, 1, pendingDE)
        pendingDE = nil
        if ui.RenderList2 then ui.RenderList2() end
        UpdateInfoBarCounters()
        RefreshDeButton()
      end
    end
  end
  if event == "LOOT_OPENED" then
    if DboxDB and DboxDB.config and DboxDB.config.autoLootDe and deJustSucceeded then
      if LootFrame and LootFrame.Hide then LootFrame:Hide() end
      local n = (GetNumLootItems and GetNumLootItems()) or 0
      for i=1,n do
        if LootSlot then LootSlot(i) end
        if ConfirmLootSlot then ConfirmLootSlot(i) end
      end
      if CloseLoot then CloseLoot() end
      deJustSucceeded = false
      suppressLootFrame = false
      return
    end
  end
  if event == "LOOT_READY" then
    if DboxDB and DboxDB.config and DboxDB.config.autoLootDe and deJustSucceeded then
      local n = (GetNumLootItems and GetNumLootItems()) or 0
      for i=1,n do
        if LootSlot then LootSlot(i) end
        if ConfirmLootSlot then ConfirmLootSlot(i) end
      end
      if CloseLoot then CloseLoot() end
      deJustSucceeded = false
      suppressLootFrame = false
      return
    end
  end
  if event == "LOOT_SLOT_CLEARED" then
    if DboxDB and DboxDB.config and DboxDB.config.autoLootDe and suppressLootFrame then
      if LootFrame and LootFrame.Hide then LootFrame:Hide() end
    end
  end
  if event == "LOOT_CLOSED" then
    deJustSucceeded = false
    suppressLootFrame = false
  end
end)
