# ZnO V–I 物理老化外部验证范围

> **NO HISTORICAL MATRIX RERUN.**

## 1. 决策摘要

新增 ZnO V–I 老化模型不会使 Phase1A、Phase1B 或 Phase2 的冻结结果失效，也不应替代原 `1.6×ir` 故障。两类模型回答不同问题：

- 原 `1.6×ir` 工况重新定位为 **controlled resistive-current anomaly / mechanism-isolation fault**。它通过只改变阻性电流幅值、保持电压、真实耦合电容、参考链路和噪声定义不变，隔离“阻性增量是否会被耦合参数估计吸收”这一机制。
- ZnO V–I aging 定位为 **external physics-consistent aging validation**。它用于检查冻结机理和冻结算法比较能否迁移到由 V–I 特性变化产生、未被强制设为原波形等比例放大的老化电流增量。

因此，本阶段不修改历史 case、算法、指标或结果，不重跑 Phase2 总矩阵。建议新增两个物理工况、每个工况运行 M0/M2/M3/M4，共 **8 个 case–algorithm 评估组**。若后续获得明确批准，可因 M0 不参与自适应吸收而缩减为 M2/M3/M4 共 **6 组**；本文件不擅自执行该删减。

## 2. 冻结边界

本范围遵守以下不可变条件：

1. Phase1A、Phase1B、Phase2 的 baseline、case、算法、随机种子、评价窗口、注册表和结果文件均保持冻结。
2. M0、M2、M3、M4 的实现、参数与状态更新规则不得修改。
3. 原 `1.6×ir` 故障及其所有结果继续保留，不重命名历史文件，不回写历史 CSV/MAT，不以新结果覆盖旧图表。
4. ZnO V–I aging 通过独立的数据生成分支或 wrapper 注入；不得进入或改写历史 Phase2 condition/execution registry。
5. 新老化模型不得按结果调参以复制 `1.6` 的基波倍率、门控状态或算法排序。应记录模型自然产生的基波增幅、谐波变化和波形差异。
6. 本阶段只评估现有证据的适用范围并定义最小新增验证，不授权完整矩阵、Monte-Carlo、敏感性、消融或参数优化。

## 3. 审计依据与直接依赖统计

本次只读审计使用以下冻结证据：

- `paper_research/phase1a_baseline/PHASE1A_BASELINE_REPORT.md`
- `paper_research/phase1b_fault_absorption/PHASE1B_FAULT_ABSORPTION_REPORT.md`
- `paper_research/phase1c_m4_method/PHASE1C_M4_METHOD_REPORT.md`
- `paper_research/phase2_full_validation/step1_matrix_spec/STEP1A_CASE_INVENTORY.csv`
- `paper_research/phase2_full_validation/step1_matrix_spec/STEP1A_REUSABLE_EVIDENCE.csv`
- `paper_research/phase2_full_validation/step1_matrix_spec/phase2_condition_registry.csv`
- `paper_research/phase2_full_validation/step1_matrix_spec/phase2_execution_registry.csv`
- `paper_research/phase2_full_validation/step2b2_deterministic_core/STEP2B2_DETERMINISTIC_CORE_REPORT.md`
- `paper_research/phase2_full_validation/step3_model_mismatch/STEP3_MODEL_MISMATCH_ROBUSTNESS.md`
- `paper_research/phase2_full_validation/step4_overlap_matrix/STEP4_SIMULTANEOUS_DRIFT_FAULT_MATRIX.md`
- `paper_research/phase2_full_validation/step5_sensitivity_validity/STEP5_SENSITIVITY_VALIDITY_BOUNDARY.md`
- `paper_research/phase2_full_validation/step6_monte_carlo_full/STEP6_MONTE_CARLO_FULL.md`
- `paper_research/phase2_full_validation/step7_final_analysis/PHASE2_FINAL_ANALYSIS.md`
- `paper_research/phase2_full_validation/step7_final_analysis/PAPER_RESULT_MAP.csv`

正式 Phase2 registry 中，`fault_factor=1.6` 的直接依赖为：

| 依赖层 | 精确 `1.6` 数量 | 内容 |
|---|---:|---|
| 冻结锚点 | 3 个物理条件 | Case05、Case06、Case08 |
| 参考相位条件 | 5 个物理条件 | Case05 背景下 0.33°、0.5°、1°、2°、3° |
| overlap rate extension | 2 个物理条件 | D1、0.5×/2×；1×由 Case08 锚点承担 |
| direction extension | 2 个物理条件 | D2/D3、1× |
| Monte-Carlo F | 7 个物理条件 | fault-only cohort 中抽到 factor 1.6 的条件 |
| Monte-Carlo O | 15 个物理条件 | overlap cohort 中抽到 factor 1.6 的条件 |
| **物理条件合计** | **34** | 不含 replay 和 sensitivity 变体 |
| 主算法评估 | **136 条** | 34 条件 × M0/M2/M3/M4 |
| Case08 counterfactual replay | **8 条** | F/N/P/A × M3/M4 |
| Case08 sensitivity variants | **15 条** | M3/M4 的冻结参数局部扰动记录 |

以上 159 条执行记录均为历史冻结证据，不进入新增老化验证的运行清单。

## 4. 结果依赖分类

### 4.1 Mechanism evidence

| 既有证据 | 对 `1.6×ir` 的依赖 | 现有结论 | 审计判断 |
|---|---|---|---|
| Phase1B Case05 | 直接依赖；真实 Cs 固定，阻性支路由 1.0 过渡至 1.6 | 故障残差投影到 `col(X)`，产生 LS 等效偏置、递归虚假 Cs、错误补偿和保持损失 | **仍然有效**；这是受控机理隔离的核心证据 |
| Phase1B Case06 | 直接依赖；真实 Cs 先漂移完成，再施加 1.6 异常 | 同一吸收链在不同估计工作点复现 | **仍然有效**；是工作点迁移证据，不是物理老化模型验证 |
| Phase1B fault-amplitude chain | 故障族依赖；1.6 是端点/锚点之一 | 投影绝对量、虚假参数偏置和保持损失随受控幅值变化 | **仍然有效**；只对乘性受控异常族作幅值链解释 |
| Phase2 Case08 F/N/P/A replay | 直接依赖 1.6 临时异常 | 分解保护日程、适应日程和剩余故障相关作用 | **仍然有效**；属于 operation-level counterfactual decomposition，不升级为物理老化因果识别 |

机制证据的关键对象是“一个未建模阻性增量进入自适应残差后，与耦合回归子空间发生重叠”，并不要求该增量必须来自完整老化物理模型。`1.6×ir` 的简化正是隔离这一对象所需的控制条件。

### 4.2 Algorithm comparison

| 既有证据 | 对故障模型的依赖 | 现有比较 | 审计判断 |
|---|---|---|---|
| Phase1A Case05/06 | 直接依赖 1.6 | M0/M2/M3 的故障保持与虚假 Cs 变化 | **仍然有效**，但论文表述应限定为 controlled anomaly |
| Phase1C Case05/06/08 与消融 | 直接依赖 1.6；Case07 使用 1.3 | M2 持续吸收、M3 hard gate、M4 continuous weighting 及其 protection–adaptation trade-off | **仍然有效**；比较对象是冻结算法对受控残差的响应 |
| Phase2 deterministic fault chain | 依赖乘性异常族，包含/连接 1.6 锚点 | M3 阈值型响应、M4 连续权重、M4 相对 M2 的部分改善 | **仍然有效**；不得外推为任意老化波形下必然保持相同排序 |
| Phase2 overlap matrix | 1.10/1.30/1.60 混合；其中 1.6 点直接依赖 | 漂移与异常重叠下的跟踪—保护折中 | **仍然有效**；只覆盖冻结异常族和冻结 timing |
| Phase2 Monte-Carlo F/O | 依赖乘性异常族；其中 22 条物理条件精确使用 1.6 | 条件内配对分布和失败区域 | **仍然有效**；总体统计不由单个 1.6 点单独决定，也不代表 V–I aging 总体分布 |

### 4.3 Robustness evidence

| 既有证据 | 故障依赖 | 审计判断 | 是否需在本轮老化验证中重跑 |
|---|---|---|---|
| Case05 参考相位误差 sweep | 以 1.6 persistent anomaly 为背景 | 对该冻结组合仍有效 | **否** |
| overlap drift-rate / direction extension | 部分点使用 1.6，其他点使用 1.3 | 对冻结速率、方向和异常族仍有效 | **否** |
| Case08 局部 sensitivity | 直接依赖 1.6 | 对冻结 Case08 锚点仍有效 | **否** |
| fault-amplitude sweep | 使用 1.05–1.60 乘性异常族 | 对受控幅值链仍有效 | **否** |
| Monte-Carlo F/O | 使用离散乘性异常等级 | 对注册分布仍有效 | **否** |

新增 V–I aging 只需要检查跨故障生成机制的可迁移性。若将上述每个鲁棒性轴与 aging 再做笛卡尔积，问题会从“外部验证”扩张成新的完整矩阵；当前证据和目标均不要求这样做。

### 4.4 Unrelated to fault model

下列结果不依赖 `1.6×ir`，新增 aging model 不改变其输入、算法或解释，因而无需重跑：

- Case01 static、Case02 slow drift、Case03 smooth transition、Case04 random drift 的正常跟踪结果；
- healthy SNR、third-harmonic amplitude 与 negative-sequence validity-boundary 条件；
- Cself common-mode mismatch 与未建模 CsAC mismatch；
- Monte-Carlo H cohort；
- M4 正常工况 unnecessary suppression 及 M2/M3/M4 正常跟踪代价；
- 模型/runner 等价门、SHA 完整性门、schema 与 registry 完整性结果；
- 任何仅描述数值复现、结果文件完整性或冻结状态的记录。

## 5. 为什么原 `1.6×ir` 实验仍然有效

原试验具有明确的因果控制价值。它固定真实 Cs、电压、参考和噪声生成逻辑，只改变 B 相阻性支路，因此可以把故障后估计 Cs 变化解释为 fault-induced parameter absorption，而不是物理 Cs 漂移。Case06 又在真实漂移完成后的不同估计状态上复现了同一链条。

这种简化并非在模拟 ZnO 老化的全部物理细节，而是在构造一个可辨识的机制干预。只要论文不再把它描述成完整的 ZnO 老化机理，它对以下结论仍是直接、干净且可重复的证据：

1. 未建模阻性增量可以投影到 coupling-regressor subspace；
2. 持续自适应可以把该增量吸收到 Cs 估计中；
3. hard gate 和 continuous weighting 对这种吸收采取不同的保护—跟踪策略。

新增 V–I aging 不反驳这些结果；它只检验上述链条是否能在一个更具物理结构、非强制等比例的阻性增量下再次观察到。

## 6. 论文中的新定位

论文应把两层证据分开陈述：

| 证据层 | 推荐定位 | 可支持措辞 | 不可支持措辞 |
|---|---|---|---|
| `1.6×ir` | controlled resistive-current anomaly / mechanism-isolation fault | “在受控阻性电流异常下，验证 fault-induced parameter absorption 及算法保护—跟踪差异” | “完整复现 ZnO 真实老化物理过程” |
| ZnO V–I aging | external physics-consistent aging validation | “在独立 V–I 老化生成机制下，检查冻结机理与算法响应的可迁移性” | “替换并推翻原故障模型”或“完成现场实证验证” |

这里的 external validation 仍是**仿真层面的外部生成机制验证**：它相对于原乘性异常模型是外部的，但不等于试验站或现场实测验证。V–I 模型本身的参数来源与物理可信度必须另行记录，不能由算法结果反向证明。

## 7. 为什么 V–I aging 只能作为 external validation

1. **研究问题不同。** 原模型回答“阻性异常能否被参数估计吸收”；V–I aging 回答“该现象能否迁移到物理结构不同的老化增量”。
2. **替换会破坏可比性。** 用 aging 回写 Case05/06 会同时改变故障波形、谐波组成、实际增幅和门控输入，使历史算法差异与新物理变化混在一起。
3. **原机制需要受控干预。** 纯乘性异常使残差方向和幅值可控，适合投影、LS 预测、递归偏置和保持损失的闭环解释；V–I aging 更适合检验外部可迁移性，而不是替代该隔离实验。
4. **冻结证据已包含负面结果。** Phase2 的阈值漏触发、hard-freeze 漂移损失、M4 residual contamination 和适用边界都依赖一致的历史定义；替换会使这些证据失去同一比较基准。
5. **物理模型也有自身不确定性。** aging 参数、分段 V–I 曲线和温度/电压依赖需要独立来源。把它设为唯一故障模型会把模型不确定性误当成算法结论。

## 8. 最小新增验证集

### 8.1 两个新增物理条件

#### Case05-P — constant true Cs + V–I aging

- 真实 `Cs1/Cs2` 全程保持 Case05 的常值；
- 初始化、参考、噪声、采样、评价窗口与 Case05 保持可比；
- 老化前使用 healthy V–I law，老化后使用 frozen aged V–I law；
- 只改变 B 相 ZnO 阻性支路的 V–I 参数，不改变真实 Cs；
- aging transition 可以沿用 Case05 的事件时序以方便窗口比较，但其电流增幅不得强制校准为 1.6。

它回答：当阻性增量来自独立 V–I 特性变化，而不是原波形的常数倍缩放时，是否仍出现投影、虚假 Cs 更新和故障增量损失；M3/M4 是否仍表现出冻结与连续加权的不同响应。

#### Case06-P — completed true-Cs drift + V–I aging

- 沿用 Case06 的真实 Cs 漂移轨迹，确保 aging 开始前漂移已经完成；
- aging 前后的真实 Cs 在故障评价窗口内保持不变；
- healthy/aged V–I law、参考、噪声和事件时序采用与 Case05-P 一致的定义；
- 不引入同时漂移—老化 overlap，以避免扩张到新的 Phase2 overlap matrix。

它回答：物理一致老化下观察到的吸收与保护行为能否从常值工作点迁移到已有跟踪历史和不同终端 Cs 工作点，而不把结果混同为“老化期间继续漂移”。

### 8.2 推荐 8 组

| Group | Case | Algorithm | 主要科学问题 |
|---|---|---|---|
| PA-01 | Case05-P | M0 | 在无自适应吸收通道时，V–I aging 增量能否被提取并作为物理参考保留？ |
| PA-02 | Case05-P | M2 | 非比例 aging residual 是否仍投影为虚假 Cs 并造成 aging-increment retention loss？ |
| PA-03 | Case05-P | M3 | 冻结 hard gate 在物理 aging 波形下是否触发，触发后保护与延迟如何？ |
| PA-04 | Case05-P | M4 | continuous weighting 是否对物理 aging residual 作连续抑制，且是否仍保留 residual contamination？ |
| PA-05 | Case06-P | M0 | 在既有 Cs 漂移历史下，固定补偿的背景误差有多大，是否会混淆 aging increment？ |
| PA-06 | Case06-P | M2 | 吸收现象能否迁移到漂移完成后的不同参数工作点？ |
| PA-07 | Case06-P | M3 | hard gate 的物理 aging 保护是否依赖常值初始工作点？ |
| PA-08 | Case06-P | M4 | continuous weighting 的响应和残余污染能否在已跟踪工作点复现？ |

计数口径：**2 个新增物理条件，8 个 case–algorithm 评估组，0 个历史条件重跑。** 每个条件在单条连续轨迹中包含 healthy pre-event 与 aged post-event，不另建幅值、噪声、相位、方向或随机种子 sweep。

### 8.3 M0 的信息增量与可选 6 组方案

M0 不更新 Cs，因而不能直接检验 parameter absorption、gate 或 weighting。Case06-P 中，M0 还会把未跟踪漂移误差带入 aging 前背景，因此对核心方法比较的信息增量小于 M2/M3/M4。

但 M0 仍提供两个用途：

- Case05-P 中作为“不允许参数吸收”时的 aging-increment extraction reference；
- Case06-P 中暴露固定补偿与已完成漂移的混杂程度，防止把 M0 的背景误差误判为 aging 响应。

因此，本报告的治理安全建议是保留 8 组。若人工审查明确批准删去 M0，则科学核心最小集为 **6 组：Case05-P/Case06-P × M2/M3/M4**。在获得该批准前，M0 不得从计划中删除。

## 9. 新增验证的最小指标

新增指标只用于新目录，不改写冻结 schema。

### 9.1 Aging truth characterization

- healthy/aged B 相阻性电流基波幅值与相位；
- 三次谐波幅值与相位；
- aged-minus-healthy 波形 RMSE、峰值和实际基波增幅；
- “是否为纯比例缩放”的残差检查。若 aged waveform 实际仍等价于常数倍缩放，应标记外部验证信息不足，不得称为独立物理形态验证。

### 9.2 Mechanism transfer

- aging residual 对 `col(X)` 的投影量或几何比例；
- 由 aging residual 得到的 `Delta c_LS,aging`；
- M2/M3/M4 的实际 aging-induced `Delta Cs1/Delta Cs2`；
- LS 预测方向与递归参数移动方向的一致性；
- 虚假 coupling compensation 与真实 aging increment 的基波相位关系。

### 9.3 Algorithm response

- aging-increment retention ratio/error，以 post-minus-pre 增量定义，不把实际 V–I aging 强行归一为 1.6；
- Cs1/Cs2 truth error 及 aging 前后变化；
- M3 gate activity、首次触发时间和覆盖区间；
- M4 mean/min update weight 与 unnecessary suppression；
- Case06-P aging 前的 tracking error，用于确认工作点已建立；
- 波形 RMSE，避免只用基波倍率掩盖非线性波形差异。

本轮不设结果导向的通过阈值，不因 M3 未触发、M4 未改善或算法排序变化而删除工况。所有结果均应保留，并按“支持迁移、部分迁移或未迁移”报告。

## 10. 不需要重跑的既有实验

明确不重跑：

1. Phase1A 六 case baseline；
2. Phase1B Case05/06 机制闭环、fault-amplitude sweep 和 reference-phase sweep；
3. Phase1C Case02/05/07/08、fault preservation、overlap 与 ablation；
4. Phase2 Step 2B-2 的 25 个 deterministic conditions；
5. Phase2 Step 3 的 Cself/CsAC mismatch；
6. Phase2 Step 4 的 13 个 overlap points 与 Case08 F/N/P/A replay；
7. Phase2 Step 5 的 15 条 sensitivity records；
8. Phase2 Step 6 的 H/F/O 各 50 条物理条件和 600 条算法评估；
9. Phase2 Step 7 的统计复算、结果映射和图表规划。

新增验证不需要证明既有数值可以由 V–I aging 逐点复现。它只检查核心机制和算法响应是否跨生成机制保持，避免将 external validation 误写成 historical regression replacement。

## 11. 论文结论的保留与新增边界

| 结论 | 现有状态 | aging 后需要的处理 |
|---|---|---|
| 受控阻性异常可被 M2 吸收到 Cs | 已有强机制证据 | 保留；aging 只提供外部迁移检查 |
| M3 是阈值型 hard-gate protection | 在冻结异常族中成立 | 保留；报告其在 aging 下是否触发，不预设必须触发 |
| M4 是 continuous residual-evidence weighting | 算法结构与冻结结果均成立 | 保留；检查 aging 波形下权重与污染表现 |
| M4 相对 M2 在多数历史条件中减少部分吸收 | 对历史矩阵成立 | 保留历史限定；不得在 aging 只有两个 case 时改写为总体优势 |
| M3/M4 构成 protection–adaptation trade-off | 对历史受控矩阵成立 | 用 Case05-P/06-P 检查方向性可迁移，不重建完整统计分布 |
| 相位、负序、Cself、CsAC、SNR、谐波等边界 | 与各自冻结输入定义对应 | 不受 aging 新分支影响，无需重跑 |
| ZnO 物理老化下同样存在吸收/保护差异 | 当前未验证 | 只能由 PA-01 至 PA-08 新结果支持，且限于所选 V–I 模型和两种工作点 |

## 12. 七个必须回答的问题

1. **为什么原 `1.6×ir` 实验仍然有效？** 因为它是受控机理干预，能够隔离阻性增量进入耦合参数子空间并形成虚假补偿的因果链；它不需要承担完整老化物理建模任务。
2. **它在论文中的新定位是什么？** `controlled resistive-current anomaly / mechanism-isolation fault`，用于机制证据和冻结算法比较。
3. **为什么 V–I aging 是 external validation 而不是替换原模型？** 因为它检验跨生成机制迁移，若替换历史模型会破坏控制变量、可比性和已冻结证据链；它自身也带有模型参数不确定性。
4. **哪些已有实验无需重跑？** Phase1A、Phase1B、Phase1C 和 Phase2 Step 2B-2 至 Step 7 的全部冻结实验、replay、sensitivity 与 Monte-Carlo 均无需重跑。
5. **最小需要新增多少组？** 科学核心为 6 组（M2/M3/M4 × Case05-P/Case06-P）；因 M0 当前仍在指定算法集合中，未经批准不得删除，故推荐并冻结为 **8 组**。
6. **新增实验分别回答什么问题？** Case05-P 检验常值真实 Cs 下的物理 aging 机制迁移；Case06-P 检验漂移完成后不同估计工作点的迁移；四算法分别提供固定参考、持续吸收、硬冻结保护和连续加权响应。
7. **是否重跑历史矩阵？** **NO HISTORICAL MATRIX RERUN.**

## 13. 最终范围声明

```text
HISTORICAL BASELINE MODIFIED: NO
HISTORICAL CASE MODIFIED: NO
M0/M2/M3/M4 MODIFIED: NO
HISTORICAL RESULT RECOMPUTED: NO
NEW PHYSICAL CONDITIONS: 2
RECOMMENDED NEW CASE-ALGORITHM GROUPS: 8
MINIMUM CORE GROUPS IF M0 IS EXPLICITLY WAIVED: 6
FULL PHASE2 MATRIX RERUN: PROHIBITED
NO HISTORICAL MATRIX RERUN.
```

