# 跨 Agent 兼容说明

本仓库从「opencode 专用」升级为「多 agent 通用」:根目录 `SKILL.md` 为 **agent 中立**版本(任意支持 skill 的 agent/harness 均可加载),`agents/` 下提供各 agent 的专属变体。

## 兼容矩阵

| Agent / harness | 推荐使用 | 安装位置 | frontmatter 差异 | 调用方式 |
|---|---|---|---|---|
| opencode | `agents/opencode/SKILL.md` | `~/.config/opencode/skills/goal-mode/` | 增加 `argument-hint`、`allowed-tools` | `/goal-mode <目标>` · `/goal-mode resume` |
| Claude Code | `agents/claude-code/SKILL.md` | `~/.claude/skills/goal-mode/` | 增加 `argument-hint` | 自然语言("goal mode: 完成X")或已安装命令 |
| Codex | 根 `SKILL.md`(canonical) | `~/.codex/skills/goal-mode/` | 仅 `name`+`description` | 自然语言或 `/goal`(独立实现,不依赖 OpenAI gated 的 `/goal`) |
| 其他 harness | 根 `SKILL.md` | 任意 `**/SKILL.md` 技能目录 | 仅 `name`+`description` | 把目标作为 prompt 交予 agent |

> 所有变体正文与根 `SKILL.md` **完全一致**,仅 frontmatter 不同;由 `scripts/verify-skill.ps1` 自动生成,保证不漂移。

## 状态与报告(跨 agent 一致)

- 工作报告:`###OpenCode工作报告<YYYYMMDDHHMM>.md`(会话主目录)
- 检查点:`GOAL_STATE.json`(同一目录,固定名;旧版 `OPENCODE_GOAL_STATE.json` 可改名为 `GOAL_STATE.json` 后继续 resume)

## 校验

```powershell
pwsh scripts/verify-skill.ps1        # 生成变体 + 全量校验
pwsh scripts/verify-skill.ps1 -SkipGenerate   # 只校验不生成
```

校验项:frontmatter 有效性、`name==goal-mode`、canonical 仅含 `name`+`description`、正文关键段落齐全、变体正文与 canonical 逐字一致。全部通过输出 `RESULT: ALL PASS`。

## 变体维护

只改根 `SKILL.md`,再运行 `scripts/verify-skill.ps1` 重新生成变体。不要直接手改 `agents/*/SKILL.md`(会被覆盖)。