# 分步落地计划：Codex CLI 双闭环（从 0 到可用）

## Summary
你可以按 6 个阶段实施，先打通“能跑通”，再加“质量门禁”。  
核心原则：先闭环 A（计划评审）再闭环 B（代码执行评审），每阶段都有明确验收点，避免一次性做太大。

## 0) 前置准备（半天）
目标：把“运行入口、目录、权限”先统一。

1. 创建目录约定
- `docs/requirements/`
- `docs/ui/`
- `plans/<ticket_id>/`
- `scripts/codex/`
- `.github/workflows/`

2. 统一脚本入口（先占位也行）
- `npm run lint`
- `npm run test`
- `npm run build`
- `npm run verify`（串联 lint/test/build）

3. GitHub 令牌与权限
- 需要 `contents:write`, `pull_requests:write`, `issues:read`
- 工作流里确认 `permissions` 字段配置

验收标准
- 本地能执行 `npm run verify`（先允许 test 占位）
- 仓库目录结构已创建

---

## 1) 实现闭环 A 最小可用版（1 天）
目标：需求/UI -> `plan.md` -> `plan/<ticket-id>` PR -> 评论反馈 -> 再生成计划。

1. 新增 workflow：`codex-plan-loop.yml`
触发：
- `workflow_dispatch`（输入 `ticket_id`, `requirements_path`, `ui_path`）
- `issue_comment`（评论含 `/codex-plan`）

2. 新增脚本：`scripts/codex/generate_plan.sh`
输入：
- `ticket_id`, `requirements_path`, `ui_path`, `review_feedback.txt`
输出：
- `plans/<ticket_id>/plan.md`
- `plans/<ticket_id>/plan_history/plan_<timestamp>.md`

3. PR 自动化
- 分支：`plan/<ticket_id>`
- 自动创建/更新 PR
- 自动贴说明评论：如何继续迭代（`/codex-plan`）

4. 反馈迭代
- 从 PR comments / review comments 拉取文本
- 合并后喂给 Codex 再生成 `plan.md`（覆盖）  
- 可选：同时生成 `plan_v2.md`（建议先不做，先覆盖+历史归档）

验收标准
- 首次触发能自动建 PR 且包含 `plan.md`
- 评论 `/codex-plan` 后计划会更新并产生新 commit

---

## 2) 给闭环 A 加“批准门禁”（半天）
目标：只有计划批准才能进入实施闭环。

1. 状态标签
- `plan-review`
- `plan-approved`

2. 批准判定（二选一，建议先标签）
- 方案 A（推荐）：PR 带 `plan-approved` label
- 方案 B：required review ≥ 1 Approve

3. Gate 脚本
- `scripts/codex/check_plan_gate.sh`
- 在闭环 B 启动前执行，未通过则 fail fast

验收标准
- 未批准时执行闭环 B 会被拒绝并给出原因
- 批准后闭环 B 可启动

---

## 3) 实现闭环 B 最小可用版（1~2 天）
目标：按 plan 改代码 + 自动测试 + 提交 PR + 可迭代。

1. 新增 workflow：`codex-implement-loop.yml`
触发：
- `workflow_dispatch`（`ticket_id`）
- `issue_comment`（评论含 `/codex-impl`）

2. 新增执行脚本：`scripts/codex/execute_plan.sh`
输入：
- `plans/<ticket_id>/plan.md`
- 评论反馈（可选）
输出：
- 代码改动
- `plans/<ticket_id>/execution_report.md`

3. 自动测试生成脚本：`scripts/codex/generate_tests.sh`
策略：
- 先单测
- 再关键链路集成测试
- 最后 1~2 条 e2e smoke（可先占位）

4. 自动验证与重试
- 执行 `npm run verify`
- 失败则调用 Codex 修复并重跑（最多 2 次）
- 仍失败则输出错误报告并退出

5. PR 自动化
- 分支：`feat/<ticket_id>`
- 自动创建/更新 PR
- 评论提示：用 `/codex-impl` 继续迭代

验收标准
- 一次闭环可完成：读 plan -> 改代码 -> 跑 verify -> 提交 PR
- 失败时能自动重试并保留日志报告

---

## 4) 计划微调机制（plan_delta）接入（半天）
目标：代码审阅后，不是盲改，而是“先更新计划差异再改”。

1. 新增脚本：`scripts/codex/update_plan_delta.sh`
输入：
- 新 review 评论 + 当前 `plan.md`
输出：
- `plans/<ticket_id>/plan_delta.md`

2. 执行顺序强制
- `/codex-impl` 触发时先更新 `plan_delta.md`
- 再按 `plan + delta` 实施改动

3. 报告关联
- `execution_report.md` 增加字段：
  - 本次引用的 review comment ids
  - 对应 commit sha
  - 影响的 plan 条目

验收标准
- 每次代码迭代前都有新的或更新后的 `plan_delta.md`
- report 能追溯“哪个意见导致了哪些改动”

---

## 5) CI 与主分支保护（半天）
目标：形成“必须经过双闭环”的正式流程。

1. Branch Protection（`main`）
- 必须通过：`verify`、`plan-gate`、`impl-gate`
- 必须至少 1 个审阅通过

2. 合并条件
- `plan-approved`
- `code-approved`
- CI 全绿

3. 安全约束
- 仅仓库成员评论 slash command 生效
- 仅在对应 PR 上下文执行命令

验收标准
- 不满足任一门禁时无法合并
- 满足后可正常合并

---

## 6) 运行手册（你团队实际使用步骤）
1. 产品/开发放需求到 `docs/requirements/<ticket>.md`，UI 放 `docs/ui/<ticket>/`
2. 手动触发 `codex-plan-loop`（填 `ticket_id`）
3. 在 plan PR 上评审；有意见评论 `/codex-plan`
4. 直到加上 `plan-approved`
5. 触发 `codex-implement-loop`
6. 在实现 PR 上评审；有意见评论 `/codex-impl`
7. 直到加上 `code-approved` 且 CI 全绿
8. 合并到 `main`

---

## Important API / Interface Changes
- 新增评论命令接口：
  - `/codex-plan`
  - `/codex-impl`
- 新增状态标签接口：
  - `plan-review`, `plan-approved`, `impl-review`, `code-approved`
- 新增文档产物接口：
  - `plan.md`, `plan_history/*`, `plan_delta.md`, `execution_report.md`

---

## Test Cases & Scenarios
1. 首次计划生成：能建 `plan/<ticket_id>` PR
2. 评论驱动计划迭代：`/codex-plan` 触发新提交
3. 未批准计划时执行被阻断
4. 批准后执行能自动改代码并跑 `verify`
5. verify 首轮失败可自动修复重跑
6. 代码审阅意见触发 `plan_delta + code` 新一轮迭代
7. 满足 `code-approved + CI green` 才能合并

---

## Assumptions / Defaults
- 主分支默认 `main`
- 计划通过判定默认用 label（`plan-approved`）
- 自动修复重试默认 2 次
- `test` 初期允许占位，后续逐步补全真实用例
- 先做 GitHub 原生闭环，不接 Jira/Linear（后续可扩展）
