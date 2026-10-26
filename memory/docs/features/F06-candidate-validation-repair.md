# 候选校验原因诊断与一次原地修复

日期：2026-09-22。影响范围：普通 LLM Extractor 和本地 adapter 诊断。

## 背景

Oracle 第 4 题 attempt-03 在 Add 76/148、第 6 题 attempt-02 在 Add 8/12
抛出 InvalidExtractionCandidateError。现有日志只记录异常类型，旧日志无法回溯确定
究竟哪个字段不合法。这两题最终失败不是 Windows 时间转换错误，也不能归因于 429。
第 5 题的 QA 阶段仍独立存在网关 429。

## 行为

build_candidates 为七种结构失败生成固定错误码与计数：not_object、missing_confidence、
invalid_confidence、confidence_out_of_range、source_id_not_in_batch、empty_content、
non_string_evidence。异常原文也不再包含模型提供的 source_id 值。
adapter exception_info 只采集白名单错误码与正整数计数，输出 validation_reasons。
错误正文、模型原始响应、密钥都不进入诊断。

普通 LLM 抽取在 JSON 已解析但所有候选不可用时，用相同来源、上下文与生成参数，
追加固定字段格式反馈，最多再抽取一次。该时点尚未构建派生 MemoryUnit，更未写入索引。
第二次依然执行原候选校验，失败继续上抛。显式 []、合法的低置信度过滤和部分成功
保持原行为；不把格式失败直接吞成成功，不猜测来源 ID，不替模型填置信度。
传输错误只走既有传输重试，不触发额外的候选修复；SDK/传输重试可能令实际 HTTP 次数
超过两次。无效 JSON 的既有失败行为不变，动态/schema/过程抽取不新增此修复轮。

## 比较与恢复

初次抽取提示词、原仓库 QA/judge 与评分标准未改变，错误后的修复轮会增加模型调用，
也可能改变最终抽取结果；不能把修复前后视为完全相同的记忆系统版本。
已完成的 8 题保留，失败题仍需从头写入新 scope；没有增加 Add 级 checkpoint。
并发调度与失败后停止派发的规则不变，429 仍需独立解决。
批次已有指纹未覆盖 core 与 diagnostics，另存 candidate-repair-note.json 记录变更哈希与边界。

## 验证

5 个纯函数回归测试验证修复成功、失败次数上限、部分成功/空结果不重试、传输异常隔离、
七种结构校验原因和敏感值不泄漏；用 runpy 直接执行，全部通过。
39 项 adapter unittest 通过，其中包含新增日志白名单测试以及原 QA/HTTP 接入回归。
未连接真实模型或数据库；旧运行的具体非法字段无法从已有日志恢复。
