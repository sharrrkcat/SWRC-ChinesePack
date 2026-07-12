# XinterfaceCtmenus 校对记录 — 不确定条目与决策

> 2026-07-12 校对/精翻。本区块 336 条(126 条 PS4 官方锁定 + 210 条待校),共修订 65 条。
> 原则:PS4 官方译法优先(装填/轮替/蹲伏/观察/中等/震动/反向Y轴/镜头灵敏度/声效音量/上一个/下一个);确认句式统一为官方"确定…?"(去掉"你确定要…吗?")。

## 待复核(不确定)条目

> **2026-07-12 已定夺**:下表全部采用"现译"列方案,仅两处调整——①AUTO PULL MANEUVERS 保持"自动撤回行动",并已在 translation.json 的 note 中标注与 PS4 官方不同;②CTSaveGameMenu#21 NEW 改为"新建"(存档菜单中为新建存档按钮,不跟随 PS4 的"新")。

| 条目 | en | 现译 | 疑点 |
| --- | --- | --- | --- |
| CTGameOptionsPCMenu#6 / CTGameOptionsXboxMenu#6 | AUTO PULL MANEUVERS | 自动撤回行动 | PS4 官方(CTGameOptionsPSMenu#6)仅译"自动",疑似官方截断/漏译,不可照搬。jp=自動撤退。含义:队员濒危时自动撤回小队行动。改为"自动撤回行动",待游戏内确认语义 |
| CTOptionsXboxMenu#2 | SOUND / GRAPHICS OPTIONS | 声音/图像选项 | PS4 官方(CTOptionsPSMenu#2)译"声音选项",疑似官方漏译"/GRAPHICS"。未照搬 |
| CTGraphicsOptionsPCMenu#0 | GRAPHICS QUALITY | 图像质量 | GRAPHICS 统一取 PS4"图像"(图像选项);若后续发现 PS4 其他处用"图形",需回改 |
| CTControlsOptionsPCMenu.OptionSet1Labels#11 | SECURE POSITION | 占领阵地(未改) | 术语表:Secure Area=占领区域、Grenade Position=手榴弹阵地、Sniper Position=狙击手位置,Position 译法不统一。保留"占领阵地",待统一 |
| CTGameOptionsPCMenu#1 | INVERT MOUSE | 鼠标反转(未改) | PS4 风格是"反向Y轴";若统一应为"反向鼠标",但"鼠标反转"更符合 PC 习惯。保留 |
| CTSoundOptionsPCMenu#6 | AUDIO CHANNELS | 音频声道 | 原译"音频通道";选项值为 16/32/64,指声道数。也可译"声道数" |
| CTControllerOptionsRemapXboxMenu#13–16 | (CLICK) LEFT/RIGHT THUMBSTICK | (按下)左/右摇杆(未改) | PS4 对 LEFT/RIGHT STICK 用"左/右操作杆"。Xbox 菜单 PC 端基本不显示,保留"摇杆" |
| CTControllerOptionsRemapXboxMenu.OptionSet1Labels#3 | MP SCORES | 多人分数(未改) | 亦可"多人游戏分数",按钮空间考虑保留短版 |
| CTSaveGameMenu#21 | NEW | 新 | 对齐 PS4 YLabel"： 新";单字按钮略生硬,可考虑"新建"(需与 PS4 标签一致性取舍) |
| CTControllerOptionsXboxMenu#0–5 | USE (DEFAULT) XBOX CONTROLLER CONFIGURATION … | 使用默认控制器配置 等(未改) | 译文省略"XBOX",与 PS4 版(无平台词)口径一致;如需严格忠实可补"XBOX" |
| CTStartPCMenu#2 | LegalText(PC 版,仅 © 2005) | 采用 PS4 官方法律文本译文并将年份改回"(C) 2005" | 法律文本是否必须保留英文原文待定;PS4 官方已翻译,故跟随。GBK 无 © 字符,沿用官方"(C)"写法 |
| CT_Focus_LoadGameMenu / CT_MSEval_* | (开发/评测用菜单) | 已按正式风格翻译 | 玩家一般不可见,优先级低;"INFILTRATE"由"渗入"改"潜入" |

## 已确认的官方风格基准(供后续区块沿用)

- RELOAD=装填;CYCLE=轮替(轮替雷管/轮替面罩模式);CROUCH=蹲伏;LOOK=观察;LOOK SENSITIVITY=镜头灵敏度;INVERT Y AXIS=反向Y轴;VIBRATION=震动;MEDIUM(难度)=中等;SOUND FX VOLUME=声效音量;PREVIOUS/NEXT SET=上一个/下一个;LOAD LAST SAVE=载入最新存档;LOAD GAME=载入游戏;APPEAR ONLINE/OFFLINE=当前在线/当前离线;REMAP=重新配置/重新分配
- 确认框:"确定〈动作〉？任何未保存的进度都将丢失。"(demo 变体:"所有进度都将丢失。")
- 退出确认:"确定退出至WINDOWS桌面？"
- 重启提示:"更改的选项需要重启游戏后才能生效。"
- 按钮标签"X :"/": X"的全角冒号与空格格式遵循 PS4 原文(如"： 恢复默认")
