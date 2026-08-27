# 同类 goal-mode 方案调研报告

> 调研时间:2026-08-28 · 检索渠道:GitHub API(仓库搜索)、Web 检索 · 聚焦:与 qysnb/goal-mode 类似的「自主目标执行」类 skill/插件

## 一、结论摘要

- **「goal mode」已是主流方向**:OpenAI Codex 原生 `/goal`、Claude Code `/goal`、以及大量社区 skill/插件都在做「设定目标 → 长时自主执行 → 持久化状态 → 断点恢复」。
- **最相似的三类**:① opencode 专用插件(`prevalentWare/opencode-goal-plugin`);② 跨 harness 的 goal skill(`tolibear/goalbuddy`、`AgentPilotLab/loop-goal-runner`、`arjunkshah12345-hash/goal-mode`);③ 目标前置规划 skill(`michaelpersonal/goal-forge`)。
- **本仓库差异化优势**:自带中文工作报告(`###OpenCode工作报告<时间戳>.md`)、明确的「不打扰白名单 + ≥3 条路径穷尽再升级」、断点自愈。与同类相比**缺少**的是:跨 agent 安装与变体、校验脚本、`skills.sh`/`npx skills` 生态接入。
- **可借鉴**:变体目录结构 + 校验脚本(loop-goal-runner)、跨 harness 状态与 resume(goalbuddy)、`npx skills add` 安装范式(loop-goal)、结构化 GOAL/验证门(goal-forge)。

## 二、主要同类项目对比

| 项目 | Stars | 形式 | 目标平台 | 核心机制 | 与本仓库的异同 |
|---|---|---|---|---|---|
| `tolibear/goalbuddy` | 812 | npm 工具+插件 | Codex / Claude Code 跨 harness | repo 内 `docs/goals/<slug>/goal.md` + `state.yaml` 板子,`npx goalbuddy resume` 跨 agent 交接,可混用 worker/judge | 同:断点续跑、可验证;异:重(工具+插件),本仓库是单文件 skill |
| `prevalentWare/opencode-goal-plugin` | 321 | opencode 插件(npm) | opencode | `/goal` 命令、持久 goal 状态、完成证据、idle 自动续跑、TUI 指示器 | 同:opencode 上的 goal 模式;异:插件(非 skill),无中文报告/白名单 |
| `michaelpersonal/goal-forge` | 216 | Codex skill | Codex | 粗糙想法 → SPEC.md → GOAL.md → `/goal` 契约;budget/scorecard/feedback loop/working memory | 互补:专注执行前规格化,不替代执行 |
| `alirezarezvani/claude-code-tresor` | 766 | Claude Code skill 集合 | Claude Code | 自治 skill/专家 agent/斜杠命令合集 | 合集,非单一 goal 机制 |
| `lgqyhm2010/loop-goal` | 10 | 单 SKILL.md | Claude Code / Codex / Copilot | checkpoint 状态、每轮隔离上下文、显式退出条件;`npx skills add` 安装 | 同:单文件、checkpoint、run-until-done;异:侧重「纪律」而非报告/白名单 |
| `AgentPilotLab/loop-goal-runner` | 2 | skill 变体目录 | Codex / Claude Code | `skills/` 与 `claude-code/` 双入口、STATE.md、门(gate)、stop 规则、`validate-repo.ps1` | 本仓库跨 agent 改造的**直接参考**(变体目录+校验脚本) |
| `clanyxh-blip/goal-for-claude-skill` | 0 | Claude Code skill | Claude Code | `/goal status/pause/resume/cancel`,状态机 active/paused/blocked/complete,blocked=外部阻塞或 3x 失败 | 同:3x 失败即阻塞、状态机;异:状态存 `~/.claude/`,本仓库存项目内 |
| `arjunkshah12345-hash/goal-mode` | 0 | 独立 skill | 任意 agent(9 种) | `docs/goals/<slug>/goal.md`+`state.yaml`,Scout/Judge/Worker 同线程,run until proven | 同:独立 skill、跨 agent;异:英文板子,本仓库中文报告 |
| `aalexli1/full-agent` | - | 脚本 | Claude Code | 单目标启动 Claude Code 自主跑完,文件系统记忆+子 agent | 同类思路,偏脚本化 |
| OpenAI Codex 原生 `/goal` | - | 官方能力 | Codex | 持久目标+完成条件+跨 turn 保持(OpenAI 侧 gated) | 官方实现;本 skill 是其独立通用复刻 |

> 另有生态线索:`skills.sh` 目录服务、`vercel-labs/skills` CLI(`npx skills add <repo> -a <agent>`)、Anthropic `claude-quickstarts/autonomous-coding`(harness 演示)。

## 三、对本仓库跨 agent 改造的启发

1. **变体目录 + 校验脚本**:loop-goal-runner 用 `skills/`(Codex)+ `claude-code/` 两个入口 + `validate-repo.ps1`。本仓库改为:根 `SKILL.md`(agent 中立)+ `agents/{opencode,claude-code}/` 变体 + `scripts/verify-skill.ps1`。
2. **frontmatter 中立**:根 SKILL.md 只保留 `name`+`description`(各 agent 都能解析);变体按 agent 增加 `argument-hint`/`allowed-tools`。
3. **工具名中立**:正文不再绑定 opencode 工具名(`Write`/`Bash`/`Task`),改用通用表述。
4. **安装生态**:README 提供 `npx skills add`(若支持)与手动复制两种路径,并说明各 agent 的技能目录。
5. **差异化卖点保留**:中文报告、不打扰白名单、≥3 条路径穷尽、断点自愈——同类项目均无完整组合。

## 四、备注

- Codex 原生 `/goal` 为 OpenAI 侧 gated 功能;本 skill 为独立实现,不依赖该能力。
- 检索为快照,星标/数据以调研当日为准。