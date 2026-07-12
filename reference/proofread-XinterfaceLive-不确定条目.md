# XinterfaceLive 校对记录 — 不确定条目与决策

> 2026-07-12 校对/精翻。本区块 212 条(全部待校,无 PS4 锁定条目),共修订 77 处(定点 22 + 区块级统一 52 + 空格修正 3)。
> 说明:本区块是 Xbox Live 专用 UI(登录/好友/邀请/匹配/举报/排行榜),PC 版基本不可见,优先级低,但仍按全项目标准统一。

## 区块级统一

- **人称"您"→"你"**:全项目(含 PS4 官方)统一用"你",本区块粗翻大量用"您",已批量替换。
- **冒号半角→全角**:标签类("主机名：""平均玩家数：")与按钮提示("是 ：""： 否""： 继续")统一为全角冒号,按钮提示保留"文字+空格+："格式(与 shared/XinterfaceCtmenus 一致)。
- **确认句式**:去"吗",统一官方"确定…？"(确定离开当前游戏？/确定退出Xbox Live登录？等)。
- **状态短语补句号**(跟随 en 'ONLINE.'):在线。/离线。/好友。/游戏中。/语音开启。等 8 条。

## 多行拼接修正

MenuPlayerFeedbackConfirm.Body(举报后果说明,5 行拼接):原译行 2/3 连读产生"可能导致该玩家被可能会导致语音禁止…"重复,重排为"…多次举报/可能导致该玩家受到/语音禁止、锁定乃至/账户封禁的处罚。"

## 待复核(不确定)条目

| 条目 | en | 现译 | 疑点 |
| --- | --- | --- | --- |
| MenuLiveMain#1 | OPTIMATCH | 最优比赛(未改) | Xbox Live 匹配术语,Halo 2 等作官方曾译"自选游戏";jp 误写"オプティカルマッチ"。无本作官方译名,暂保留 |
| MenuDashboardConfirm 系列 | Xbox Dashboard | Xbox仪表盘(未改) | 初代 Xbox 系统界面,无大陆官方译名;亦可"主控台/操控面板" |
| MenuLivePasscode | PASSCODE | 密码(未改) | Xbox Live 通行码实为手柄按键组合,严格说是"通行码";UI 空间考虑保留"密码" |
| MenuAcceptCrossTitleInvite#4 | JOIN SESSION? | 加入会话？ | 与 Xbox 暂停菜单"离开游戏将结束此会话"的 SESSION=会话 保持一致;统计页 SESSIONS 仍译"场次" |
| MenuDHMStats#6/#7 | BR / DD SESSIONS | BR场次/DD场次(未改) | 未知模式缩写(疑似未发布的 Bounty/Domination 类),保留缩写 |
| MenuPlayerFeedback#2 | SCREAMING | 喧哗 | 举报选项(麦克风喧哗尖叫);原译"大声尖叫",jp"うるさかった" |
| MenuPlayerStats#5 | SPECIALS: | 特殊： | 统计条目,疑指特殊击杀/奖项次数,语义待实测 |
| MenuGamerList#10 | VOICE THROUGH TV. | 通过电视输出语音。(未改) | Xbox 语音走电视扬声器的状态 |
| MenuLiveErrorMessage#6 | MEMORY MANAGER | 内存管理器(未改) | 实为 Xbox 存储管理(记忆卡/硬盘),或译"存储管理器";Xbox 专用,影响小 |

## 一致性说明

- 好友/邀请动词组:发送/接受/拒绝(DECLINE)/取消/屏蔽(BLOCK);"REMOVE FROM FRIENDS LIST"=从好友列表中移除。
- 匹配相关:QUICK MATCH=快速比赛、CREATE MATCH=创建比赛、AVAILABLE MATCHES=可用比赛、MATCH DETAILS=比赛详情、LEADERBOARD=排行榜。
- PingLabels:EXCELLENT/GOOD/FAIR/POOR=优秀/良好/一般/差。
- "正在…"进行时格式沿用(正在验证.../正在更新LIVE统计数据...);省略号跟随 en 用半角"..."。
