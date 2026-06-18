---
name: teambition-commit
description: 自动化"代码提交 + Teambition 任务流转"研发闭环。分析暂存变更、按业务意图拆分提交、在 Teambition 定位或创建子任务、生成带任务号的规范 commit、提交并推送后回写任务状态与代码链接。当用户要求"提交代码并更新 Teambition""跑研发闭环""关联任务卡片提交"时使用。
---

# Teambition 研发闭环提交

打通本地 Git 与 Teambition：让每次实质性代码变更都可追溯到任务卡片，并自动推进任务状态，实现端到端溯源。

## 前置配置

- **提交规范（权威来源）**：本目录下的 [COMMIT_CONVENTION.md](COMMIT_CONVENTION.md) 随 skill 分发，是 commit 格式的**权威依据**，提交前必须读取并**严格遵循**。Step 3 内置了其要点；如需调整规范，直接改该文件即可。
- **Teambition MCP**：需已接入 Teambition MCP（官方托管 HTTP MCP，配置见项目 README「一步接入」），提供 `GetUsersMe`、`SearchUserTasksV3`、`SearchProjectTasksV3`、`CreateTaskV3`、`SearchTaskflowNodes`、`UpdateTaskStatusV3`、`QueryTaskV3`、`CreateTaskLinkV3` 等工具。

## 工作流

逐阶段执行；关键节点按下述要求向用户求证。

### Step 0 预检与拆分

1. 执行 `git status -s`，必要时配合 `git diff` 探测变更。
2. 对变更做意图聚类。**禁止无脑 `git add .`**：评估是否包含多个独立业务意图（如同时含 Bug 修复与新功能）。
3. 分批触发：
   - **单一意图** → `git add .` 后进入 Step 1，不打断用户。
   - **≥2 个独立意图** → 主动暂停，输出文件级拆分方案并请用户确认：“探测到混合提交，建议拆为 N 次独立 Commit，是否确认？” 确认后逐意图 `git add <files>`，每批走完整 Step 1–4，循环至工作区清空。不提供合并提交降级方案。

### Step 1 提取变更上下文

1. `git branch --show-current`，从分支名提取任务编号特征（如 `PRJ-4432`）作为搜索词。
2. `git diff --cached` 获取本批已暂存改动；变更过大时改用 `git diff --stat` 防文本过载。
3. 产出：①≤50 字的「动作意图文案」（仅描述本批变更）；②业务名词组成的「搜索检索词」。

### Step 2 定位或创建任务（子任务为最小挂载单元）

1. 采集环境：调用 `GetUsersMe` 取 `userId` 作 `executorId`；调用 `SearchProjectTasksV3` 取同项目任务，提取“需求分类”等必填自定义字段模板（`cfId` 及深层 `value`）。
2. 用搜索词在用户参与/执行域调用 `SearchUserTasksV3` 查主任务。
3. **命中主任务** → 不直接使用主任务，调用 `CreateTaskV3` 在其下新建子任务（`parentTaskId`=主任务，标题=动作意图文案，填执行者与需求分类），取子任务 ShortId。
4. **未命中** → 构建“主任务 → 子任务”树：先建主任务（标题=分支名/功能概括，无 `parentTaskId`），再建子任务，取子任务 ShortId。
5. 自定义字段报 `Custom fields is invalid` → 降级为不带字段创建，结束后提示用户到 Web 端补填，不中断流程。

详细 MCP 调用序列与容错见 [reference.md](reference.md)。

### Step 3 组装规范 commit（严格遵循 COMMIT_CONVENTION.md）

**标准格式**：`[Type] 简要描述 #<任务类型>-<ShortId>`

1. **[Type]**：按本批变更性质从枚举选择，首字母大写：
   `[Feat]` 新功能 ｜ `[Fix]` 修 Bug ｜ `[Hotfix]` 生产紧急修复 ｜ `[Refactor]` 重构 ｜ `[Perf]` 性能优化 ｜ `[Style]` 代码格式 ｜ `[Docs]` 文档 ｜ `[Chore]` 杂务/构建/依赖 ｜ `[Test]` 测试 ｜ `[Revert]` 回滚。
2. **简要描述**：一句话说清"改了什么"，≤50 字。禁止 `fix bug`、`优化`、`提交一下` 等无信息描述。
3. **#任务ID**：必须带 `#`。前缀与 Step 2 子任务在 Teambition 的实际类型一致（需求/任务 → `Task`，缺陷/Bug → `Bug`），拼为 `#Task-<ShortId>` 或 `#Bug-<ShortId>`。
4. 示例：
   - `[Feat] 新增会员积分兑换接口 #Task-1024`
   - `[Fix] 修复优惠券核销失败的逻辑漏洞 #Bug-886`
   - `[Perf] 优化会员查询SQL并加索引，耗时降50% #Task-601`

类型选择细则与正反例见 [reference.md](reference.md)。组装后直接 `git commit`，无需二次确认；**不得跳过 Git 钩子**（除非用户明确要求）。

### Step 4 提交后闭环

1. 执行 `git commit -m "<正文>"`。
2. 流转任务：调用 `SearchTaskflowNodes` 取 `taskflowstatusId`（遇 `AuthBaseError` 降级从兄弟卡抓取 `tfsId`）→ 调用 `UpdateTaskStatusV3` 推进子任务状态。若主任务进入“完成”态，调用 `QueryTaskV3` 拉取其全部子任务并级联更新为完成（控制请求频率防限流）。
3. 执行 `git push`，解析输出构造提交在代码仓（Codeup / GitLab 等）的 Web URL，调用 `CreateTaskLinkV3` 回写到对应子任务卡片，完成端到端溯源。
