# Fig.2 数据包说明：故障吸收机理验证

本目录仅包含 Origin 可直接导入的数据，不包含最终论文图。数据来自已经冻结的 Phase1B Case05/Case06 正式结果；本次未运行仿真、未修改模型、算法、实验定义或原始结果。

## 1. 数据处理边界

- 未平滑、未滤波、未插值、未重采样。
- Panel (a)、(b) 逐行复制 Phase1B 正式 cycle summary；每行对应一次完整 50 Hz 周期更新。
- Panel (c) 从正式 MAT workspace 中连续截取 `[3.40, 3.44) s`，共 2000 个原始样本，即两个完整 50 Hz 周期。该区间位于 Phase1B 正式 post-fault 窗口 `[3.40, 3.80) s` 内，且故障倍率已稳定为 1.6。
- Panel (d) 逐字段复制正式 key metrics。CSV 保留正式文件中的完整数值精度。
- CSV 中可能出现 `3.4000000000000004` 一类十进制文本，这是源 MATLAB double 的无损往返表示，不是时间重采样。Origin 中可仅调整坐标轴显示位数，不要改写数据列。

## 2. 文件与列定义

### `fig2a_fault_factor.csv`

来源：

- Case05：`paper_research/phase1b_fault_absorption/step2/case05_mechanism_summary.csv`
- Case06：`paper_research/phase1b_fault_absorption/step3/case06_mechanism_summary.csv`

时间范围：cycle-end 时间 `0.71998–3.99998 s`，165 行；这是正式在线辨识更新序列的完整范围。

| 列名 | 单位 | 来源字段 | 属性 |
|---|---:|---|---|
| `cycle_index` | 1 | `cycle_index` | 原始正式值 |
| `time_s` | s | 两个 case 共同的 `time_end_s` | 原始正式值 |
| `case05_fault_factor` | 1 | Case05 `fault_factor_true` | 原始正式值 |
| `case06_fault_factor` | 1 | Case06 `fault_factor_true` | 原始正式值 |

### `fig2b_case05_cs.csv`

来源：`paper_research/phase1b_fault_absorption/step2/case05_mechanism_summary.csv`。

时间范围：cycle-end 时间 `0.71998–3.99998 s`，165 行。

| 列名 | 单位 | 来源字段 | 属性 |
|---|---:|---|---|
| `cycle_index` | 1 | `cycle_index` | 原始正式值 |
| `time_s` | s | `time_end_s` | 原始正式值 |
| `cs1_truth_pF` | pF | `Cs1_true_pF` | 原始正式值 |
| `cs1_vff_rls_estimate_pF` | pF | `Cs1_est_pF`，M2 ungated VFF-RLS | 原始正式值 |
| `cs2_truth_pF` | pF | `Cs2_true_pF` | 原始正式值 |
| `cs2_vff_rls_estimate_pF` | pF | `Cs2_est_pF`，M2 ungated VFF-RLS | 原始正式值 |

### `fig2b_case06_cs.csv`

来源：`paper_research/phase1b_fault_absorption/step3/case06_mechanism_summary.csv`。

时间范围与列定义同 `fig2b_case05_cs.csv`。Case06 的 truth 列包含冻结实验中 `0.8–2.2 s` 的真实耦合电容漂移，estimate 列仍为正式 M2 ungated VFF-RLS 结果。

### `fig2c_case05_waveform.csv` 与 `fig2c_case06_waveform.csv`

来源：

- Case05：`paper_research/phase1b_fault_absorption/step2/case05_mechanism_workspace.mat`
- Case06：`paper_research/phase1b_fault_absorption/step3/case06_mechanism_workspace.mat`

时间窗口：`[3.40, 3.44) s`；2000 个连续样本；采样间隔 `20 µs`；两个完整 50 Hz 周期。没有抽点或补点。

| 列名 | 单位 | 来源/定义 | 属性 |
|---|---:|---|---|
| `sample_index` | 1 | 正式全长数组中的 MATLAB 1-based 样本索引 | 由窗口掩码取得的索引 |
| `time_s` | s | `data.t` | 原始正式值 |
| `time_from_window_start_s` | s | `time_s - time_s(1)` | 本数据包派生，仅用于 Origin 横轴；首点严格为 0 |
| `true_fault_increment_B_A` | A | `analysis.rFaultB` | Phase1B 正式派生数组的原值 |
| `false_coupling_compensation_B_A` | A | `analysis.deltaCouplingB` | Phase1B 正式派生数组的原值 |

上述两个正式派生数组在 Phase1B 中定义为：

```matlab
rFaultB = (1 - 1./signals.fault_scale) .* data.irB;
deltaC = instrumented.fault.hist - instrumented.counterfactual.hist;
deltaCouplingB = deltaC(:,1)*1e-12.*(ref.dub-ref.dua) + ...
                 deltaC(:,2)*1e-12.*(ref.dub-ref.duc);
```

本次打包没有重新计算这两个波形，而是直接读取 workspace 中已经保存的 `analysis.rFaultB` 与 `analysis.deltaCouplingB`。若论文纵轴需要 mA，可在 Origin 中用显示换算或新建派生列乘以 `1e3`，原始 A 列应保留。

### `fig2d_summary.csv`

来源：

- `paper_research/phase1b_fault_absorption/step2/case05_key_metrics.csv`
- `paper_research/phase1b_fault_absorption/step3/case06_key_metrics.csv`

指标定义窗口：正式 pre-fault 窗口 `[2.60, 2.90) s` 与 post-fault 窗口 `[3.40, 3.80) s`。

| 列名 | 单位 | 来源字段 | 属性 |
|---|---:|---|---|
| `case_id` | — | 数据包标签 `Case05` / `Case06` | 本数据包标签 |
| `case_name` | — | `case_name` | 原始正式值 |
| `true_fault_factor` | 1 | `true_fault_factor` | Phase1B 正式派生指标 |
| `vff_rls_estimated_fault_factor` | 1 | `M2_actual_fault_factor` | Phase1B 正式派生指标 |
| `counterfactual_parameter_fault_factor` | 1 | `counterfactual_parameter_fault_factor` | Phase1B 正式派生指标 |

## 3. Summary 与正式报告一致性

| Case | True factor | VFF-RLS estimated factor | Counterfactual-parameter factor | 正式报告六位小数 |
|---|---:|---:|---:|---|
| Case05 | 1.59999999999967 | 1.40107479735928 | 1.60105115428053 | 1.600000 / 1.401075 / 1.601051 |
| Case06 | 1.59999999999967 | 1.40226869710244 | 1.60264742837203 | 1.600000 / 1.402269 / 1.602647 |

六位小数结果与 `paper_research/phase1b_fault_absorption/PHASE1B_FAULT_ABSORPTION_REPORT.md` 第 6 节的 `M2 factor` 和 `counterfactual recovery` 完全一致。真值均按正式 key metrics 为 1.6。

## 4. 来源完整性记录

| 来源文件 | SHA-256 |
|---|---|
| `MATLAB一键实验/AI6109_MOA_AutoComp9.slx` | `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70` |
| `step2/case05_mechanism_summary.csv` | `F20A07ED08120951245A5F96342FBB1B051040C427154BD274779E8145E57A74` |
| `step2/case05_key_metrics.csv` | `889FB69A32A17D5E55998C68DF99D11E02389A7C0631B4FCAFA05F368C62830A` |
| `step2/case05_mechanism_workspace.mat` | `AA585D987828728479BE4C521DFEFBD339120ECBD30C9E1DD9FAED216587A112` |
| `step3/case06_mechanism_summary.csv` | `009969AF53D04BCFBAECF4B812C53C50D20D299383285A99156B32B5988D6238` |
| `step3/case06_key_metrics.csv` | `783D223B4A10DF654DC32A9C0579493397871B63EEB7D4796E435B222627E574` |
| `step3/case06_mechanism_workspace.mat` | `9E3190869BCF764841F062EDB0F152DADE56D1DDA2F3C85B55F0DD4915C553A4` |

生成后校验结果：cycle-level 原始列逐字符串一致；两份 waveform CSV 相对正式 MAT 数组的最大数值差均为 0；summary 字段逐字符串一致，且报告中的六位小数值全部命中。
