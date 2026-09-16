# Phase 1A — Step 1：Baseline Freeze and Research Scaffold

执行日期：2026-09-16  
冻结时间：`2026-09-16T16:22:02+08:00`  
执行范围：只冻结 AutoComp9 基线并创建 Phase 1A 元数据、Case Registry、Algorithm Registry 和 Result Schema；未运行 MATLAB/Simulink，未进入 Step 2。

## 1. Baseline 冻结记录

| 字段 | 冻结值 |
|---|---|
| `baseline_model` | `AI6109_MOA_AutoComp9` |
| `baseline_model_path` | `MATLAB一键实验/AI6109_MOA_AutoComp9.slx` |
| 绝对路径 | `D:/Codex/MOA_Arrester/MATLAB一键实验/AI6109_MOA_AutoComp9.slx` |
| `baseline_model_sha256` | `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70` |
| `baseline_integrity` | `PASS` |
| `git_branch` | `main` |
| `git_commit` | `fc9d2a99ec06dd8c236258804986b17b35c64e1c` |
| `git_dirty_status` | `CLEAN`（冻结瞬间、创建 Step 1 文件之前） |
| `freeze_timestamp` | `2026-09-16T16:22:02+08:00` |

独立计算的 AutoComp9 SHA-256 与 `PHASE1A_IMPLEMENTATION_AUDIT.md` 中冻结目标完全一致，因此允许继续建立脚手架。AutoComp9 本体未打开、未另存、未覆盖、未修改。

## 2. 建立的独立论文目录

```text
paper_research/
  phase1a_baseline/
    figures/
    STEP1_FREEZE_AND_SCAFFOLD.md
```

`figures/` 目前只有用于保留空目录的 `.gitkeep`，没有生成任何实验图。以下最终产物本轮均未创建：

- `baseline_summary.csv`
- `baseline_workspace.mat`
- `PHASE1A_BASELINE_REPORT.md`

## 3. 本轮新增文件

| 文件 | 用途 |
|---|---|
| `MATLAB一键实验/phase1a_baseline_metadata.m` | 返回冻结模型、哈希、Git 和输出根目录元数据 |
| `MATLAB一键实验/phase1a_case_registry.m` | 定义六个正式 case 的名称、旧名称、seed、历史证据状态和运行需求 |
| `MATLAB一键实验/phase1a_algorithm_registry.m` | 冻结 M0/M2/M3 编号及其现有实现映射 |
| `MATLAB一键实验/phase1a_result_schema.m` | 定义未来统一结果表的字段、类型、行粒度和 NaN 规则 |
| `paper_research/phase1a_baseline/figures/.gitkeep` | 保留正式图目录，不含实验数据 |
| `paper_research/phase1a_baseline/STEP1_FREEZE_AND_SCAFFOLD.md` | 本 Step 1 冻结与验收记录 |

## 4. 本轮修改文件

**无。** 本轮只新增文件和目录，没有修改任何既有文件。

特别确认以下受保护文件没有 tracked diff：

- `AI6109_MOA_AutoComp9.slx`
- `track_coupling_cvff_rls.m`
- `initial_coupling_estimate.m`
- `coupling_regressor.m`
- `extract_resistive_current.m`
- `reconstruct_refs_from_b.m`
- `patent_default_config.m`
- `run_phase2_simulink_dynamic.m`
- `run_gating_ablation.m`

`results/`、`results_phase1/`、`results_phase2/` 也没有 tracked diff。

## 5. Case Registry

正式来源：`MATLAB一键实验/phase1a_case_registry.m`。

| `case_name` | `legacy_scenario_name` | `seed` | `duration_s` | `model` | `source_type` | `historical_result_available` | `requires_phase1a_run` | 说明 |
|---|---|---:|---:|---|---|---|---|---|
| `Case01_static` | `static` | 101 | 4.0 | `AI6109_MOA_AutoComp9.slx` | `autocomp9_partial` | true | true | AutoComp9 仅有静态链路一致性，缺统一 M0/M2/M3 结果 |
| `Case02_slow_drift` | `slow_drift` | 102 | 4.0 | `AI6109_MOA_AutoComp9.slx` | `autocomp9_partial` | true | true | 已有 M0/M3 历史指标，缺 M2 和统一结果结构 |
| `Case03_smooth_step` | `smooth_step` | 103 | 4.0 | `AI6109_MOA_AutoComp9.slx` | `legacy_matlab_synthetic_only` | true | true | 只有旧 MATLAB 合成链结果；轨迹迁移留到 Step 2 |
| `Case04_random_drift` | `random_drift` | 104 | 4.0 | `AI6109_MOA_AutoComp9.slx` | `legacy_matlab_synthetic_only` | true | true | 只有旧 MATLAB 合成链结果；轨迹迁移留到 Step 2 |
| `Case05_fault_only` | `fault_only` | `NaN` | 4.0 | `AI6109_MOA_AutoComp9.slx` | `none` | false | true | 没有历史定义或结果；seed 与轨迹留到 Step 2 确认 |
| `Case06_drift_then_fault` | `fault_with_drift` | 105 | 4.0 | `AI6109_MOA_AutoComp9.slx` | `autocomp9_fragmented` | true | true | 当前语义一致，但历史证据分散，需统一输出 |

Case05 的 seed 使用 `NaN`，因为当前没有历史定义；本轮没有擅自选择新 seed，也没有设计 fault-only 数学轨迹。

## 6. Algorithm Registry

正式来源：`MATLAB一键实验/phase1a_algorithm_registry.m`。

| `algorithm_mode` | `algorithm_name` | `enabled` | `implementation_source` | `gate_enabled` | 说明 |
|---|---|---|---|---|---|
| `M0` | Fixed coupling compensation | true | `initial_coupling_estimate.m` + 既有入口中的冻结 `c0` 历史 | false | 初始化 LS 后全程冻结 |
| `M2` | VFF-RLS without fault gate | true | `track_coupling_cvff_rls.m(..., false)` | false | 保留 VFF、变化率限制和物理投影，仅关闭故障门控 |
| `M3` | VFF-RLS with existing hard fault gate | true | `track_coupling_cvff_rls.m(..., true)` | true | 与 M2 参数和公式相同，仅启用既有硬门控 |

没有创建 M1、M4、软门控、`P_X` 或 `eta_abs`，也没有复制 RLS 内部公式。

## 7. Result Schema

正式来源：`MATLAB一键实验/phase1a_result_schema.m`。行粒度固定为：

```text
one row per case x algorithm
```

字段定义：

| 字段 | 类型 | 用途 |
|---|---|---|
| `case_name` | string | 正式 case 名 |
| `algorithm_mode` | string | M0/M2/M3 |
| `Cs1_RMSE_pF` | double | Cs1 跟踪 RMSE |
| `Cs2_RMSE_pF` | double | Cs2 跟踪 RMSE |
| `B_resistive_fundamental_error_pct` | double | B 相阻性电流基波误差 |
| `fault_factor_true` | double | 真实故障增幅 |
| `fault_factor_est` | double | 估计故障增幅 |
| `fault_retention_error_pct` | double | 故障增幅保持误差 |
| `Cs1_pre_post_change_pF` | double | 故障前后 Cs1 估计变化 |
| `Cs2_pre_post_change_pF` | double | 故障前后 Cs2 估计变化 |
| `first_gate_trigger_s` | double | 首次门控触发时刻 |
| `gate_duration_cycles` | double | 门控持续周期数 |
| `gate_duration_s` | double | 门控持续秒数 |
| `random_seed` | double | 本次 case 随机 seed |
| `model_file` | string | 使用的模型文件 |
| `model_sha256` | string | 运行时模型哈希 |
| `run_timestamp` | string | 运行时间戳 |
| `git_commit` | string | 运行时 Git commit |
| `git_branch` | string | 运行时 Git branch |
| `git_dirty_status` | string | 运行时工作区状态 |

Schema 规则明确规定：任何不适用的数值指标必须写 `NaN`，禁止用 `0` 冒充不适用。本轮只创建内存中的空表定义，没有输出空 CSV 或伪造结果。

## 8. Step 1 验收

| 编号 | 验收项 | 结果 | 依据 |
|---|---|---|---|
| A | AutoComp9 哈希与审计值一致 | **PASS** | 两次独立 SHA-256 计算均得到 `56067...A70` |
| B | 建立 `paper_research/phase1a_baseline/figures/` | **PASS** | 两级目录均存在 |
| C | 建立六个正式 case registry | **PASS** | 六个正式名称和 legacy 映射均存在 |
| D | 建立 M0/M2/M3 algorithm registry | **PASS** | 仅包含 M0、M2、M3 |
| E | 建立正式 baseline result schema | **PASS** | 20 个字段、类型和 NaN 规则已定义 |
| F | 未修改算法核心文件 | **PASS** | 受保护文件 `git diff --name-only` 为空 |
| G | 未修改历史结果 | **PASS** | 三个历史结果目录 `git diff --name-only` 为空 |
| H | 未启动正式 AutoComp9 六工况实验 | **PASS** | 本轮未调用 MATLAB、`sim` 或任何实验入口 |

## 9. 最终 Git 检查

执行：

```text
git diff --stat
```

结果：无输出。原因是本轮没有修改 tracked 文件，当前变更全部是新增的未跟踪文件。

执行：

```text
git status --short
```

结果：

```text
?? "MATLAB\344\270\200\351\224\256\345\256\236\351\252\214/phase1a_algorithm_registry.m"
?? "MATLAB\344\270\200\351\224\256\345\256\236\351\252\214/phase1a_baseline_metadata.m"
?? "MATLAB\344\270\200\351\224\256\345\256\236\351\252\214/phase1a_case_registry.m"
?? "MATLAB\344\270\200\351\224\256\345\256\236\351\252\214/phase1a_result_schema.m"
?? paper_research/
```

上述 `MATLAB\344...` 是 Git 对中文目录 `MATLAB一键实验/` 的转义显示。生成本报告后 `paper_research/` 仍由同一条目录级状态覆盖，因此最终 short status 的顶层条目不变。

## 10. 停止点

Phase 1A Step 1 已完成。本轮没有创建运行入口、指标计算实现或工况轨迹，没有运行六工况，也没有进入 Step 2。
