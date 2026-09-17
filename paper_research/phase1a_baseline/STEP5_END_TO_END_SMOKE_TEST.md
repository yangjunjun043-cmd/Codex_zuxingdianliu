# Phase 1A — Step 5：End-to-End Historical Smoke Test

执行日期：2026-09-17  
最终结论：`STEP5_END_TO_END_SMOKE_TEST = PASS`  
通过依据：Case02 四项、Case06 七项冻结历史回归共 `11/11` 通过；没有修改任何冻结算法、case、metrics、历史 reference 或 AutoComp9。

## 1. Step 4 checkpoint

| 项目 | 值 |
|---|---|
| commit | `ac657b407faea8dd2f88efea2e9bfc7769e6faee` |
| subject | `paper: add Phase 1A unified metrics` |

## 2. AutoComp9 integrity

| 字段 | 值 |
|---|---|
| path | `D:\Codex\MOA_Arrester\MATLAB一键实验\AI6109_MOA_AutoComp9.slx` |
| expected SHA-256 | `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70` |
| actual SHA-256 before run | `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70` |
| actual SHA-256 after run | `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70` |
| integrity | **PASS** |

模型未打开保存、另存或修改，也没有使用 AutoComp11。

## 3. 运行环境与 metadata

| 字段 | 值 |
|---|---|
| run timestamp | `2026-09-17T10:09:32+08:00` |
| Git commit | `ac657b407faea8dd2f88efea2e9bfc7769e6faee` |
| Git branch | `main` |
| Git dirty status | `DIRTY`（运行时 smoke runner 为未跟踪文件） |
| MATLAB | `23.2.0.2365128 (R2023b)` |
| Simulink | `23.2` |
| platform | `PCWIN64` |
| Case02 seed | `102` |
| Case06 seed | `105` |

运行中出现 AutoComp9 原有的未连接 Current Measurement 输出和一个 algebraic loop 警告；仿真正常完成，没有修改模型来消除这些历史警告。

## 4. 端到端调用链

两个 case 均使用同一冻结链路：

```text
phase1a_case_registry
  -> generate_coupling_signals
  -> simulate_phase2_case / AutoComp9
  -> reconstruct_refs_from_b
  -> run_phase1a_algorithm(M0/M2/M3)
  -> evaluate_phase1a_metrics
  -> phase1a_historical_reference regression
```

每个 case 的 M0/M2/M3 共用完全相同的 `data/ref/cfg`。runner 不含算法公式、门控判据、case 数学轨迹或评价公式。

输入信号与模型输出真值的最大差异：

| Case | Cs1 max abs diff / pF | Cs2 max abs diff / pF |
|---|---:|---:|
| Case02 | `1.7763568394002505e-15` | `1.7763568394002505e-15` |
| Case06 | `1.7763568394002505e-15` | `1.7763568394002505e-15` |

## 5. Case02 — Slow Drift

正式名称：`Case02_slow_drift`  
legacy 名称：`slow_drift`  
seed：`102`

### 5.1 M0/M2/M3 result summary

| Mode | Cs1 RMSE / pF | Cs2 RMSE / pF | B fundamental error / % | Gate |
|---|---:|---:|---:|---|
| M0 | `2.9437879861163161` | `2.2135826900779447` | `8.9587533463069029` | N/A |
| M2 | `0.15732025186656448` | `0.10851358796267101` | `0.35478585759494319` | N/A |
| M3 | `0.15732025186656448` | `0.10851358796267101` | `0.35478585759494319` | 未触发，指标为 NaN |

Case02 中 M2/M3 数值相同，是因为该慢漂移工况没有触发硬门控。M2 正常计算并保存，但没有人为新增历史回归基准。

### 5.2 Historical regression

| Mode | Metric | Historical | New | Abs diff | Relative diff | Abs tol | Rel tol | Result |
|---|---|---:|---:|---:|---:|---:|---:|---|
| M0 | B fundamental error / % | `8.9587533463068993` | `8.9587533463069029` | `3.5527136788005009e-15` | `3.9656339911010604e-16` | `1e-9` | `1e-8` | **PASS** |
| M3 | B fundamental error / % | `0.35478585759494302` | `0.35478585759494319` | `1.6653345369377348e-16` | `4.6939146566519478e-16` | `1e-9` | `1e-8` | **PASS** |
| M3 | Cs1 RMSE / pF | `0.15732025186656401` | `0.15732025186656448` | `4.7184478546569153e-16` | `2.9992628403995975e-15` | `1e-9` | `1e-8` | **PASS** |
| M3 | Cs2 RMSE / pF | `0.10851358796267099` | `0.10851358796267101` | `1.3877787807814457e-17` | `1.2788986216720095e-16` | `1e-9` | `1e-8` | **PASS** |

Case02：`4/4 PASS`。

## 6. Case06 — Drift Then Fault

正式名称：`Case06_drift_then_fault`  
legacy 名称：`fault_with_drift`  
seed：`105`

### 6.1 M0/M2/M3 result summary

| Mode | Cs1 RMSE / pF | Cs2 RMSE / pF | B fund. error / % | True factor | Est. factor | Retention error / % | ΔCs1 / pF | ΔCs2 / pF | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| M0 | `2.5794845448028503` | `1.6832529638171365` | `6.7818401820872749` | `1.5999999999996732` | `1.5510737523226841` | `-3.0578904798124471` | `7.496225862269057e-13` | `1.2434497875801753e-14` | N/A |
| M2 | `2.6151618174242355` | `2.5998580359342758` | `-4.6566029534085152` | `1.5999999999996732` | `1.4022686971024385` | `-12.358206431079696` | `5.0062709271749739` | `-4.9773479465068169` | N/A |
| M3 | `0.31525785226767983` | `0.32806639286690631` | `-0.31016281540014451` | `1.5999999999996732` | `1.582876486293163` | `-1.0702196066571072` | `0.56111492922905803` | `-0.61625263109284223` | first=`3.05998 s`; `48 cycles`; `0.96 s` |

### 6.2 Historical regression

| Mode | Metric | Historical | New | Abs diff | Relative diff | Abs tol | Rel tol | Result |
|---|---|---:|---:|---:|---:|---:|---:|---|
| TRUTH | fault factor | `1.5999999999996699` | `1.5999999999996732` | `3.3306690738754696e-15` | `2.0816681711725977e-15` | `1e-9` | `1e-8` | **PASS** |
| M2 | Cs1 change / pF | `5.0062709271749704` | `5.0062709271749739` | `3.5527136788005009e-15` | `7.0965269968025704e-16` | `1e-9` | `1e-8` | **PASS** |
| M2 | Cs2 change / pF | `-4.9773479465068204` | `-4.9773479465068169` | `3.5527136788005009e-15` | `7.137764361629269e-16` | `1e-9` | `1e-8` | **PASS** |
| M2 | estimated fault factor | `1.4022686971024401` | `1.4022686971024385` | `1.5543122344752192e-15` | `1.1084268212554072e-15` | `1e-9` | `1e-8` | **PASS** |
| M3 | Cs1 change / pF | `0.56111492922905803` | `0.56111492922905803` | `0` | `0` | `1e-9` | `1e-8` | **PASS** |
| M3 | Cs2 change / pF | `-0.61625263109284201` | `-0.61625263109284223` | `2.2204460492503131e-16` | `3.6031425055543322e-16` | `1e-9` | `1e-8` | **PASS** |
| M3 | estimated fault factor | `1.5828764862931599` | `1.582876486293163` | `3.1086244689504383e-15` | `1.9639084261276332e-15` | `1e-9` | `1e-8` | **PASS** |

Case06：`7/7 PASS`。

## 7. 回归判据与总结果

所有比较均从 `phase1a_historical_reference.m` 读取：

```text
absTol = 1e-9
relTol = 1e-8
pass = abs(new-reference) <= absTol + relTol*abs(reference)
```

没有在 runner 中复制历史值或重新定义容差。总结果：

```text
Case02: 4/4 PASS
Case06: 7/7 PASS
Total:  11/11 PASS

STEP5_END_TO_END_SMOKE_TEST = PASS
```

## 8. 仿真次数与公平性说明

成功的正式 smoke run：

```text
simulate_phase2_case calls = 2
Case02 calls = 1
Case06 calls = 1
```

即每个 case 只生成一次正式数据，随后 M0/M2/M3 共享同一份 `data/ref/cfg`：

```text
Each case was simulated once at the case-runner level.
M0/M2/M3 shared the same case data.
```

必须同时披露冻结 helper 的内部行为：`simulate_phase2_case` 为构造历史一致的噪声，先执行一次零噪声 `run_once`，再执行一次带噪声 `run_once`。因此：

```text
successful run low-level sim invocations = 4
```

这不是 M0/M2/M3 分别重跑模型；三种算法仍共用第二次 `run_once` 返回的同一正式数据。若“Simulink 实际运行次数”严格按底层 `sim(in)` 计数，则冻结实现不是预期的 2，而是 4；本轮按禁改规则没有重构 `simulate_phase2_case.m`。

执行过程还有两次未形成结果的启动尝试：第一次在任何 `sim` 前因 runner 的 PowerShell 哈希调用失败；第二次完成 Case02 helper 调用后，被 runner 额外设置的逐位 `isequal` 轨迹检查中止。后者包含 2 次底层 `sim`。修正的只是新 runner 的哈希和数值一致性检查，冻结层没有变化。因此本轮会话累计底层 `sim` 调用为 6；正式通过结果来自最后一次完整执行的 4 次底层调用。

## 9. 产物

| 文件 | 用途 |
|---|---|
| `MATLAB一键实验/run_phase1a_smoke_test.m` | 最小端到端 runner |
| `paper_research/phase1a_baseline/step5_smoke_workspace.mat` | 调试/验收 workspace，约 73.2 MB；不是正式 baseline workspace |
| `paper_research/phase1a_baseline/STEP5_END_TO_END_SMOKE_TEST.md` | 本报告 |

没有生成 `baseline_summary.csv`、`baseline_workspace.mat` 或正式论文 Figures。

## 10. Step 5 验收 A–T

| 编号 | 验收项 | 结果 | 依据 |
|---|---|---|---|
| A | Step 4 checkpoint 已建立 | **PASS** | commit `ac657b4...` |
| B | AutoComp9 SHA-256 正确 | **PASS** | 前后哈希均与冻结值一致 |
| C | 只运行 Case02 和 Case06 | **PASS** | 没有选择其他 case |
| D | Case02 在成功 run 中只调用一次 case simulator | **PASS** | 一次 `simulate_phase2_case`；内部两次 `sim` 已披露 |
| E | Case06 在成功 run 中只调用一次 case simulator | **PASS** | 一次 `simulate_phase2_case`；内部两次 `sim` 已披露 |
| F | 每个 case 的三算法共享 data/ref/cfg | **PASS** | runner 先生成一次 case，再遍历算法 |
| G | 所有算法通过 dispatcher | **PASS** | 仅调用 `run_phase1a_algorithm` |
| H | 所有指标通过统一 metrics | **PASS** | 仅调用 `evaluate_phase1a_metrics` |
| I | Case02 四项历史回归通过 | **PASS** | `4/4` |
| J | Case06 七项历史回归通过 | **PASS** | `7/7` |
| K | 没有调参 | **PASS** | 仅把 `cfg.model` 指向冻结 AutoComp9 |
| L | 没有修改门控 | **PASS** | 核心文件无 diff |
| M | 没有修改 Case | **PASS** | generator/registry 无 diff |
| N | 没有修改 Metrics | **PASS** | Step 4 checkpoint 后无 diff |
| O | 没有修改 historical reference | **PASS** | Step 4 checkpoint 后无 diff |
| P | 没有修改 AutoComp9 | **PASS** | 哈希不变 |
| Q | 没有修改算法核心 | **PASS** | 受保护文件无 diff |
| R | 没有修改历史结果目录 | **PASS** | `results*` 无 diff |
| S | 没有运行其他四个 Case | **PASS** | runner 只选 Case02/06 |
| T | 没有进入 M1/M4/Phase1B | **PASS** | 无相关实现或运行 |

## 11. Git 检查

最终执行：

```text
git diff --check
git diff --stat
```

均无输出，因为 Step 5 只新增未跟踪文件，没有修改 tracked 文件。

最终 `git status --short --untracked-files=all`：

```text
?? "MATLAB\344\270\200\351\224\256\345\256\236\351\252\214/run_phase1a_smoke_test.m"
?? paper_research/phase1a_baseline/STEP5_END_TO_END_SMOKE_TEST.md
?? paper_research/phase1a_baseline/step5_smoke_workspace.mat
```

Git 的 `MATLAB\344...` 是中文目录 `MATLAB一键实验/` 的转义显示。

## 12. 停止点

Step 5 端到端历史 smoke test 已完成并通过。没有进入 Step 6，没有运行完整六工况，没有提交 Step 5，等待人工验收。
