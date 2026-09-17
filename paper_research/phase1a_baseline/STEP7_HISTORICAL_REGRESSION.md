# Phase 1A Step 7 — Formal Historical Regression Verification

执行日期：2026-09-17
最终结论：`STEP7_HISTORICAL_REGRESSION = PASS`

## 1. 输入与完整性

本步骤没有运行 Simulink、算法或 baseline runner。正式值只读取：

```text
paper_research/phase1a_baseline/baseline_summary.csv
```

SHA-256：

```text
E7BEB3ECFEDF521105B67198684752BB32AFAAEFD84ACA80822BA57FBD9D0AB3
```

历史值和容差只读取：

```text
MATLAB一键实验/phase1a_historical_reference.m
```

该 reference 的历史来源为：

```text
results_phase2/phase2_key_metrics.csv
results_phase2/fault_retention.csv
results_phase2/gating_ablation/cs_parameter_change.csv
results_phase2/gating_ablation/fault_retention_summary.csv
```

未读取 `step5_smoke_workspace.mat` 作为正式数值来源。

## 2. 冻结容差与判据

```text
absolute tolerance = 1e-9
relative tolerance = 1e-8

pass = abs(formal-historical)
       <= absoluteTolerance + relativeTolerance*abs(historical)
```

relative difference 定义为：

```text
abs(formal-historical) / (abs(historical)+eps)
```

没有修改容差、评价窗口、CSV 或历史 reference。

## 3. Case02 正式回归

| case_name | algorithm_mode | metric_name | historical_value | formal_baseline_value | absolute_difference | relative_difference | absTol | relTol | pass |
|---|---|---|---:|---:|---:|---:|---:|---:|---|
| Case02_slow_drift | M0 | B_resistive_fundamental_error_pct | 8.9587533463069 | 8.9587533463069 | 0 | 0 | 1e-9 | 1e-8 | PASS |
| Case02_slow_drift | M3 | B_resistive_fundamental_error_pct | 0.354785857594943 | 0.354785857594943 | 0 | 0 | 1e-9 | 1e-8 | PASS |
| Case02_slow_drift | M3 | Cs1_RMSE_pF | 0.157320251866564 | 0.157320251866564 | 0 | 0 | 1e-9 | 1e-8 | PASS |
| Case02_slow_drift | M3 | Cs2_RMSE_pF | 0.108513587962671 | 0.108513587962671 | 0 | 0 | 1e-9 | 1e-8 | PASS |

```text
Case02 = 4 / 4 PASS
```

## 4. Case06 正式回归

| case_name | algorithm_mode | metric_name | historical_value | formal_baseline_value | absolute_difference | relative_difference | absTol | relTol | pass |
|---|---|---|---:|---:|---:|---:|---:|---:|---|
| Case06_drift_then_fault | TRUTH | fault_factor_true | 1.59999999999967 | 1.59999999999967 | 0 | 0 | 1e-9 | 1e-8 | PASS |
| Case06_drift_then_fault | M2 | Cs1_pre_post_change_pF | 5.00627092717497 | 5.00627092717497 | 0 | 0 | 1e-9 | 1e-8 | PASS |
| Case06_drift_then_fault | M2 | Cs2_pre_post_change_pF | -4.97734794650682 | -4.97734794650682 | 0 | 0 | 1e-9 | 1e-8 | PASS |
| Case06_drift_then_fault | M2 | fault_factor_est | 1.40226869710244 | 1.40226869710244 | 0 | 0 | 1e-9 | 1e-8 | PASS |
| Case06_drift_then_fault | M3 | Cs1_pre_post_change_pF | 0.561114929229058 | 0.561114929229058 | 0 | 0 | 1e-9 | 1e-8 | PASS |
| Case06_drift_then_fault | M3 | Cs2_pre_post_change_pF | -0.616252631092842 | -0.616252631092842 | 0 | 0 | 1e-9 | 1e-8 | PASS |
| Case06_drift_then_fault | M3 | fault_factor_est | 1.58287648629316 | 1.58287648629316 | 0 | 0 | 1e-9 | 1e-8 | PASS |

```text
Case06 = 7 / 7 PASS
```

## 5. 总结

| 分组 | 通过 | 总数 | 结果 |
|---|---:|---:|---|
| Case02 | 4 | 4 | PASS |
| Case06 | 7 | 7 | PASS |
| Total | 11 | 11 | PASS |

```text
historical_results_reproduced = true
STEP7_HISTORICAL_REGRESSION = PASS
```

统一正式 baseline 成功保持了 Case02 慢漂移与 Case06 漂移后故障的全部冻结历史关键
证据。Step 7 通过阶段闸门，允许继续使用同一正式 CSV/MAT 完成 Step 8；本报告不包含
任何新算法、调参、模型重跑或 Phase 1B 机理结论。
