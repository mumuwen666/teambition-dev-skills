# Teambition Dev Skills

> 一套面向 AI 编码代理（Cursor / Codex / Claude Code 等支持 Agent Skills 的工具）的 **Teambition 研发提效技能包**。把"本地 Git 提交"与"Teambition 任务协同"打通，消除项目管理与代码仓库之间的数据孤岛。
>
> A set of Agent Skills that bridge local Git workflow with Teambition task management. Auto-link every commit to a task card, advance task status, and generate work dashboards — all driven by your AI coding agent.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 这是什么 / What

两个聚焦、可独立使用的 Skill：

| Skill | 作用 | 触发示例 |
|---|---|---|
| **teambition-commit** | 分析暂存变更 → 按业务意图拆分提交 → 在 Teambition 定位/创建子任务 → 生成带任务号的规范 commit → 提交推送后回写任务状态与代码链接 | “提交代码并更新 Teambition”、“跑一下研发闭环” |
| **teambition-dashboard** | 按时间范围检索个人任务 → 按项目/状态分类 → 生成 Markdown 工作看板 | “生成本周工作看板”、“整理最近三天的任务” |


## 依赖 / Requirements

1. 一个支持 **Agent Skills** 的 AI 编码代理（Cursor、Codex CLI、Claude Code 等）。
2. **Teambition MCP**（官方托管的 HTTP MCP，无需本地安装，见下方「一步接入」）。
3. 本地具备 `git` 与终端命令执行能力。

## 一步接入 Teambition MCP / Connect Teambition MCP

Teambition 提供**官方托管的 HTTP MCP**，无需 `npx`、无需起本地进程，只要在代理的 MCP 配置里加一段、填上你的 `userToken` 即可。

1. 在 [Teambition 开放平台](https://open.teambition.com/docs/documents/68ad49a3f7d70fb6fb33f272) 获取你的 **userToken**。
2. 把 [`mcp.json.example`](mcp.json.example) 的内容合并进你的 MCP 配置文件，替换 `<YOUR_TEAMBITION_USER_TOKEN>`：
   - Cursor：`~/.cursor/mcp.json`（全局）或项目内 `.cursor/mcp.json`
   - 其他代理：对应的 MCP 配置文件

```json
{
  "mcpServers": {
    "teambition-mcp": {
      "type": "http",
      "url": "https://open.teambition.com/api/mcp?userToken=<YOUR_TEAMBITION_USER_TOKEN>"
    }
  }
}
```

3. 重启/重载代理，确认 `teambition-mcp` 已连接，即可触发 skill。

> ⚠️ `userToken` 是私密凭证，等同账号访问权限。请勿提交到仓库或分享；`mcp.json.example` 仅为模板，真实 token 只填到本地配置。
>
> 该 MCP 提供 `GetUsersMe`、`SearchUserTasksV3`、`SearchProjectTasksV3`、`CreateTaskV3`、`SearchTaskflowNodes`、`UpdateTaskStatusV3`、`QueryTaskV3`、`CreateTaskLinkV3` 等工具，供本 skill 调用。

## 安装 / Install

将 `skills/` 下的技能目录复制（或软链）到你的代理技能目录：

```bash
# Cursor（项目级）
cp -r skills/* .cursor/skills/

# Codex / 通用 .agent 约定（项目级）
cp -r skills/* .agent/skills/

# 仅安装提交闭环
cp -r skills/teambition-commit .cursor/skills/
```

或使用脚本一键安装到指定目录：

```bash
./install.sh .cursor/skills        # 或 .agent/skills
```

## 配置 / Configure

**提交格式**由 `teambition-commit/COMMIT_CONVENTION.md` 定义——该文件随 skill 一起分发，安装后必然存在，**不依赖宿主仓库**。格式：`[Type] 简要描述 #<任务类型>-<ShortId>`：

- 示例：`[Feat] 新增积分兑换接口 #Task-1024`、`[Fix] 修复核销漏洞 #Bug-886`。
- Type 枚举：`[Feat] [Fix] [Hotfix] [Refactor] [Perf] [Style] [Docs] [Chore] [Test] [Revert]`。
- ID 前缀按 Teambition 任务类型派生：需求/任务 → `Task-`，缺陷 → `Bug-`。

**自定义规范**：直接编辑 `teambition-commit/COMMIT_CONVENTION.md` 即可（如改 Type 枚举、改用固定项目前缀 `MYVH-585` 等），skill 会以该文件为准。

## 用法 / Usage

在已安装技能的代理里，直接用自然语言触发：

```
你：帮我提交代码并更新 Teambition
代理：[git status -s → 意图聚类 → 定位/创建子任务 → git commit → 流转状态 → git push → 回写链接]

你：生成一份本周工作看板
代理：[检索本周任务 → 分类 → 输出 work_dashboard_YYYYMMDD.md]
```

## 工作原理 / How it works

```
本地 Git 变更
   │  git status / diff --cached
   ▼
意图聚类（多意图则拆分提交）
   │
   ▼
Teambition 定位/创建子任务（子任务=最小挂载单元）
   │  GetUsersMe / SearchUserTasksV3 / CreateTaskV3
   ▼
组装规范 commit（[Type] 描述 #Task-ShortId）→ git commit
   │
   ▼
流转任务状态（含主子级联）→ git push → 回写 Commit 链接
   updateTaskStatusV3 / createTaskLinkV3
```

详见各 skill 的 `SKILL.md` 与 `teambition-commit/reference.md`。

## 目录结构 / Layout

```
teambition-dev-skills/
├── README.md
├── LICENSE
├── install.sh
├── mcp.json.example       # Teambition MCP 一步接入模板
└── skills/
    ├── teambition-commit/
    │   ├── SKILL.md               # 提交闭环主流程
    │   ├── COMMIT_CONVENTION.md   # 提交规范（随 skill 分发，权威来源）
    │   └── reference.md           # MCP 调用与容错细节
    └── teambition-dashboard/
        └── SKILL.md        # 工作看板
```

## 贡献 / Contributing

欢迎 Issue / PR。新增能力时请遵循"单一职责 + 精简祈使句 + 渐进式披露（细节下沉到 reference.md）"的 skill 编写原则。

## License

[MIT](LICENSE)
