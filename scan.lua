local ui = _G.ui or {}
_G.ui = ui

local function GetState()
  return _G.DboxState
end

local function EnsureQualityFilter()
  if type(DboxDB) ~= "table" then DboxDB = {} end
  if type(DboxDB.config) ~= "table" then DboxDB.config = {} end
  if type(DboxDB.config.qualityFilter) ~= "table" then
    DboxDB.config.qualityFilter = { [2] = true, [3] = true, [4] = true }
  else
    if DboxDB.config.qualityFilter[2] == nil then DboxDB.config.qualityFilter[2] = true end
    if DboxDB.config.qualityFilter[3] == nil then DboxDB.config.qualityFilter[3] = true end
    if DboxDB.config.qualityFilter[4] == nil then DboxDB.config.qualityFilter[4] = true end
  end
end

local function BuildFilterSet()
  local set = {}
  if type(DboxDB) ~= "table" or type(DboxDB.FilterList) ~= "table" then return set end
  for _, s in ipairs(DboxDB.FilterList) do
    if type(s) == "string" then
      local id = tonumber(string.match(s, "^(%d+),"))
      if id then set[id] = true end
    end
  end
  return set
end

local function WriteFilterListToDB()
  local state = GetState()
  if not state then return 0 end

  if type(DboxDB) ~= "table" then DboxDB = {} end
  if type(DboxDB.FilterList) ~= "table" then DboxDB.FilterList = {} end
  local existing = BuildFilterSet()
  local appended = 0

  for _, item in ipairs(state.list3) do
    local id = item.key or tonumber(string.match(item.itemLink or "", "item:(%d+):"))
    if id and not existing[id] then
      local name, _, quality = GetItemInfo(item.itemLink or id)
      name = name or item.itemLink or tostring(id)
      quality = quality or item.quality or 0
      table.insert(DboxDB.FilterList, string.format("%d,%s,%d", id, name, quality))
      existing[id] = true
      appended = appended + 1
    end
  end

  return appended
end

local function ReadFilterListFromDB()
  local state = GetState()
  if not state then return 0 end

  state.list4 = {}
  if type(DboxDB) ~= "table" or type(DboxDB.FilterList) ~= "table" then
    if ui.RenderList4 then ui.RenderList4() end
    if UpdateInfoBarCounters then UpdateInfoBarCounters() end
    return 0
  end

  local count = 0
  for _, s in ipairs(DboxDB.FilterList) do
    if type(s) == "string" then
      local id, name, quality = string.match(s, "^(%d+),([^,]*),(%d+)$")
      id = tonumber(id)
      quality = tonumber(quality)
      if id then
        local link = select(2, GetItemInfo(id))
        local ilvl = select(4, GetItemInfo(id))
        table.insert(state.list4, {
          key = id,
          itemLink = link or name or tostring(id),
          quality = quality or 0,
          itemLevel = ilvl or 0,
        })
        count = count + 1
      end
    end
  end

  if ui.RenderList4 then ui.RenderList4() end
  if UpdateInfoBarCounters then UpdateInfoBarCounters() end
  return count
end

local function ClearDBFilterList()
  local state = GetState()
  if not state then return end

  if type(DboxDB) ~= "table" then DboxDB = {} end
  DboxDB.FilterList = {}
  state.list4 = {}
  if ui.RenderList4 then ui.RenderList4() end
  if UpdateInfoBarCounters then UpdateInfoBarCounters() end
end

local function AddToList1(item)
  local state = GetState()
  if not state then return end
  table.insert(state.list1, item)
end

local function ClearList1()
  local state = GetState()
  if not state then return end
  for i = #state.list1, 1, -1 do table.remove(state.list1, i) end
  state.selected[1] = nil
end

local function ScanBagsForDisenchantables()
  EnsureQualityFilter()
  ClearList1()
  local filterSet = BuildFilterSet()
  local WEAPON_NAME = (GetItemClassInfo and GetItemClassInfo(2)) or "Weapon"
  local ARMOR_NAME = (GetItemClassInfo and GetItemClassInfo(4)) or "Armor"

  local function accept(quality, itemTypeName, classID, link)
    if not quality then return false end
    if quality < 2 or quality > 4 then return false end
    if not (DboxDB.config and DboxDB.config.qualityFilter and DboxDB.config.qualityFilter[quality]) then return false end
    if classID then
      return (classID == 2 or classID == 4)
    end
    if itemTypeName and (itemTypeName == WEAPON_NAME or itemTypeName == ARMOR_NAME) then
      return true
    end
    if IsEquippableItem and link then
      return IsEquippableItem(link)
    end
    return false
  end

  local function push(link, bag, slot, qfallback, iconOverride)
    if not link then return end
    local itemID = tonumber(string.match(link, "item:(%d+):"))
    if not itemID then
      local id2 = select(2, GetItemInfoInstant(link))
      itemID = id2 or itemID
    end
    if itemID and filterSet[itemID] then return end

    local name, _, quality, ilvl, itemTypeName, _, _, _, _, icon = GetItemInfo(link)
    if (not quality) and qfallback then quality = qfallback end
    if not quality and GetContainerItemInfo then
      local info = GetContainerItemInfo(bag, slot)
      if type(info) == "table" then
        quality = info.quality or quality
        if not icon and info.iconFileID then icon = info.iconFileID end
      else
        local _, _, _, q = GetContainerItemInfo(bag, slot)
        quality = quality or q
      end
    end
    if not icon and iconOverride then icon = iconOverride end

    local classID = select(12, GetItemInfo(link))
    if accept(quality, itemTypeName, classID, link) then
      if not itemID then return end
      AddToList1({
        key = itemID,
        itemLink = link or name or tostring(itemID),
        icon = icon,
        quality = quality,
        itemLevel = ilvl,
        bag = bag,
        slot = slot,
      })
    end
  end

  if C_Container and C_Container.GetContainerNumSlots then
    local maxBags = NUM_BAG_SLOTS or 4
    for bag = 0, maxBags do
      local slots = C_Container.GetContainerNumSlots(bag) or 0
      for slot = 1, slots do
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info and info.hyperlink then
          push(info.hyperlink, bag, slot, info.quality, info.iconFileID)
        end
      end
    end
  else
    for bag = 0, 4 do
      local slots = GetContainerNumSlots and GetContainerNumSlots(bag)
      if slots and slots > 0 then
        for slot = 1, slots do
          local link = GetContainerItemLink and GetContainerItemLink(bag, slot)
          if link then
            local texQ, texIcon = nil, nil
            if GetContainerItemInfo then
              local info = GetContainerItemInfo(bag, slot)
              if type(info) == "table" then
                texQ = info.quality
                texIcon = info.iconFileID
              else
                local _, _, _, q = GetContainerItemInfo(bag, slot)
                texQ = q
              end
            end
            push(link, bag, slot, texQ, texIcon)
          end
        end
      end
    end
  end

  if ui.RenderList1 then ui.RenderList1() end
  if UpdateInfoBarCounters then UpdateInfoBarCounters() end
end

_G.EnsureQualityFilter = EnsureQualityFilter
_G.BuildFilterSet = BuildFilterSet
_G.WriteFilterListToDB = WriteFilterListToDB
_G.ReadFilterListFromDB = ReadFilterListFromDB
_G.ClearDBFilterList = ClearDBFilterList
_G.ScanBagsForDisenchantables = ScanBagsForDisenchantables