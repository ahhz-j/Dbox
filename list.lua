local ui = _G.ui or {}
_G.ui = ui

local function GetState()
  return _G.DboxState
end

local function UpdateInfoBarCounters()
  local state = GetState()
  if not state or not ui.DboxInfo then return end

  local function w(n) return "|cFFFFFFFF" .. tostring(n) .. "|r" end
  local a = #state.list1
  local b = #state.list2
  local c = #state.list3
  local d = #state.list4
  local freeSlots = 0

  if C_Container and C_Container.GetContainerNumFreeSlots then
    local maxBags = NUM_BAG_SLOTS or 4
    for bag = 0, maxBags do
      freeSlots = freeSlots + (C_Container.GetContainerNumFreeSlots(bag) or 0)
    end
  elseif GetContainerNumFreeSlots then
    for bag = 0, 4 do
      local free = GetContainerNumFreeSlots(bag)
      if type(free) == "number" then freeSlots = freeSlots + free end
    end
  end

  if isMiniMode then
    if ui.BagFreeText then ui.BagFreeText:Hide() end
    if ui.InfoText then
      ui.InfoText:SetText(string.format(
        " 包空:%s  可拆:%s  待拆:%s  待排:%s  已排:%s",
        w(freeSlots), w(a), w(b), w(c), w(d)
      ))
    end
  else
    if ui.BagFreeText then
      ui.BagFreeText:Show()
      ui.BagFreeText:SetText(" 背包空格:" .. w(freeSlots))
    end
    if ui.InfoText then
      ui.InfoText:SetText(" 可分解:" .. w(a) .. " 待分解:" .. w(b) .. " 待排除:" .. w(c) .. " 已排除:" .. w(d))
    end
  end
end

local function TransferItemByIndex(srcId, dstId, idx)
  local state = GetState()
  if not state then return end

  local src = state["list" .. tostring(srcId)]
  local dst = state["list" .. tostring(dstId)]
  if not src or not dst then return end

  local item = src[idx]
  if not item then return end
  table.insert(dst, item)
  table.remove(src, idx)
  state.selected[srcId] = nil
end

local function TransferAll(srcId, dstId)
  local state = GetState()
  if not state then return end

  local src = state["list" .. tostring(srcId)]
  local dst = state["list" .. tostring(dstId)]
  if not src or not dst then return end

  for i = 1, #src do
    table.insert(dst, src[i])
  end
  for i = #src, 1, -1 do
    table.remove(src, i)
  end
  state.selected[srcId] = nil
end

local function ClearList(id)
  local state = GetState()
  if not state then return end

  local list = state["list" .. tostring(id)]
  if not list then return end
  for i = #list, 1, -1 do table.remove(list, i) end
  state.selected[id] = nil
end

local function CreateRows(parent, id, count)
  local rows = {}
  local rowHeight = 20

  for i = 1, (count or 40) do
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(260, rowHeight)
    if i == 1 then
      btn:SetPoint("TOPLEFT", 5, -5)
    else
      btn:SetPoint("TOPLEFT", rows[i - 1], "BOTTOMLEFT", 0, -2)
    end

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(true)
    bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
    btn.bg = bg

    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", 6, 0)
    btn.text = text
    btn.index = i

    btn:SetScript("OnClick", function()
      local state = GetState()
      if not state then return end
      state.selected[id] = btn.index
      if ui["RenderList" .. id] then ui["RenderList" .. id]() end
    end)

    btn:SetScript("OnDoubleClick", function()
      if id == 2 then
        TransferItemByIndex(2, 3, btn.index)
        if ui.RenderList2 then ui.RenderList2() end
        if ui.RenderList3 then ui.RenderList3() end
      elseif id == 3 then
        TransferItemByIndex(3, 2, btn.index)
        if ui.RenderList3 then ui.RenderList3() end
        if ui.RenderList2 then ui.RenderList2() end
      elseif id == 4 then
        TransferItemByIndex(4, 3, btn.index)
        if ui.RenderList4 then ui.RenderList4() end
        if ui.RenderList3 then ui.RenderList3() end
      end
      UpdateInfoBarCounters()
    end)

    btn:SetScript("OnEnter", function(self)
      if self._itemLink and GameTooltip then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self._itemLink)
        GameTooltip:Show()
      end
    end)

    btn:SetScript("OnLeave", function()
      if GameTooltip then GameTooltip:Hide() end
    end)

    rows[i] = btn
  end

  return rows
end

local function CreateListUI(frame, id, listTitle)
  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", 8, -6)
  title:SetText(listTitle)
  title:SetTextColor(1, 1, 1, 1)
  ui["ListTitle" .. id] = title

  local bar = CreateFrame("Frame", nil, frame)
  bar:SetFrameStrata("LOW")
  bar:SetFrameLevel(frame:GetFrameLevel())
  local y = (DboxDB and DboxDB.config and DboxDB.config.buttonBarYOffset) or 2
  bar:SetPoint("BOTTOMLEFT", 0, y)
  bar:SetPoint("BOTTOMRIGHT", 0, y)
  local h = (DboxDB and DboxDB.config and DboxDB.config.buttonBarHeight) or 35
  bar:SetHeight(h)
  CreatePanelBG(bar, (DboxDB and DboxDB.config and DboxDB.config.alphaPanel) or 1)

  local sf = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", 4, -22)
  sf:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", -26, 2)
  local content = CreateFrame("Frame", nil, sf)
  content:SetSize(10, 10)
  sf:SetScrollChild(content)

  local rows = CreateRows(content, id, 50)
  ui["ListRows" .. id] = rows
  ui["ListBar" .. id] = bar
  ui["ListScroll" .. id] = sf
  ui["ListContent" .. id] = content
end

local function RenderListGeneric(id)
  local state = GetState()
  if not state then return end

  local rows = ui["ListRows" .. id]
  local list = state["list" .. tostring(id)]
  if not rows or not list then return end

  local rowHeight = 22
  for i = 1, #rows do
    local btn = rows[i]
    local item = list[i]
    if item then
      btn.text:SetText(item.itemLink or tostring(item.key or ""))
      btn._itemLink = item.itemLink
      if state.selected[id] == i then
        btn.bg:SetColorTexture(0.2, 0.4, 0.8, 0.6)
      else
        btn.bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
      end
      btn:Show()
    else
      btn._itemLink = nil
      btn.text:SetText("")
      btn.bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
      btn:Show()
    end
  end

  local content = ui["ListContent" .. id]
  if content then
    local height = #rows * (rowHeight + 2) + 8
    content:SetHeight(height)
  end
  if id == 2 and RefreshDeButton then RefreshDeButton() end
end

ui.RenderList1 = function() RenderListGeneric(1) end
ui.RenderList2 = function() RenderListGeneric(2) end
ui.RenderList3 = function() RenderListGeneric(3) end
ui.RenderList4 = function() RenderListGeneric(4) end

_G.UpdateInfoBarCounters = UpdateInfoBarCounters
_G.TransferItemByIndex = TransferItemByIndex
_G.TransferAll = TransferAll
_G.ClearList = ClearList
_G.CreateListUI = CreateListUI