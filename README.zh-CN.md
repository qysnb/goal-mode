# goal-mode — 自主目标执行模式(多 Agent)

一个跨 agent 的 skill:设定一个目标后,**agent 一口气自主执行到达成**——拆任务、写代码、运行、验证、写文档/注释,全程记录工作报告。除关键事项外**不打扰用户**,中断后自动续跑。

兼容 **opencode / Claude Code / Codex / 其他支持 skill 的 harness**。

## 特性

- **自主执行**:目标 → 拆任务 → 实现 → 运行验证 → 记录,循环直到成功标准达成
- **工作报告**:在会话主目录生成 `###OpenCodeWorkReport<YYYYMMDDHHMM>.md`,进度日志/问题/方案/验证结果全程留档
- **问题留档**:每个问题记录「现象 / ≥3 条尝试路径 / 解决或待解决 / 备选方案」
- **不打扰原则**:仅对关键事项(不可逆破坏操作、缺凭据/密钥、真实金钱/账号操作、目标不可达、同一阻塞穷尽 3 条路径仍失败)询问用户;版本迭代批量删旧文件先 git 存档再删,**不打断**
- **断点自愈**:每个里程碑强制落盘检查点(`GOAL_STATE.json`);因 LLM 输出上限 / 网络中断 / 会话结束中断后,resume 自动复原并先核对磁盘真实状态再续

> 注:本 skill 文件为英文版(适配国际化使用)。工作报告文件名前缀可在 skill 的「常量」中修改 `REPORT_PREFIX`(默认 `###OpenCodeWorkReport`,可改回 `###OpenCode工作报告`)。

## 安装

### 方式一:按 agent 选择变体

```bash
git clone https://github.com/qysnb/goal-mode.git
```

| Agent | 复制源 | 目标目录 |
|---|---|---|
| opencode | `agents/opencode/` | `~/.config/opencode/skills/goal-mode/` |
| Claude Code | `agents/claude-code/` | `~/.claude/skills/goal-mode/` |
| Codex / 通用 | 根 `SKILL.md` | `~/.codex/skills/goal-mode/` 或任意 `**/SKILL.md` 技能目录 |

示例(opencode,全局):

```bash
mkdir -p ~/.config/opencode/skills/goal-mode
cp goal-mode/agents/opencode/SKILL.md ~/.config/opencode/skills/goal-mode/SKILL.md
```

Windows (PowerShell):

```powershell
git clone https://github.com/qysnb/goal-mode.git
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.config\opencode\skills\goal-mode"
Copy-Item goal-mode\agents\opencode\SKILL.md "$env:USERPROFILE\.config\opencode\skills\goal-mode\SKILL.md"
```

### 方式二:`npx skills`(vercel-labs/skills CLI)

```bash
npx skills add qysnb/goal-mode -a claude-code -a codex -y
```

### 方式三:opencode `skills.paths`(不复制)

```json
{
  "skills": { "paths": ["C:/path/to/goal-mode"] }
}
```

> 安装后**重启对应 agent** 才会加载生效(配置仅在启动时读取)。

## 使用

```
/goal-mode <目标>     # opencode:开始自主执行
/goal-mode resume     # opencode:中断后从检查点续跑
```

其他 agent 直接用自然语言:`goal mode: <目标>`、`run until done`、`do it in one go`、`autonomous`;续跑用「continue the last goal」。

## 产物

| 文件 | 说明 |
|---|---|
| `###OpenCodeWorkReport<YYYYMMDDHHMM>.md` | 工作报告(主交付物):目标 / 约束与成功标准 / 执行计划 / 进度日志 / 问题与解决方案 / 验证结果 / 最终总结 |
| `GOAL_STATE.json` | 检查点,断点续跑依据,每个里程碑覆盖写 |

## 打断(升级)白名单

仅在以下情况 agent 会暂停并提问,其余全程静默执行:

1. 不可逆破坏性操作(如 `rm -rf` 未版本化数据、`git reset --hard` 丢弃未提交工作、强推)
2. 需要 API key / 密码 / 密钥但环境中没有
3. 真实金钱 / 账号操作(付款、购买、注册、开通服务)
4. 目标根本不可达 / 方向冲突
5. 同一阻塞已穷尽 ≥3 条不同路径仍失败(附已尝试方案 + 建议)

完成时发送一条完成摘要(目标 / 主要成果 / 报告路径 / 遗留问题)。

## 仓库结构

```
goal-mode/
├── SKILL.md                  # canonical(agent 中立,任意 harness 可加载)
├── agents/
│   ├── opencode/SKILL.md     # opencode 变体(argument-hint / allowed-tools)
│   └── claude-code/SKILL.md  # Claude Code 变体
└── scripts/
    └── verify-skill.ps1      # 生成变体 + 全量校验
```

变体由根 `SKILL.md` 自动生成(`pwsh scripts/verify-skill.ps1`),正文保持一致。

## License

MIT