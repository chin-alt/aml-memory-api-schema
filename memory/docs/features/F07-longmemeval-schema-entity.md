# LongMemEval HTTP Schema + 实体关联实验

日期：2026-09-22。

## 决策与边界

本工作副本在当前主链路基线之上整合用户指定的 PR #337 完整差异，
保留本地 HTTP 评测接入、Windows 时间投影修复和普通抽取错误容错。
Schema 使用 PR 提供的 `examples/entity_schema_locomo_person.json`，而非 persona.json。
原仓库 `run.main → Runner → LLMJudge` 继续执行 LongMemEval Oracle 30 题，
只更换记忆系统配置，不更换数据清单或 QA 提示词/判分。

启动器使用显式 schema-entity profile，独立进程加载此副本；ordinary profile
仍加载原 agent-memory。模式、Schema 文件、内核源码均计入批次指纹，禁止跨模式续跑。
两种模式使用相同模型、Top-200、三档 QA 和融合器，共享存储服务，以独立 scope 隔离数据。
实体反向索引显式配置 ES 后端，启动先校验，防止开关为真但缺端口时的静默降级。

Schema 抽取返回 source-only 降级、实体写入失败或实体 lookup 异常在此评测封装中
被视为失败；没有改变上游的默认容错策略。诊断记录属性单元、实体单元与扩展候选计数，
无新增模型响应正文。实体扩展仍按仓库原有条件短路，因此实际新增候选可能为零。

这是联合实验，不能单独识别 PR/Schema/实体扩展各自收益；正式收益分析应按同题配对，
并单列失败题。没有承诺消除公司网关 429。

## 验证

实验工作副本下 46 项 adapter unittest 通过，包含真实内存内核经 HTTP 的 Schema 写入、
实体关联补召回、跨用户隔离、降级失败，以及 PR 时间语义回归。外部模型与存储均用
离线替身，不连接公司网关。PowerShell 六并发计划命令验证了 30 题/409 Add/180 QA。

命令、限制、指纹升级与详细产物见 [实验说明](../../../aml-adapter/LONGMEMEVAL_EXPERIMENTS.md)。
