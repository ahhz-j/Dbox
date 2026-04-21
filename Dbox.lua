local ADDON_PREFIX = "|cff57b6ffDbox|r"

local function Print(message)
  DEFAULT_CHAT_FRAME:AddMessage(string.format("%s: %s", ADDON_PREFIX, message))
end

local uncommonTable = {
  { min = 1, max = 15, dust = "Strange Dust", essence = "Lesser Magic Essence" },
  { min = 16, max = 20, dust = "Strange Dust", essence = "Greater Magic Essence" },
  { min = 21, max = 25, dust = "Soul Dust", essence = "Lesser Astral Essence" },
  { min = 26, max = 30, dust = "Soul Dust", essence = "Greater Astral Essence" },
  { min = 31, max = 35, dust = "Vision Dust", essence = "Lesser Mystic Essence" },
  { min = 36, max = 40, dust = "Vision Dust", essence = "Greater Mystic Essence" },
  { min = 41, max = 45, dust = "Dream Dust", essence = "Lesser Nether Essence" },
  { min = 46, max = 50, dust = "Dream Dust", essence = "Greater Nether Essence" },
  { min = 51, max = 55, dust = "Illusion Dust", essence = "Lesser Eternal Essence" },
  { min = 56, dust = "Illusion Dust", essence = "Greater Eternal Essence" },
}

local rareTable = {
  { min = 1, max = 20, shard = "Small Glimmering Shard" },
  { min = 21, max = 25, shard = "Large Glimmering Shard" },
  { min = 26, max = 30, shard = "Small Glowing Shard" },
  { min = 31, max = 35, shard = "Large Glowing Shard" },
  { min = 36, max = 40, shard = "Small Radiant Shard" },
  { min = 41, max = 45, shard = "Large Radiant Shard" },
  { min = 46, max = 50, shard = "Small Brilliant Shard" },
  { min = 51, shard = "Large Brilliant Shard" },
}

local function MatchRange(level, tableData)
  for _, info in ipairs(tableData) do
    if level >= info.min and (not info.max or level <= info.max) then
      return info
    end
  end
end

local function GetItemLinkFromMessage(message)
  return message and message:match("(|c%x+|Hitem:[^|]+|h%[[^%]]+%]|h|r)")
end

local function DescribeDisenchant(itemLink)
  local _, _, itemQuality, itemLevel, _, _, _, _, _, _, _, classID = GetItemInfo(itemLink)

  if not itemQuality then
    Print("Item data is not cached yet. Try again in a moment.")
    return
  end

  if classID ~= LE_ITEM_CLASS_ARMOR and classID ~= LE_ITEM_CLASS_WEAPON then
    Print("Only armor and weapons can be disenchanted in Classic.")
    return
  end

  if itemQuality == LE_ITEM_QUALITY_UNCOMMON then
    local match = MatchRange(itemLevel, uncommonTable)
    if match then
      Print(string.format("%s (iLvl %d): %s and %s", itemLink, itemLevel, match.dust, match.essence))
      return
    end
  elseif itemQuality == LE_ITEM_QUALITY_RARE then
    local match = MatchRange(itemLevel, rareTable)
    if match then
      Print(string.format("%s (iLvl %d): %s", itemLink, itemLevel, match.shard))
      return
    end
  elseif itemQuality == LE_ITEM_QUALITY_EPIC then
    if itemLevel >= 56 then
      Print(string.format("%s (iLvl %d): Nexus Crystal", itemLink, itemLevel))
    elseif itemLevel >= 51 then
      Print(string.format("%s (iLvl %d): Large Brilliant Shard", itemLink, itemLevel))
    else
      Print(string.format("%s (iLvl %d): Small Brilliant Shard", itemLink, itemLevel))
    end
    return
  end

  Print("Quality not supported. Use uncommon, rare, or epic armor/weapons.")
end

SLASH_DBOX1 = "/dbox"
SLASH_DBOX2 = "/disenchant"
SlashCmdList.DBOX = function(message)
  local itemLink = GetItemLinkFromMessage(message)
  if not itemLink then
    Print("Usage: /dbox <shift-click item link>")
    return
  end

  DescribeDisenchant(itemLink)
end
