# Phase 1A Step 6 — Six-Case Formal Baseline Run

执行日期：2026-09-17  
最终结论：`STEP6_FORMAL_BASELINE_RUN = PASS`

## 1. Step 6A checkpoint

| 项目 | 值 |
|---|---|
| commit | `21db36134f1ff89be6d3be390a58b0afb741ac32` |
| subject | `paper: fix Phase 1A fault-only compatibility` |
| branch | `main` |
| Step 6A | 人工验收通过 |

checkpoint 包含 `fault_only` compatibility 修复、专项测试、正式 runner/validator、
Step 6A 报告和第一次失败审计报告。`step5_smoke_workspace.mat` 未提交。

## 2. 第一次 Step 6 失败与 Step 6A 修复

第一次 Step 6 在 Case05 处停止：

```text
Case05_fault_only
  -> simulate_phase2_case
  -> synthesize_dynamic_case(...,"fault_only",...)
  -> Unknown scenario fault_only
```

失败审计保存在：

```text
paper_research/phase1a_baseline/
STEP6_FORMAL_BASELINE_RUN_FAILED_ATTEMPT1.md
```

Step 6A 只为 `synthesize_dynamic_case.m` 增加缺失的 `fault_only` 接口支持：Cs1/Cs2
保持 10 pF，B 相故障继续使用 3.00–3.06 s、1.0→1.6 的冻结数学定义。专项测试
`12/12 PASS`，Case06 修改前后完整向量 SHA-256 相同。

## 3. 运行环境与 AutoComp9 integrity

| 字段 | 值 |
|---|---|
| run timestamp | `2026-09-17T10:45:57+08:00` |
| MATLAB | `23.2.0.2365128 (R2023b)` |
| Simulink | `23.2` |
| platform | `PCWIN64` |
| model | `AI6109_MOA_AutoComp9.slx` |
| model SHA-256 | `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70` |
| expected SHA-256 | 同上 |
| integrity before/after | **PASS** |
| Git commit recorded in rows | `21db36134f1ff89be6d3be390a58b0afb741ac32` |
| Git branch | `main` |
| Git dirty status | `DIRTY`，仅因未跟踪的 Step 5 workspace |

运行中仅出现 AutoComp9 已知的未连接 Current Measurement 端口和 algebraic loop 警告；
六个 case 均正常完成，没有为消除警告修改模型。

## 4. 六个正式 Case

Case 和 seed 全部来自 `phase1a_case_registry.m`：

| 顺序 | Case | legacy scenario | seed | 状态 |
|---:|---|---|---:|---|
| 1 | `Case01_static` | `static` | 101 | PASS |
| 2 | `Case02_slow_drift` | `slow_drift` | 102 | PASS |
| 3 | `Case03_smooth_step` | `smooth_step` | 103 | PASS |
| 4 | `Case04_random_drift` | `random_drift` | 104 | PASS |
| 5 | `Case05_fault_only` | `fault_only` | 106 | PASS |
| 6 | `Case06_drift_then_fault` | `fault_with_drift` | 105 | PASS |

本轮从 Case01 重新开始，所有 baseline 数据来自 Step 6A checkpoint 后的同一代码状态。

## 5. 调用次数与算法公平性

```text
case-level simulate_phase2_case calls = 6
successful low-level sim(in) calls   = 12
```

每个 case 只调用一次 `simulate_phase2_case`。冻结 helper 内部依次运行一次 zero-noise
和一次 noisy AutoComp9。正式 noisy data 返回后，M0/M2/M3 共用同一份
`data/ref/cfg`，没有按算法重新运行模型。

## 6. 18 行 baseline 完整性

| 检查 | 结果 |
|---|---:|
| rows | 18 |
| unique cases | 6 |
| unique algorithms | 3 |
| unique case × algorithm pairs | 18 |
| rows per case | 3 |
| rows per algorithm | 6 |
| duplicate/missing pairs | 0 |

## 7. Case × Algorithm 关键结果

单位：Cs RMSE 和 ΔCs 为 pF；B fundamental error、retention error 为 %；gate time 为 s。

| Case | Mode | Cs1 RMSE | Cs2 RMSE | B fund. error | true factor | est. factor | retention error | ΔCs1 | ΔCs2 | first gate | gate cycles |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Case01 | M0 | 0.0199495 | 0.0501155 | 0.0528195 | — | — | — | — | — | — | — |
| Case01 | M2 | 0.0403700 | 0.0392950 | -0.0356104 | — | — | — | — | — | — | — |
| Case01 | M3 | 0.0403700 | 0.0392950 | -0.0356104 | — | — | — | — | — | — | — |
| Case02 | M0 | 2.9437880 | 2.2135827 | 8.9587533 | — | — | — | — | — | — | — |
| Case02 | M2 | 0.1573203 | 0.1085136 | 0.3547859 | — | — | — | — | — | — | — |
| Case02 | M3 | 0.1573203 | 0.1085136 | 0.3547859 | — | — | — | — | — | — | — |
| Case03 | M0 | 4.3031645 | 3.4843264 | 14.0220462 | — | — | — | — | — | — | — |
| Case03 | M2 | 0.2297934 | 0.1800564 | 0.1641919 | — | — | — | — | — | — | — |
| Case03 | M3 | 0.2297934 | 0.1800564 | 0.1641919 | — | — | — | — | — | — | — |
| Case04 | M0 | 1.1637680 | 0.9823113 | -1.3540312 | — | — | — | — | — | — | — |
| Case04 | M2 | 0.2692849 | 0.2098954 | -0.0876052 | — | — | — | — | — | — | — |
| Case04 | M3 | 0.2692849 | 0.2098954 | -0.0876052 | — | — | — | — | — | — | — |
| Case05 | M0 | 0.0257478 | 0.0608465 | -0.1319936 | 1.6000000 | 1.6045753 | 0.2859590 | 0.0000000 | 0.0000000 | — | — |
| Case05 | M2 | 2.6007977 | 2.5909658 | -4.8375879 | 1.6000000 | 1.4010748 | -12.4328252 | 4.9167737 | -4.9569945 | — | — |
| Case05 | M3 | 0.2665636 | 0.3160356 | -0.4986047 | 1.6000000 | 1.5811371 | -1.1789305 | 0.4575192 | -0.6182875 | 3.05998 | 48 |
| Case06 | M0 | 2.5794845 | 1.6832530 | 6.7818402 | 1.6000000 | 1.5510738 | -3.0578905 | 0.0000000 | 0.0000000 | — | — |
| Case06 | M2 | 2.6151618 | 2.5998580 | -4.6566030 | 1.6000000 | 1.4022687 | -12.3582064 | 5.0062709 | -4.9773479 | — | — |
| Case06 | M3 | 0.3152579 | 0.3280664 | -0.3101628 | 1.6000000 | 1.5828765 | -1.0702196 | 0.5611149 | -0.6162526 | 3.05998 | 48 |

M0 的 ΔCs 数值为约 `1e-13 pF`，表中按显示精度写为 0；CSV 保留完整浮点值。

## 8. Schema 检查

`baseline_summary.csv` 共 20 个字段，名称、顺序和 MATLAB 类型均与
`phase1a_result_schema.m` 完全一致：

```text
case_name
algorithm_mode
Cs1_RMSE_pF
Cs2_RMSE_pF
B_resistive_fundamental_error_pct
fault_factor_true
fault_factor_est
fault_retention_error_pct
Cs1_pre_post_change_pF
Cs2_pre_post_change_pF
first_gate_trigger_s
gate_duration_cycles
gate_duration_s
random_seed
model_file
model_sha256
run_timestamp
git_commit
git_branch
git_dirty_status
```

validator：`Frozen schema exact = PASS`。

## 9. NaN 与 numeric sanity

- Case01–Case04 的五个故障指标均为 NaN；
- M0/M2 的三个 gate 指标均为 NaN；
- 未触发真实 gate 的 M3 行三个 gate 指标均为 NaN；
- Case05/06 M3 使用真实 tracker log：first gate `3.05998 s`、48 cycles、`0.96 s`；
- 没有用 0 代替“不适用”；
- 216 个 numeric cells 已检查；
- 不存在 Inf、-Inf 或 complex；
- 所有非适用之外的 NaN 均不存在。

validator：NaN rules 与 numeric sanity 均为 **PASS**。

## 10. Metadata

每一行均包含并一致记录：case、algorithm、seed、model file、model SHA、timestamp、
Git commit、branch 和 dirty status。seed 与 registry 逐 case 一致。

`git_dirty_status=DIRTY` 是可解释状态：运行开始时只有未跟踪的
`step5_smoke_workspace.mat`；没有冻结代码修改。

validator：`Metadata complete = PASS`。

## 11. Case03 / Case04 / Case05 专项检查

### Case03

```text
Cs1: 10 -> 15 pF
Cs2: 10 -> 6 pF
smooth transition: 1.45-1.65 s
```

起点、终点和中间过渡样本检查通过。

### Case04

```text
seed = 104
```

用同一 seed 重生成两次，轨迹逐样本相同；正式 `caseData` 与冻结 generator 最大差值
不超过 `1e-10 pF`。没有重抽随机轨迹。

### Case05

```text
seed = 106
Cs1 range = [10,10] pF
Cs2 range = [10,10] pF
```

Case05 已完整完成 zero-noise AutoComp9、synthetic reference/noise、noisy AutoComp9、
M0/M2/M3 和 metrics。Case05 与 Case06 的 `fault_scale` 向量逐样本完全相同。

## 12. Case02 / Case06 sanity

validator 从 `phase1a_historical_reference.m` 读取冻结值和容差：

```text
absolute tolerance = 1e-9
relative tolerance = 1e-8
```

结果：

```text
Case02: 4/4 PASS
Case06: 7/7 PASS
Total:  11/11 PASS
```

关键复现值包括：

```text
Case02 M0 B error       = 8.9587533463069 %
Case02 M3 B error       = 0.354785857594943 %
Case02 M3 Cs1 RMSE      = 0.157320251866564 pF
Case02 M3 Cs2 RMSE      = 0.108513587962671 pF

Case06 true factor      = 1.59999999999967
Case06 M2 estimated     = 1.40226869710244
Case06 M3 estimated     = 1.58287648629316
```

这只是 Step 6 sanity；正式历史回归报告仍留给 Step 7。

## 13. 正式产物

| 文件 | 大小 | SHA-256 |
|---|---:|---|
| `paper_research/phase1a_baseline/baseline_summary.csv` | 5,821 bytes | `E7BEB3ECFEDF521105B67198684752BB32AFAAEFD84ACA80822BA57FBD9D0AB3` |
| `paper_research/phase1a_baseline/baseline_workspace.mat` | 115,337,063 bytes（约 110.0 MiB） | `A90632B72479E7B6ADC4E410DB37542E9CA4985CA8381B6BAFC8F71C961E87B5` |

CSV 为 1 行表头加 18 行结果。MAT workspace 保存：

```text
cfg
caseRegistry
algorithmRegistry
resultSchema
historicalReference
resultsTable
runMetadata
caseData
algorithmResults
validation
```

时序内容包括 t、Cs 真值、fault scale、三相阻性真值、cHist、估计 irB，以及 M2/M3
cycle log；没有保存 `SimulationOutput`、编译缓存或 `slprj`。

## 14. Validator 完整结果

| ID | 检查 | 结果 |
|---|---|---|
| A | AutoComp9 SHA correct | PASS |
| B | All six cases completed | PASS |
| C | One formal data set per case | PASS |
| D | M0/M2/M3 share case data | PASS |
| E | Result row count = 18 | PASS |
| F | Six unique cases | PASS |
| G | Three unique algorithms | PASS |
| H | 18 unique and complete pairs | PASS |
| I | Frozen schema exact | PASS |
| J | Frozen NaN rules | PASS |
| K | No Inf or complex values | PASS |
| L | Metadata complete | PASS |
| M | Case04 seed and determinism | PASS |
| N | Case05 fixed coupling | PASS |
| O | Case05/06 fault profiles match | PASS |
| P | Case02/06 Step 5 sanity 11/11 | PASS |
| Q | AutoComp9 unchanged by run | PASS |
| R | Frozen algorithm core unchanged, 14/14 | PASS |
| S | Historical result directories untouched | PASS |

```text
validator checks = 19/19 PASS
STEP6_FORMAL_BASELINE_RUN = PASS
```

## 15. Git 状态

运行和报告生成后不提交 Step 6。

### `git diff --check`

```text
(no output)
```

### `git diff --stat`

```text
(no output; Step 6 outputs/report are untracked)
```

### `git status --short --untracked-files=all`

```text
?? paper_research/phase1a_baseline/STEP6_FORMAL_BASELINE_RUN.md
?? paper_research/phase1a_baseline/baseline_summary.csv
?? paper_research/phase1a_baseline/baseline_workspace.mat
?? paper_research/phase1a_baseline/step5_smoke_workspace.mat
```

历史目录 `results/`、`results_phase1/`、`results_phase2/` 的 Git status 为空。

## 16. 停止点

```text
STEP6_FORMAL_BASELINE_RUN = PASS
```

Step 6 已完成。本轮未提交 Step 6，没有进入 Step 7、M1、M4、soft gate、Phase 1B、
Monte-Carlo 或鲁棒性扫描。等待人工验收。
