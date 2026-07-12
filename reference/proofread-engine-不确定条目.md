# engine 校对记录 — 不确定条目与决策

> 2026-07-12 校对/精翻。本区块 471 条(82 条 PS4 官方锁定 + 389 条待校),共修订 29 条。
> 区块构成:约六成是 GameEngine 按键名(UNKNOWN 占位、F1-F24、JOY 轴等,多为直通保留),其余为网络/引擎系统消息、死亡消息、GameMessage 多人消息。

## 修订要点

- 状态词对齐 PS4:LOADING=正在读取、SAVING=正在保存、CONNECTING=正在连接(engine.Console/Progress 由"加载中/保存中/连接中"统改);PRECACHING=正在预缓存
- 视角消息对齐 PS4 PlayerController:Now viewing from=当前视角：、own camera=自身
- 死亡消息占位符两侧空格去除,与 shared 风格统一("%o被%k击杀了。")
- 手柄 PAD UP/DOWN/LEFT/RIGHT=方向键上/下/左/右(去空格)

## 待复核(不确定)条目

| 条目 | en | 现译 | 疑点 |
| --- | --- | --- | --- |
| engine.Mutator#1 | Mutator | 修改器(未改) | Unreal 术语,社区也译"突变器";本作 MP 自定义选项中出现,取通俗的"修改器" |
| engine.GameEngine#19 | PAUSE(键名) | 暂停(未改) | 键盘 Pause 键;与功能"暂停"同词,如需区分可改"PAUSE" |
| engine.GameEngine#37-40 | LEFT/UP/RIGHT/DOWN(键名) | 左/上/右/下(未改) | 方向箭头键;亦可用"←↑→↓"(GBK 可编码),暂用文字 |
| engine.GameEngine#5 等大量 | UNKNOWNxx(键名) | 保留英文(未改) | jp 版译"不明なキーxx";这些是无名键位占位,保留英文更安全,不太可能显示 |
| engine.Suicided#1 | %o had an aneurysm. | %o暴毙了。 | 原文是幽默死法(动脉瘤);直译生硬,取意译 |
| engine.Falling#1 | %o left a small crater | %o砸出了一个小坑 | 幽默死法,意译 |
| engine.GameInfo#5 | ...'PlayerStart' actor | 关卡可能缺少 'PlayerStart' Actor | 开发者向错误消息,Actor 保留术语不译"角色" |

## PS4 官方锁定条目中发现的疑似错译(禁止改动,仅记录)

| 条目 | en | PS4 译文 | 问题 |
| --- | --- | --- | --- |
| engine.Helmet#8 | MAINTAIN CURRENT ORDERS | 保留当前顺序 | orders 应为"命令"(保持当前命令),官方误译为"顺序" |
| engine.SubActionSceneSpeed#1 | Scene Speed | 游场景度 | 官方乱序错字(应为"场景速度") |
| engine.SubActionFade#1 | Fade | 褪色 | 过场淡入淡出效果,应为"淡出";编辑器向文本,影响小 |
| engine.Helmet#12 | SAVING CHECKPOINT | 存档检查点 | 语境是"正在保存检查点",官方译文按名词处理,勉强可读 |
| engine.Helmet#67 | PLEASE DON'T TURN OFF YOUR XBOX CONSOLE | 快速存档完成 | PS4 按 de 行(SCHNELLSPEICHERUNG ABGESCHLOSSEN)翻译,与 en 完全错位;PS4 平台改词所致,输出到 PC 端时文案与场景不符的风险待发布前实测 |

## 本区块新确认的官方风格基准

- LOADING=正在读取;SAVING=正在保存;CONNECTING=正在连接;PAUSED=已暂停
- 提示语:PRESS @ TO DETONATE=按@引爆、MOUNT TURRET=登上炮塔、PICKUP=拾起、ENGAGE/CANCEL MANEUVER=展开行动/取消行动、REVIVE SQUADMATE=复活队友
- HUD:SEARCH AND DESTROY=搜索和摧毁(注意:Helmet 官方用"搜索和摧毁",术语表小队指令为"搜索并摧毁",两处并存)、FORM UP=列队、SECURE AREA=占领区域、TARGET HEALTH=目标生命值、INCAPACITATED=失去作战能力、HEALTH CRITICAL=生命值极低、CHARGING SHIELDS=正在为防护罩充能
- PS 键名:交叉键/圆圈键/正方键/三角键、L1-R3键、OPTIONS键、触摸板键、上/下/左/右方向键
