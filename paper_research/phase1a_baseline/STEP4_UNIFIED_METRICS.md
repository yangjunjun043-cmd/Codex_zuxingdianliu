# Phase 1A — Step 4：Unified Metrics and Result Schema

执行日期：2026-09-17  
执行范围：建立统一指标评价函数、历史回归参考和纯 MATLAB 指标测试；未加载或运行 AutoComp9，未调用 `sim`，未生成正式 baseline CSV/MAT/图，未进入 Step 5。

## 1. Step 3 checkpoint

开始 Step 4 前，工作区只包含已人工验收的 Step 3 三个新增文件。按要求建立 checkpoint：

| 项目 | 值 |
|---|---|
| commit | `267d4d15ae1b836e0f34bc367cd98c38845f1b87` |
| subject | `paper: add Phase 1A algorithm dispatcher` |
| timestamp | `2026-09-17T09:27:44+08:00` |

## 2. 新增/修改文件

| 文件 | 动作 | 职责 |
|---|---|---|
| `MATLAB一键实验/evaluate_phase1a_metrics.m` | 新增 | 把一个 case × algorithm 的既有数据映射为冻结 result schema |
| `MATLAB一键实验/phase1a_historical_reference.m` | 新增 | 保存 Case02/06 历史数值，仅供未来回归比较 |
| `MATLAB一键实验/tests/Phase1AMetricsTest.m` | 新增 | 纯 MATLAB 指标、NaN、门控、schema 和错误处理测试 |
| `paper_research/phase1a_baseline/STEP4_UNIFIED_METRICS.md` | 新增 | 本报告 |

本轮没有修改任何既有 MATLAB/Simulink 文件。特别是 result schema、Step 3 dispatcher、case 生成器、算法核心和 Phase 2 历史入口均未修改。

## 3. 统一指标接口

正式接口为：

```matlab
metrics = evaluate_phase1a_metrics( ...
    caseInfo,algorithmResult,data,cfg,metadata)
```

建议接口中的 `ref` 被省略，因为正式指标只需要 `data` 内的真值、dispatcher 返回的 `ir/cHist/tracker`、`cfg` 评价参数和运行元数据；把未参与评价的 `ref` 传入会造成虚假的依赖。

输入约定：

- `caseInfo`：一行 case registry table 或等价标量结构，至少含 `case_name/seed/model`；
- `algorithmResult`：Step 3 返回结构，至少含 `algorithm_mode/cHist/ir/tracker`；
- `data`：至少含 `t/Cs1/Cs2/irA/irB/irC`；
- `cfg`：至少含 `metric_start/f`；
- `metadata`：含 `model_sha256/run_timestamp/git_commit/git_branch/git_dirty_status`。

输出是严格的一行 table，字段名称、顺序和类型完全与 `phase1a_result_schema.m` 一致，行粒度为：

```text
one case × one algorithm
```

## 4. 每个指标的精确定义

### 4.1 Cs1/Cs2 RMSE

时间索引沿用正式 AutoComp9 Phase 2 结果生成代码：

```matlab
idx = data.t >= cfg.metric_start;
```

公式：

```text
Cs1_RMSE_pF = sqrt(mean((cHist(idx,1) - data.Cs1(idx))^2))
Cs2_RMSE_pF = sqrt(mean((cHist(idx,2) - data.Cs2(idx))^2))
```

真值 `data.Cs1/Cs2` 和估计 `cHist` 均为 pF，不再进行单位转换。当前配置的历史评价起点是 `0.80 s`，但统一函数读取 `cfg.metric_start`，不硬编码该值。

来源：`run_phase2_simulink_dynamic.m` 的 `case_row` 和 `run_gating_ablation.m` 的 `trackingSummary`。

### 4.2 B 相阻性基波误差

统一函数直接调用现有 `evaluate_case_metrics`，读取其 `B_FundErr_pct`，没有另写第二套基波拟合：

```text
B_resistive_fundamental_error_pct
  = (estimated fundamental RMS - true fundamental RMS)
    / (true fundamental RMS + eps) × 100%
```

评价区间同样为 `data.t >= cfg.metric_start`。该指标是带符号相对误差，不是绝对值、波形 RMSE 或瞬时误差平均。

### 4.3 Fault factor

仅 Case05/06 计算。窗口严格沿用两个历史 Phase 2 入口：

```text
pre  = [2.60, 2.90) s
post = [3.40, 3.80) s
```

每个窗口用 `[sin(ωt), cos(ωt), 1]` 最小二乘拟合基波，基波 RMS 为：

```text
hypot(b1,b2) / sqrt(2)
```

随后：

```text
fault_factor = post fundamental RMS / (pre fundamental RMS + eps)
```

- `fault_factor_true` 从 `data.irB` 真值自然计算；
- `fault_factor_est` 从 `algorithmResult.ir.B` 自然计算；
- 不把 `1.6` 硬编码到正式 metrics。

### 4.4 Fault retention error

历史 `run_phase2_simulink_dynamic.m` 和 `run_gating_ablation.m` 均使用带符号公式：

```text
fault_retention_error_pct
  = (fault_factor_est - fault_factor_true)
    / fault_factor_true × 100%
```

因此低估故障增幅时结果为负，例如历史 M3 为约 `-1.07022%`。本轮没有改成绝对误差。

### 4.5 故障前后 Cs 参数变化

仅 Case05/06 计算，使用同一 pre/post 窗口和历史 gating ablation 的窗口均值差：

```text
Cs1_pre_post_change_pF = mean(Cs1_est(post)) - mean(Cs1_est(pre))
Cs2_pre_post_change_pF = mean(Cs2_est(post)) - mean(Cs2_est(pre))
```

这不是单点差，也不表示普通漂移起止变化。

## 5. NaN 适用规则

| 场景/算法 | 必须为 NaN 的字段 |
|---|---|
| Case01–Case04 | `fault_factor_true`、`fault_factor_est`、`fault_retention_error_pct`、两个 `Cs*_pre_post_change_pF` |
| M0 | 全部三个 gate 指标 |
| M2 | 全部三个 gate 指标，即使 tracker 中存在残差或人工 gate 标记 |
| M3 未触发 gate | 全部三个 gate 指标 |

不适用指标不会用 `0` 代替。Case05/06 的 fault 指标适用于 M0/M2/M3；是否存在门控不影响 fault 指标适用性。

## 6. Gate 指标定义

只有 M3 会读取现有 `tracker.cycle`，统一函数不重算门控判据。

| 指标 | 定义 |
|---|---|
| `first_gate_trigger_s` | cycle log 中第一次 `gate>0` 对应的 `time_s` |
| `gate_duration_cycles` | 整份 cycle log 中实际 `gate>0` 的总周期数，不限于首次连续事件 |
| `gate_duration_s` | `gate_duration_cycles / cfg.f` |

`track_coupling_cvff_rls` 按一个工频周期写一行 cycle log，因此使用运行时 `cfg.f` 换算，不硬编码 `0.02 s`。M3 缺少真实 cycle log 会抛出 `Phase1A:MissingGateLog`，不会输出虚构值。

## 7. Case05/06 fault 评价一致性

Case05 和 Case06 通过同一个 `isFaultCase` 分支，使用完全相同的：

- `[2.60,2.90)` pre 窗口；
- `[3.40,3.80)` post 窗口；
- 基波 RMS 拟合；
- true/estimated fault factor；
- 带符号保持误差；
- Cs 窗口均值差；
- M3 gate log 统计。

测试把相同输入分别标记为 Case05/06，五个 fault/参数变化指标逐项完全相等。

## 8. 历史评价公式来源

| 指标 | 历史生成位置 |
|---|---|
| Cs RMSE | `run_phase2_simulink_dynamic.m::case_row`、`run_gating_ablation.m::trackingSummary` |
| B 基波误差 | `evaluate_case_metrics.m::signal_metrics/relative_error` |
| fault factor | 两个历史入口各自的 `fault_factor/fund_rms` 局部函数 |
| retention error | `run_phase2_simulink_dynamic.m`、`run_gating_ablation.m` |
| Cs pre/post change | `run_gating_ablation.m::parameter_row` |
| gate count | `track_coupling_cvff_rls.m` 的真实 cycle log；历史汇总为故障后 `gate>0` 数量 |

历史 CSV 只读核对，没有覆盖或重写。

## 9. Historical regression reference

`phase1a_historical_reference.m` 独立保存以下只读回归常量，`reference_role="regression_only"`：

| Case | Algorithm | 指标 | 历史值 |
|---|---|---|---:|
| Case02 | M0 | B fundamental error / % | `8.9587533463069` |
| Case02 | M3 | B fundamental error / % | `0.354785857594943` |
| Case02 | M3 | Cs1 RMSE / pF | `0.157320251866564` |
| Case02 | M3 | Cs2 RMSE / pF | `0.108513587962671` |
| Case06 | truth | fault factor | `1.59999999999967` |
| Case06 | M2 | Cs1 change / pF | `+5.00627092717497` |
| Case06 | M2 | Cs2 change / pF | `-4.97734794650682` |
| Case06 | M2 | estimated fault factor | `1.40226869710244` |
| Case06 | M3 | Cs1 change / pF | `+0.561114929229058` |
| Case06 | M3 | Cs2 change / pF | `-0.616252631092842` |
| Case06 | M3 | estimated fault factor | `1.58287648629316` |

参考结构同时记录未来建议容差：absolute `1e-9`、relative `1e-8`。这些值没有出现在 `evaluate_phase1a_metrics.m`，不会进入正式结果；未来统一运行必须从数据自然计算，再与参考比较。

## 10. 错误处理

指标层会明确拒绝未知 case、未知算法模式、缺失字段、时序长度不一致、空评价窗口、fault case 缺失历史 pre/post 窗口，以及 M3 缺失真实 gate log。不会以 `0` 代替错误或不适用值。

## 11. 单元测试结果

测试文件：`MATLAB一键实验/tests/Phase1AMetricsTest.m`。测试使用内存中人工构造的确定性三相信号，不加载 Simulink，不读写结果文件。

MATLAB MCP 无法附着桌面会话，因此按前两步已验收的方式回退到 `matlab -batch`，命令只执行 `checkcode` 和该测试文件。

最终结果：

```text
13 passed / 0 failed / 0 incomplete
```

覆盖内容：

- 输出字段与 schema 名称、顺序和类型完全一致；
- B fundamental error 与现有 `evaluate_case_metrics` 一致；
- 非故障 fault 指标全为 NaN；
- M0/M2 gate 指标全为 NaN；
- M3 无 gate 为 NaN，有 gate 时首触发、总周期和秒数正确；
- fault factor、带符号保持误差和 Cs 窗口均值差正确；
- Case05/06 评价口径一致；
- 历史参考常量独立保存；
- 未知 case、缺失 truth、M3 缺失 log 明确报错；
- 评价层不调用仿真、case 生成或算法函数。

第一次测试中，测试夹具未给非故障 M3 提供真实 dispatcher 会返回的空门控 cycle log，正确触发 `Phase1A:MissingGateLog`；修正夹具后最终全通过，正式指标实现没有为该测试放宽输入要求。

## 12. Code Analyzer 结果

| 文件 | issue 数 |
|---|---:|
| `evaluate_phase1a_metrics.m` | 0 |
| `phase1a_historical_reference.m` | 0 |
| `tests/Phase1AMetricsTest.m` | 0 |

## 13. Step 4 验收 A–Q

| 编号 | 验收项 | 结果 | 依据 |
|---|---|---|---|
| A | 建立统一 `evaluate_phase1a_metrics.m` | **PASS** | 新增纯评价函数 |
| B | 输出字段与 result schema 完全一致 | **PASS** | 字段名直接取 schema；测试逐项确认 |
| C | Cs1/Cs2 RMSE 与历史兼容 | **PASS** | `cfg.metric_start` 后 pF 真值 RMSE |
| D | B fundamental error 与历史兼容 | **PASS** | 直接复用 `evaluate_case_metrics` |
| E | fault factor 使用历史窗口和定义 | **PASS** | 相同 pre/post 和基波 RMS 比值 |
| F | Cs pre/post change 使用历史定义 | **PASS** | 相同窗口均值差 |
| G | M0 gate 指标为 NaN | **PASS** | 单元测试通过 |
| H | M2 gate 指标为 NaN | **PASS** | 即使存在标记也忽略；测试通过 |
| I | M3 gate 指标来自真实 tracker log | **PASS** | 不重算判据；缺 log 报错 |
| J | 非故障 case 的 fault 指标为 NaN | **PASS** | Case02 测试通过 |
| K | Case05/06 使用统一 fault 口径 | **PASS** | 同输入的五项指标完全相等 |
| L | 历史关键值仅作 regression reference | **PASS** | 独立文件；评价函数不含历史常量 |
| M | 未修改算法核心 | **PASS** | 最终 Git 核查无既有文件 diff |
| N | 未修改 AutoComp9 | **PASS** | SHA-256 仍为 `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70` |
| O | 未修改历史结果 | **PASS** | 三个历史结果目录无 diff |
| P | 未运行正式六工况 | **PASS** | 仅 checkcode 和人工数据函数测试 |
| Q | 未进入 M1/M4/软门控/P_X/eta_abs | **PASS** | 无新增模式或算法实现 |

## 14. Git 检查

执行：

```text
git diff --stat
```

结果：无输出。原因是 Step 4 只新增四个未跟踪文件，没有修改已跟踪文件。

执行：

```text
git status --short --untracked-files=all
```

结果：

```text
?? "MATLAB\344\270\200\351\224\256\345\256\236\351\252\214/evaluate_phase1a_metrics.m"
?? "MATLAB\344\270\200\351\224\256\345\256\236\351\252\214/phase1a_historical_reference.m"
?? "MATLAB\344\270\200\351\224\256\345\256\236\351\252\214/tests/Phase1AMetricsTest.m"
?? paper_research/phase1a_baseline/STEP4_UNIFIED_METRICS.md
```

Git 的 `MATLAB\344...` 是中文目录 `MATLAB一键实验/` 的转义显示。

## 15. 停止点

Phase 1A Step 4 已完成。当前只建立统一评价层及回归参考；没有运行 AutoComp9，没有生成正式 baseline 数据或图，没有进入 Step 5。
