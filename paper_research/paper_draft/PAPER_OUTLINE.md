# 《避雷器在线监测中自适应参数辨识的故障吸收机理及抑制方法》论文框架

## 0. 文档定位与证据边界

本文档只规划论文科学结构，不构成正文。论文主贡献冻结为三条：

1. 揭示真实阻性故障经耦合参数回归子空间投影形成虚假参数变化、错误耦合补偿与故障保持损失的完整 fault absorption mechanism；
2. 提出 M4 / Residual-Evidence Weighted Adaptive Identification（REW-AI），以状态一致的连续权重调节 information-state increment；
3. 揭示同时参数漂移与阻性故障下 protection 与 adaptation 的结构性冲突，并以确定性、带符号移动、反事实重放、敏感性与 Monte-Carlo 证据验证。

正式模型为 `MATLAB一键实验/AI6109_MOA_AutoComp9.slx`。Phase 2 没有完全同名的 `PHASE2_FULL_VALIDATION_REPORT.md`；本规划以实际正式文件 `paper_research/phase2_full_validation/step7_final_analysis/PHASE2_FINAL_ANALYSIS.md` 和 `paper_research/phase2_full_validation/step7_final_analysis/PAPER_RESULT_MAP.csv` 作为 Phase 2 integrated analysis。当前全部主要证据来自冻结 Simulink 仿真框架，低压实物试验尚未完成。

路径约定：以 `phase1a_baseline/`、`phase1b_fault_absorption/`、`phase1c_m4_method/` 或 `phase2_full_validation/` 开头的缩写路径，均相对于项目目录 `paper_research/`；其余路径给出项目根目录相对路径。

证据状态含义：`SUFFICIENT` 表示足以支持限定在冻结仿真体系内的拟写结论；`PARTIAL` 表示还缺文献、边界澄清或外部验证；`NEEDS_EXPERIMENT` 表示必须等待低压实物试验；`NOT_SUPPORTED` 表示现有数据不能支持。

## 1 引言

- **Scientific question：** 为什么 MOA 在线监测中的动态相间耦合需要在线辨识，而在线辨识又会在真实阻性故障出现时引入新的 fault absorption 风险？
- **Core message：** 论文的核心不是“又一种改进 RLS”，而是识别并解释 adaptive identification 中的 fault absorption mechanism；REW-AI 是针对该机制的连续抑制方法，不是对 M3 hard gate 的全面替代。
- **Existing evidence：** Phase 1A 证明动态耦合下持续自适应具有跟踪价值；Phase 1B 闭合 fault residual → false Cs → false compensation → retention loss 的因果链；Phase 1C 与 Phase 2 显示 M2/M3/M4 的 protection–adaptation trade-off。
- **Source files：** `paper_research/phase1a_baseline/PHASE1A_BASELINE_REPORT.md`；`paper_research/phase1b_fault_absorption/PHASE1B_FAULT_ABSORPTION_REPORT.md`；`paper_research/phase1c_m4_method/PHASE1C_M4_METHOD_REPORT.md`；`paper_research/phase2_full_validation/step7_final_analysis/PHASE2_FINAL_ANALYSIS.md`。
- **Required equations：** 引言只给出概念链，不展开完整推导；可简写 `r_fault → Δc_fault → false ΔCs → false compensation → retention loss`。
- **Planned figure/table：** Fig.1；Table 2；Table 5。
- **Evidence status：** `PARTIAL`。内部研究证据充分，但中文核心论文所需的国内外研究现状、专利/论文差异与引用尚未在本阶段建立。
- **Writing caution：** 不写“M4 全面优于 M3”“M4 完全解决故障吸收”“适用于各种不平衡状态”；不得把仿真规模本身当作创新点。

## 2 相间耦合模型与自适应辨识问题

### 2.1 三相 MOA 泄漏电流及相间耦合模型

- **Scientific question：** 三相 MOA 总泄漏电流中，自电容、AB/BC 相间耦合、阻性电流与测量噪声如何进入统一观测模型？
- **Core message：** 动态相间耦合会使固定补偿产生系统偏差，因此需要在线跟踪 Cs1/Cs2；当前正式模型只辨识 AB/BC 两个耦合参数，Cself 固定、CsAC 未建模。
- **Existing evidence：** Phase 1A Case02–04 中 M0 在动态耦合下明显退化，而 M2/M3 能跟踪；Phase 2 Step 3 表明 Cself 与 CsAC 失配是共同模型边界。
- **Source files：** `paper_research/phase1a_baseline/baseline_summary.csv`（Case02–04）；`paper_research/phase1a_baseline/baseline_workspace.mat`；`paper_research/phase2_full_validation/step3_model_mismatch/step3_model_mismatch_results.csv`；`MATLAB一键实验/coupling_regressor.m`。
- **Required equations：** 三相总电流分解；准静态耦合电流 `i_AB=Cs1(du_A/dt-du_B/dt)`、`i_BC=Cs2(du_B/dt-du_C/dt)`；向量式 `y=Xc+b+n`。
- **Planned figure/table：** Fig.1(a)；Table 1。
- **Evidence status：** `SUFFICIENT`（限冻结 AB/BC 准静态仿真模型）。
- **Writing caution：** 不把 Cself 或 CsAC 说成已被在线辨识；不把当前模型外推为一般三相完整耦合矩阵。

### 2.2 耦合参数回归模型

- **Scientific question：** 如何把三相观测组织为 Cs1/Cs2 的联合回归，以及为什么阻性故障可能在该回归空间中具有可表达分量？
- **Core message：** `X` 是三相联合的两列 AB/BC 回归矩阵；故障吸收的几何基础来自 `r_fault` 与 `col(X)` 的非正交重叠，而非数值发散。
- **Existing evidence：** Case05/06 的每周期回归矩阵秩、条件数、投影能量闭合与静态 LS 预测均已保存；Case05 `eta_geom≈0.275451`。
- **Source files：** `paper_research/phase1b_fault_absorption/STEP1_THEORY_AND_DATA_DEFINITION.md`；`step2/case05_mechanism_summary.csv`；`step3/case06_mechanism_summary.csv`；`step2/observation_blocks_case05.mat`；`step3/observation_blocks_case06.mat`。
- **Required equations：** `y_k=X_k c_true,k+b_k+r_fault,k+n_k`；`P_X=X X^+` 或冻结报告采用的等价投影定义；`rank(X)=2` 的适用条件。
- **Planned figure/table：** Fig.1(b)；Fig.2(b)；Table 1。
- **Evidence status：** `SUFFICIENT`。
- **Writing caution：** `eta_geom` 是几何能量比例，不是最终 retention 的通用预测量；不能把相关性当作完整因果识别。

### 2.3 在线自适应辨识

- **Scientific question：** M2 的 VFF-RLS、物理投影与变化率约束如何更新耦合参数，M3 又如何在此基础上增加硬门控？
- **Core message：** M2 提供持续 tracking；M3 在阈值触发后冻结 `J/h/c/baseIn`；rate limit 与 projection 是安全约束，但 Phase 1B 正式工况中并非故障吸收的主导原因。
- **Existing evidence：** Phase 1A 统一算法注册、历史回归与 Case02 tracking；Phase 1B 受控条件中 rate limit/projection 均未参与；Phase 2 扩展了门控行为与边界。
- **Source files：** `paper_research/phase1a_baseline/PHASE1A_BASELINE_REPORT.md`；`MATLAB一键实验/track_coupling_cvff_rls.m`；`paper_research/phase1c_m4_method/step6_ablation/tables/parameter_table.csv`；`paper_research/phase2_full_validation/step1_matrix_spec/STEP1B_ALGORITHM_SCOPE.csv`。
- **Required equations：** `R_k=X_k^T X_k`、`z_k=X_k^T y_k`；VFF `lambda_k`；信息状态 `J_k=lambda_kJ_{k-1}+R_k`、`h_k=lambda_kh_{k-1}+z_k`；投影与每周期变化率约束。
- **Planned figure/table：** Fig.1(c)；Table 1；Table 2。
- **Evidence status：** `SUFFICIENT`。
- **Writing caution：** 不把变化率约束或投影包装成新贡献；不声称 VFF 自身具有 fault protection。

### 2.4 真实阻性故障下的异常参数学习现象

- **Scientific question：** 在真实 Cs 不变或已完成真实漂移时，为什么 M2 仍出现约 `+5/-5 pF` 的估计变化，并伴随故障增幅低估？
- **Core message：** Case05/06 首先给出异常现象：真值故障因子 1.6 时，M2 估计约 1.401–1.402，同时出现 `+4.9/-4.9 pF` 的非物理参数移动。
- **Existing evidence：** Phase 1A baseline；Phase 1B Case05/06 key metrics；M3 对照显著减小偏移并恢复保持能力。
- **Source files：** `paper_research/phase1a_baseline/baseline_summary.csv`；`paper_research/phase1b_fault_absorption/step2/case05_key_metrics.csv`；`step3/case06_key_metrics.csv`；现有图源 `phase1b_fault_absorption/step2/figures/figure1_case05_false_cs_drift.fig` 与 `step3/figures/figure2_case06_true_drift_vs_fault_bias.fig`。
- **Required equations：** 故障因子、fault retention error、故障前后 `Delta Cs` 的冻结定义。
- **Planned figure/table：** Fig.2；Table 3。
- **Evidence status：** `SUFFICIENT`。
- **Writing caution：** 本节只陈述现象，机理推导留到第 3 章；不将 M3 的单点优势扩展为普遍最优。

## 3 故障吸收机理及 REW-AI 方法

### 3.1 故障残差模型

- **Scientific question：** 如何从正常背景、噪声与真实阻性故障中定义专门用于机理分析的 `r_fault`？
- **Core message：** 在冻结故障注入结构下，`r_fault` 是 fault branch 与 matched no-fault/counterfactual branch 的 observation-space 增量，进入辨识残差但不代表全部背景残差。
- **Existing evidence：** Phase 1B Step 1 定义；Case05/06 fault/counterfactual branch 在故障前严格一致；counterfactual identity 数值闭合。
- **Source files：** `paper_research/phase1b_fault_absorption/STEP1_THEORY_AND_DATA_DEFINITION.md`；`step2/case05_mechanism_summary.csv`；`step3/case06_mechanism_summary.csv`；`step4/controlled_factor_validation.csv`。
- **Required equations：** `y=Xc_true+b+r_fault+n`；`r_fault=y_F-y_CF`（按正式定义展开）；窗口与 matched branch 条件。
- **Planned figure/table：** Fig.1(d)；Fig.2(a)。
- **Evidence status：** `SUFFICIENT`。
- **Writing caution：** 不把 `r_fault` 与现场可直接测得的“纯故障量”等同；它是机理分析和反事实定义。

### 3.2 故障在耦合参数回归空间中的投影

- **Scientific question：** 故障残差中有多少分量可被耦合参数模型解释，其等效参数变化方向和量级是什么？
- **Core message：** `r_fault=P_Xr_fault+(I-P_X)r_fault`；可表达分量产生 `Delta c_fault≈X^+r_fault`。Case05/06 中该预测稳定指向 `+Cs1/-Cs2`。
- **Existing evidence：** Case05 `eta_geom≈0.275451`；投影能量闭合约 `10^-15`；11 个受控条件中 LS 与递归 bias 方向一致率 100%，最大相对误差 0.663%。
- **Source files：** `paper_research/phase1b_fault_absorption/step2/case05_mechanism_summary.csv`；`step3/case06_mechanism_summary.csv`；`step4/controlled_factor_summary.csv`；`step5/prediction_error_summary.csv`；`step5/mechanism_evidence_table.csv`。
- **Required equations：** `P_X=XX^+`；正交分解；`eta_geom=||P_Xr_fault||^2/||r_fault||^2`；`Delta c_fault=X^+r_fault`，仅在满列秩时可写为 `(X^TX)^-1X^Tr_fault`。
- **Planned figure/table：** Fig.2(b–c)；Table 5。
- **Evidence status：** `SUFFICIENT`。
- **Writing caution：** 静态 LS 与动态递归不是数学同一量，应写“高精度预测方向和量级”，不能写成完全相等定理。

### 3.3 Fault absorption mechanism

- **Scientific question：** 可表达故障分量如何经过递归参数学习转化为错误补偿并损失故障保持？
- **Core message：** `r_fault → Delta c_fault → false Delta Cs → false coupling compensation → resistive fault retention loss` 构成完整链；该偏差有界且看似物理合理，因此比显式发散更隐蔽。
- **Existing evidence：** Case05/06 recursive bias 约 `+4.89/-4.88 pF`；错误 B 相补偿约为故障基波增量的三分之一、近同相；M2 因子约 1.401–1.402，反事实参数恢复至约 1.601–1.603；fault-amplitude sweep 形成近比例幅值链。
- **Source files：** `paper_research/phase1b_fault_absorption/PHASE1B_FAULT_ABSORPTION_REPORT.md`；`step2/case05_key_metrics.csv`；`step3/case06_key_metrics.csv`；`step4/controlled_factor_summary.csv`；`step5/correlation_summary.csv`。
- **Required equations：** `i_false,B=X_B Delta c_fault`；fault increment loss 与 false compensation 的关系；必要时给出 counterfactual restoration 定义。
- **Planned figure/table：** Fig.1；Fig.2；Fig.3(a)。
- **Evidence status：** `SUFFICIENT`。
- **Writing caution：** 不从有限的 AB/BC、单故障方向结果外推为所有回归模型的普遍比例；`eta_geom` 不能单独预测 retention。

### 3.4 Hard-gate 保护原理及其局限

- **Scientific question：** M3 为什么能在强故障触发后保护故障增量，又为什么会漏过弱故障并冻结真实漂移学习？
- **Core message：** 二值门控以 update/freeze 换取强保护；阈值以下完全不动作，阈值以上完全冻结，因此具有离散行为与 overlap cost。
- **Existing evidence：** Step 2B-2 中 1.05–1.30 的 8 个点未触发、1.40 两点触发；Step 4 中 1.10/1.30 不触发、1.60 全触发；Case08 gate 内 M3 参数移动为 0；MC F/O 触发 15/50、16/50。
- **Source files：** `paper_research/phase2_full_validation/step2b2_deterministic_core/step2b2_deterministic_results.csv`；`step4_overlap_matrix/step4_overlap_results.csv`；`step6_monte_carlo_full/step6_monte_carlo_full_results.csv`；`paper_research/phase1c_m4_method/step5b_triggered_overlap/tables/gate_interval_summary.csv`。
- **Required equations：** M3 触发条件 `E_in>gate_ratio·baseIn` 且 `E_in>gate_quad_ratio·E_quad`；门控期间 `Delta J=Delta h=Delta c=0`。
- **Planned figure/table：** Fig.3；Fig.4；Fig.5；Table 2。
- **Evidence status：** `SUFFICIENT`。
- **Writing caution：** 不能据已测点声明精确、普适的故障检测阈值；强故障触发后 M3 通常比 M4 保护更强，必须保留。

### 3.5 REW-AI 连续信息加权方法

- **Scientific question：** 如何在不引入二值冻结的情况下，连续降低故障相关残差信息写入，同时保持非零适应？
- **Core message：** M4 从 `r_b,r_q,e_b,p_q,s` 形成 `0<g<=1`，对 `J/h/baseIn` 的候选增量进行同一权重的状态一致更新；它调节 information-state increment，而不是事后缩放 `Delta Cs`。
- **Existing evidence：** `paper_method_v1` 公式冻结；`g=1` 与 M2 7/7 sample-for-sample 等价；确定性幅值链、重叠矩阵与 MC 均观察到连续非零权重。
- **Source files：** `paper_research/phase1c_m4_method/step6_ablation/PAPER_METHOD_V1_FREEZE.md`；`paper_research/phase1c_m4_method/step6_ablation/tables/no_weight_equivalence.csv`；`paper_research/phase2_full_validation/step2b2_deterministic_core/step2b2_deterministic_results.csv`；`paper_research/phase2_full_validation/step4_overlap_matrix/step4_overlap_results.csv`。
- **Required equations：** `r_b=E_in/(baseIn+eps)`；`r_q=E_in/(E_quad+eps)`；`e_b=max(0,(r_b-1)/(gate_ratio-1))`；`p_q=clip(r_q/gate_quad_ratio,0,1)`；`s=e_bp_q`；`g=1/(1+s)`；`J*=lambda J_prev+R`、`h*=lambda h_prev+z`；`J=J_prev+g(J*-J_prev)`、`h=h_prev+g(h*-h_prev)`；状态一致的 `baseIn` 更新。
- **Planned figure/table：** Fig.1；Fig.4；Table 1；Table 2。
- **Evidence status：** `SUFFICIENT`。
- **Writing caution：** 不称为 fault/drift classifier；phase-consistency factor 的独立贡献在当前消融中 `NOT DEMONSTRATED`；direction 仅诊断，不参与控制。

### 3.6 Protection–adaptation trade-off 分析

- **Scientific question：** 连续加权究竟改变了什么，它为何不能同时获得 M3 的强保护与 M2 的无损 tracking？
- **Core message：** scalar weighting 主要改变向有偏解移动的速率，未必改变有偏固定点；M4 保留 adaptation 也保留 residual fault contamination。M3 与 M4 是不同 trade-off，而非统一排名。
- **Existing evidence：** Case05 M4 仅比 M2 将 retention error 改善 0.469 个百分点，远弱于 M3；Case07 M3 miss 而 M4 有响应；Case08 M3 强保护但冻结真实漂移，M4 非零移动且受污染；MC 相对 M3 的配对改善约一半。
- **Source files：** `paper_research/phase1c_m4_method/PHASE1C_M4_METHOD_REPORT.md`；`step6_ablation/tables/case05_ablation.csv`；`case07_ablation.csv`；`case08_ablation.csv`；`phase2_full_validation/step6_monte_carlo_full/step6_monte_carlo_full_results.csv`。
- **Required equations：** ISR 定义及其与 final bias reduction 的非等价说明；tracking error、retention distance、`F-CF` contamination norm 三目标分开表达，不构造综合评分。
- **Planned figure/table：** Fig.4；Fig.5；Fig.8；Table 2；Table 5。
- **Evidence status：** `SUFFICIENT`。
- **Writing caution：** 不把 ISR 解释为最终偏差降低比例；不写“M4 综合性能优于 M3”；不把小 `F-N` 当作纯净分离。

## 4 仿真与统计验证

### 4.1 仿真模型、工况和评价指标

- **Scientific question：** 如何保证 M0/M2/M3/M4 在共享物理数据、冻结工况、预注册窗口和统一指标下公平比较？
- **Core message：** Phase 1/2 采用冻结 AutoComp9、统一算法入口、共享数据签名与预注册矩阵；性能失败不被重分类为数值失败，负结果全部保留。
- **Existing evidence：** Phase 1A 6 cases×3 algorithms；Phase 2 54 deterministic +150 MC conditions；执行 registry 839 records；MC 600 evaluations；冻结完整性全部通过。
- **Source files：** `paper_research/phase1a_baseline/PHASE1A_BASELINE_REPORT.md`；`paper_research/phase2_full_validation/step1_matrix_spec/STEP1_PHASE2_MATRIX_SPECIFICATION.md`；`paper_research/phase2_full_validation/step1_matrix_spec/phase2_condition_registry.csv`；`paper_research/phase2_full_validation/step1_matrix_spec/phase2_execution_registry.csv`；`paper_research/phase2_full_validation/step1_matrix_spec/STEP1B_METRIC_FREEZE.csv`。
- **Required equations：** Cs RMSE、B 相基波误差、fault retention error、retention distance、`F-CF` norm、post-fault AUC、USR。
- **Planned figure/table：** Table 1；Table 3；Table 4。
- **Evidence status：** `SUFFICIENT`。
- **Writing caution：** 不把 839 registry records 写成 839 次新仿真；不把数值无失败等同于方法性能无失败。

### 4.2 故障吸收机理验证

- **Scientific question：** Case05/06 是否在不同参数背景下都闭合投影、虚假参数、错误补偿和 retention loss？
- **Core message：** Case05 给出完整闭环，Case06 在真实漂移后的另一工作点复现；二者共同支持同一机理。
- **Existing evidence：** 两 case 投影/递归/反事实闭合；M2 因子 1.4011/1.4023；反事实参数恢复 1.6011/1.6026；约三分之一错误补偿比。
- **Source files：** `paper_research/phase1b_fault_absorption/step2/case05_key_metrics.csv`；`step3/case06_key_metrics.csv`；`step3/case05_case06_comparison.csv`；相应 mechanism workspace MAT 与 figure source。
- **Required equations：** 第 3.1–3.3 节公式在两 case 的指标映射，不新增复杂理论。
- **Planned figure/table：** Fig.2；Table 5。
- **Evidence status：** `SUFFICIENT`。
- **Writing caution：** 两个 representative cases 不能单独代表随机总体；统计扩展由 4.8 节承担。

### 4.3 不同故障程度下的响应

- **Scientific question：** 故障强度增加时，M2 参数偏置、M3 门控和 M4 权重如何变化？
- **Core message：** M2 bias 与损失总体增大；M3 呈 step-like threshold behavior；M4 权重连续降低且相对 M2 小幅减弱吸收。
- **Existing evidence：** Step 2B-2 10 个新 fault-amplitude 条件；1.6 anchor 来自 Case05/06；M4 在 10/10 新条件中同时降低绝对保持误差和 bias norm。
- **Source files：** `paper_research/phase2_full_validation/step2b2_deterministic_core/step2b2_deterministic_results.csv`；`paper_research/phase1a_baseline/baseline_summary.csv`；`paper_research/phase1c_m4_method/step4_fault_preservation/tables/fault_preservation_summary.csv`。
- **Required equations：** fault factor excess `F-1`；bias norm；absolute retention error；M3 gate ratio；M4 mean `g`。
- **Planned figure/table：** Fig.3；Fig.4；Table 3。
- **Evidence status：** `SUFFICIENT`。
- **Writing caution：** 观察到的单调趋势不升级为全局严格单调定理；M3 转变区不是普适阈值。

### 4.4 Simultaneous drift + fault trade-off

- **Scientific question：** 漂移速率、方向和故障强度共同变化时，tracking、retention 与 contamination 如何竞争？
- **Core message：** M3 强故障冻结提高 protection 但损失真实 drift learning；M4 在 13/13 点相对 M2 减小 retention error 与 `F-CF` norm，但相对 M3 只在部分点更优。
- **Existing evidence：** 3 rates×3 factors 的 D1 core 与 D1/D2/D3 direction extension；13 physical points、52 main records；带符号移动与反向移动均保留。
- **Source files：** `paper_research/phase2_full_validation/step4_overlap_matrix/step4_overlap_results.csv`；`paper_research/phase2_full_validation/step4_overlap_matrix/STEP4_SIMULTANEOUS_DRIFT_FAULT_MATRIX.md`；Phase 1C Case07/08 tables 与 diagnostics。
- **Required equations：** `Delta c_F`、`Delta c_CF`、`Delta c_F-Delta c_CF`；parameter-error RMS norm；W1/W2 retention；signed dot product 仅作诊断。
- **Planned figure/table：** Fig.5；Table 3；Table 5。
- **Evidence status：** `SUFFICIENT`。
- **Writing caution：** 不使用 `||Delta c_CF||/||Delta c_F||` 作为 purity；方向证据不能识别 fault；速率响应非单调。

### 4.5 F/N/P/A counterfactual replay

- **Scientific question：** 小的表面 `F-N` 是真实低污染，还是 fault-related effect、adaptation schedule 与 protection-induced drift loss 相互抵消？
- **Core message：** `F-N=(F-A)+(A-P)+(P-N)` 提供操作性分解；M3 的小 `F-N` 由显著 `F-A` 与 `P-N` 抵消形成，不能据此宣称正确分离。
- **Existing evidence：** M3/M4 replay equivalence 在 `1e-12` 容差通过，恒等式 residual=0；M3 `P-N=[-0.923983,+0.613373] pF`，M4 主要残余为 `F-A=[+4.575018,-4.578660] pF`。
- **Source files：** `paper_research/phase2_full_validation/step4_overlap_matrix/step4_overlap_results.csv` 中 replay rows；`paper_research/phase2_full_validation/step4_overlap_matrix/STEP4_SIMULTANEOUS_DRIFT_FAULT_MATRIX.md`；`paper_research/phase2_full_validation/step1_matrix_spec/STEP1B_COUNTERFACTUAL_SPEC.md`。
- **Required equations：** 四轨迹定义；向量恒等式；各项 operational interpretation。
- **Planned figure/table：** Fig.6；Table 5。
- **Evidence status：** `SUFFICIENT`（对操作性解释）；因果识别强度仍为 `MODERATE`。
- **Writing caution：** 明确不是 perfect causal identification；分解等价门只验证实现，不提升因果强度。

### 4.6 Model mismatch 与 validity boundary

- **Scientific question：** 参考相位、Cself、未建模 CsAC、负序、漂移速率和方向分别构成怎样的适用边界？
- **Core message：** reference phase error 是明显 sensitivity boundary；Cself/CsAC 共同模型偏差不能被 M4 根本消除；negative sequence 只能作为 configured validity boundary。
- **Existing evidence：** phase error 0–3°、Cself -10%–+10%、CsAC 0–3 pF、negative sequence 0–5%、rate 0.5–2、D1/D2/D3 均已测试；边界与失败结果保留。
- **Source files：** `paper_research/phase2_full_validation/step2b2_deterministic_core/step2b2_deterministic_results.csv`；`paper_research/phase2_full_validation/step3_model_mismatch/step3_model_mismatch_results.csv`；`paper_research/phase2_full_validation/step4_overlap_matrix/step4_overlap_results.csv`；`paper_research/phase2_full_validation/step5_sensitivity_validity/STEP5_SENSITIVITY_VALIDITY_BOUNDARY.md`。
- **Required equations：** Cself mismatch 百分比；CsAC 注入式；边界指标为 Cs RMSE 与 B 相误差，不建立事后安全阈值。
- **Planned figure/table：** Fig.7；Table 5。
- **Evidence status：** `PARTIAL`。phase/Cself/CsAC 边界已有证据；negative-sequence internal convention 仍 unresolved，不能形成完整机理结论。
- **Writing caution：** 不写“M4 具有很强模型失配鲁棒性”“适用于各种电网不平衡”；Cself/CsAC 是未解决限制。

### 4.7 参数敏感性

- **Scientific question：** 冻结参数局部变化会如何影响 M3 的离散门控与 M4 的连续权重？
- **Core message：** `gate_ratio` 在 Case08 单锚点明显敏感；`gate_quad_ratio` 与 `gate_hold_cycles` 在注册邻域出现局部平台。该分析不是调参或最优性证明。
- **Existing evidence：** 15/15 sensitivity records；M3 在 gate_ratio 高值由全触发变为不触发；M4 mean `g` 从 0.033545 到 0.523789 且始终非零。
- **Source files：** `paper_research/phase2_full_validation/step5_sensitivity_validity/step5_sensitivity_results.csv`；`paper_research/phase2_full_validation/step5_sensitivity_validity/STEP5_SENSITIVITY_VALIDITY_BOUNDARY.md`。
- **Required equations：** 不新增算法方程；报告局部参数水平、gate ratio、mean `g`、movement norm 与 retention。
- **Planned figure/table：** Fig.4(c)；Table 5。若版面紧张，完整敏感性移入补充材料。
- **Evidence status：** `SUFFICIENT`（限局部单锚点描述）。
- **Writing caution：** 不选择“最优参数”，不建议修改冻结值，不把局部平台外推为全局不敏感。

### 4.8 Monte-Carlo statistical validation

- **Scientific question：** Phase 1 representative conclusions 在 H/F/O 多因素随机组合中是否仍具有统计层面的方向一致性与边界？
- **Core message：** H/F/O 各 50 条、共 600 evaluations 支持 M4 正常代价较小但非零、相对 M2 在多数故障/重叠条件减少部分吸收、与 M3 呈近似对半 trade-off；不建立综合排名。
- **Existing evidence：** H 组 USR mean/P95=0.025744/0.087019；F 组 M4 对 M2 retention/bias 改善 36/50、33/50；O 组 tracking/retention/contamination 改善 33/50、43/50、40/50；0 numerical failures。
- **Source files：** `paper_research/phase2_full_validation/step6_monte_carlo_full/step6_monte_carlo_full_results.csv`；`paper_research/phase2_full_validation/step6_monte_carlo_full/STEP6_MONTE_CARLO_FULL.md`；`paper_research/phase2_full_validation/step7_final_analysis/PAPER_RESULT_MAP.csv`。
- **Required equations：** 配对差异定义；ECDF；median/IQR/P5/P95；cohort-specific metric，不构造跨 cohort score。
- **Planned figure/table：** Fig.8；Table 4；Table 5。
- **Evidence status：** `SUFFICIENT`（对冻结仿真框架内的统计外部验证）。
- **Writing caution：** 不把 paired improvement count 称为胜率；不把 MC 视为硬件或现场外部验证；极端条件不得删除。

## 5 实验验证（接口预留）

- **Scientific question：** 冻结仿真中识别的核心机理与 protection–adaptation 趋势能否在低压等效实物平台复现？
- **Core message：** 本章当前只给出验证目标、输入输出和判据接口，不提供数据与结论。硬件不需复现完整 Monte-Carlo，只验证核心机理、主要趋势和可实现性。
- **Existing evidence：** 无低压实验数据；现有全部主证据来自冻结 Simulink 框架。
- **Source files：** 当前无硬件 source file；仿真参照为 Phase 1B/1C 正式报告与 Table 1 参数。
- **Required equations：** 实验数据使用与仿真一致的 Cs tracking、fault retention、`Delta Cs_fault` 和 update/gate 指标；实际可测量定义需在实验设计阶段冻结。
- **Planned figure/table：** 后续硬件补充 Fig.2/4/5 的同类趋势图；当前不占正式图号。Table 5 标记 `NEEDS_EXPERIMENT`。
- **Evidence status：** `NEEDS_EXPERIMENT`。
- **Writing caution：** 不虚构平台、波形、误差条或实验结论；不把 Simulink 结果称为实物实验。

### 5.1 Experiment A：仅 coupling parameter change

- **Scientific question：** 无阻性故障时，M2/M3/M4 能否跟踪真实 Cs 变化，M4 是否产生可接受的正常抑制代价？
- **Core message：** 作为 parameter tracking 的硬件锚点，对照静态/慢漂移或可控等效电容变化。
- **Existing evidence：** 仅有 Phase 1A Case02–04、Phase 1C Case02 与 MC H 仿真证据。
- **Source files：** `phase1a_baseline/baseline_summary.csv`；`phase1c_m4_method/step3_normal_tracking/tables/normal_tracking_summary.csv`；`phase2_full_validation/step6_monte_carlo_full/step6_monte_carlo_full_results.csv`。
- **Required equations：** Cs RMSE、lag、USR、B 相误差。
- **Planned figure/table：** 后续实验图 A；Table 5。
- **Evidence status：** `NEEDS_EXPERIMENT`。
- **Writing caution：** 不用仿真 tracking 代替硬件可辨识性结论。

### 5.2 Experiment B：仅 resistive fault change

- **Scientific question：** 真实或等效阻性支路变化是否会在自适应参数中产生与仿真一致的 false Cs movement，M3/M4 是否呈预期保护行为？
- **Core message：** 直接验证 fault absorption 与 fault protection 的核心趋势。
- **Existing evidence：** 仅有 Case05、fault-amplitude sweep 与 MC F 仿真证据。
- **Source files：** `phase1b_fault_absorption/step2/case05_key_metrics.csv`；`phase2_full_validation/step2b2_deterministic_core/step2b2_deterministic_results.csv`；`step6_monte_carlo_full/step6_monte_carlo_full_results.csv`。
- **Required equations：** fault factor、fault-induced `Delta Cs`、retention error、gate ratio、mean `g`。
- **Planned figure/table：** 后续实验图 B；Table 5。
- **Evidence status：** `NEEDS_EXPERIMENT`。
- **Writing caution：** 不预设硬件上的阈值位置或精确偏置比例。

### 5.3 Experiment C：Cs drift + resistive fault

- **Scientific question：** 同时漂移和故障时，hard freeze 与 continuous weighting 的 protection–adaptation trade-off 能否在实物平台观察？
- **Core message：** 以可控 Cs 漂移和阻性支路变化复现 Case07/08 的趋势，而非追求复现全部随机矩阵。
- **Existing evidence：** 仅有 Case07/08、Step 4 overlap 与 MC O 仿真证据。
- **Source files：** `phase1c_m4_method/step5_simultaneous_drift_fault/`；`step5b_triggered_overlap/`；`phase2_full_validation/step4_overlap_matrix/step4_overlap_results.csv`；`step6_monte_carlo_full/step6_monte_carlo_full_results.csv`。
- **Required equations：** signed F/CF movement、tracking error、W1/W2 retention、post-fault memory；若实验无法构造 F/N/P/A，则不得声称完成同等反事实分解。
- **Planned figure/table：** 后续实验图 C；Table 5。
- **Evidence status：** `NEEDS_EXPERIMENT`。
- **Writing caution：** 不把净移动解释为纯 drift adaptation；必须保留 fault contamination 与方向错误的可能性。

## 6 结论

- **Scientific question：** 在冻结证据允许的范围内，论文能给出哪些机制、方法与边界结论？
- **Core message：** fault absorption mechanism 得到强证据；REW-AI 提供连续、状态一致的信息加权并相对 M2 减少部分吸收；M3/M4 代表不同 protection–adaptation trade-off；模型失配、参考误差、负序与硬件外推边界必须与贡献并列陈述。
- **Existing evidence：** Phase 1B 机理；Phase 1C 方法冻结；Phase 2 deterministic、mismatch、overlap/replay、sensitivity、MC 与 integrated analysis。
- **Source files：** `paper_research/phase2_full_validation/step7_final_analysis/PHASE2_FINAL_ANALYSIS.md`；`paper_research/phase2_full_validation/step7_final_analysis/PAPER_RESULT_MAP.csv`；本阶段 `paper_research/paper_draft/PAPER_EVIDENCE_MAPPING.md`。
- **Required equations：** 不引入新方程；回扣 fault absorption chain 和 `0<g<=1` 的 information-state weighting。
- **Planned figure/table：** Table 5。
- **Evidence status：** `PARTIAL`。仿真范围内结论充分；面向实际装置的最终外推仍需第 5 章低压实验。
- **Writing caution：** 结论不出现“准确区分”“完全消除”“综合最优”“各种不平衡适用”“强模型失配鲁棒性”；明确 primary evidence is simulation-based。

## 7 章节证据成熟度总览

| 章节 | 状态 | 主要缺口 |
|---|---|---|
| 1 引言 | PARTIAL | 文献综述、现有方法差异与正式引用尚未建立 |
| 2 模型与问题 | SUFFICIENT | 仅限冻结 AB/BC、单参考与准静态模型 |
| 3 机理与方法 | SUFFICIENT | phase-consistency 独立贡献未证明；direction 仅诊断 |
| 4.1–4.5 | SUFFICIENT | 结论必须限定于冻结仿真体系 |
| 4.6 边界 | PARTIAL | negative-sequence internal convention unresolved |
| 4.7 敏感性 | SUFFICIENT | 仅单锚点局部分析，不是优化 |
| 4.8 Monte-Carlo | SUFFICIENT | 属于同一仿真框架内统计外部验证，不是现场验证 |
| 5 实验验证 | NEEDS_EXPERIMENT | A/B/C 三类低压实验均未开展 |
| 6 结论 | PARTIAL | 实际装置外推需硬件验证 |
