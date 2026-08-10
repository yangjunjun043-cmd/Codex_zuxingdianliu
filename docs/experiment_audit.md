# Phase 0 实验审计记录

## 审计范围

- 日期：2026-08-10（Asia/Shanghai）
- 工程入口：`D:\Codex\MOA_Arrester\MATLAB一键实验\run_all_patent_experiments.m`
- 工作区状态：当前目录及上级没有 `.git`，因此记录为“非 Git 工作区”，无法提供提交号或脏文件状态。
- 原始结果保护：未在原工程中运行会覆盖 `results/` 的基线命令；未修改代码的副本运行于 `artifacts/phase0_baseline_run/`。

## 执行环境

| 项目 | 版本/值 |
|---|---|
| MATLAB | 23.2.0.2365128 (R2023b) |
| Simulink | 23.2 |
| Simscape Electrical | 23.2 |
| Stateflow | 23.2 |
| MATLAB Test | 23.2 |
| 基准模型 | `AI6109_MOA_AutoComp7.slx` |
| AutoComp7 SHA-256 | `7BBBB729FF91F457D8A9B221055B69123588E6EE28CAF93DE2613B3FF9974CD1` |

MATLAB 在受限沙箱内启动时，其 DDUX 日志服务发生 `abort()`。实际实验在用户批准的沙箱外 MATLAB 批处理中运行，`MATLAB_PREFDIR` 指向工程内独立目录；未更改系统 `HOME`。

## Phase 0 执行命令

```powershell
matlab -batch "run_all_patent_experiments"
matlab -batch "run_patent_robustness_sweep"
```

第一条命令在外层工具超时后失去输出通道，但动态实验已完成。随后终止该任务创建的残留 MATLAB 进程，并单独运行鲁棒性入口；两部分最终均成功。所有基线输出均位于隔离副本的 `results/`。

## 修改前动态基线

以下为 CVFF-RLS 的关键值：

| 场景 | Cs1 MaxErr / pF | Cs2 MaxErr / pF | B 相基波误差 / % |
|---|---:|---:|---:|
| 固定耦合基准 | 0.13524 | 0.10613 | -0.029800 |
| 缓慢漂移 | 3.9726 | 3.0397 | 0.32467 |
| 平滑阶跃 | 5.0057 | 4.0031 | 0.14364 |
| 随机波动 | 0.93187 | 0.73387 | -0.12368 |
| 阻性故障与漂移 | 2.9712 | 1.9681 | -0.32494 |

故障真值增幅为 `1.6000`，CVFF-RLS 估计为 `1.5770`，保持误差为 `-1.4369%`。

修改前单 seed 鲁棒性基线中，B 相基波误差为：无噪声 `0.50475%`、40 dB `0.51609%`、30 dB `0.48139%`、20 dB `0.36514%`。负序 1%/3%/5% 时分别为 `11.193%`、`35.030%`、`61.991%`。

## 基线告警与边界

- 所有 Simulink 运行均成功，但模型稳定报告 1 个代数环，涉及三个 MOA MATLAB Function、powergui 等效状态空间和电压测量块。
- Phase 0 动态总泄漏电流仍由 `synthesize_dynamic_case.m` 在 MATLAB 中合成，不是完整 Simulink 动态耦合证据。
- 参考仍直接来自真实 `ub`；单 B 相参考在负序不平衡下存在已确认的不可观测性边界。
- 原工程 `results/` 的文件时间戳仍为 2026-08-06，本轮未覆盖。
