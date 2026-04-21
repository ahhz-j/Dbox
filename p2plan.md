# Dbox 保守拆分方案（P2）

## 目标

在不改变当前功能、不大幅重写全局共享方式的前提下，对 Dbox 做一轮保守模块化拆分，降低 dbox.lua 的体量和职责密度，同时保持现有加载顺序、运行时行为和排错路径基本不变。

本方案遵循三个原则：

- 只拆职责边界清晰、连续成块的代码，不做大规模逻辑重写。
- 允许阶段性继续使用 _G、ui、state、DboxDB 作为共享边界，优先完成文件拆分，再考虑后续解耦。
- 每一步拆分后都应能单独回归验证，避免一次性搬动过多代码。

## 当前基线

- dbox.lua：约 1523 行
- panels.lua：约 351 行
- data.lua：约 49 行
- 现有 TOC 顺序：data.lua -> panels.lua -> dbox.lua

## 当前执行状态（更新至 1.2.1 / Build 10420）

- 已完成：阶段 1，list.lua 与 scan.lua 已拆出并接入 TOC。
- 已完成：阶段 2，layout.lua 已拆出，迷你模式恢复异常已修正并通过游戏内验证。
- 已完成：阶段 3 的一部分，ui.lua 与 config.lua 已继续拆出，主文件仅保留入口、核心分解、主界面总装配、Slash 与事件主线。
- 当前 TOC 顺序：data.lua -> ui.lua -> list.lua -> scan.lua -> layout.lua -> config.lua -> panels.lua -> dbox.lua
- 当前体量：dbox.lua 约 572 行，panels.lua 约 351 行，data.lua 约 49 行，ui.lua 约 158 行，list.lua 约 234 行，scan.lua 约 222 行，layout.lua 约 343 行，config.lua 约 103 行。
- 已完成的游戏内验证：扫描、列表迁移、排除表读写、迷你模式切换、主界面与面板基础交互、执行分解按钮兼容修复。
- 待继续确认：Reset 后的默认配置恢复、/reload 与重新登录后的配置保持、BugSack 无新增加载错误。

当前主文件主要承担的职责：

- 通用工具与样式辅助
- 列表状态操作与渲染
- 过滤表读写与背包扫描
- 布局与迷你模式
- 主界面创建与按钮绑定
- Slash 命令与事件总入口

## 保守拆分后的目标结构

原始保守目标是新增 3 个 Lua 文件形成 6 文件结构；目前已在此基础上继续细分为 8 文件结构：

- data.lua：保留静态数据与文本资源
- ui.lua：承接通用 UI 工具、样式与附魔技能显示
- panels.lua：保留帮助面板和设置面板
- list.lua：承接列表状态、列表 UI、计数信息栏
- scan.lua：承接过滤表读写、扫描与背包筛选
- layout.lua：承接普通/迷你模式布局、面板重锚、模式配置
- config.lua：承接 SavedVariables 默认初始化与 Reset 流程
- dbox.lua：保留入口、分解执行、主界面总装配、Slash、事件分发

这是“保守拆分”而不是“完全模块化重构”。短期内不要求消灭 _G，也不强求将 ui/state 封装为单独对象。

## 分阶段拆分方案

### 阶段 1：先拆列表与过滤扫描

目标：优先移走最稳定、最少依赖主入口时序的代码。

建议从 dbox.lua 抽出到 list.lua：

- UpdateInfoBarCounters
- TransferItemByIndex
- TransferAll
- ClearList
- CreateRows
- CreateListUI
- RenderListGeneric
- ui.RenderList1 ~ ui.RenderList4 的挂接

建议从 dbox.lua 抽出到 scan.lua：

- EnsureQualityFilter
- BuildFilterSet
- WriteFilterListToDB
- ReadFilterListFromDB
- ClearDBFilterList
- AddToList1
- ClearList1
- ScanBagsForDisenchantables

这一阶段的边界最清楚，原因如下：

- 这两块主要围绕 state、ui、DboxDB 运作，和 Slash、事件初始化耦合不深。
- 迁移后只需要在 dbox.lua 中保留少量对外调用点，如扫描按钮、读写按钮、渲染刷新。
- 风险主要是函数加载顺序，因此需要把新文件放在 dbox.lua 之前加载。

阶段 1 完成后的预期结果：

- dbox.lua 预计从 1523 行下降到约 1050 到 1150 行。
- 主文件中“列表/扫描/过滤”相关实现显著减少，阅读压力会立刻下降。

回归检查点：

- 扫描按钮是否正常填充“可分解”列表
- 双击在待分解/待排除/已排除之间的迁移是否正常
- 写入、读取、清空排除表是否正常
- 信息栏统计是否实时刷新

### 阶段 2：拆布局与迷你模式

目标：进一步移走大块 UI 布局逻辑，但保留主界面创建入口在 dbox.lua。

建议从 dbox.lua 抽出到 layout.lua：

- LayoutContainersRow
- GetMainWidthBreakdown
- GetMainWidthBreakdownText
- saveInterfaceState
- SetContainerVisible
- ApplyMiniLayout
- _AnchorInfoBar
- ApplyMiniInfoBarAnchors
- ApplyNormalInfoBarAnchors
- ReanchorPanels
- ReanchorPanelsSoon
- GetModeKey
- SaveCurrentModeSettings
- ApplyModeSettings
- UpdateMainWidthSliderRange
- toggleMiniMode
- InitializeMiniMode
- SaveMiniModeState

这一阶段适合在阶段 1 之后进行，原因如下：

- 它的耦合主要是 ui 和 DboxDB，不再直接依赖扫描细节。
- 迷你模式逻辑虽然长，但本身是一个相对完整的功能域。
- 先拆掉列表与过滤后，再拆布局，主界面构建代码会更容易看清剩余边界。

阶段 2 完成后的预期结果：

- dbox.lua 预计下降到约 600 到 750 行。
- 主文件将主要剩下工具函数、分解执行、主界面创建、Slash、事件入口。

回归检查点：

- 普通模式四列布局是否正常
- 迷你模式切换是否正常
- 面板位置是否跟随主界面重锚
- 迷你模式下按钮、信息栏、宽度恢复是否正常

### 阶段 3：保留主界面组装，但缩小主文件职责

目标：不强拆 EnsureMainUI，只做轻量边界收缩，让 dbox.lua 保持“入口文件”定位。

这一阶段不建议马上把整个 EnsureMainUI 全量搬出。保守做法如下：

- 保留 EnsureMainUI 在 dbox.lua 中，继续作为主界面总装配入口。
- 保留分解按钮相关逻辑在 dbox.lua 中，包括：
	- GetDEName
	- HasDE
	- RefreshDeButton
	- BtnDe 的安全宏与 PreClick 逻辑
- 保留 SlashCmdList["DBOX"] 和 eventFrame:SetScript("OnEvent", ...) 在 dbox.lua 中。

这样做的理由：

- 分解执行逻辑是插件的核心业务，放在主文件中更利于排查。
- Slash 和事件分发天然适合作为 bootstrap 保留在入口文件。
- EnsureMainUI 当前包含大量按钮绑定和闭包，强拆会明显增加搬运风险。

阶段 3 完成后的主文件定位：

- 入口初始化
- 核心业务按钮逻辑
- 主界面总装配
- Slash 与事件总线

回归检查点：

- /dbox 是否仍能正常打开和关闭主界面
- /dbox ver、/dbox mini、/dbox debug 是否仍能正常响应
- 执行分解按钮是否仍能点亮、变灰、显示原因提示并正常逐件分解
- 登录、重载、退出游戏后 SavedVariables 和界面状态是否正常保留

## TOC 调整建议

当前实装后的 TOC 顺序如下：

- data.lua
- ui.lua
- list.lua
- scan.lua
- layout.lua
- config.lua
- panels.lua
- dbox.lua

顺序原则：

- 先加载静态资源
- 再加载被主文件依赖的功能模块
- 最后加载入口文件 dbox.lua

如果 panels.lua 继续依赖 _G.EnsureMainUI，则它也可以放在 dbox.lua 之后；但更推荐让 panels.lua 只依赖前面已导出的通用函数，逐步减少它对主入口的反向依赖。

## 共享边界建议

为了保持“保守拆分”，短期内使用以下共享边界即可：

- ui：继续作为运行时 UI 容器
- state：继续作为列表与选择状态容器
- DboxDB：继续作为 SavedVariables 容器
- _G：只暴露必要能力，如 EnsureMainUI、ApplyFontSizes、CreatePanelBG

但要控制扩散：

- 新模块尽量只消费已有共享对象，不新增更多全局入口。
- 每个新模块只导出少量必要函数到 _G。
- 不在多个模块里重复创建同名工具函数。

## 预估结果

按本保守方案继续执行并结合当前实装结果：

- dbox.lua 已从约 1523 行降到约 572 行。
- 如果后续继续抽离主界面内部的局部装配助手，仍有机会继续下降到约 420 到 500 行。
- 若坚持保留 EnsureMainUI 与核心分解逻辑在入口文件，则 420 到 500 行已是更现实的稳妥区间。

对应新增模块体量预估：

- list.lua：约 180 到 260 行
- scan.lua：约 140 到 220 行
- layout.lua：约 260 到 380 行

## 不建议在 P2 阶段做的事

- 不要同时改写成彻底的对象化结构。
- 不要在拆分阶段顺手重写按钮回调风格。
- 不要把 panels.lua 一并彻底重构为无全局依赖版本。
- 不要混入功能性修复，除非拆分过程发现明确 bug。

## 建议执行顺序

1. 新建 list.lua，完成列表与信息栏迁移。
验证：进游戏执行 /reload，打开 /dbox，确认列表仍能显示、单击高亮正常、信息栏数字会随列表变化实时刷新。
2. 新建 scan.lua，完成过滤表与扫描迁移。
验证：进游戏点击“扫描”，确认“可分解”列表能正常填充；再测试“全部写入 / 读取表单 / 清除表单”，确认排除表行为正常。
3. 调整 TOC，确保新文件在 dbox.lua 之前加载。
验证：完全重载插件或重进游戏，确认 Dbox 能正常加载、/dbox 可用、BugSack 没有新增加载时报错。
4. 做一次阶段 1 完整功能回归。
验证：在游戏中完整走一遍“扫描 -> 加入待分解 -> 双击移转 -> 写入排除表 -> 读取排除表 -> 清空排除表”的流程。
5. 新建 layout.lua，迁移普通/迷你模式与重锚逻辑。
验证：进游戏测试普通模式四列布局、迷你模式切换、设置/帮助面板打开位置、主界面拖动后面板重锚是否正常。
6. 做一次阶段 2 完整功能回归。
验证：在游戏中重复测试迷你模式开关、信息栏切换、容器显示隐藏、宽度恢复、登录后迷你模式状态恢复。
7. 最后只清理 dbox.lua 中剩余的调用关系和注释，保持它作为入口文件。
验证：进游戏执行 /dbox、/dbox ver、/dbox mini，并实际点击“执行分解”按钮，确认入口命令、主界面装配和核心分解流程均未回归。

## 游戏内验证原则

- 每完成一个文档步骤，都必须至少进行一次 /reload 后的实机验证，不能只依赖静态检查。
- 任何涉及 TOC、模块加载顺序、_G 导出关系的改动，都必须通过“重进游戏或完全重载插件”验证。
- 任何涉及按钮、列表、面板、迷你模式的改动，都必须通过实际点击和界面观察验证。
- 任何涉及 SavedVariables 的改动，都必须至少验证一次“/reload 后保留”和一次“重新登录后保留”。

## P2 完成标准

满足以下条件即可视为 P2 完成：

- dbox.lua 不再承担列表渲染、过滤表读写、扫描和布局模式的具体实现。
- dbox.lua 保持入口文件职责清晰，主逻辑可在单屏或少量翻页内看完。
- 所有现有功能行为不变：扫描、迁移、排除表、分解、迷你模式、设置/帮助、Slash 命令都能正常工作。
- 主文件行数进入约 320 到 420 行区间。
