local ui = _G.ui or {}
_G.ui = ui

local function GetState()
  return _G.DboxState
end

local function ResetSavedData()
  local state = GetState()

  DboxDB = {}
  DboxDB.version = 1
  DboxDB.FilterList = {}
  DboxDB.config = {
    debug = false,
    alphaMain = 0.3,
    alphaPanel = 0.2,
    titleBarHeight = 20,
    qualityFilter = { [2] = true, [3] = true, [4] = true },
    autoDeLoop = false,
    buttonBarYOffset = 2,
  }

  if state then
    state.list1, state.list2, state.list3, state.list4, state.selected = {}, {}, {}, {}, {}
  end

  if ui.RenderList1 then ui.RenderList1() end
  if ui.RenderList2 then ui.RenderList2() end
  if ui.RenderList3 then ui.RenderList3() end
  if ui.RenderList4 then ui.RenderList4() end
  if UpdateInfoBarCounters then UpdateInfoBarCounters() end
  if ApplyThemeAlpha then ApplyThemeAlpha() end
end

local function EnsureDBDefaults(build)
  if type(DboxDB) ~= "table" then DboxDB = {} end
  if type(DboxDB.config) ~= "table" then DboxDB.config = {} end
  if type(DboxDB.FilterList) ~= "table" then DboxDB.FilterList = {} end
  if DboxDB.version == nil then DboxDB.version = 1 end
  if DboxDB.config.debug == nil then DboxDB.config.debug = false end
  if DboxDB.config.alphaMain == nil then DboxDB.config.alphaMain = 0.3 end
  if DboxDB.config.alphaPanel == nil then DboxDB.config.alphaPanel = 0.2 end
  if DboxDB.config.titleBarHeight == nil then DboxDB.config.titleBarHeight = (DboxDefaults and DboxDefaults.titleBarHeight) or 26 end
  if DboxDB.config.fontTitleSize == nil then DboxDB.config.fontTitleSize = (DboxDefaults and DboxDefaults.fontTitleSize) or 14 end
  if DboxDB.config.fontContainerTitleSize == nil then DboxDB.config.fontContainerTitleSize = (DboxDefaults and DboxDefaults.fontContainerTitleSize) or 14 end
  if DboxDB.config.fontButtonSize == nil then DboxDB.config.fontButtonSize = (DboxDefaults and DboxDefaults.fontButtonSize) or 14 end
  if DboxDB.config.fontContentSize == nil then DboxDB.config.fontContentSize = (DboxDefaults and DboxDefaults.fontContentSize) or 14 end
  if DboxDB.config.containerWidth == nil then DboxDB.config.containerWidth = (DboxDefaults and DboxDefaults.containerWidth) or 180 end
  if DboxDB.config.containerHeight == nil then DboxDB.config.containerHeight = (DboxDefaults and DboxDefaults.containerHeight) or 260 end
  if DboxDB.config.mainWidth == nil then DboxDB.config.mainWidth = (DboxDefaults and DboxDefaults.mainWidth) or 820 end
  if DboxDB.config.mainHeight == nil then DboxDB.config.mainHeight = (DboxDefaults and DboxDefaults.mainHeight) or 310 end
  if DboxDB.config.alphaMain and DboxDB.config.alphaMain > 0.9 then DboxDB.config.alphaMain = 0.3 end
  if DboxDB.config.alphaPanel and DboxDB.config.alphaPanel > 0.9 then DboxDB.config.alphaPanel = 0.2 end
  if type(DboxDB.config.qualityFilter) ~= "table" then
    DboxDB.config.qualityFilter = (DboxDefaults and DboxDefaults.qualityFilter) or { [2] = true, [3] = true, [4] = false }
  end
  if DboxDB.config.autoDeLoop == nil then DboxDB.config.autoDeLoop = false end
  if DboxDB.config.buttonBarYOffset == nil then DboxDB.config.buttonBarYOffset = 2 end
  if DboxDB.config.autoLootDe == nil then DboxDB.config.autoLootDe = true end

  if type(DboxDB.modes) ~= "table" then DboxDB.modes = {} end
  if type(DboxDB.modes.normal) ~= "table" then
    DboxDB.modes.normal = {
      containerWidth = (DboxDefaults and DboxDefaults.containerWidth) or 180,
      containerHeight = (DboxDefaults and DboxDefaults.containerHeight) or 260,
      mainWidth = (DboxDefaults and DboxDefaults.mainWidth) or 820,
      mainHeight = (DboxDefaults and DboxDefaults.mainHeight) or 310,
      titleBarHeight = (DboxDefaults and DboxDefaults.titleBarHeight) or 26,
    }
  end
  if type(DboxDB.modes.mini) ~= "table" then
    DboxDB.modes.mini = {
      containerWidth = (DboxDefaults and DboxDefaults.containerWidth) or 180,
      containerHeight = (DboxDefaults and DboxDefaults.containerHeight) or 260,
      mainWidth = 290,
      mainHeight = (DboxDefaults and DboxDefaults.mainHeight) or 310,
      titleBarHeight = (DboxDefaults and DboxDefaults.titleBarHeight) or 26,
    }
  end

  DboxDB.lastBuild = build
end

if StaticPopupDialogs and not StaticPopupDialogs["DBOX_RESET_CONFIRM"] then
  StaticPopupDialogs["DBOX_RESET_CONFIRM"] = {
    text = "将要重置WTF存储档数据，是否确认？",
    button1 = "是",
    button2 = "否",
    OnAccept = function(self)
      if self and self.Hide then self:Hide() end
      ResetSavedData()
      if StaticPopup_Hide then StaticPopup_Hide("DBOX_RESET_CONFIRM") end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }
end

_G.ResetSavedData = ResetSavedData
_G.EnsureDBDefaults = EnsureDBDefaults