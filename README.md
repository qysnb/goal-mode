# goal-mode — opencode 自主目标执行模式

一个 opencode skill:设定一个目标后,**agent 一口气自主执行到达成**——拆任务、写代码、运行、验证、写文档/注释,全程记录工作报告。除关键事项外**不打扰用户**,中断后自动续跑。

## 特性

- **自主执行**:目标 → 拆任务 → 实现 → 运行验证 → 记录,循环直到成功标准达成
- **工作报告**:在会话主目录生成 `###OpenCode工作报告<YYYYMMDDHHMM>.md`,进度日志/问题/方案/验证结果全程留档
- **问题留档**:每个问题记录「现象 / ≥3 条尝试路径 / 解决或待解决 / 备选方案」
- **不打扰原则**:仅对关键事项(不可逆破坏操作、缺凭据/密钥、真实金钱/账号操作、目标不可达、同一阻塞穷尽 3 条路径仍失败)询问用户;版本迭代批量删旧文件先 git 存档再删,**不打断**
- **断点自愈**:每个里程碑强制落盘检查点;因 LLM 输出上限 / 网络中断 / 会话结束中断后,`/goal-mode resume` 自动复原并先核对磁盘真实状态再续

## 安装

### 方式一:全局安装(推荐)

```bash
git clone https://github.com/qysnb/goal-mode.git
mkdir -p ~/.config/opencode/skills/goal-mode
cp goal-mode/SKILL.md ~/.config/opencode/skills/goal-mode/SKILL.md
```

Windows (PowerShell):

```powershell
git clone https://github.com/qysnb/goal-mode.git
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.config\opencode\skills\goal-mode"
Copy-Item goal-mode\SKILL.md "$env:USERPROFILE\.config\opencode\skills\goal-mode\SKILL.md"
```

### 方式二:项目级安装

放到项目的 `.opencode/skills/goal-mode/SKILL.md`,仅该仓库可用。

### 方式三:`skills.paths`(不复制,直接引用)

克隆到本地后,在 `opencode.json` 中添加:

```json
{
  "skills": {
    "paths": ["C:/path/to/goal-mode"]
  }
}
```

> 安装后**重启 opencode** 才会加载生效(配置仅在启动时读取)。

## 使用

```
/goal-mode <目标描述>     # 开始自主执行
/goal-mode resume         # 中断后从检查点续跑
```

也可以在对话中直接说:`goal mode`、`一口气做完`、`run until done`、`自主完成`、`不要打扰我直接做`。

## 产物

| 文件 | 说明 |
|---|---|
| `###OpenCode工作报告<YYYYMMDDHHMM>.md` | 工作报告(主交付物),含 目标/约束与成功标准/执行计划/进度日志/问题与解决方案/验证结果/最终总结 |
| `OPENCODE_GOAL_STATE.json` | 检查点,断点续跑依据,每个里程碑覆盖写 |

## 打断(升级)白名单

仅在以下情况 agent 会暂停并提问,其余全程静默执行:

1. 不可逆破坏性操作(如 `rm -rf` 未版本化数据、`git reset --hard` 丢弃未提交工作、强推)
2. 需要 API key / 密码 / 密钥但环境中没有
3. 真实金钱 / 账号操作(付款、购买、注册、开通服务)
4. 目标根本不可达 / 方向冲突
5. 同一阻塞已穷尽 ≥3 条不同路径仍失败(附已尝试方案 + 建议)

完成时发送一条完成摘要(目标 / 主要成果 / 报告路径 / 遗留问题)。

## License

MIT