---
name: teambition-dashboard
description: 按时间范围生成个人 Teambition 工作看板。检索指定时间段内用户参与/创建/截止的任务，按项目与状态分类，输出 Markdown 看板文件并给出汇总。当用户要求"生成本周工作看板""整理最近几天的任务""出周报/工作总结"时使用。
---

# Teambition 工作看板

按指定时间范围聚合个人任务，生成结构化工作看板，用于周报、复盘或工作总结。

## 前置配置

- **Teambition MCP**：需已接入 Teambition MCP（官方托管 HTTP MCP，配置见项目 README「一步接入」），提供 `GetUsersMe`、`SearchUserTasksV3` 工具。

## 工作流

1. **解析时间范围与身份**：明确用户诉求中的时间跨度（如“本周”“上个月”“最近三天”）；不清晰时先与用户确认。调用 `GetUsersMe` 取当前操作者身份。
2. **检索任务**：调用 `SearchUserTasksV3`，用 `roleTypes` 指定身份（如 `executor,involveMember,creator`）；配合 `tql` 过滤指定时间范围内有活动/被创建/截止的任务；注意分页，单页未取全时用 `pageToken` 翻页拉全量。
3. **结构化分类**：按“项目归属 / 当前状态（进行中、已完成、待处理）/ 优先级”等维度划分；提取每条任务的 ShortId、标题、所属项目、状态、关联链接。
4. **生成产物**：创建 Markdown 文件 `work_dashboard_YYYYMMDD.md`，以表格/列表清晰呈现；最后给用户一段简明汇总回复。
