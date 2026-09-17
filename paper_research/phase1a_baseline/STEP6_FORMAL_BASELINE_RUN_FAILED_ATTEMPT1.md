# Phase 1A Step 6 — Six-Case Formal Baseline Run

## 1. 结论

```text
STEP6_FORMAL_BASELINE_RUN = FAIL
```

本轮按冻结 registry 和统一调用链启动了正式六工况运行，但在
`Case05_fault_only` 处遇到冻结调用链不兼容并立即停止。根据 Step 6 的
“若必须修改冻结文件才能运行，则停止，不自行修复后继续”规则，本轮没有修改
任何冻结文件，也没有重试或绕过统一入口。

由于六工况没有全部完成，下列正式产物没有生成：

- `baseline_summary.csv`
- `baseline_workspace.mat`

## 2. Step 5 checkpoint

| 项目 | 值 |
|---|---|
| Step 5 checkpoint commit | `165d2bea04d997de9e82f99818f5c03828c46f94` |
| 分支 | `main` |
| Step 5 smoke regression | `11/11 PASS` |
| 本轮开始前已知未跟踪文件 | `step5_smoke_workspace.mat` |

## 3. AutoComp9 integrity

| 项目 | 值 |
|---|---|
| model file | `MATLAB一键实验/AI6109_MOA_AutoComp9.slx` |
| model SHA-256 | `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70` |
| frozen SHA-256 | `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70` |
| baseline integrity before run | **PASS** |
| model integrity after failure | **PASS** |

## 4. 运行环境

| 项目 | 值 |
|---|---|
| MATLAB | `23.2.0.2365128 (R2023b)` |
| Simulink | `23.2` |
| platform | Windows 64-bit (`win64`) |
| runner | `MATLAB一键实验/run_phase1a_baseline.m` |
| validator | `MATLAB一键实验/validate_phase1a_baseline.m` |

两个新增 MATLAB 文件在正式运行前均通过 `checkcode`，问题数为 0。

## 5. 冻结 Case / seed

| 顺序 | Case | seed | 本次状态 |
|---:|---|---:|---|
| 1 | `Case01_static` | 101 | 完成；M0/M2/M3 共用同一 data |
| 2 | `Case02_slow_drift` | 102 | 完成；M0/M2/M3 共用同一 data |
| 3 | `Case03_smooth_step` | 103 | 完成；M0/M2/M3 共用同一 data |
| 4 | `Case04_random_drift` | 104 | 完成；M0/M2/M3 共用同一 data |
| 5 | `Case05_fault_only` | 106 | **失败；helper 未返回正式 data** |
| 6 | `Case06_drift_then_fault` | 105 | 未开始 |

## 6. 失败位置与根因

冻结调用链为：

```text
run_phase1a_baseline
  -> simulate_phase2_case(cfg, "fault_only", 106)
     -> generate_coupling_signals(..., "fault_only", ...)
     -> run_once(...)                         % 零噪声 AutoComp9 仿真成功
     -> synthesize_dynamic_case(..., "fault_only", ...)
        -> error: 未知场景 fault_only
```

只读代码核对确认，`synthesize_dynamic_case.m` 现有 switch 仅包含：

```text
static
slow_drift
smooth_step
random_drift
fault_with_drift
```

它没有 `fault_only` 分支。`simulate_phase2_case.m` 又必须先调用该历史合成器生成
参考总电流和 30 dB 噪声，之后才会执行正式 noisy AutoComp9 run。因此，虽然
`generate_coupling_signals.m` 已定义 Case05 的固定 Cs 与故障轨迹，当前冻结 helper
仍无法让 Case05 完整返回。

这不是算法数值失败，而是 Case Registry 与冻结 helper/历史合成器之间的接口缺口。

## 7. 调用计数与公平性

| 计数 | 结果 |
|---|---:|
| 计划 case-level calls | 6 |
| 已尝试 case-level calls | 5 |
| 完整返回的 case-level calls | 4 |
| 计划成功 low-level `sim(in)` | 12 |
| 失败前成功 low-level `sim(in)` | 9 |

计数解释：Case01–Case04 各完成零噪声和 noisy 两次底层仿真，共 8 次；Case05
完成零噪声仿真后，在创建 MATLAB reference 时失败，因此又有 1 次成功底层仿真，
但没有正式 noisy data 返回。

对已经完整返回的 Case01–Case04，runner 的结构确实是每个 case 先生成一次 data，
随后 M0/M2/M3 共用该 data。没有按算法重跑模型。

## 8. 18 行结果完整性

正式输出采用“先完成全部六工况并通过 A–S 校验，再写 CSV/MAT”的原子式顺序。
因此失败时没有写出 12 行半成品，也没有覆盖任何旧结果。

| 项目 | 结果 |
|---|---|
| 目标结果行数 | 18 |
| 正式写出行数 | 0 |
| `baseline_summary.csv` | 未生成 |
| `baseline_workspace.mat` | 未生成 |

## 9. Schema、NaN、numeric 与 metadata 检查

完整 A–S validator 已在 `validate_phase1a_baseline.m` 中建立，但 runner 在 Case05
失败后没有进入 validator。故不能把 Schema、NaN、Inf/complex、metadata 等完整
数据集检查标为通过。

Case01–Case04 的内存中间结果没有作为正式产物保存，避免把不完整结果误认为 baseline。

## 10. Case03 / Case04 / Case05 状态

- Case03 使用 registry 的 seed 103 和冻结 `smooth_step` 轨迹，仿真及三算法计算完成；
  完整 validator 尚未执行，故不形成正式验收结论。
- Case04 使用 registry 的 seed 104，仿真及三算法计算完成；没有重抽 seed；完整
  deterministic validator 尚未执行。
- Case05 使用 registry 的 seed 106。零噪声 AutoComp9 run 已启动并完成，但 helper
  在 `synthesize_dynamic_case("fault_only")` 处失败，未返回正式 data。不能据此声称
  Case05 baseline 已完成。

## 11. Case02 / Case06 历史 sanity 状态

- Case02 本轮计算完成，但完整数据集 validator 尚未执行。
- Case06 本轮尚未开始。
- 因此本报告不重复 Step 7 历史回归结论；Step 5 的 `11/11 PASS` 仍是最近一次已完成
  的历史回归证据。

## 12. 正式输出路径与文件大小

| 文件 | 状态 | 大小 |
|---|---|---:|
| `paper_research/phase1a_baseline/baseline_summary.csv` | 未生成 | — |
| `paper_research/phase1a_baseline/baseline_workspace.mat` | 未生成 | — |
| `paper_research/phase1a_baseline/STEP6_FORMAL_BASELINE_RUN.md` | 已生成 | 以工作区实际值为准 |

## 13. A–S 验收表

| ID | 检查项 | 状态 | 说明 |
|---|---|---|---|
| A | AutoComp9 SHA 正确 | **PASS** | 运行前后均为冻结 SHA |
| B | 六个 Case 全部运行 | **FAIL** | Case05 失败，Case06 未开始 |
| C | 每个 case 只有一份正式 data | **FAIL** | Case05 未返回正式 data |
| D | M0/M2/M3 共用 data | **PARTIAL** | Case01–04 满足；全六工况未完成 |
| E | 结果共 18 行 | **FAIL** | 未写出不完整结果 |
| F | 6 unique cases | **NOT REACHED** | validator 未执行 |
| G | 3 unique algorithms | **NOT REACHED** | validator 未执行 |
| H | 18 unique pairs | **NOT REACHED** | validator 未执行 |
| I | Schema 完全一致 | **NOT REACHED** | validator 未执行 |
| J | NaN 规则正确 | **NOT REACHED** | validator 未执行 |
| K | 无 Inf / complex | **NOT REACHED** | validator 未执行 |
| L | metadata 完整 | **NOT REACHED** | validator 未执行 |
| M | Case04 seed/deterministic | **PARTIAL** | seed=104，未进入正式 validator |
| N | Case05 Cs 固定 | **NOT REACHED** | helper 在返回 data 前失败 |
| O | Case05/06 fault profile 一致 | **NOT REACHED** | Case06 未开始 |
| P | Case02/06 与 Step 5 无明显冲突 | **NOT REACHED** | Case06 未运行 |
| Q | AutoComp9 未修改 | **PASS** | SHA 不变 |
| R | 算法核心未修改 | **PASS** | Git 无已跟踪文件 diff |
| S | 历史结果目录未修改 | **PASS** | 指定目录 Git status 为空 |

## 14. Git 检查

### `git diff --check`

```text
(no output)
```

### `git diff --stat`

```text
(no output; Step 6 files are untracked)
```

### `git status --short --untracked-files=all`

```text
?? "MATLAB一键实验/run_phase1a_baseline.m"
?? "MATLAB一键实验/validate_phase1a_baseline.m"
?? paper_research/phase1a_baseline/STEP6_FORMAL_BASELINE_RUN.md
?? paper_research/phase1a_baseline/step5_smoke_workspace.mat
```

`step5_smoke_workspace.mat` 是开始前已存在的 Step 5 本地验收文件；本轮没有覆盖它。

## 15. 停止点与后续决策

本轮停在 Step 6，未进入 Step 7、Step 8 或 Phase 1B。要完成 Step 6，需先由人工决定
如何修复 Case05 的统一数据生成接口。最小候选方向是让历史参考/噪声生成链支持
`fault_only`，但这会触及冻结调用链，必须作为明确授权的单独修复轮次处理，不能在
本轮自动实施。
