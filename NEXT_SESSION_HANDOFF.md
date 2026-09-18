# NEXT SESSION HANDOFF — MOA 中文核心论文研究

核对日期：2026-09-17
项目根目录：`D:/Codex/MOA_Arrester`
当前 Git 分支：`main`
核对时 HEAD：`91e1b3efc8d2bf637c3fa30865d44c7691330fe5`

本文是下一段 Codex 对话的项目交接入口。内容来自当前目录中的代码、报告、CSV、MAT
文件元数据和 Git 历史核对，不以聊天记忆作为事实来源。本次仅整理交接，没有运行
MATLAB/Simulink，没有修改任何模型、算法、参数或实验结果。

## 状态标记

- **FROZEN**：已冻结的正式版本、参数、结果或回归基准。下一阶段不得无授权改写。
- **DEPRECATED**：已淘汰为“当前正式论文主证据/主路线”的方案；文件可能仍保留供历史追溯。
- **TODO**：尚未完成，不能表述成已经实现或已经验证。
- **HISTORICAL / NON-FORMAL**：实际存在且可能有参考价值，但不是当前 Phase 1A 正式论文结果。

---

## 1. 当前研究总目标

研究面向金属氧化物避雷器（MOA）在线监测，目标是形成可用于发明专利和中文核心论文的
阻性电流提取方法与证据链。当前推荐主线是：

1. 建立三相 MOA 总泄漏电流中的自身电容和相间耦合电容模型；
2. 在线辨识 A-B、B-C 相间耦合参数 `Cs1/Cs2`；
3. 使用带物理范围投影、单周期变化率限制和变遗忘因子的 RLS 跟踪耦合变化；
4. 使用 `E_in/E_quad` 残差方向信息和故障门控，避免真实阻性故障被参数估计吸收；
5. 扣除估计的容性及耦合电流，提取三相阻性电流；
6. 后续补充模型有效性、置信度、传感器误差、三相不平衡和鲁棒性证据；
7. 最终形成可复现的论文图表、定量指标、消融实验和实验验证。

普通 LMS、单一等效电容补偿、普通 FFT 补偿或“无 PT”本身不是当前拟强调的创新核心。

---

## 2. 当前阶段目标

### 2.1 已结束阶段

**FROZEN — Phase 1A：统一论文 Baseline Framework，状态 COMPLETE。**

Phase 1A 的目标不是发明新算法，而是冻结以下公平比较基础：

- 同一个正式 Simulink 模型；
- 六个统一 Case；
- M0/M2/M3 统一算法入口；
- 统一结果 schema、NaN 规则、评价指标和复现元数据；
- 一套正式 CSV/MAT/图/报告；
- 对历史 slow-drift 和 drift-then-fault 关键数值进行严格回归。

### 2.2 下一阶段

**TODO — Phase 1B：Fault Absorption Mechanism。**

下一阶段首先应定量解释：为何无门控 VFF-RLS 在阻性故障发生时会把一部分故障信息吸收到
`Cs1/Cs2` 参数中，以及现有硬门控为何能够缓解但不能完全消除该现象。Phase 1B 尚未启动，
尚未正式定义或实现 `P_X`、`eta_abs`、M4、soft gate 或 direction-aware update。

---

## 3. 已完成工作

### 3.1 Phase 1A 统一框架

- **FROZEN** 六工况 Case Registry：
  `MATLAB一键实验/phase1a_case_registry.m`
- **FROZEN** 三算法 Algorithm Registry：
  `MATLAB一键实验/phase1a_algorithm_registry.m`
- **FROZEN** 统一调度器：
  `MATLAB一键实验/run_phase1a_algorithm.m`
- **FROZEN** 20 字段结果 schema：
  `MATLAB一键实验/phase1a_result_schema.m`
- **FROZEN** 统一指标：
  `MATLAB一键实验/evaluate_phase1a_metrics.m`
- **FROZEN** 六工况正式 runner 与 validator：
  `MATLAB一键实验/run_phase1a_baseline.m`、
  `MATLAB一键实验/validate_phase1a_baseline.m`
- **FROZEN** 历史参考与容差：
  `MATLAB一键实验/phase1a_historical_reference.m`
- **FROZEN** 模型哈希与冻结元数据：
  `MATLAB一键实验/phase1a_baseline_metadata.m`

### 3.2 Case05 兼容性修复

第一次 Step 6 在 `Case05_fault_only` 失败，原因是
`MATLAB一键实验/synthesize_dynamic_case.m` 缺少 `fault_only` 分支。Step 6A 仅增加了
缺失接口，使 Case05 保持 `Cs1=Cs2=10 pF`，并使用与 Case06 相同的
`3.00–3.06 s`、`1.0→1.6` 故障轨迹。

专项测试位于：

- `MATLAB一键实验/tests/Phase1AFaultOnlyCompatibilityTest.m`
- `paper_research/phase1a_baseline/STEP6A_FAULT_ONLY_COMPATIBILITY_FIX.md`

验证结果为 12/12 PASS，Case06 冻结向量修改前后哈希相同。

### 3.3 正式六工况运行与历史回归

- Step 6 正式运行：6 cases × 3 algorithms = 18 rows；validator 19/19 PASS。
- Step 7 历史回归：Case02 4/4 PASS，Case06 7/7 PASS，总计 11/11 PASS。
- 正式图：三组 PNG/FIG 已从正式 workspace 只读生成并视觉检查。
- 最终报告：A–V 验收全部 PASS。

对应报告：

- `paper_research/phase1a_baseline/STEP6_FORMAL_BASELINE_RUN.md`
- `paper_research/phase1a_baseline/STEP7_HISTORICAL_REGRESSION.md`
- `paper_research/phase1a_baseline/PHASE1A_BASELINE_REPORT.md`

### 3.4 已有算法与工程基础

- M0：初始化窗口联合 LS，之后固定补偿；
- M2：VFF-RLS + 变化率限制 + `[0,40] pF` 投影，不启用故障门控；
- M3：与 M2 相同，仅启用现有 hard fault gate；
- `E_in/E_quad` 周期残差分解；
- `baseIn` 慢速基线、门控保持、参数冻结；
- AutoComp9 中动态 Cs 直接进入 Simulink 总泄漏电流链；
- tracker 尾部样本填充修复；
- 历史 Phase 1 中已有扩展幅相/波形指标、30-seed SNR Monte-Carlo 和单元测试，但这些
  不属于 Phase 1A 的 18 行正式 deterministic baseline。

---

## 4. 已验证结论

### 4.1 Phase 1A 完整性

- **FROZEN** 正式模型是 `MATLAB一键实验/AI6109_MOA_AutoComp9.slx`。
- 模型 SHA-256：
  `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70`。
- 六个 Case 均通过统一入口生成；每个 Case 的 M0/M2/M3 共用同一份正式 noisy data。
- 18 行结果具有 6 个唯一 Case、3 个唯一算法和 18 个唯一组合。
- 不适用数值使用 NaN，不用 0 冒充。
- Phase 1A 的历史关键证据在冻结容差下 11/11 精确复现。

### 4.2 Case02 — Slow drift

正式来源：`paper_research/phase1a_baseline/baseline_summary.csv`。

| 指标 | 正式值 |
|---|---:|
| M0 B 相阻性基波误差 | `8.9587533463069 %` |
| M2/M3 B 相阻性基波误差 | `0.354785857594943 %` |
| M2/M3 Cs1 RMSE | `0.157320251866564 pF` |
| M2/M3 Cs2 RMSE | `0.108513587962671 pF` |

结论：动态耦合下固定补偿误差明显增加；在线 VFF-RLS 能跟踪慢漂移。无故障时 M2/M3
结果相同，说明 hard gate 没有改变该工况的正常更新。

### 4.3 Case05 — Fault only

| Mode | 估计故障倍率 | Cs1 前后变化/pF | Cs2 前后变化/pF |
|---|---:|---:|---:|
| M0 | `1.60457534329617` | 约 `0` | 约 `0` |
| M2 | `1.40107479735928` | `+4.91677374531756` | `-4.95699445662807` |
| M3 | `1.58113711210479` | `+0.457519176229072` | `-0.618287543571657` |

### 4.4 Case06 — Drift then fault

| 指标 | M2 | M3 |
|---|---:|---:|
| 真实故障倍率 | `1.59999999999967` | `1.59999999999967` |
| 估计故障倍率 | `1.40226869710244` | `1.58287648629316` |
| Cs1 前后变化 | `+5.00627092717497 pF` | `+0.561114929229058 pF` |
| Cs2 前后变化 | `-4.97734794650682 pF` | `-0.616252631092842 pF` |
| fault retention error | `-12.3582064310797 %` | `-1.07021960665711 %` |

M3 在 Case05/06 的首次 gate 均为 `3.05998 s`，累计 48 cycles，即 `0.96 s`。

可作出的有限结论是：阻性故障存在时，无门控自适应参数出现明显偏移，同时故障增幅估计
被削弱；现有 hard gate 显著缓解该现象。尚不能声称 fault absorption 的完整机理已经被
定量证明，也不能据此宣称 M3 在所有工况下最优。

### 4.5 已知模型边界

- 当前参考仍直接使用理想 `data.ub`；没有真实电场传感器链 `eB_meas`。
- A/B/C 基波按 `+120°/0/-120°` 平衡关系重构，三次谐波假定三相同相。
- 自身电容固定为 `C0 + C_moa = 400 pF`。
- 只辨识 A-B、B-C 两个耦合参数，没有 A-C 耦合。
- 动态电容电流采用准静态 `C(t)·du/dt`，未加入 `u·dC/dt`。
- 默认电流噪声为 30 dB；没有电场传感器增益、偏置、漂移和独立 50/150 Hz 相移模型。
- 已有历史负序扫描表明单 B 相参考在 1%/3%/5% 负序下误差约
  `11.193%/35.030%/61.991%`；尚无 result-validity gate。

---

## 5. 当前正式模型、代码和脚本

### 5.1 正式模型

| 状态 | 路径 | 角色 |
|---|---|---|
| **FROZEN** | `MATLAB一键实验/AI6109_MOA_AutoComp9.slx` | Phase 1A 唯一正式模型；输出动态耦合下的三相总泄漏电流和阻性真值 |
| HISTORICAL | `MATLAB一键实验/AI6109_MOA_AutoComp7.slx` | 原始基线模型；不作为当前正式论文模型 |
| HISTORICAL | `MATLAB一键实验/AI6109_MOA_AutoComp8.slx` | 参数化 MOA 模型；旧 Phase 1/合成链使用 |
| NON-FORMAL | `MATLAB一键实验/AI6109_MOA_AutoComp10.slx` | AutoComp9 布局整理版；做过有限布局一致性验证，不是 Phase 1A 冻结模型 |
| NON-FORMAL | `MATLAB一键实验/AI6109_MOA_AutoComp11.slx` | 后续实验模型；缺少等价的可复现构建说明和 Phase 1A 正式冻结证据 |

### 5.2 正式执行链

```text
MATLAB一键实验/run_phase1a_baseline.m
  -> MATLAB一键实验/phase1a_baseline_metadata.m
  -> MATLAB一键实验/patent_default_config.m
     （runner 将 cfg.model 从默认 AutoComp8 显式覆盖为 FROZEN AutoComp9）
  -> MATLAB一键实验/phase1a_case_registry.m
  -> MATLAB一键实验/generate_coupling_signals.m
  -> MATLAB一键实验/simulate_phase2_case.m
     -> MATLAB一键实验/AI6109_MOA_AutoComp9.slx
     -> MATLAB一键实验/synthesize_dynamic_case.m
        （仅保留历史 reference/noise 兼容角色，不是正式总电流主证据）
  -> MATLAB一键实验/reconstruct_refs_from_b.m
  -> MATLAB一键实验/run_phase1a_algorithm.m
     -> MATLAB一键实验/initial_coupling_estimate.m
     -> MATLAB一键实验/track_coupling_cvff_rls.m
     -> MATLAB一键实验/extract_resistive_current.m
  -> MATLAB一键实验/evaluate_phase1a_metrics.m
  -> MATLAB一键实验/validate_phase1a_baseline.m
  -> paper_research/phase1a_baseline/baseline_summary.csv
  -> paper_research/phase1a_baseline/baseline_workspace.mat
```

### 5.3 正式只读复核和绘图脚本

- `MATLAB一键实验/run_phase1a_step7_regression.m`：只读取正式 CSV 与冻结 historical reference；
- `MATLAB一键实验/generate_phase1a_baseline_figures.m`：只读取正式 MAT 生成三组图；
- 两者均不调用 `sim`、`simulate_phase2_case` 或 `run_phase1a_baseline`。

### 5.4 正式测试

- `MATLAB一键实验/tests/Phase1ACaseSignalTest.m`
- `MATLAB一键实验/tests/Phase1AAlgorithmDispatcherTest.m`
- `MATLAB一键实验/tests/Phase1AMetricsTest.m`
- `MATLAB一键实验/tests/Phase1AFaultOnlyCompatibilityTest.m`

其他测试位于 `MATLAB一键实验/tests/`，用于历史 Phase 1 的参数化、指标、尾部填充、
Monte-Carlo 可重复性等验证；测试通过不等于产生了正式论文结果。

---

## 6. 当前正式实验数据

### 6.1 正式数据文件

| 状态 | 路径 | 大小/bytes | SHA-256 | Git 状态 |
|---|---|---:|---|---|
| **FROZEN FORMAL** | `paper_research/phase1a_baseline/baseline_summary.csv` | `5,821` | `E7BEB3ECFEDF521105B67198684752BB32AFAAEFD84ACA80822BA57FBD9D0AB3` | 已提交 |
| **FROZEN FORMAL** | `paper_research/phase1a_baseline/baseline_workspace.mat` | `115,337,063` | `A90632B72479E7B6ADC4E410DB37542E9CA4985CA8381B6BAFC8F71C961E87B5` | 本地保留、未提交 |

`baseline_workspace.mat` 虽未进入普通 Git commit，但它是正式研究数据，不是临时文件。
未提交原因是体积约 110 MiB。它保存 `cfg`、Case/Algorithm Registry、schema、historical
reference、18 行结果、run metadata、`caseData`、`algorithmResults` 和 validation。

### 6.2 正式图

- `paper_research/phase1a_baseline/figures/figure1_case02_slow_drift_tracking.png`
- `paper_research/phase1a_baseline/figures/figure1_case02_slow_drift_tracking.fig`
- `paper_research/phase1a_baseline/figures/figure2_case06_fault_parameter_tracking.png`
- `paper_research/phase1a_baseline/figures/figure2_case06_fault_parameter_tracking.fig`
- `paper_research/phase1a_baseline/figures/figure3_case06_B_resistive_current.png`
- `paper_research/phase1a_baseline/figures/figure3_case06_B_resistive_current.fig`

### 6.3 正式报告

- `paper_research/phase1a_baseline/PHASE1A_BASELINE_REPORT.md`
- `paper_research/phase1a_baseline/STEP7_HISTORICAL_REGRESSION.md`
- `paper_research/phase1a_baseline/STEP6_FORMAL_BASELINE_RUN.md`
- `paper_research/phase1a_baseline/STEP6A_FAULT_ONLY_COMPATIBILITY_FIX.md`
- `paper_research/phase1a_baseline/STEP6_FORMAL_BASELINE_RUN_FAILED_ATTEMPT1.md`
- `paper_research/phase1a_baseline/STEP1_FREEZE_AND_SCAFFOLD.md`
- `paper_research/phase1a_baseline/STEP2_CASE_REGISTRY_AND_SIGNAL_GENERATION.md`
- `paper_research/phase1a_baseline/STEP3_ALGORITHM_DISPATCHER.md`
- `paper_research/phase1a_baseline/STEP4_UNIFIED_METRICS.md`
- `paper_research/phase1a_baseline/STEP5_END_TO_END_SMOKE_TEST.md`

失败记录必须保留，但不能作为成功结果。

---

## 7. 已废弃方案及废弃原因

### 7.1 正式证据链层面

1. **DEPRECATED — 用 AutoComp8 + `synthesize_dynamic_case.m` 的 MATLAB 合成总电流作为最终论文主证据。**
   - 路径：`MATLAB一键实验/AI6109_MOA_AutoComp8.slx`、
     `MATLAB一键实验/synthesize_dynamic_case.m`、
     `MATLAB一键实验/results_phase1/`。
   - 原因：旧链只从模型读取电压和阻性真值，再在 MATLAB 中人工合成动态耦合总电流；
     不能表述为完整 Simulink 动态总泄漏电流验证。
   - 当前用途：历史回归、噪声/reference 兼容、快速单元测试；不得覆盖 Phase 1A 正式结果。

2. **DEPRECATED — AutoComp7/AutoComp8 作为当前论文正式 baseline。**
   - 路径：`MATLAB一键实验/AI6109_MOA_AutoComp7.slx`、
     `MATLAB一键实验/AI6109_MOA_AutoComp8.slx`。
   - 原因：Phase 1A 已明确冻结 AutoComp9；旧模型不具备同一正式动态耦合总电流证据链。

3. **DEPRECATED — AutoComp10/AutoComp11 作为 Phase 1A 正式模型。**
   - 路径：`MATLAB一键实验/AI6109_MOA_AutoComp10.slx`、
     `MATLAB一键实验/AI6109_MOA_AutoComp11.slx`。
   - 原因：AutoComp10 主要是布局整理；AutoComp11 属于后续模型，缺少 Phase 1A 同等级冻结、
     构建和回归证据。两者可保留研究，但不得替换已冻结的 AutoComp9 baseline。

4. **DEPRECATED — 第一次 Step 6 的不完整运行作为正式结果。**
   - 路径：`paper_research/phase1a_baseline/STEP6_FORMAL_BASELINE_RUN_FAILED_ATTEMPT1.md`。
   - 原因：Case05 helper 接口失败，Case06 未运行，未生成正式 CSV/MAT；该文件仅是失败审计。

### 7.2 算法/创新表述层面

5. **DEPRECATED — 把普通 LMS/NLMS 或单一等效电容补偿作为专利/论文核心创新。**
   - 路径：`MATLAB一键实验/track_coupling_block_nlms.m`。
   - 原因：普通自适应补偿公开方案接近，且 NLMS 不在 Phase 1A 的 M0/M2/M3 Registry 中。
   - 当前用途：历史对比算法；文件不得删除，但不能冒充当前主算法。

6. **DEPRECATED — 声称单个理想 B 相参考可以覆盖任意三相不平衡并保持高精度。**
   - 原因：现有负序扫描已经显示 1%/3%/5% 时误差约 11.193%/35.030%/61.991%；这是
     可观测性/模型边界，不是调 RLS 参数即可消除的问题。

7. **DEPRECATED — 把 `CURRENT_RESEARCH_STATUS_REVIEW.md` 中“Phase 1A 部分完成”的结论当作当前状态。**
   - 路径：`CURRENT_RESEARCH_STATUS_REVIEW.md`。
   - 原因：该报告是 Phase 1A 实施前的时间截面；现在应以
     `paper_research/phase1a_baseline/PHASE1A_BASELINE_REPORT.md` 为准。

---

## 8. 当前冻结参数

### 8.1 全局配置

来源：`MATLAB一键实验/patent_default_config.m`。Phase 1A runner 会把默认模型名覆盖为
AutoComp9；其余值保持冻结。

| **FROZEN** 参数 | 值 |
|---|---:|
| 仿真时长 `StopTime` | `4.0 s` |
| 频率 `f` | `50 Hz` |
| 步长 `Ts` | `2e-5 s` |
| 线电压 `Un_LL` | `110 kV RMS` |
| `C0` / `C_moa` / `Cself` | `100 / 300 / 400 pF` |
| 初始 `C1/C2` | `10/10 pF` |
| `moa_Iref_A` | `0.3 mA` |
| `moa_alpha` | `6` |
| 三次谐波比例 / 相位 | `0.05 / 0°` |
| 负序 `Vneg_pu` | `0` |
| 正式单次 SNR | `30 dB` |
| 初始化窗口 | `[0.10,0.70) s` |
| 指标起点 | `0.80 s` |
| `lambda_min/max` | `0.55 / 0.995` |
| Cs 物理范围 | `[0,40] pF` |
| 单周期变化限制 | `±1.2 pF/cycle` |
| gate ratio | `1.12` |
| gate directional ratio | `1.20` |
| gate hold | `25 cycles` |

配置中还保留历史 `nlms_mu=0.18`、SNR 等级 `[Inf,40,30,20]` 和 seeds `2001:2030`；
它们不改变 Phase 1A 正式三算法和 18 行 deterministic 结果。

### 8.2 Case 定义与 seeds

来源：`MATLAB一键实验/phase1a_case_registry.m`、
`MATLAB一键实验/generate_coupling_signals.m`。

| Case | seed | **FROZEN** 定义 |
|---|---:|---|
| `Case01_static` | 101 | Cs1/Cs2 恒为 10/10 pF |
| `Case02_slow_drift` | 102 | 1.0–3.0 s，Cs1 `10→14 pF`，Cs2 `10→7 pF` |
| `Case03_smooth_step` | 103 | 1.45–1.65 s，Cs1 `10→15 pF`，Cs2 `10→6 pF` |
| `Case04_random_drift` | 104 | 0.5–1.0 s 淡入；冻结正弦和 0.30 s 平滑随机项 |
| `Case05_fault_only` | 106 | Cs1/Cs2=10/10 pF；3.00–3.06 s，B 相故障 `1.0→1.6` |
| `Case06_drift_then_fault` | 105 | 0.8–2.2 s，Cs1 `10→13 pF`、Cs2 `10→8 pF`；同一故障轨迹 |

### 8.3 算法内部历史常量

来源：`MATLAB一键实验/initial_coupling_estimate.m`、
`MATLAB一键实验/track_coupling_cvff_rls.m`、
`MATLAB一键实验/evaluate_phase1a_metrics.m`。

- 初始 LS 正则：`1e-10 I`；
- RLS 初始化：`J0=0.05 X0'X0 + 1e-8 I`；
- RLS 求解正则：`1e-10 I`；
- innovation normalization：`[5;5] pF`，饱和尺度 `0.20`；
- gate 只在周期末时间大于 `1.0 s` 后允许触发；
- `baseIn` 更新条件：`E_in < 1.08*baseIn`；
- `baseIn` 指数更新：`0.985*baseIn + 0.015*E_in`；
- fault 指标窗口：`[2.60,2.90) s` 和 `[3.40,3.80) s`；
- 残差只拟合 1 次/3 次谐波，三相基波固定 ±120°，三次谐波同相；
- 历史回归容差：`absTol=1e-9`、`relTol=1e-8`。

这些常量在 Phase 1A 中被冻结，没有重新调参。不能声称工程“完全没有硬编码”。

---

## 9. 尚未完成的问题

1. **TODO — Fault Absorption Mechanism 定量化。** 当前只有参数偏移和故障倍率削弱现象；
   尚无正式投影/吸收比例指标和机理证明。
2. **TODO — M1。** 普通/固定遗忘因子 RLS 尚未加入正式 Algorithm Registry。
3. **TODO — M4。** soft gate、continuous update weight、direction-aware、fault-preserving
   更新均未实现。
4. **TODO — M4 gate 指标泛化。** `MATLAB一键实验/evaluate_phase1a_metrics.m` 的
   `gate_metrics` 目前以 `algorithmMode == "M3"` 判断；未来应改为 Registry capability 驱动，
   但不得回写破坏 Phase 1A 冻结结果。
5. **TODO — Phase 1B/后续 Monte-Carlo。** Phase 1A 正式包是 deterministic；历史 30-seed
   SNR 扫描不能替代新机理/新算法的统计检验。
6. **TODO — 真实电场参考链。** 增益、邻相场耦合、偏置、漂移、噪声、延迟、50/150 Hz
   独立相频响应均未建模。
7. **TODO — 不平衡有效性门控。** 严重负序下应冻结更新并输出 `result_valid=false`；尚未实现。
8. **TODO — 自身电容失配。** Cself ±1/2/5%、温漂和慢漂移尚未进入正式实验。
9. **TODO — 更一般耦合结构。** 没有 CsAC 或物理结构约束的三相耦合矩阵。
10. **TODO — 快变电容。** 没有 `u·dC/dt` 项和变化速率适用边界。
11. **TODO — MOA 模型失配。** 尚缺三相不同 alpha/Iref、分段 V-I、老化和受潮模型。
12. **TODO — 低压/硬件实验和论文正文。** 当前只有仿真证据，尚无低压实验验证和完整正文。

---

## 10. 下一阶段具体任务

下一段对话建议严格按下列顺序推进，每一步单独验收：

1. **Phase 1B Step 1 — 只读证据审计与数学定义。**
   - 读取 `baseline_workspace.mat` 中 Case05/06 的 `caseData`、M2/M3 `algorithmResults`、
     `tracker.cycle`、`cHist` 和阻性电流；
   - 明确“故障吸收”的输入、投影空间、能量/幅值口径和时间窗口；
   - 先形成 `paper_research/phase1b_fault_absorption/PHASE1B_MECHANISM_SPEC.md`；
   - 此步不得修改算法或运行 Simulink。

2. **Phase 1B Step 2 — 建立只读机理分析脚本。**
   - 新建独立脚本读取 FROZEN workspace，不覆盖 Phase 1A 文件；
   - 在定义通过评审后再实现投影矩阵、故障吸收比例等候选指标；
   - 所有新指标必须有单位、取值范围、物理解释、退化情况和测试。

3. **Phase 1B Step 3 — Case05/Case06 双证据验证。**
   - Case05 隔离“纯故障”；Case06 验证“漂移后故障”；
   - 比较 M2/M3 的参数偏移、故障倍率保持、残差方向和门控时序；
   - 确认指标不是由固定评价窗口或单个 seed 偶然制造。

4. **Phase 1B Step 4 — 统计与稳健性。**
   - 在机理指标冻结后，再设计 seeds、噪声、故障幅度、故障斜率、Cs 漂移和模型失配扫描；
   - 结果写入新的 Phase 1B 目录，不写回 `paper_research/phase1a_baseline/`。

5. **后续阶段 — M1/M4。**
   - 先增加 M1 形成普通 RLS 对照；
   - 只有 Phase 1B 已证明吸收方向和指标有效后，才设计 M4 soft/direction-aware gate；
   - 新算法应通过 Registry/dispatcher 扩展，保持既有 Phase 1A schema 和 M0/M2/M3 回归不变。

---

## 11. 下一阶段禁止重复进行的工作

1. 不要再次把 Phase 1A 判为“部分完成”；以最终报告和 commit `91e1b3e...` 为准。
2. 不要无理由重新运行六工况正式 baseline；现有 CSV/MAT 已冻结并通过 11/11 回归。
3. 不要覆盖或删除：
   - `paper_research/phase1a_baseline/baseline_summary.csv`
   - `paper_research/phase1a_baseline/baseline_workspace.mat`
   - `paper_research/phase1a_baseline/figures/`
   - 任一 Step 1–7 报告，包括失败记录。
4. 不要修改或覆盖 `MATLAB一键实验/AI6109_MOA_AutoComp9.slx`。
5. 不要为获得更漂亮结果而改变 seeds、Case 轨迹、故障窗口、评价窗口、容差、gate threshold、
   rate limit、projection range 或 historical reference。
6. 不要把 `MATLAB一键实验/results/`、`MATLAB一键实验/results_phase1/`、
   `MATLAB一键实验/results_phase2/` 或 `artifacts/phase0_baseline_run/results/` 中的历史值
   混入 Phase 1A 正式表，除非明确标为历史回归来源。
7. 不要把 `step5_smoke_workspace.mat` 当作正式值来源。
8. 不要重复实现 M0/M2/M3 公式；应复用统一 dispatcher 和现有核心函数。
9. 不要在机理指标尚未定义和验证前直接创建 M4、soft gate 或方向感知更新。
10. 不要把计划中的 `P_X`、`eta_abs`、M4、置信度或电场传感器链写成“已实现”。
11. 不要提交 `.slxc`、`slprj/`、autosave、MATLAB cache 或无审查的大型 MAT。

---

## 12. 下一阶段建议首先读取的文件

按顺序读取：

1. `NEXT_SESSION_HANDOFF.md`
2. `AGENTS.md`
3. `paper_research/phase1a_baseline/PHASE1A_BASELINE_REPORT.md`
4. `paper_research/phase1a_baseline/STEP7_HISTORICAL_REGRESSION.md`
5. `paper_research/phase1a_baseline/baseline_summary.csv`
6. `MATLAB一键实验/phase1a_baseline_metadata.m`
7. `MATLAB一键实验/phase1a_case_registry.m`
8. `MATLAB一键实验/phase1a_algorithm_registry.m`
9. `MATLAB一键实验/run_phase1a_algorithm.m`
10. `MATLAB一键实验/track_coupling_cvff_rls.m`
11. `MATLAB一键实验/coupling_regressor.m`
12. `MATLAB一键实验/evaluate_phase1a_metrics.m`
13. `MATLAB一键实验/run_phase1a_baseline.m`
14. `MATLAB一键实验/phase1a_historical_reference.m`
15. `PHASE1A_IMPLEMENTATION_AUDIT.md`（仅作实施前审计背景，完成状态已过时）
16. `docs/patent_algorithm_definition.md`（公式说明应继续与当前代码交叉核对）

只有在需要时再加载约 110 MiB 的：

- `paper_research/phase1a_baseline/baseline_workspace.mat`

---

## 13. 当前项目目录结构

下列结构按当前磁盘实际目录整理，只展开研究相关部分：

```text
./
├─ AGENTS.md
├─ NEXT_SESSION_HANDOFF.md
├─ CURRENT_RESEARCH_STATUS_REVIEW.md
├─ PHASE1A_IMPLEMENTATION_AUDIT.md
├─ .gitignore
├─ artifacts/
│  └─ phase0_baseline_run/          # 历史 Phase 0 快照与旧结果
├─ docs/
│  ├─ experiment_audit.md
│  ├─ phase1_report.md
│  ├─ phase2_report.md
│  ├─ gating_ablation_report.md
│  └─ patent_algorithm_definition.md
├─ MATLAB一键实验/
│  ├─ AI6109_MOA_AutoComp7.slx      # HISTORICAL
│  ├─ AI6109_MOA_AutoComp8.slx      # HISTORICAL
│  ├─ AI6109_MOA_AutoComp9.slx      # FROZEN FORMAL
│  ├─ AI6109_MOA_AutoComp10.slx     # NON-FORMAL layout variant
│  ├─ AI6109_MOA_AutoComp11.slx     # NON-FORMAL later variant
│  ├─ patent_default_config.m
│  ├─ phase1a_baseline_metadata.m
│  ├─ phase1a_case_registry.m
│  ├─ phase1a_algorithm_registry.m
│  ├─ phase1a_result_schema.m
│  ├─ phase1a_historical_reference.m
│  ├─ generate_coupling_signals.m
│  ├─ simulate_phase2_case.m
│  ├─ run_phase1a_algorithm.m
│  ├─ run_phase1a_baseline.m
│  ├─ validate_phase1a_baseline.m
│  ├─ evaluate_phase1a_metrics.m
│  ├─ track_coupling_cvff_rls.m
│  ├─ run_phase1a_step7_regression.m
│  ├─ generate_phase1a_baseline_figures.m
│  ├─ scripts/                       # 模型构建/布局脚本
│  ├─ tests/                         # MATLAB 单元测试
│  ├─ results/                       # 即 MATLAB一键实验/results/；HISTORICAL/NON-FORMAL
│  ├─ results_phase1/                # 即 MATLAB一键实验/results_phase1/；HISTORICAL/NON-FORMAL
│  ├─ results_phase2/                # 即 MATLAB一键实验/results_phase2/；历史 AutoComp9/消融证据
│  ├─ slprj/                         # 即 MATLAB一键实验/slprj/；IGNORE/TEMP
│  ├─ *.slxc                         # MATLAB一键实验/*.slxc；IGNORE/TEMP
│  └─ *.autosave                     # MATLAB一键实验/*.autosave；IGNORE/TEMP
└─ paper_research/
   └─ phase1a_baseline/
      ├─ baseline_summary.csv        # FROZEN FORMAL, tracked
      ├─ baseline_workspace.mat      # FROZEN FORMAL, local/untracked
      ├─ step5_smoke_workspace.mat   # TEMP/SMOKE, local/untracked
      ├─ PHASE1A_BASELINE_REPORT.md
      ├─ STEP1_FREEZE_AND_SCAFFOLD.md
      ├─ STEP2_CASE_REGISTRY_AND_SIGNAL_GENERATION.md
      ├─ STEP3_ALGORITHM_DISPATCHER.md
      ├─ STEP4_UNIFIED_METRICS.md
      ├─ STEP5_END_TO_END_SMOKE_TEST.md
      ├─ STEP6_FORMAL_BASELINE_RUN_FAILED_ATTEMPT1.md
      ├─ STEP6A_FAULT_ONLY_COMPATIBILITY_FIX.md
      ├─ STEP6_FORMAL_BASELINE_RUN.md
      ├─ STEP7_HISTORICAL_REGRESSION.md
      └─ figures/                    # 即 paper_research/phase1a_baseline/figures/；FROZEN FORMAL
```

---

## 14. 临时文件、测试文件及非正式结果

### 14.1 正式但未提交

- **FROZEN FORMAL** `paper_research/phase1a_baseline/baseline_workspace.mat`
  - 正式时序和算法结果；因为体积约 110 MiB 留在本地；不得删除或误标为临时文件。

### 14.2 临时/验收文件

- **TEMP / NON-FORMAL** `paper_research/phase1a_baseline/step5_smoke_workspace.mat`
  - 大小 `73,214,323 bytes`；SHA-256
    `C32D1AE6E04392F2F0FF67453CE652AAAA8481DC82BE0A218D7D12AF27C6A5CA`；
  - 仅用于 Step 5 smoke test，不能作为正式论文数值来源。

### 14.3 历史结果目录

以下目录中有真实历史实验和回归价值，但不是当前 Phase 1A 正式 18 行结果：

- `MATLAB一键实验/results/`
- `MATLAB一键实验/results_phase1/`
- `MATLAB一键实验/results_phase2/`
- `artifacts/phase0_baseline_run/results/`

其中 `MATLAB一键实验/results_phase2/` 是 Case02/06 historical reference 的主要来源；
引用时必须标注“历史回归来源”，不能与正式 CSV 混称。

### 14.4 生成缓存和自动保存

以下文件或目录由 `.gitignore` 排除，不能作为论文结果或提交内容：

- `MATLAB一键实验/slprj/`
- `MATLAB一键实验/*.slxc`
- `MATLAB一键实验/*.autosave`
- `MATLAB一键实验/.matlab_prefs/`
- `.matlab_prefs/`
- `matlab_startup.log`

### 14.5 报告时间截面

- `CURRENT_RESEARCH_STATUS_REVIEW.md`：Phase 1A 实施前盘点，结论“部分完成”已过时；
- `PHASE1A_IMPLEMENTATION_AUDIT.md`：Phase 1A 实施前审计，关于缺统一框架的描述已被后续
  Step 1–8 完成，但其中对旧文件、硬编码和历史证据来源的核查仍有参考价值；
- `paper_research/phase1a_baseline/STEP6_FORMAL_BASELINE_RUN_FAILED_ATTEMPT1.md`：必须保留的
  失败记录，不是正式成功结果。

---

## 15. 当前 Git/文件状态

### 15.1 Git 基本信息

- 仓库：是；
- 分支：`main`；
- 当前冻结 HEAD：`91e1b3efc8d2bf637c3fa30865d44c7691330fe5`；
- HEAD subject：`paper: finalize Phase 1A baseline`；
- Step 6 checkpoint：`80b8898b5a9685f393c5147df3788361dc8562d5`；
- 正式运行记录的代码 commit：`21db36134f1ff89be6d3be390a58b0afb741ac32`。

Phase 1A 主要提交链：

```text
31885f1  paper: freeze Phase 1A baseline scaffold
fe0821f  paper: unify Phase 1A case signals
267d4d1  paper: add Phase 1A algorithm dispatcher
ac657b4  paper: add Phase 1A unified metrics
165d2be  paper: validate Phase 1A end-to-end baseline
21db361  paper: fix Phase 1A fault-only compatibility
80b8898  paper: complete Phase 1A formal baseline run
91e1b3e  paper: finalize Phase 1A baseline
```

### 15.2 本交接文件创建前的工作区

创建本文前，`git status --short --untracked-files=all` 只有：

```text
?? paper_research/phase1a_baseline/baseline_workspace.mat
?? paper_research/phase1a_baseline/step5_smoke_workspace.mat
```

两者均为有意保留的本地 MAT，前者正式、后者临时。本交接文件创建后，预期再增加：

```text
?? NEXT_SESSION_HANDOFF.md
```

除上述未跟踪文件外，不应存在已跟踪源码、模型或历史结果的修改。下一段对话开始时应先用：

```text
git status --short --untracked-files=all
git rev-parse HEAD
```

确认状态仍一致。

---

## 下一段对话的一句话起点

**Phase 1A 已冻结完成；下一步不是重跑 baseline 或立即写 M4，而是只读使用正式 Case05/06
数据，先建立可审查、可测试的 Fault Absorption Mechanism 数学定义和定量证据。**
