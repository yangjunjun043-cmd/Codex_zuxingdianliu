# Fig.3 数据说明：不同故障程度下的自适应响应

## 数据用途

本目录仅整理现有冻结数据，用于中文核心论文 Fig.3 “不同故障程度下的自适应响应 / Fault severity validation”。未重新运行仿真，未修改算法、模型、参数或原始结果；未进行平滑、拟合、插值或人为补点。

Fig.3 只展示故障程度变化下的观测响应，不用于算法综合排名，也不把当前 M3 的触发转变区解释为普适故障阈值。

## 方法名映射

| 内部编号 | 论文方法名 |
|---|---|
| M2 | VFF-RLS |
| M3 | HG-VFF-RLS |
| M4 | REW-VFF-RLS |

## 数据来源

- Step2B-2 新 fault-amplitude 条件：`paper_research/phase2_full_validation/step2b2_deterministic_core/step2b2_deterministic_results.csv`。
- 1.60 锚点注册关系：`paper_research/phase2_full_validation/step1_matrix_spec/phase2_condition_registry.csv` 中的 `P2_AN_C05` 与 `P2_AN_C06`，均为 `EXACT_REUSE`、`is_anchor=TRUE`、`is_new_phase2_condition=FALSE`。
- 1.60 的 M2/M3 基线核对：`paper_research/phase1a_baseline/baseline_summary.csv`。
- 1.60 的 M2/M3/M4 retention 与 fault-induced ΔCs：`paper_research/phase1c_m4_method/step4_fault_preservation/tables/fault_preservation_summary.csv`。
- 1.60 的 M3 hard-gate ratio：同一冻结 Step4 目录中的正式伴随表 `paper_research/phase1c_m4_method/step4_fault_preservation/tables/m3_gate_response_summary.csv`。指定的 fault-preservation summary 不包含该列，因此未从 gate duration 反推。
- 1.60 的 M4 fault-window mean update weight：同一冻结 Step4 目录中的正式伴随表 `paper_research/phase1c_m4_method/step4_fault_preservation/tables/m4_fault_response_summary.csv` 的 `fault_mean_g`。指定的 fault-preservation summary 不包含该列，因此未从其他指标重算。

## family 处理

- `fault_only`：主作图 severity chain；包含 1.05、1.10、1.20、1.30、1.40 的 Step2B-2 新条件和 1.60 的冻结 Case05 锚点。
- `drift_then_fault`：独立复核数据；包含相同六个 fault factor，但不与 `fault_only` 平均，也不视作重复独立样本。

## fig3_master.csv 字段

| 列名 | 物理含义 | 单位/取值 |
|---|---|---|
| fault_factor | B 相阻性电流故障倍率的名义设定值 | 无量纲 |
| family | 工况族标记 | fault_only / drift_then_fault |
| algorithm_internal | 内部算法编号 | M2 / M3 / M4 |
| algorithm_paper_name | 论文方法名 | VFF-RLS / HG-VFF-RLS / REW-VFF-RLS |
| Cs_fault_induced_bias_norm_pF | fault/counterfactual 两分支的故障诱导参数偏差向量二范数 | pF |
| fault_retention_error_pct | 故障增幅保持误差，保留原始正负号 | % |
| abs_fault_retention_error_pct | 上一列的绝对值，仅便于 Fig.3(b) 数据复核 | % |
| hard_gate_active_ratio | M3 在正式故障窗口内的 hard-gate 激活比例 | 0–1；M2/M4 为 NaN |
| mean_update_weight | M4 在正式故障窗口内的平均连续更新权重 | 0–1；M2/M3 为 NaN |
| source_file | 该行指标使用的冻结源文件；多个源以分号分隔 | 相对路径 |
| anchor_reuse | 是否为 1.60 冻结锚点复用 | TRUE / FALSE |

1.60 的 `Cs_fault_induced_bias_norm_pF` 仅由冻结表中正式的 `DeltaCs1_fault_induced_pF` 与 `DeltaCs2_fault_induced_pF` 按与 Step2B-2 相同的二范数定义整理；未读取仿真工作区、未重新运行模型。

## 作图文件

- Fig.3(a)：`fig3a_bias_norm.csv`，仅含 `fault_only`，三种方法的 fault-induced parameter bias norm。
- Fig.3(b)：`fig3b_retention_error.csv`，仅含 `fault_only`，只在此作图宽表中使用 retention error 绝对值。signed 值保留在 `fig3_master.csv`。
- Fig.3(c)：`fig3c_gate_weight.csv`，仅含 `fault_only`，M3 hard-gate active ratio 与 M4 mean update weight 共用 0–1 Y 轴。

所有 fault factor 均按升序排列。CSV 保留冻结源中的有效数字；小数位显示由 Origin 控制。
