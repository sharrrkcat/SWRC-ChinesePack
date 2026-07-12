# shared.enjp 校对记录 — 不确定条目与决策

> 2026-07-12 校对/精翻。本组 692 条(237 条 PS4 官方锁定 + 455 条待校),共修订 41 条 + 2 处 note 标注 + 1 处上区块回改。
> 原则:同一短语先查组内 PS4 官方条目;战斗语音短语(On my way/Taking fire/Incoming/Affirmative 等)与官方字幕译法逐一对齐。

## 重要发现:INFILTRATE 官方译"渗入"

PS4 官方加载标题:"INFILTRATE THE DROID FOUNDRY→渗入机器人铸造厂"、"INFILTRATION OF THE CORE SHIP→渗入核心飞船"。
上一区块(XinterfaceCtmenus)曾把 CT_Focus_LoadGameMenu#3 的"渗入敌方主力舰"改为"潜入",**已回改为"渗入"**。后续区块 INFILTRATE 统一译"渗入"。

## 待复核(不确定)条目

| 条目 | en | 现译 | 疑点 |
| --- | --- | --- | --- |
| #100028 | Trandoshan Mercenary SMG | ACP连发炮(未改) | **与 PS4 冲突**:PS4 同名条目(#100712)译"特兰多佣兵冲锋枪";术语表规定别名统一为"ACP连发炮"。按术语表保留,已在 note 标注 |
| #100990 / #101019 | SABOTAGE SEPARATIST CORESHIP | 破坏分裂势力核心飞船(未改) | PS4 对任务目标"LOCATE SEPARATIST CRUISER"用"分离主义者巡洋舰",与术语表"军事实体→分裂势力"规则冲突;此二条为开发用菜单,暂按术语表保留,待 Separatist 分译规则复查 |
| #100995 | Kashyyyk Approach | 接近卡希克 | 关卡名(开发菜单);原译"卡希克进场",航空术语 approach=进场/进近,但玩家语感取"接近"。也可译"抵近卡希克" |
| #100018 | Near(LocationPrefix) | 靠近 | 多人模式位置前缀,拼接成"靠近○○队伍基地";需游戏内确认拼接顺序 |
| #100017 | Objective Disabled! | 目标已瘫痪！(未改) | 多人模式设施被破坏提示;jp"目標を破壊!",也可译"目标已被破坏！" |
| #100555 / #100955 | RESTORE DEFAULTS | 恢复默认(未改) | PS4 对应按钮仅译"默认"(#101035);"恢复默认"语义更清楚,未跟随官方缩写 |
| #100692 | PLAYING | 游戏中(未改) | 分屏/玩家槽位状态,jp"プレイ可能"(可游玩);语境待游戏内确认 |
| #100974 | CHANGE TEAMS | 更换队伍(未改) | 上区块 SWITCH TEAM=切换队伍;en 用词不同故保留差异,可考虑统一 |
| #100665 | Rebreather | 再呼吸器(未改) | 星战装备 breath mask;"再呼吸器"是潜水术语直译,也可译"呼吸器" |
| #100083 | killed(Name 字段) | killed(保留英文,未改) | 疑似内部标识符而非显示文本,保留原文更安全 |
| 冒号标签格式 | 'YES :' / ': NO' 等 | 是 ：/： 否 | PS4 官方自身格式不一("是  ："“是：  "并存);统一为"文字+空格+全角冒号"/"全角冒号+空格+文字" |

## 本组新确认的官方风格基准(补充进后续区块沿用)

- INFILTRATE=渗入;On my way=正在途中;Taking fire=受到火力攻击;Incoming(敌袭)=敌人来袭;Affirmative=明白;Roger that=收到;Fire in the hole=小心手雷;Moving into position=前往就位;In position=就位;Take cover=找掩护;Man down=有人倒下了;Hostile/Enemy down=敌人倒下了;Good to go, sir=随时可以出动,长官
- ACCEPT=接受;RESTORE DEFAULTS(官方)=默认;APPEAR ONLINE/OFFLINE=当前在线/当前离线;LOAD GAME(标题)=读取存档;LOADING=正在读取;AutoSave/QuickSave=自动存档/快速存档;OK=确定;CANCEL=取消;ON/OFF=开启/关闭
- 页签:CONTROLS=控制、GAME=游戏、SOUND=声音、GRAPHICS=图像
- 竞技场关卡名无空格:竞技场A17、竞技场G9
- 说话人标签:德尔塔07/38/40/62、克隆顾问1、特兰多雇佣兵、炮艇驾驶员1(冒号用全角"：")
