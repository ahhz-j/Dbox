-- 初始界面与配置默认值（首次运行采用；后续以 SavedVariables 为准）
DboxDefaults = {
  containerWidth = 180,
  containerHeight = 260,
  mainWidth = 820,
  mainHeight = 310,
  titleBarHeight = 26,
  qualityFilter = { [2] = true, [3] = true, [4] = false },
  fontTitleSize = 14,
  fontContainerTitleSize = 14,
  fontButtonSize = 14,
  fontContentSize = 14,
}

-- 帮助面板文本（简版）
DboxHelpText = [[
|cFFFFFF00关于ahhz's Dbox分解助手|r
ahhz's Dbox分解助手是一个用于分解装备的轻量级独立插件，它可以帮助玩家快速、方便地分解大数量装备。
由iTank Studio Works开发制作，欢迎反馈问题和建议。
以下是我们的联系方式：


|cFFFFFF00【使用步骤】|r
1. /dbox 打开界面，点击左侧“扫描”。
2. 在“可分解”栏中点“全部添加”按钮将可分解列表内容传递给待分解栏。
3. 不想分解的条目：在“待分解”栏中双击对应装备放入“待排除”栏，在“待排除”点“全部写入”保存为排除表；可随时“读取/清除”。
4. 在“待分解”栏点击“执行分解”，将按照列表顺序逐件分解；失败会回滚到队首。

|cFFFFFF00【核心功能】|r
- 扫描：识别武器/护甲、品质≥绿，遵守排除表。
- 队列：待分解/待排除双列表，双击互转。
- 排除表：读取/写入/清除，长期生效。
- 分解：安全宏，仅在条件满足时可用。

|cFFFFFF00【迷你模式】|r
- 迷你模式：仅显示“待分解”，减少屏幕占用。

|cFFFFFF00【常用命令】|r
- /dbox：打开/关闭插件界面

附录：附魔技能等级与可分解物品的关系（诺森德）
- 325：诺森德精良装备，物品等级121-165；
- 350：诺森德稀有装备，物品等级166-200；
- 375：当前版本所有装备都可以分解，分解史诗装备的最低要求；
]]

-- 文本资源
DboxText = {
  title = "ahhz's Dbox",
  helpTitle = "ahhz's Dbox 帮助",
  btnHelp = "帮助",
  btnClose = "关闭",
  btnScan = "扫描",
  btnDebug = "Debug",
  btnSetting = "设置",
  settingsTitle = "ahhz's Dbox设置选项",
  btnReset = "Reset",
  btnAddAll = "全部添加",
  btnClearAll = "全部清除",
  btnDe = "执行分解",
  btnAdd2DB = "全部写入",
  btnReadDB = "读取表单",
  btnClearDB = "清除表单",
  btnMini = "迷你模式",
}
