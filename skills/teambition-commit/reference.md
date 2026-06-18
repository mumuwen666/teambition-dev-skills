# teambition-commit 参考：MCP 调用与容错细节

本文件为 SKILL.md 的补充，仅在执行中需要确认具体调用方式或处理异常时阅读。

## 涉及的 Teambition MCP 工具

| 用途 | 工具 | 关键入参 | 取值 |
|---|---|---|---|
| 取当前用户 | `GetUsersMe` | - | `userId`（用作 `executorId`） |
| 取项目字段模板 | `SearchProjectTasksV3` | 项目内任一有效任务 | 必填自定义字段 `customfields`（`cfId` + 深层 `value`） |
| 查用户任务 | `SearchUserTasksV3` | 搜索词、`roleTypes` | 候选主任务 |
| 建任务/子任务 | `CreateTaskV3` | `parentTaskId`、标题、`executorId`、`customfields` | 新任务 ShortId |
| 取流转节点 | `SearchTaskflowNodes` | 任务/项目 | `taskflowstatusId` |
| 更新状态 | `UpdateTaskStatusV3` | 任务 id、`taskflowstatusId` | - |
| 拉子任务 | `QueryTaskV3` | 主任务 id | 子任务列表 |
| 回写链接 | `CreateTaskLinkV3` | 子任务 id、URL、`subType` | - |

> 工具名称与入参以实际接入的 Teambition MCP 服务为准。

## 自定义字段容错

- 创建任务挂载“需求分类”等字段时若返回 `Custom fields is invalid`：
  1. 立即降级为**不带 `customfields`** 重新创建，保证任务先建成功。
  2. 流程结束后提示用户到 Teambition Web 端手动补填缺失字段。
  3. 不得因字段问题中断整个闭环。

## 流转节点取值容错

- `searchTaskflowNodes` 遇 `AuthBaseError`（权限不足）时，降级方案：从同项目“兄弟任务卡”读取其 `tfsId` / `taskflowstatusId` 复用。
- 切勿向 `updateTaskStatusV3` 直接传状态名文本，必须使用底层散列 id。

## 级联闭环注意事项

- 主任务置为“完成”时，需 `QueryTaskV3` 拉取其名下所有子任务，循环调用 `UpdateTaskStatusV3` 批量置完成。
- 批量更新时控制请求频率（如串行 + 短间隔），避免触发接口限流。

## 提交规范（严格遵循 COMMIT_CONVENTION.md）

本目录随 skill 分发的 [COMMIT_CONVENTION.md](COMMIT_CONVENTION.md) 为权威来源；其完整内容即下述格式，提交时严格遵循：

**格式**：`[Type] 简要描述 #Teambition-ID`

### Type 枚举与场景

| Type | 含义 | 应用场景 | 对应 TB 任务类型 |
|---|---|---|---|
| `[Feat]` | 新功能 | 新增 API/页面；现有功能逻辑变更（如改积分计算规则） | 需求 / 任务 |
| `[Fix]` | 修 Bug | 空指针、样式错位、逻辑漏洞、测试阶段发现的问题 | 缺陷 / Bug |
| `[Hotfix]` | 紧急热修复 | 生产环境紧急故障，通常直接合入 Master/Release | 严重/致命缺陷 |
| `[Refactor]` | 重构 | 提取公共方法、封装组件、重命名；不改业务也不修 Bug | 任务（技术债） |
| `[Perf]` | 性能优化 | 优化 SQL、首屏加载、资源压缩、内存泄漏 | 任务 / 缺陷 |
| `[Style]` | 代码格式 | 缩进/空格/换行/分号、删多余空行；非 CSS 样式 | 通常不关联任务 |
| `[Docs]` | 文档 | README、代码注释、Swagger API 文档 | 任务 |
| `[Chore]` | 杂务/构建 | `.gitignore`、依赖升级、构建配置（Maven/Webpack 等） | 通常不关联任务 |
| `[Test]` | 测试 | 新增/修复单测、测试用例 | 任务 |
| `[Revert]` | 回滚 | 撤销某次提交 | 视情况而定 |

### ID 前缀

- `#` 必填，工具据此识别关联。
- 前缀对应 Teambition 任务类型：需求/任务 → `#Task-<ShortId>`；缺陷 → `#Bug-<ShortId>`。

### 正反例（Do / Don't）

- ❌ `提交一下` / `bug fix` / `[Fix] fix bug` / `优化`
- ✅ `[Feat] 新增食集卡列表页前端布局及样式 #Task-592`
- ✅ `[Fix] 修复会员积分扣减逻辑导致显示负数的问题 #Bug-886`
- ✅ `[Perf] 优化会员查询 SQL，增加索引，耗时降低 50% #Task-601`

> 不得使用 `--no-verify` 等方式跳过 Git 钩子，除非用户明确要求。
