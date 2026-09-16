# 故障门控消融实验结果

## 实验设置

复用 Phase 2 的 `AI6109_MOA_AutoComp9.slx`、“阻性故障 + 耦合漂移”场景和 `seed=105`。故障从 `3.00 s` 开始并在 `3.06 s` 平滑达到 1.6 倍；故障增幅仍使用 `2.60–2.90 s` 与 `3.40–3.80 s` 两个窗口计算。噪声、真值、初值、CVFF-RLS 参数和评价窗口均不变，唯一变量是 `enableGate=false/true`。

## 简短结果表

| 指标 | 无门控 | 有门控 |
|---|---:|---:|
| Cs1 RMSE / pF | 2.6152 | 0.31526 |
| Cs2 RMSE / pF | 2.5999 | 0.32807 |
| 故障前后 Cs1 估计变化 / pF | +5.0063 | +0.5611 |
| 故障前后 Cs2 估计变化 / pF | −4.9773 | −0.6163 |
| 估计故障增幅 | 1.4023 | 1.5829 |
| 相对真实 1.6000 的保持误差 | −12.358% | −1.0702% |

故障前后窗口内，真实 `Cs1=13 pF`、`Cs2=8 pF`，两者变化均为零。无门控却将参数调整到约 `17.948/3.080 pF`，说明部分阻性故障被耦合参数吸收。门控后对应估计约为 `13.503/7.441 pF`，故障后累计冻结 48 个工频周期，故障增幅得到更完整保留。

该对照支持当前模型与工况范围内的独立技术效果：同一 CVFF-RLS 仅启用故障冻结门控，即可同时抑制相间耦合参数的异常调整，并将故障增幅保持误差从 `−12.358%` 降至 `−1.0702%`。这不是负序、自电容失配或电场传感器条件下的结论。

## 证据文件

- `MATLAB一键实验/results_phase2/gating_ablation/gating_ablation_comparison.png`
- `MATLAB一键实验/results_phase2/gating_ablation/gating_ablation_evidence.mat`
- `MATLAB一键实验/results_phase2/gating_ablation/cs_parameter_change.csv`
- `MATLAB一键实验/results_phase2/gating_ablation/fault_retention_summary.csv`
- `MATLAB一键实验/results_phase2/gating_ablation/tracking_rmse_summary.csv`

复现命令：

```powershell
matlab -batch "results=run_gating_ablation"
```
