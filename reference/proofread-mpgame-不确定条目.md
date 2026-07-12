# mpgame 校对记录 — 不确定条目与决策

> 2026-07-12 校对/精翻。本区块 166 条(全部待校,无 PS4 锁定条目),共修订 34 条。

## 重要发现:MPVoice* 漏译 22 条(已补翻)

`mpgame.MPVoiceDelta07x/38x/40x`、`MPVoiceTrandoMerc01x`、`MPVoiceTrandoSlaver01x/02x` 下 22 条的 zh_CN 仍是英文原文(粗翻遗漏——这些是从 shared.enjp 拆分出来的 voicepack 独立行)。已按 shared/subtitles_all_mp 校准基准补翻(小心手雷/一枪毙命/跟我来/战斗准备,德尔塔/扫清道路等)。**其他区块校对时应同样检查 zh==en 的漏译条目**(本次校验脚本已加此项)。

## 拼接消息语序修正(引擎按 前缀+玩家名+后缀 拼接)

| 条目 | en | 修正 | 拼接效果 |
| --- | --- | --- | --- |
| VictimMessage#1/#2 | 'You were killed by' + 凶手 + '!' | 你被 / 击杀了！ | "你被〈凶手〉击杀了！" |
| MPDeathMessage#1 | 死者 + 'was killed by' + 凶手 | 死于 | "〈死者〉死于〈凶手〉"(无尾缀字段,原译"被击杀了"会产生"X被击杀了Y"错序) |
| KillingSpreeMessage#1 | 死者 + "'s reign of terror ended by" + 终结者 | 的恐怖统治被终结了，终结者： | 尾随凶手名不再悬空 |
| MPHUD#21 | …respawn in + 秒数 | 按[开火]键重生，倒计时： | 尾随秒数 |
| DMStatsScreen#1 | 'PERSONAL STATS FOR' + 玩家名 | 个人统计： | 尾随玩家名 |

## 待复核(不确定)条目

| 条目 | en | 现译 | 疑点 |
| --- | --- | --- | --- |
| MPDeathMessage#1 | was killed by | 死于 | 拼接语序推断自 UE 惯例(死者+中缀+凶手),需游戏内确认;若引擎实际带空格拼接则显示"X 死于 Y",可接受 |
| DMScoreboard#8 | NET | 网络 | 与 PING 并列的计分板列头,推断为网络状态;原译"净值"疑为 net score 理解,若实测是净胜分需改回 |
| DMScoreboard#19 | OUT | 出局 | 回合制出局状态(原译"退出") |
| DMScoreboard#11 | FPH | 每小时击杀(未改) | frags per hour,列头偏长,可考虑保留"FPH" |
| DMStatsScreen#19/#20 | Killed By / Deaths w/ | 被其击杀 / 持有时死亡 | 武器统计列头:该武器击杀你的次数 / 持有该武器时死亡次数;语义按 UT2003 惯例推断 |
| DMStatsScreen#4-6/#10 | Flak Monkey! / Combo Ape! / Head Hunter! / Hat Trick! | 火力达人/连击高手/猎头者/帽子戏法(未改) | UT 系奖项梗,意译 |
| KillString#6 | HOLY MACKEREL! | 太厉害了！(未改) | 感叹语意译 |
| SelfSpreeNote#0 | Menace! | 银河威胁！(未改) | 对应他人版"是银河系的威胁";自我版补足语境 |
| MPGame#1 | Team Score Rounds | 队伍分数回合(未改) | 服务器配置项,含义为"按回合计队伍分",措辞待实测 |
| MPHUD#4 | (N +) frags wins the match. | 次击杀赢得比赛。(未改) | 数字前缀拼接:"N次击杀赢得比赛。" |
| StartupMessage#2-4 | The match is about to begin...3 | 比赛即将开始...3(未改) | 倒计时用半角"..."与 en 一致(区别于叙述文本的"……") |

## 一致性说明

- 连杀播报两套并存:MultiKillMessage(双杀/三杀/…/令人印象深刻)与 DMStatsScreen.KillString(双杀/多重击杀/超级击杀/…)——en 本身就是两套词,保持区分。
- 'Trando neutralized.'(带句号,voicepack 版)译"特兰多人已除掉。";subtitles_all_mp 无句号版为"特兰多人已除掉"。
- OVER TIME!=加时赛!;engine.GameMessage 的 Sudden Death Overtime 为"突然死亡加时赛",不同 en 保持区分。
