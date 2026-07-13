# Steam 原版本地化覆盖诊断

> 生成时间：2026-07-12T13:23:52.538832+00:00

## 摘要

- 非地图原版 `.int`：52 个文件，9391 行；catalog 缺 0 行，build 缺 0 行。
- 原包脚本：导出 36 个包、3334 个类。
- 明确声明为 localized 的缺口候选：36 项。
- 按字段名识别的显示文本缺口候选：5 项（需人工排除开发/未使用路径）。

## 人工复核结论

### Steam PC 高优先真实缺口（13 项）

- `CTCharacters`：三名队员的 `HUDNickname`（SEV / FIXER / SCORCH），由 `GetHudNickname()` 返回给 HUD。
- `Engine.GameMessage`：`StrTooMangRep`、`StrTooMangTran`，由多人消息 switch 的 case 17/18 返回。
- `XInterfaceCommon.MenuConnectionFailed.MissingContentStr`，服务器内容缺失时直接显示。
- `XInterfaceCommon.MenuCreateGame.StringNoName`，PC 创建服务器且名称为空时直接弹窗。
- `XInterfaceCommon.MenuSelectProfile.DamagedProfileStart/End`，档案校验失败时拼接并弹窗。
- `XInterfaceCTMenus.CTMultiplayerPausePCMenu.StringEnterSpectatorMode/StringExitSpectatorMode`，Steam PC 暂停菜单根据观战状态直接显示。
- `XInterfaceGameSpy.GameSpyMenuTemplate.DedicatedServerLabel/FriendlyFirePctLabel`，源码注释明确说明由原生 GameSpy 管理器读取。

### 可达但应保留原值并显式覆盖（9 项）

- 三名队员的 `HUDDescription`（07 / 40 / 62）。
- `Engine.Console.cSay/cTeamSay`：同时参与实际 `Say` / `TeamSay` 控制台命令，不应翻译。
- GameSpy 的 `DM / TD / CTF / AS` 四个模式缩写。

### Xbox 或 Steam PC 不可达（10 项）

- `DMScoreboard.PingFriendly[0..4]`：只在 `IsOnConsole()` 分支使用，PC 显示数值 ping。
- `GameEngine.DiscReadError`：零售光盘读取错误。
- `MenuLowStorage.XboxLiveMsg`：Xbox Live 磁盘块分支。
- `MenuSelectMaps.DamagedContent`：Xbox downloadable-content 检查路径。
- `CTMultiplayerPauseXboxMenu` 的两个观战模式字段：Steam 绑定 PC 菜单类。

### 暂不能确认（4 项）

- `GameEngine.DeathMatchStr / TeamDeathMatchStr / CaptureTheFlagStr / AssaultStr` 只有 localized 声明和默认值；脚本没有消费者，可能由 native 代码读取。建议纳入覆盖并翻译为标准模式名。

> 这些字段缺少 `.cht` 覆盖时会回退到包内英文默认值，通常表现为残留英文，而不是空白字形。

## 原版 .int 缺口

未发现。

## 明确 localized 缺口候选

- `ctcharacters.u [Commando07Delta] HUDDescription` — 缺于 catalog, build；原值 `"07"`
- `ctcharacters.u [Commando07Delta] HUDNickname` — 缺于 catalog, build；原值 `"SEV"`
- `ctcharacters.u [Commando40Delta] HUDDescription` — 缺于 catalog, build；原值 `"40"`
- `ctcharacters.u [Commando40Delta] HUDNickname` — 缺于 catalog, build；原值 `"FIXER"`
- `ctcharacters.u [Commando62Delta] HUDDescription` — 缺于 catalog, build；原值 `"62"`
- `ctcharacters.u [Commando62Delta] HUDNickname` — 缺于 catalog, build；原值 `"SCORCH"`
- `engine.u [Console] cSay` — 缺于 catalog, build；原值 `"Say"`
- `engine.u [Console] cTeamSay` — 缺于 catalog, build；原值 `"TeamSay"`
- `engine.u [GameEngine] AssaultStr` — 缺于 catalog, build；原值 `"ASSAULT"`
- `engine.u [GameEngine] CaptureTheFlagStr` — 缺于 catalog, build；原值 `"CAPTURE THE FLAG"`
- `engine.u [GameEngine] DeathMatchStr` — 缺于 catalog, build；原值 `"DEATHMATCH"`
- `engine.u [GameEngine] DiscReadError` — 缺于 catalog, build；原值 `"THERE'S A PROBLEM WITH THE DISC YOU'RE USING. IT MAY BE DIRTY OR DAMAGED."`
- `engine.u [GameEngine] TeamDeathMatchStr` — 缺于 catalog, build；原值 `"TEAM DEATHMATCH"`
- `engine.u [GameMessage] StrTooMangRep` — 缺于 catalog, build；原值 `"Too many Republic players."`
- `engine.u [GameMessage] StrTooMangTran` — 缺于 catalog, build；原值 `"Too many Trandoshan players."`
- `mpgame.u [DMScoreboard] PingFriendly[0]` — 缺于 catalog, build；原值 `"?"`
- `mpgame.u [DMScoreboard] PingFriendly[1]` — 缺于 catalog, build；原值 `"****"`
- `mpgame.u [DMScoreboard] PingFriendly[2]` — 缺于 catalog, build；原值 `"***"`
- `mpgame.u [DMScoreboard] PingFriendly[3]` — 缺于 catalog, build；原值 `"**"`
- `mpgame.u [DMScoreboard] PingFriendly[4]` — 缺于 catalog, build；原值 `"*"`
- `xinterfacecommon.u [MenuConnectionFailed] MissingContentStr` — 缺于 catalog, build；原值 `"SERVER CONTENT '%s' IS NOT PRESENT ON THE LOCAL MACHINE."`
- `xinterfacecommon.u [MenuCreateGame] StringNoName` — 缺于 catalog, build；原值 `"NO SERVER NAME SPECIFIED!"`
- `xinterfacecommon.u [MenuLowStorage] XboxLiveMsg` — 缺于 catalog, build；原值 `"YOUR XBOX DOESN'T HAVE ENOUGH FREE BLOCKS TO SIGN IN TO XBOX LIVE. YOU NEED TO FREE %d MORE BLOCKS. PRESS A TO CONTINUE OFFLINE OR B TO FREE MORE BLOCKS."`
- `xinterfacecommon.u [MenuSelectMaps] DamagedContent` — 缺于 catalog, build；原值 `"THE DOWNLOADABLE CONTENT %s IS DAMAGED AND CANNOT BE USED."`
- `xinterfacecommon.u [MenuSelectProfile] DamagedProfileEnd` — 缺于 catalog, build；原值 `" APPEARS TO BE DAMAGED AND CANNOT BE USED."`
- `xinterfacecommon.u [MenuSelectProfile] DamagedProfileStart` — 缺于 catalog, build；原值 `"THE PROFILE "`
- `xinterfacectmenus.u [CTMultiplayerPausePCMenu] StringEnterSpectatorMode` — 缺于 catalog, build；原值 `"ENTER SPECTATOR MODE"`
- `xinterfacectmenus.u [CTMultiplayerPausePCMenu] StringExitSpectatorMode` — 缺于 catalog, build；原值 `"EXIT SPECTATOR MODE"`
- `xinterfacectmenus.u [CTMultiplayerPauseXboxMenu] StringEnterSpectatorMode` — 缺于 catalog, build；原值 `"ENTER SPECTATOR MODE"`
- `xinterfacectmenus.u [CTMultiplayerPauseXboxMenu] StringExitSpectatorMode` — 缺于 catalog, build；原值 `"EXIT SPECTATOR MODE"`
- `xinterfacegamespy.u [GameSpyMenuTemplate] DedicatedServerLabel` — 缺于 catalog, build；原值 `"Dedicated Server"`
- `xinterfacegamespy.u [GameSpyMenuTemplate] FriendlyFirePctLabel` — 缺于 catalog, build；原值 `"Friendly Fire Pct"`
- `xinterfacegamespy.u [GameSpyServerBrowserBase] AssaultAbbreviation` — 缺于 catalog, build；原值 `"AS"`
- `xinterfacegamespy.u [GameSpyServerBrowserBase] CaptureTheFlagAbbreviation` — 缺于 catalog, build；原值 `"CTF"`
- `xinterfacegamespy.u [GameSpyServerBrowserBase] DeathmatchAbbreviation` — 缺于 catalog, build；原值 `"DM"`
- `xinterfacegamespy.u [GameSpyServerBrowserBase] TeamDeathmatchAbbreviation` — 缺于 catalog, build；原值 `"TD"`

## 启发式显示文本缺口候选

- `xinterfacecommon.u [MenuGameSettings] Options[8].Items` — 缺于 catalog, build；原值 `("0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15")`
- `xinterfacectmenus.u [CTHUDOptionsXboxMenu] Options[2].Items` — 缺于 catalog, build；原值 `("ON","OFF","CYCLE")`
- `xinterfacectmenus.u [CTHUDOptionsXboxMenu] Options[3].Items` — 缺于 catalog, build；原值 `("0","1","2","3","4","5","6","7","8","9","10")`
- `xinterfacelive.u [MenuMatchMakingOptiMatchOptions] Options[0].Items` — 缺于 catalog, build；原值 `("0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15")`
- `xinterfacelive.u [MenuMatchMakingOptiMatchOptions] Options[1].Items` — 缺于 catalog, build；原值 `("1","2","3","4","5","6","7","8","9","10","11","12","13","14","15")`

## 范围与限制

- 已按要求忽略 `GEO_/RAS_/YYY_*` 与 `subtitles_geo/ras/yyy_*` 文件。
- `.int` 缺口是确定的键覆盖差异；包内启发式候选不等同于运行时必达字段。
- 无脚本类或 UCC 无法导出的纯数据包不能通过本方法证明完整性。
- 附加运行现有 unittest 时为 16/17 通过；失败项是 Fix 专属 `Mod.cht` 未保留当前 `GameData/System/Mod.int` 的 commandlet 帮助行。Steam 原始备份不含 `Mod` 包，因此不计入本次“游戏本体”覆盖结论，但应另行处理 Fix 兼容性。
