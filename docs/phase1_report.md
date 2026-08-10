# Phase 1 正确性修复与回归报告

## 结论

Phase 0 + Phase 1 已完成，未进入 Phase 2。原始 `AI6109_MOA_AutoComp7.slx` 未修改，SHA-256 仍为 `7BBBB729FF91F457D8A9B221055B69123588E6EE28CAF93DE2613B3FF9974CD1`。Phase 1 使用可复现脚本生成 `AI6109_MOA_AutoComp8.slx`，仅参数化三个 MOA MATLAB Function；动态耦合仍未搬入 Simulink。

全量实验成功，自动回归 `11 passed / 0 failed / 0 incomplete`。

## 修改文件及原因

| 文件 | 修改目的 |
|---|---|
| `track_coupling_block_nlms.m` | 用最后一次有效参数填充不足整周期的尾部样本 |
| `track_coupling_cvff_rls.m` | 同上，消除虚假的 MaxErr 峰值 |
| `patent_default_config.m` | 统一参数来源、加入中文单位注释、30 个固定 seed、独立输出目录 |
| `simulate_moa_base.m` | 删除未被模型引用的传模变量，传递 `Vref_moa/Iref_moa/alpha_moa` |
| `scripts/build_or_patch_model.m` | 从 AutoComp7 可复现构建参数化 AutoComp8 |
| `AI6109_MOA_AutoComp8.slx` | Phase 1 模型副本；未改变连接和物理结构 |
| `evaluate_case_metrics.m` | 增加基波相位、三次谐波幅值/相位、波形 RMSE/NRMSE |
| `run_patent_robustness_sweep.m` | SNR 改为 4 等级 × 30 seeds；输出原始值和统计值 |
| `run_all_patent_experiments.m` | 正确报告 `results_phase1/` 输出目录 |
| `run_phase1_validation.m` | 一键构建、全量实验和自动回归入口 |
| `tests/*.m` | 尾部、指标、参数传递、确定性和基线回归测试 |
| `README.md` | 由原中文文件名 README 重命名并更新 Phase 1 说明 |
| `docs/experiment_audit.md` | 固化 Phase 0 环境、模型哈希和修改前基线 |
| `docs/phase1_report.md` | 本报告 |

## Simulink 参数审计

### 修改前实际被 AutoComp7 引用

`C0`、`C_moa`、`C1`、`C2`、`StopTime`、`Ts`、`Un_LL`、`f`、`h3_ratio`、`phi3_deg`、`Vneg_pu`。

### 修改前传入但未被模型引用

| 参数 | Phase 1 处理 |
|---|---|
| `SNR_i` | 删除传模；噪声属于 MATLAB 合成数据链路 |
| `hf_ratio` | 删除传模；模型无引用 |
| `pulse_ratio` | 删除传模；模型无引用 |
| `w` | 删除传模；模型内部由频率配置决定 |
| `Uph` | 不再传模；保留为 MATLAB 后处理派生量 |
| `IR_rms` | 替换为真实进入模型的 `moa_Iref_A` |
| `R_moa` | 删除；模型无引用 |
| `Rs_src` | 删除；模型无引用 |

AutoComp8 新增三个 MATLAB Function 参数：`Vref_moa`、`Iref_moa`、`alpha_moa`。短时仿真验证结果：

- `Iref × 2`：B 相阻性电流 RMS 比值 `2.00000002`；
- `Vref × 1.1`：RMS 比值 `0.564474`；
- `alpha = 5`：RMS 比值 `0.774117`。

## 尾部修复前后

评价窗口保持 `t >= 0.8 s`，没有修改真值或窗口。以下为 CVFF-RLS：

| 场景 | Cs1 MaxErr 修复前 / pF | 修复后 / pF | Cs2 MaxErr 修复前 / pF | 修复后 / pF |
|---|---:|---:|---:|---:|
| 固定耦合基准 | 0.13524 | 0.13524 | 0.10613 | 0.10613 |
| 缓慢漂移 | 3.9726 | 0.40001 | 3.0397 | 0.28518 |
| 平滑阶跃 | 5.0057 | 1.7718 | 4.0031 | 1.3665 |
| 随机波动 | 0.93187 | 0.93187 | 0.73387 | 0.73387 |
| 阻性故障与漂移 | 2.9712 | 0.55513 | 1.9681 | 0.62228 |

随机波动场景的最大误差发生在有效更新区间内，因此修复前后不变；其余动态场景原 MaxErr 被最后 1 个未更新样本放大。

## 主指标是否漂移

| 场景 | 修改前 B 相基波误差 / % | 修改后 / % |
|---|---:|---:|
| 固定耦合基准 | -0.029800 | -0.029800 |
| 缓慢漂移 | 0.32467 | 0.32467 |
| 平滑阶跃 | 0.14364 | 0.14364 |
| 随机波动 | -0.12368 | -0.12368 |
| 阻性故障与漂移 | -0.32494 | -0.32494 |

故障增幅真值仍为 `1.6000`，估计仍为 `1.5770`，保持误差仍为 `-1.4369%`。因此尾部修复没有改变原主要结论。

## 新增指标示例

以下为 CVFF-RLS 的 B 相结果：

| 场景 | 基波相位误差 / deg | 三次幅值误差 / % | 三次相位误差 / deg | 波形 RMSE / A |
|---|---:|---:|---:|---:|
| 固定耦合基准 | 0.028656 | 0.48675 | -0.028896 | 2.7525e-4 |
| 缓慢漂移 | 0.024776 | -0.16332 | 0.12176 | 2.7699e-4 |
| 平滑阶跃 | 0.021554 | -0.017976 | 0.13019 | 2.7604e-4 |
| 随机波动 | -0.018125 | -0.26736 | -0.018427 | 2.7581e-4 |
| 阻性故障与漂移 | 0.087345 | -0.14891 | -0.063291 | 2.7757e-4 |

谐波幅值和相位通过基波与三次谐波联合最小二乘拟合获得；相位误差包裹到 `[-180°,180°)`。波形 RMSE 对评价窗口内的真实与估计阻性电流直接计算，另同步输出 NRMSE。

## SNR Monte Carlo

固定 seed 列表为 `2001:2030`，每个等级 30 次，共 120 行噪声原始结果。`robustness_summary.xlsx` 包含 `SNR原始` 和 `SNR统计` 两个工作表，统计为 mean/std/median/P95；误差类指标先取绝对值再统计。Excel 对数值 `Inf` 的序列化不稳定，因此额外输出 `SNR_label = "Inf (无噪声)"`，MAT 文件中仍保留数值 `Inf`。

| SNR | N | |B 相基波误差| mean / % | std / % | median / % | P95 / % |
|---|---:|---:|---:|---:|---:|
| 无噪声 | 30 | 0.50475 | 2.26e-16 | 0.50475 | 0.50475 |
| 40 dB | 30 | 0.49027 | 0.016857 | 0.48984 | 0.52617 |
| 30 dB | 30 | 0.40967 | 0.050787 | 0.40663 | 0.51620 |
| 20 dB | 30 | 0.18465 | 0.13815 | 0.16210 | 0.50919 |

均值仍不随 SNR 单调恶化，说明随机噪声与现有系统偏差存在抵消，不能据此宣称低 SNR 更好。P95 在 20–40 dB 间约为 `0.509–0.526%`。失败或反直觉结果均已保留。

## 实际执行与测试

主要命令：

```powershell
matlab -batch "run_all_patent_experiments"
matlab -batch "run_patent_robustness_sweep"
matlab -batch "addpath(genpath(pwd)); results=runtests('tests','IncludeSubfolders',true)"
```

自动测试：

- BaselineRegressionTest：3 passed；
- EvaluateCaseMetricsTest：2 passed；
- ModelParameterizationTest：3 passed；
- MonteCarloDeterminismTest：1 passed；
- TrackerTailTest：2 passed；
- 总计：11 passed，0 failed，0 incomplete。

## 基线影响

- `AI6109_MOA_AutoComp7.slx` 哈希未变化；
- 原 `results/` 未写入，文件时间戳保持 2026-08-06；
- Phase 0 隔离证据保存在 `artifacts/phase0_baseline_run/`；
- Phase 1 新结果保存在 `MATLAB一键实验/results_phase1/`；
- 本轮未实现动态耦合 Simulink 支路，未进入 Phase 2。

## 未解决问题与下一阶段建议

1. 原模型仍有 1 个代数环；本轮只记录，未改变结构。
2. 动态总电流仍由 MATLAB 合成，不能表述为完整 Simulink 动态物理模型验证。
3. 参考仍直接使用真实 `ub`，电场传感器链路尚未建立。
4. 单 B 相参考在 1%/3%/5% 负序下的 B 相误差仍约为 `11.193%/35.030%/61.991%`。
5. 自电容仍作为已知常量，尚未做 ±1%/±2%/±5% 失配实验。
6. MOA 本体仍是统一幂律模型；参数已经可配置，但多曲线失配扫描留待后续阶段。

人工确认 Phase 1 后，下一步才建议进入 Phase 2：在不覆盖 AutoComp7 的前提下，把动态 Cs1/Cs2 总泄漏电流真正放入 Simulink，并用静态解析一致性测试先验收。
