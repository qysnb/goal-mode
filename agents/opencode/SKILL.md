---
name: goal-mode
description: Execute a goal end-to-end autonomously — write code, run it, document progress and problems in a timestamped work report (###OpenCode工作报告<时间戳>.md), and resume from checkpoints after interruption. Only interrupts the user for critical matters (irreversible destructive ops, missing credentials, real-money actions, unreachable goals, 3 failed paths). Use when user says "goal mode", "一口气做完", "run until done", "自主完成", "不要打扰我直接做", or provides a goal to execute autonomously.
argument-hint: "<目标描述> | resume"
allowed-tools: Bash(*), Read, Write, Edit, Glob, Grep, Task, Skill, WebFetch, WebSearch
---

# Goal Mode: 自主目标执行模式

把一个目标(goal)交给你,由你**一口气自主执行到达成**:拆任务 → 写代码 → 运行 → 验证 → 写文档/注释 → 全程记录工作报告。除白名单内的关键事项外,**不打扰用户**。

> ⚠️ 本 skill **显式覆盖**默认的"先批准再实现"行为(brainstorming 的 HARD-GATE 不适用于本模式)。除「打断/升级策略」白名单外,你**不得**询问"是否可以开始/要不要我继续/我这样做可以吗"。直接执行。

> 🔧 **跨 Agent**:本文件为 agent 中立版本,frontmatter 仅保留 `name` + `description`,工具名用通用表述,可直接被任何支持 skill 的 agent/harness 加载。各 agent 专属变体(带 `argument-hint`、`allowed-tools` 等)见仓库 `agents/` 目录,由本文件生成,正文完全一致。

## 常量

- **REPORT_PREFIX** = `###OpenCode工作报告`
- **TIMESTAMP** = `YYYYMMDDHHMM`(例如 `202608271902`)
- **REPORT_FILE** = `<REPORT_PREFIX><TIMESTAMP>.md`(写入**会话主目录**,即当前工作目录)
- **STATE_FILE** = `GOAL_STATE.json`(同一目录,固定名,用于断点续跑)
- **RESUME_WINDOW** = 24 小时(超出则视为过期状态,全新开始)
- **BLOCK_PATHS** = 3(同一阻塞需穷尽 **≥3 条不同路径**方可升级打断)
- **报告语言** = 中文(与用户一致);文件名与内容均用中文

## 文件契约

**工作报告 `###OpenCode工作报告<时间戳>.md`** — 主交付物,模板见下,随进度持续追加。

**检查点 `GOAL_STATE.json`** — 断点恢复依据,每个里程碑覆盖写:

```json
{
  "goal": "<目标描述>",
  "status": "in_progress",
  "report_file": "###OpenCode工作报告202608271902.md",
  "created_at": "2026-08-27T19:02:00",
  "last_updated": "2026-08-27T19:30:00",
  "success_criteria": ["..."],
  "todo": ["任务A", "任务B"],
  "done": ["任务A"],
  "current_task": "任务B",
  "next_action": "实现模块 X 并运行验证",
  "problems": [{"desc": "...", "attempts": ["路径1", "路径2", "路径3"], "status": "solved|pending"}]
}
```

## 调用方式(按 agent)

- **opencode**:`/goal-mode <目标>` 开始;`/goal-mode resume` 断点续跑(变体见 `agents/opencode/`)
- **Claude Code**:直接以自然语言给出目标(如"goal mode: 完成X"),或按已安装命令触发;续跑用"继续上次的目标"(变体见 `agents/claude-code/`)
- **Codex**:`/goal <目标>` 或自然语言触发;Codex 原生 `/goal` 为 OpenAI 侧能力,本 skill 是其独立的通用实现(变体见 `agents/codex/`)
- **其他 harness**:把目标作为 prompt 交给 agent,语言如"goal mode: <目标>";中断后再次给出同一目标并说明"resume"

## 工作流

### Phase 0: 目标摄入

- 若参数/意图为 `resume` / `继续` / `恢复`:
  - `STATE_FILE` 存在 且 `status=in_progress` 且 `last_updated` 在 24h 内 → **走 Phase 5 断点续跑**
  - 否则 → 说明"无有效断点,全新开始",走 Phase 1
- 若为新目标:
  - 若 `STATE_FILE` 存在 且 `status=in_progress` 且 24h 内 → **询问一次**:恢复旧目标 / 放弃旧目标开新 / 合并(涉及未完成工作的取舍,属方向级事项)
  - 否则 → 全新开始,走 Phase 1

### Phase 1: 初始化

1. 读取项目上下文:**先读项目约定文件**(如 `AGENTS.md`、`CLAUDE.md`)、目录结构、最近 commit,识别语言/脚本/约定/验证方式(有无测试套件、示例脚本等)
2. 创建 `REPORT_FILE`,写入骨架(见模板)
3. 创建 `STATE_FILE`(goal、success_criteria、todo 初版、status=in_progress)
4. 在报告中记录:目标、约束、成功标准、执行计划初稿

### Phase 2: 执行循环(直到成功标准达成或触发升级)

每轮:

1. **选任务**:从 `todo` 取最高价值/最前置的下一项
2. **实现**:写代码并附带必要注释/文档字符串;按需更新项目文档
3. **运行验证**:用项目约定方式验证(有测试就跑测试;无测试用示例脚本/运行命令;Web 项目可构建/预览)。验证要**真跑**,不得假设
4. **记录**:把结果写入报告「进度日志」;成功/失败/部分完成都如实写
5. **落盘**:刷新 `STATE_FILE`(`todo`/`done`/`current_task`/`next_action`/`problems`/`last_updated`)——**每次里程碑必须落盘**
6. **判定**:对照 `success_criteria`,全部满足 → 走 Phase 4;未满足 → 进入下一轮

阻塞处理(任一任务遇阻时):
- 先穷尽 **≥3 条不同路径**解决(改实现、换工具、查资料、换思路),每次失败记录:尝试了什么 / 为何不行 / 下一步备选
- 3 条路径都失败 → 走 Phase 3 白名单第 5 条升级

### Phase 3: 打断/升级策略

**仅以下情形**暂停并提问(一条消息,说明阻塞 + 给出选项;用户答复后静默继续):

1. **不可逆破坏性操作**:如 `rm -rf` 未版本化数据、删除用户数据文件、`git reset --hard` 丢弃未提交工作、强推覆盖远程等。
   - **例外**:版本迭代中批量删除旧文件 → 先 `git add` + `git commit`(或归档)存档,再删除,**不打断**。
2. **缺凭据/密钥**:需要 API key/密码/令牌但环境中没有 → 询问,禁止猜测、硬编码进代码/仓库。
3. **真实金钱/账号操作**:付款、购买、注册、开通外部服务等。
4. **目标根本不可达/方向冲突**:成功标准自相矛盾,或目标在现实约束下完全无法推进 → 询问是否调整方向/范围。
5. **反复碰壁**:同一阻塞已穷尽 ≥3 条不同路径仍失败 → 报告一次(附已尝试方案 + 建议下一步 + 待决问题),等指示。

除此之外**绝不打扰**:不中途汇报进度、不问"要不要继续"、不请求批准。

### Phase 4: 完成判定

1. **最终验证**:重跑验证命令,确认产出物存在且非空;逐条对照 `success_criteria`
2. 补全报告「验证与测试结果」和「最终总结」(目标 / 关键结果 / 遗留问题 / 报告路径)
3. `STATE_FILE` 置 `status=completed`
4. 向用户发送**一条**完成摘要(目标 / 主要成果 / 报告文件路径 / 遗留问题)

### Phase 5: 断点续跑(resume)

1. 读 `STATE_FILE` 与 `REPORT_FILE`,恢复上下文
2. **先核对磁盘真实状态**(`git status`、文件是否存在、输出/产物是否已生成、进程是否在跑),**再**决定从哪继续——绝不基于过期假设
3. 从 `next_action` 续;若中断发生在"写一半/跑到一半"的步骤,先重做该步骤
4. 在报告追加一行:`已从断点恢复(<时间>),下一步: <next_action>`
5. 回到 Phase 2 循环

## 工作报告模板

```markdown
### OpenCode工作报告 202608271902

## 目标
<目标描述>

## 约束与成功标准
- 约束: <环境/资源/时间等限制>
- 成功标准:
  - [ ] <可验证的标准 1>
  - [ ] <可验证的标准 2>

## 执行计划
- [ ] 任务 1 …
- [ ] 任务 2 …

## 进度日志
| 时间 | 任务 | 结果 |
|---|---|---|

## 遇到的问题与解决方案
### <问题标题>
- 现象:
- 已尝试路径:
  1. …
  2. …
  3. …
- 解决 / 待解决:
- 备选方案:

## 验证与测试结果

## 最终总结
```

## 关键规则

- **不打扰原则**:除 Phase 3 白名单外,全程自主,不问任何"要不要/是否可以/继续吗"
- **诚实记录**:失败、负结果、卡点必须如实写入报告;禁止编造测试结果、运行输出或"看起来成功"的假象
- **穷尽再升级**:阻塞先走 ≥3 条不同路径,不轻易放弃;每条失败都留档备选
- **强制落盘**:每个任务完成、每条重要日志写入后,立即刷新 `STATE_FILE` 与报告——断电/断网/输出上限最多丢失当前一步
- **断点自愈**:若因 LLM 输出上限、网络中断、会话结束等中断,用户再次以 resume 意图触发即可从检查点复原
- **大文件写入**:文件写入工具失败时,改用 shell heredoc(`cat << 'EOF' > file`)分块写入,不询问
- **文档与注释**:产出代码附必要注释/文档字符串;文档按需更新并记入报告
- **凭据安全**:密钥只经环境变量或询问获得,绝不写入代码或提交仓库
- **环境优先**:动手前先读项目约定文件(如 `AGENTS.md`);无测试套件时用示例脚本/运行命令做验证
- **诚实停止**:所有路径穷尽必须等待用户时,把"待办 / 已尝试 / 建议"写清再打断,不让工作假死